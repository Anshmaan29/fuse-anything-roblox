local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local storage = game:GetService("ReplicatedStorage")
local Catalog = require(storage.Shared.Catalog)
local Data = require(script.Parent.DataService)
local WorldFirst = require(script.Parent.WorldFirstService)
local Daily = require(script.Parent.DailyService)
local CreatureLab = require(script.Parent.CreatureLabService)
local Progression = require(script.Parent.ProgressionService)
local Hooks = require(script.Parent.Hooks)
local Retention = {}
local rates, ranking, names, fetching, published = {}, {}, {}, {}, {}
local codes = {FUSE25=25}
local boards = {}
for _,stat in {"Wins","Discoveries","WorldFirsts"} do
	boards[stat] = Data.Store("FuseRanks"..stat.."V1",true)
end

local function count(map)
	local total = 0
	for _ in map do total += 1 end
	return total
end

local function publishRanks(player, profile)
	local values = {Wins=profile.Wins,Discoveries=count(profile.Book),WorldFirsts=count(profile.Firsts)}
	local previous=published[player] or {}
	published[player]=previous
	for stat,value in values do
		player:SetAttribute(stat,value)
		if value > (previous[stat] or 0) then
			previous[stat]=value
			task.spawn(function()
				local ok=Data.Retry(function()
					return boards[stat]:UpdateAsync(tostring(player.UserId),function(old) return math.max(old or 0,value) end)
				end)
				if not ok and previous[stat]==value then previous[stat]=nil end
				if RunService:IsStudio() then ranking[stat]=nil end
			end)
		end
	end
end

local function fetchRanks(stat)
	local cached = ranking[stat]
	if cached and os.clock()-cached.at < 60 then return cached.rows end
	if fetching[stat] then return cached and cached.rows or {} end
	fetching[stat]=true
	local ok,rows = Data.Retry(function()
		if RunService:IsStudio() then return boards[stat]:Top() end
		return boards[stat]:GetSortedAsync(false,10):GetCurrentPage()
	end)
	if not ok then
		fetching[stat]=nil
		return cached and cached.rows or {}
	end
	local result = {}
	for i=1,math.min(10,#rows) do
		local row = rows[i]
		local userId = tonumber(row.key)
		local player = userId and Players:GetPlayerByUserId(userId)
		local name = player and player.Name or names[userId]
		if not name and userId and userId > 0 then
			local found,res = pcall(Players.GetNameFromUserIdAsync,Players,userId)
			if found then name = res; names[userId] = res end
		end
		table.insert(result,{Name=name or "Player "..row.key,Value=row.value})
	end
	ranking[stat] = {at=os.clock(),rows=result}
	fetching[stat]=nil
	return result
end

function Retention.Discover(player, recipe, mutation)
	if recipe.TripleId then
		Data.Change(player,function(saved)
			if saved.Triples[recipe.TripleId] then return false end
			saved.Triples[recipe.TripleId]=recipe.Name
			return true
		end)
		return
	end
	local day,dailyRecipe = Daily.Today()
	local milestone = false
	local wasNew = false
	local record = Data.Change(player,function(profile)
		local entry = profile.Book[recipe.Id]
		local firstDiscovery = entry == nil
		wasNew = firstDiscovery
		milestone=false
		local daily = recipe.Id == dailyRecipe.Id and profile.LastRecipe < day
		if entry and (not mutation or entry[mutation]) and not daily then return false end
		entry = entry and table.clone(entry) or {}
		if mutation then entry[mutation] = true end
		profile.Book[recipe.Id] = entry
		if firstDiscovery and count(profile.Book)%10 == 0 then
			profile.Coins += 50
			milestone=true
		end
		if daily then
			profile.LastRecipe = day
			profile.DailyBadges[tostring(day)] = true
		end
		return true
	end)
	task.spawn(CreatureLab.AutoPlace,player,recipe)
	Hooks.Fire("Fuse",player,recipe,mutation,wasNew and record~=nil)
	if record then
		publishRanks(player,record)
		if milestone then player:SetAttribute("ProgressNotice",count(record.Book).." discoveries · +50 coins") end
	end
	if recipe.Id == dailyRecipe.Id and (record or Data.Get(player)) and (record or Data.Get(player)).LastRecipe == day then
		Daily.Badge(player)
		if record then player:SetAttribute("ProgressNotice","Daily mystery solved!") end
	end
	local entry = (record or Data.Get(player))
	entry = entry and entry.Book[recipe.Id]
	if not entry or entry.Owner then return end
	local owner,justWon = WorldFirst.Claim(player,recipe)
	if not owner then return end
	local updated = Data.Change(player,function(profile)
		local saved = profile.Book[recipe.Id]
		if not saved or saved.Owner then return false end
		saved = table.clone(saved)
		saved.Owner = owner.Name
		profile.Book[recipe.Id] = saved
		if owner.UserId == player.UserId then profile.Firsts[recipe.Id] = true end
		return true
	end)
	if updated then publishRanks(player,updated) end
	if justWon then
		storage.Shared.Remotes.WorldFirst:FireAllClients(owner.Name,recipe.Name)
	end
end

function Retention.Win(player)
	Hooks.Fire("Survive",player)
	local record = Data.Change(player,function(profile)
		profile.Wins += 1
		return true
	end)
	if record then publishRanks(player,record) end
end

function Retention.Start(remote)
	local function joined(player)
		task.spawn(function()
			local deadline=os.clock()+12
			repeat task.wait(.12) until Data.Get(player) or os.clock()>deadline or player.Parent~=Players
			local profile=Data.Get(player)
			if profile then
				publishRanks(player,profile)
				player:SetAttribute("DailyReady",profile.LastLogin~=Daily.Today())
			end
		end)
	end
	Players.PlayerAdded:Connect(joined)
	Players.PlayerRemoving:Connect(function(player)
		rates[player],published[player]=nil,nil
	end)
	for _,player in Players:GetPlayers() do joined(player) end
	remote.OnServerInvoke = function(player,action,value,slot)
		local now = os.clock()
		if now-(rates[player] or -10)<.33 then return nil,"Try again in a moment" end
		rates[player]=now
		if action=="LabMode" and type(value)=="boolean" and player:GetAttribute("RoundStatus")~="Playing" then
			player:SetAttribute("LabMode",value)
			return true,value and "You’ll stay in the Lab next round" or "You’ll join the next round"
		end
		local profile=Data.Get(player)
		if not profile then return nil,"Progress is loading" end
		local day = Daily.Today()
		if action == "Read" then
			local stat = boards[value] and value or "Wins"
			local quests,questBonus,bonusReward = Progression.QuestView(player,profile)
			return {
				Book=profile.Book, Triples=profile.Triples, Favorites=profile.Favorites, Lab=profile.Lab,
				Streak=profile.Streak, CanClaim=profile.LastLogin~=day,
				Solved=profile.LastRecipe==day, Hint=Daily.Hint(),
				Ranks=fetchRanks(stat), Stat=stat, LabMode=player:GetAttribute("LabMode")==true,
				Slots=CreatureLab.Slots(profile.Lab), Rate=CreatureLab.Rate(profile), Pending=CreatureLab.Pending(profile),
				LabPower=profile.LabPower or 0, PowerCost=CreatureLab.PowerCost(profile),
				Rebirths=profile.Rebirths or 0, RebirthCost=Progression.RebirthCost(profile), Coins=profile.Coins,
				Quests=quests, QuestBonus=questBonus, QuestBonusReward=bonusReward,
			}
		end
		if action == "Daily" then
			local updated,message=Data.Change(player,function(saved)
				if saved.LastLogin>=day then return false,"Already claimed today" end
				saved.Streak=saved.LastLogin==day-1 and saved.Streak+1 or 1
				saved.LastLogin=day
				local coins=15+math.min(saved.Streak-1,6)*5
				saved.Coins+=coins
				return true,"+"..coins.." coins"
			end)
			if updated then player:SetAttribute("DailyReady",false) end
			return updated~=nil,message
		end
		if action == "Code" and type(value)=="string" and #value<=24 then
			local code=value:upper():match("^%s*([A-Z0-9]+)%s*$")
			local reward=code and codes[code]
			if not reward then return false,"Unknown code" end
			local updated,message=Data.Change(player,function(saved)
				if saved.Codes[code] then return false,"Code already redeemed" end
				saved.Codes[code]=true
				saved.Coins+=reward
				return true,"+"..reward.." coins"
			end)
			return updated~=nil,message
		end
		if action == "Favorite" and type(value)=="string" and #value<=64 and Catalog.ById[value]
			and type(slot)=="number" and slot%1==0 and slot>=1 and slot<=6 then
			local updated,message=Data.Change(player,function(saved)
				if not saved.Book[value] then return false,"Discover that fusion first" end
				if slot>CreatureLab.Slots(saved.Lab) then return false,"Upgrade your Lab to unlock that slot" end
				CreatureLab.Settle(saved)
				for key,id in saved.Favorites do
					if id==value then saved.Favorites[key]=nil end
				end
				saved.Favorites[tostring(slot)]=value
				return true,"Creature placed in your Lab"
			end)
			if updated then CreatureLab.Refresh(player) end
			return updated~=nil,message
		end
		if action == "Upgrade" then
			local updated,message=Data.Change(player,function(saved)
				if saved.Lab>=4 then return false,"Lab fully upgraded" end
				local cost=saved.Lab*100
				if saved.Coins<cost then return false,"You need "..cost.." saved coins" end
				saved.Coins-=cost
				CreatureLab.Settle(saved)
				saved.Lab+=1
				return true,"Lab upgraded · new creature slot!"
			end)
			if updated then CreatureLab.Refresh(player) end
			return updated~=nil,message
		end
		if action == "Quest" then
			return Progression.ClaimQuest(player,value)
		end
		if action == "Rebirth" then
			return Progression.Rebirth(player)
		end
		if action == "Power" then
			local updated,message=Data.Change(player,function(saved)
				local cost=CreatureLab.PowerCost(saved)
				if saved.Coins<cost then return false,"You need "..cost.." saved coins" end
				saved.Coins-=cost
				CreatureLab.Settle(saved)
				saved.LabPower=(saved.LabPower or 0)+1
				return true,"Lab Power "..saved.LabPower.." · creatures earn more!"
			end)
			if updated then CreatureLab.Refresh(player) end
			return updated~=nil,message
		end
		return false,"Action unavailable"
	end
end

return Retention
