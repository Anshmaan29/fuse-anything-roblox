local Marketplace = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local studio = game:GetService("RunService"):IsStudio()
local shared = game:GetService("ReplicatedStorage").Shared
local catalog = require(shared.ShopCatalog)
local Data = require(script.Parent.DataService)
local Shop = {}
local products, passIds, byKey = {}, {}, {}
local rates, prices, busy = {}, {}, {}
local pricing=false
for _, item in catalog do
	byKey[item.Key]=item
	if item.Id>0 then
		local index=item.Kind=="Pass" and passIds or products
		assert(not index[item.Id],"Duplicate shop ID")
		index[item.Id]=item
	end
end

local function publish(player, profile)
	player:SetAttribute("PickVouchers",profile.Vouchers.Pick or 0)
	player:SetAttribute("ReviveVouchers",profile.Vouchers.Revive or 0)
end

function Shop.ProcessReceipt(receipt)
	local item=products[receipt.ProductId]
	local player=Players:GetPlayerByUserId(receipt.PlayerId)
	if not item or not player or type(receipt.PurchaseId)~="string" or #receipt.PurchaseId==0 then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local result=Data.Change(player,function(saved)
		if saved.PurchaseReceipts[receipt.PurchaseId] then return true end
		if item.Coins then
			saved.Coins+=item.Coins
		else
			saved.Vouchers[item.Key]=(saved.Vouchers[item.Key] or 0)+1
		end
		saved.PurchaseReceipts[receipt.PurchaseId]=true
		return true
	end)
	if not result then return Enum.ProductPurchaseDecision.NotProcessedYet end
	if player.Parent==Players then publish(player,result) end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function recover(player, profile)
	local expired=false
	for _,hold in profile.VoucherHolds do
		if hold.Expires<=os.time() then expired=true; break end
	end
	if expired then
		local saved=Data.Change(player,function(record)
			local changed=false
			for id,hold in record.VoucherHolds do
				if hold.Expires<=os.time() then
					record.Vouchers[hold.Kind]=(record.Vouchers[hold.Kind] or 0)+1
					record.VoucherHolds[id]=nil
					changed=true
				end
			end
			return changed
		end)
		profile=saved or profile
	end
	publish(player,profile)
end

function Shop.UseVoucher(player, kind, prepare)
	if (kind~="Pick" and kind~="Revive") or busy[player] then return false,"Try again in a moment." end
	local profile=Data.Get(player)
	if profile and (profile.Vouchers[kind] or 0)<1 and next(profile.VoucherHolds) then
		recover(player,profile)
		profile=Data.Get(player)
	end
	if not profile or (profile.Vouchers[kind] or 0)<1 then return false,"You need a voucher." end
	local apply,message=prepare()
	if not apply then return false,message end
	busy[player]=true
	local id=Http:GenerateGUID(false)
	local held=Data.Change(player,function(saved)
		if (saved.Vouchers[kind] or 0)<1 then return false end
		saved.Vouchers[kind]-=1
		saved.VoucherHolds[id]={Kind=kind,Expires=os.time()+180}
		return true
	end)
	if not held then busy[player]=nil; return false,"Voucher unavailable. Try again." end
	publish(player,held)
	local ok,applied=pcall(apply)
	if not ok then warn("Voucher could not be used",applied) end
	local used=ok and applied==true
	local function finish()
		local saved=Data.Change(player,function(record)
			if not record.VoucherHolds[id] then return true end
			record.VoucherHolds[id]=nil
			if not used then record.Vouchers[kind]=(record.Vouchers[kind] or 0)+1 end
			return true
		end)
		if saved and player.Parent==Players then publish(player,saved) end
		return saved
	end
	if not finish() and player.Parent==Players then
		task.delay(5,function()
			if player.Parent~=Players or finish() then return end
			task.delay(180,function()
				local profile=Data.Get(player)
				if player.Parent==Players and profile then recover(player,profile) end
			end)
		end)
	end
	busy[player]=nil
	return used,used and "Voucher used" or "The round moved on. Your voucher will return."
end

local function refreshPass(player,item)
	if studio or item.Id<=0 then return end
	local ok,owned=pcall(Marketplace.UserOwnsGamePassAsync,Marketplace,player.UserId,item.Id)
	if ok and player.Parent==Players then player:SetAttribute("Pass"..item.Key,owned) end
end

local function nameplate(player)
	local character=player.Character
	local head=character and character:WaitForChild("Head",4)
	if not head or not player:GetAttribute("PassVIP") or head:FindFirstChild("VIPName") then return end
	local tag=Instance.new("BillboardGui")
	tag.Name="VIPName"
	tag.Size=UDim2.fromOffset(155,28)
	tag.StudsOffset=Vector3.new(0,2.3,0)
	tag.MaxDistance=38
	local label=Instance.new("TextLabel",tag)
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.Text=player.DisplayName.."  ·  VIP"
	label.Font=Enum.Font.GothamBold
	label.TextSize=14
	label.TextColor3=Color3.fromRGB(255,202,91)
	label.TextStrokeTransparency=.24
	tag.Parent=head
end

function Shop.Start(remote, round)
	Marketplace.ProcessReceipt=Shop.ProcessReceipt
	local function joined(player)
		player.CharacterAdded:Connect(function() task.spawn(nameplate,player) end)
		player:GetAttributeChangedSignal("PassVIP"):Connect(function() task.spawn(nameplate,player) end)
		task.spawn(function()
			local deadline=os.clock()+16
			repeat task.wait(.12) until Data.Get(player) or player.Parent~=Players or os.clock()>deadline
			local profile=Data.Get(player)
			if profile and player.Parent==Players then recover(player,profile) end
		end)
		for _,item in passIds do task.spawn(refreshPass,player,item) end
	end
	Players.PlayerAdded:Connect(joined)
	Players.PlayerRemoving:Connect(function(player) rates[player],busy[player]=nil,nil end)
	for _,player in Players:GetPlayers() do joined(player) end
	Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,id,purchased)
		local item=passIds[id]
		if purchased and item then task.spawn(refreshPass,player,item) end
	end)
	remote.OnServerInvoke=function(player,action,key,value)
		local now=os.clock()
		if now-(rates[player] or -10)<.45 then return false,"Try again in a moment." end
		rates[player]=now
		if action=="Prices" then
			local results={}
			if pricing then return false,"Prices are loading." end
			pricing=true
			for _,item in catalog do
				if item.Id<=0 or studio then continue end
				local cached=prices[item.Key]
				if not cached or now-cached.At>90 then
					local infoType=item.Kind=="Pass" and Enum.InfoType.GamePass or Enum.InfoType.Product
					local ok,info=pcall(Marketplace.GetProductInfoAsync,Marketplace,item.Id,infoType)
					cached={At=now,Price=ok and info.IsForSale and info.PriceInRobux or false}
					prices[item.Key]=cached
				end
				results[item.Key]=cached.Price
			end
			pricing=false
			return true,results
		elseif action=="Buy" and type(key)=="string" then
			local item=byKey[key]
			if not item or item.Id<=0 or studio then return false,"Unavailable in this place." end
			if item.Kind=="Pass" and player:GetAttribute("Pass"..key) then return false,"Already owned." end
			local prompt=item.Kind=="Pass" and Marketplace.PromptGamePassPurchase or Marketplace.PromptProductPurchase
			local ok=pcall(prompt,Marketplace,player,item.Id)
			return ok,ok and "Roblox purchase prompt opened." or "Purchase prompt unavailable."
		elseif action=="Use" and type(key)=="string" and (key=="Pick" or key=="Revive") then
			return Shop.UseVoucher(player,key,function() return round.PrepareVoucher(player,key,value) end)
		elseif action=="VIP" then
			return round.VIP(player)
		end
		return false,"Action unavailable."
	end
end

return Shop
