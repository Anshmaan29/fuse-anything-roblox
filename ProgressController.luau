local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local storage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local shared = storage:WaitForChild("Shared")
local remotes = shared:WaitForChild("Remotes")
local remote = remotes:WaitForChild("Progress")
local shopRemote = remotes:WaitForChild("Shop")
local shopCatalog = require(shared:WaitForChild("ShopCatalog"))
local ingredients = require(shared:WaitForChild("Ingredients"))
local catalog = require(shared:WaitForChild("Catalog"))
local sounds = require(script.Parent.Sounds)
local rgb = Color3.fromRGB
local ink, panel, card = rgb(26,23,53),rgb(41,34,77),rgb(59,47,102)
local mint, cream, lavender, gold = rgb(113,250,197),rgb(255,247,223),rgb(219,206,255),rgb(255,197,106)
local heavy, bold = Enum.Font.GothamBlack,Enum.Font.GothamBold

local gui=Instance.new("ScreenGui")
gui.Name="FuseProgress"
gui.DisplayOrder=5
gui.ResetOnSpawn=false
gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
gui.Parent=player:WaitForChild("PlayerGui")
local function corner(object,radius)
	Instance.new("UICorner",object).CornerRadius=UDim.new(0,radius)
end
local function label(parent,value,size,color)
	local object=Instance.new("TextLabel",parent)
	object.BackgroundTransparency=1
	object.Font=bold
	object.TextColor3=color or cream
	object.TextSize=size or 15
	object.Text=value
	object.TextTruncate=Enum.TextTruncate.AtEnd
	return object
end
local function button(parent,value,color)
	local object=Instance.new("TextButton",parent)
	object.Text=value
	object.Font=heavy
	object.TextSize=15
	object.BackgroundColor3=color or card
	object.TextColor3=(color==mint or color==gold) and ink or cream
	object.BorderSizePixel=0
	corner(object,11)
	return object
end

local open=button(gui,"Fusion Lab",mint)
open.Name="OpenLab"
open.Size=UDim2.fromOffset(112,46)
open.AnchorPoint=Vector2.new(.5,0)
open.Position=UDim2.new(.5,0,0,101)
open.TextColor3=ink
local shade=Instance.new("Frame",gui)
shade.Name="Progress"
shade.Size=UDim2.fromScale(1,1)
shade.BackgroundColor3=ink
shade.BackgroundTransparency=.34
shade.Visible=false
local window=Instance.new("Frame",shade)
window.AnchorPoint=Vector2.new(.5,.5)
window.Position=UDim2.fromScale(.5,.5)
window.Size=UDim2.new(1,-24,1,-16)
window.BackgroundColor3=panel
window.BorderSizePixel=0
corner(window,17)
Instance.new("UISizeConstraint",window).MaxSize=Vector2.new(650,400)
local stroke=Instance.new("UIStroke",window)
stroke.Color=lavender
stroke.Transparency=.48
stroke.Thickness=2
local title=label(window,"Fusion Lab",24,mint)
title.Font=heavy
title.TextXAlignment=Enum.TextXAlignment.Left
title.Position=UDim2.fromOffset(16,6)
title.Size=UDim2.new(1,-78,0,39)
local close=button(window,"Close")
close.Size=UDim2.fromOffset(62,44)
close.Position=UDim2.new(1,-72,0,7)
local tabs=Instance.new("Frame",window)
tabs.Size=UDim2.new(1,-24,0,44)
tabs.Position=UDim2.fromOffset(12,53)
tabs.BackgroundTransparency=1
local body=Instance.new("ScrollingFrame",window)
body.Name="Content"
body.Position=UDim2.fromOffset(12,106)
body.Size=UDim2.new(1,-24,1,-138)
body.BackgroundTransparency=1
body.BorderSizePixel=0
body.ScrollBarThickness=4
body.ScrollBarImageColor3=mint
body.CanvasSize=UDim2.new()
body.AutomaticCanvasSize=Enum.AutomaticSize.Y
local notice=label(window,"",13,gold)
notice.Position=UDim2.new(0,14,1,-28)
notice.Size=UDim2.new(1,-28,0,23)
notice.TextXAlignment=Enum.TextXAlignment.Left

local statues=Instance.new("Folder",workspace)
statues.Name="MyLabStatues"
local function redrawStatues(profile)
	statues:ClearAllChildren()
	if true then return end -- creatures now live on the shared Creature Lab plots
	local assets=storage:WaitForChild("Assets")
	for slot=1,3 do
		local recipe=catalog.ById[profile.Favorites[tostring(slot)] or ""]
		if recipe then
			local point=Vector3.new((slot-2)*5.6,14.25,-91)
			local pedestal=Instance.new("Part",statues)
			pedestal.Name=recipe.Name
			pedestal.Anchored=true
			pedestal.CanCollide=false
			pedestal.CanQuery=false
			pedestal.CanTouch=false
			pedestal.Shape=Enum.PartType.Cylinder
			local width=profile.Lab==4 and 3.6 or 3.1
			pedestal.Size=Vector3.new(.45,width,width)
			pedestal.CFrame=CFrame.new(point)*CFrame.Angles(0,0,math.pi/2)
			pedestal.Color=profile.Lab==4 and lavender or (profile.Lab>2 and gold or mint)
			pedestal.Material=profile.Lab>1 and Enum.Material.Neon or Enum.Material.SmoothPlastic
			for index,ingredient in {recipe.Body,recipe.Head} do
				local asset=assets:FindFirstChild(ingredient.Model)
				if not asset then continue end
				local model=asset:Clone()
				local pivot=model:GetPivot()
				model:ScaleTo(index==1 and .65 or .49)
				model:PivotTo(CFrame.new(point+Vector3.new(0,index==1 and 1 or 2.12,0))*pivot.Rotation)
				model.Parent=statues
			end
		end
	end
end

local selected, stat, pinned, page = "Book","Wins",nil,1
local profile, busy
local shopMode, hintFirst, hintResult, shopPrices
local shopBusy=false
local render
local function request(action,value,slot)
	if busy then return end
	busy=true
	task.spawn(function()
		local ok,result,message=pcall(remote.InvokeServer,remote,action,value,slot)
		if not ok then notice.Text="Couldn’t connect. Try again."
		elseif action=="Read" then
			if result then profile=result; redrawStatues(profile) else notice.Text=message or "Progress is loading" end
		else
			notice.Text=message or (result and "Saved" or "Try again")
			if result then
				sounds.Play("Reward")
				task.wait(.36)
				local fetched,newProfile=pcall(remote.InvokeServer,remote,"Read",stat)
				if fetched and newProfile then profile=newProfile; redrawStatues(profile) end
			end
		end
		busy=false
		if shade.Visible then render() end
	end)
end

local function shopRequest(action,key,value)
	if shopBusy then return end
	shopBusy=true
	task.spawn(function()
		local ok,result,message=pcall(shopRemote.InvokeServer,shopRemote,action,key,value)
		shopBusy=false
		if ok and result and action=="Prices" then
			shopPrices=message
		else
			notice.Text=ok and (message or "Done") or "Shop unavailable."
			if ok and result then sounds.Play("Reward") end
			if ok and result and action=="Use" then shopMode=nil end
		end
		if shade.Visible and selected=="Shop" then render() end
	end)
end

local tabButtons={}
local tabsList={"Book","Lab","Quests","Daily","Ranks","Codes","Shop"}
for i,tab in tabsList do
	local control=button(tabs,tab)
	control.Size=UDim2.new(1/#tabsList,-4,1,0)
	control.Position=UDim2.fromScale((i-1)/#tabsList,0)
	control.Activated:Connect(function()
		selected,pinned,page=tab,nil,1
		if tab=="Shop" then shopMode=nil; shopRequest("Prices") end
		notice.Text=""
		sounds.Play("Open")
		render()
		if not profile or tab=="Ranks" then request("Read",stat) end
	end)
	tabButtons[tab]=control
end

local layoutOrder=0
local function order(object)
	layoutOrder+=1
	object.LayoutOrder=layoutOrder
end

local function row(value, color)
	local object=label(body,value,15,color)
	order(object)
	object.BackgroundTransparency=0
	object.BackgroundColor3=card
	object.Size=UDim2.new(1,-7,0,40)
	corner(object,9)
	return object
end
local function control(value, callback)
	local object=button(body,value)
	order(object)
	object.Size=UDim2.new(1,-7,0,44)
	object.Activated:Connect(callback)
	return object
end

local function shopCard(item, owned, price)
	local frame=Instance.new("Frame",body)
	order(frame)
	frame.Size=UDim2.new(1,-7,0,83)
	frame.BackgroundColor3=card
	frame.BorderSizePixel=0
	corner(frame,11)
	local name=label(frame,item.Name,16,mint)
	name.Font=heavy
	name.TextXAlignment=Enum.TextXAlignment.Left
	name.Position=UDim2.fromOffset(11,7)
	name.Size=UDim2.new(1,-119,0,25)
	local benefit=label(frame,item.Benefit,13,cream)
	benefit.TextWrapped=true
	benefit.TextXAlignment=Enum.TextXAlignment.Left
	benefit.TextYAlignment=Enum.TextYAlignment.Top
	benefit.Position=UDim2.fromOffset(11,35)
	benefit.Size=UDim2.new(1,-119,0,43)
	local text=owned and "Owned" or price and (price.." Robux") or "Unavailable"
	if price and not owned then
		local buy=button(frame,text,mint)
		buy.Position=UDim2.new(1,-105,0,19)
		buy.Size=UDim2.fromOffset(94,44)
		buy.Activated:Connect(function() shopRequest("Buy",item.Key) end)
	else
		local status=label(frame,text,13,lavender)
		status.Position=UDim2.new(1,-105,0,19)
		status.Size=UDim2.fromOffset(94,44)
	end
end

render=function()
	for _,child in body:GetChildren() do child:Destroy() end
	body.CanvasPosition=Vector2.zero
	layoutOrder=0
	local list=Instance.new("UIListLayout",body)
	list.SortOrder=Enum.SortOrder.LayoutOrder
	list.Padding=UDim.new(0,6)
	for tab,b in tabButtons do
		b.BackgroundColor3=tab==selected and mint or card
		b.TextColor3=tab==selected and ink or cream
	end
	if selected=="Shop" then
		local picks=player:GetAttribute("PickVouchers") or 0
		local revives=player:GetAttribute("ReviveVouchers") or 0
		if shopMode=="Pick" or shopMode=="Hint" then
			control("Back to shop",function() shopMode,hintFirst,hintResult=nil,nil,nil; render() end)
			if hintResult then row(hintResult,mint) end
			if shopMode=="Hint" then row(hintFirst and ("Second ingredient after "..hintFirst.DisplayName) or "Choose the first ingredient",lavender) end
			for _,ingredient in ingredients do
				control(ingredient.DisplayName,function()
					if shopMode=="Pick" then shopRequest("Use","Pick",ingredient.Id)
					elseif hintFirst and hintFirst~=ingredient then
						local recipe=catalog.ById[hintFirst.Id.."+"..ingredient.Id]
						hintResult=recipe.Name.." · "..recipe.Tier
						hintFirst=nil
						render()
					else hintFirst=ingredient; hintResult=nil; render() end
				end)
			end
			return
		end
		if player:GetAttribute("PassVIP") then control("Visit / leave VIP lounge",function() shopRequest("VIP") end) end
		if player:GetAttribute("PassBookHints") then control("Preview an ordered fusion",function() shopMode="Hint"; render() end) end
		if picks>0 then control("Choose an ingredient · "..picks,function() shopMode="Pick"; render() end) end
		if revives>0 then control("Use solo revive · "..revives,function() shopRequest("Use","Revive") end) end
		row("Every purchase has a fixed benefit",mint)
		for _,item in shopCatalog do
			local owned=item.Kind=="Pass" and player:GetAttribute("Pass"..item.Key)
			local price=shopPrices and shopPrices[item.Key]
			shopCard(item,owned,price)
		end
		return
	end
	if not profile then row("Loading your progress…",lavender); return end
	if selected=="Book" then
		local entries={}
		for id,data in profile.Book do
			local recipe=catalog.ById[id]
			if recipe then table.insert(entries,{recipe=recipe,data=data}) end
		end
		table.sort(entries,function(a,b) return a.recipe.Name<b.recipe.Name end)
		row(string.format("%d / %d discovered · %.1f%% complete",#entries,#catalog.Ordered,#entries/#catalog.Ordered*100),mint)
		row((10-#entries%10).." more to earn 50 coins",gold)
		if pinned then
			control("Back to discoveries",function() pinned=nil; render() end)
			local recipe=catalog.ById[pinned]
			local data=profile.Book[pinned]
			row(recipe.Name.." · "..recipe.Subtitle)
			local preview=Instance.new("ViewportFrame",body)
			order(preview)
			preview.Size=UDim2.new(1,-7,0,118)
			preview.BackgroundColor3=card
			preview.LightColor=cream
			preview.Ambient=lavender
			corner(preview,9)
			local camera=Instance.new("Camera",preview)
			camera.CFrame=CFrame.lookAt(Vector3.new(4,3,-7),Vector3.new(0,1.15,0))
			camera.FieldOfView=32
			preview.CurrentCamera=camera
			for i,ingredient in {recipe.Body,recipe.Head} do
				local asset=storage.Assets:FindFirstChild(ingredient.Model)
				if not asset then continue end
				local model=asset:Clone()
				model:ScaleTo(i==1 and .95 or .65)
				model:PivotTo(CFrame.new(0,i==1 and .45 or 2.1,0)*model:GetPivot().Rotation)
				model.Parent=preview
			end
			row(data.Owner and ("World First · @"..data.Owner) or "World First pending",lavender)
			local variants={}
			for _,mutation in {"Golden","Giant","Tiny","Rainbow"} do
				if data[mutation] then table.insert(variants,mutation) end
			end
			if #variants>0 then row(table.concat(variants," · "),gold) end
			for i=1,(profile.Slots or 3) do control("Put in Lab slot "..i,function() request("Favorite",pinned,i) end) end
		else
			if #entries==0 then row("Find your first fusion in the arena",lavender) end
			local triples={}
			for _,name in profile.Triples or {} do table.insert(triples,name) end
			table.sort(triples)
			if #triples>0 then row(#triples.." triple fusions",gold) end
			local total=#entries+#triples
			local pages=math.max(1,math.ceil(total/12))
			page=math.clamp(page,1,pages)
			if pages>1 then control("Page "..page.." / "..pages.."  ·  Next",function() page=page%pages+1; render() end) end
			for i=(page-1)*12+1,math.min(page*12,total) do
				local entry=entries[i]
				if entry then
					local recipe=entry.recipe
					control(recipe.Name.."  ·  "..recipe.Tier,function() pinned=recipe.Id; render() end)
				else
					row(triples[i-#entries].."  ·  Triple",cream)
				end
			end
		end
	elseif selected=="Lab" then
		row("Level "..profile.Lab.." · Power "..(profile.LabPower or 0).." · +"..(math.floor((profile.Rate or 0)*10)/10).." coins/min",mint)
		row("💰 "..(profile.Pending or 0).." waiting · step on your Lab's green pad",gold)
		control("⚡ Lab Power +25% income · "..(profile.PowerCost or 150).." coins",function() request("Power") end)
		control(profile.LabMode and "Join the next round" or "Stay in the Lab",function() request("LabMode",not profile.LabMode) end)
		for i=1,(profile.Slots or 3) do
			local recipe=catalog.ById[profile.Favorites[tostring(i)] or ""]
			row("Slot "..i.." · "..(recipe and recipe.Name or "Empty"))
		end
		if profile.Lab<4 then control("🔓 New creature slot · " .. (profile.Lab*100) .. " coins",function() request("Upgrade") end) end
		local rebirths=profile.Rebirths or 0
		row("🌟 Rebirth "..rebirths.." · Lab income ×"..(1+.5*rebirths).." · Round coins +"..(25*rebirths).."%",gold)
		if profile.Lab>=4 then
			local reb=control("🌟 REBIRTH for "..(profile.RebirthCost or 3000).." coins · resets coins & Lab level, keeps Book",function() request("Rebirth") end)
			reb.BackgroundColor3=gold
			reb.TextColor3=ink
			reb.TextWrapped=true
		else
			row("Unlock all 6 slots to Rebirth ("..(profile.RebirthCost or 3000).." coins)",lavender)
		end
	elseif selected=="Quests" then
		row("📜 Daily Quests · new ones every day",mint)
		for i,quest in profile.Quests or {} do
			local done=quest.Progress>=quest.Goal
			local text=quest.Text.."  ·  "..math.min(quest.Progress,quest.Goal).."/"..quest.Goal.."  ·  +"..quest.Reward.." 🪙"
			if quest.Claimed then
				row("✅ "..text,lavender)
			elseif done then
				local claim=control("🎁 CLAIM · "..text,function() request("Quest",i) end)
				claim.BackgroundColor3=gold
				claim.TextColor3=ink
			else
				row("⏳ "..text,cream)
			end
		end
		row(profile.QuestBonus and "🎉 All-quests bonus claimed!" or ("Finish all 3 for a +"..(profile.QuestBonusReward or 300).." coin bonus"),gold)
	elseif selected=="Daily" then
		local hint=row(profile.Hint,lavender)
		hint.TextWrapped=true
		hint.Size=UDim2.new(1,-7,0,48)
		if profile.CanClaim then control("Claim daily coins",function() request("Daily") end) end
		row("Login streak · "..profile.Streak..(profile.Streak==1 and " day" or " days"),mint)
		if profile.Solved then row("Mystery solved · Daily stamp earned",gold) end
	elseif selected=="Ranks" then
		for _,metric in {"Wins","Discoveries","WorldFirsts"} do
			local title=metric=="WorldFirsts" and "World Firsts" or metric
			control((metric==stat and "• " or "")..title,function() stat=metric; request("Read",stat) end)
		end
		if profile.Stat==stat then
			if #profile.Ranks==0 then row("No scores yet",lavender) end
			for i,rank in profile.Ranks do row(i..".  "..rank.Name.."   ·   "..rank.Value) end
		end
	elseif selected=="Codes" then
		local input=Instance.new("TextBox",body)
		order(input)
		input.Size=UDim2.new(1,-7,0,48)
		input.Font=bold
		input.TextColor3=cream
		input.PlaceholderColor3=lavender
		input.TextSize=16
		input.Text=""
		input.PlaceholderText="Enter a reward code"
		input.BackgroundColor3=card
		input.ClearTextOnFocus=false
		corner(input,9)
		control("Redeem",function() request("Code",input.Text) end)
	end
end

local menuAllowed=true
local function toggle()
	if shade.Visible then
		shade.Visible=false
	elseif menuAllowed then
		shade.Visible=true
		sounds.Play("Open")
		if player:GetAttribute("RoundStatus")=="Playing" then selected,shopMode="Shop","Pick" end
		render()
		if selected=="Shop" then shopRequest("Prices") else request("Read",stat) end
	end
end
open.Activated:Connect(toggle)
-- Side bar buttons open a tab directly
local openTab=Instance.new("BindableEvent")
openTab.Name="OpenTab"
openTab.Parent=gui
openTab.Event:Connect(function(tab)
	if not menuAllowed then return end
	if shade.Visible and selected==tab then shade.Visible=false return end
	selected,pinned,page,shopMode=tab,nil,1,nil
	shade.Visible=true
	notice.Text=""
	sounds.Play("Open")
	render()
	if tab=="Shop" then shopRequest("Prices") else request("Read",stat) end
end)
UserInputService.InputBegan:Connect(function(input,processed)
	if not processed and input.KeyCode==Enum.KeyCode.L then toggle() end
end)
close.Activated:Connect(function() shade.Visible=false end)
local function roundChanged()
	local phase=shared:GetAttribute("Phase")
	local playing=player:GetAttribute("RoundStatus")=="Playing"
	local canPick=playing and phase=="Grab" and (player:GetAttribute("PickVouchers") or 0)>0
	menuAllowed=not playing or phase=="Lobby" or phase=="Reward" or canPick
	gui:SetAttribute("MenuAllowed",menuAllowed)
	open.Visible=canPick -- the side bar handles normal menu opening
	open.Text="Use voucher"
	if not menuAllowed then shade.Visible=false end
end
shared:GetAttributeChangedSignal("Phase"):Connect(roundChanged)
player:GetAttributeChangedSignal("RoundStatus"):Connect(roundChanged)
player:GetAttributeChangedSignal("PickVouchers"):Connect(roundChanged)
roundChanged()
task.delay(2,function() request("Read",stat) end)
