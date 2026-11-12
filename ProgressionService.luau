-- Progression: starter gift, lucky first fusion, daily quests, rebirth, and invite rewards.
local Players = game:GetService("Players")
local storage = game:GetService("ReplicatedStorage")
local Catalog = require(storage.Shared.Catalog)
local Data = require(script.Parent.DataService)
local Daily = require(script.Parent.DailyService)
local CreatureLab = require(script.Parent.CreatureLabService)
local Hooks = require(script.Parent.Hooks)

local Progression = {}
local STARTER = "pineapple+strawberry" -- a cute Rare gift for every new player
local INVITE_REWARD = 250

-- Daily quest pool. Three different ones are picked per player per UTC day.
local QUESTS = {
	{Id = "fuse3", Text = "Fuse 3 creatures", Goal = 3, Event = "Fuse", Reward = 150},
	{Id = "fuse6", Text = "Fuse 6 creatures", Goal = 6, Event = "Fuse", Reward = 300},
	{Id = "new2", Text = "Discover 2 new creatures", Goal = 2, Event = "New", Reward = 200},
	{Id = "survive2", Text = "Survive 2 rounds", Goal = 2, Event = "Survive", Reward = 200},
	{Id = "survive4", Text = "Survive 4 rounds", Goal = 4, Event = "Survive", Reward = 350},
	{Id = "rare1", Text = "Fuse a Rare or better creature", Goal = 1, Event = "RarePlus", Reward = 150},
	{Id = "epic1", Text = "Fuse an Epic or better creature", Goal = 1, Event = "EpicPlus", Reward = 300},
	{Id = "collect500", Text = "Collect 500 coins from your Lab", Goal = 500, Event = "Collect", Reward = 250},
	{Id = "steal1", Text = "Steal a creature copy", Goal = 1, Event = "Steal", Reward = 300},
}
local ALL_DONE_BONUS = 300
local tierRank = {Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5}

function Progression.RebirthCost(profile) return 3000 * ((profile.Rebirths or 0) + 1) end
function Progression.RewardMultiplier(profile) return 1 + .5 * (profile.Rebirths or 0) end

-- The same three quests for a player all day, without storing their ids.
local function questsFor(userId, day)
	local rng = Random.new(day * 7919 + userId % 1000003)
	local picked, events = {}, {}
	while #picked < 3 do
		local quest = QUESTS[rng:NextInteger(1, #QUESTS)]
		if not events[quest.Event] then
			events[quest.Event] = true
			table.insert(picked, quest)
		end
	end
	return picked
end

local function questState(saved, day)
	local q = saved.Quests
	if type(q) ~= "table" or q.Day ~= day then
		q = {Day = day, P = {0, 0, 0}, C = {false, false, false}, Bonus = false}
	else
		q = {Day = q.Day, P = table.clone(q.P), C = table.clone(q.C), Bonus = q.Bonus}
	end
	return q
end

function Progression.QuestView(player, profile)
	local day = Daily.Today()
	local q = questState(profile, day)
	local view = {}
	local multiplier = Progression.RewardMultiplier(profile)
	for i, quest in questsFor(player.UserId, day) do
		table.insert(view, {Text = quest.Text, Goal = quest.Goal, Progress = q.P[i], Claimed = q.C[i], Reward = math.floor(quest.Reward * multiplier)})
	end
	return view, q.Bonus, math.floor(ALL_DONE_BONUS * multiplier)
end

local function refreshQuestFlag(player)
	local profile = Data.Get(player)
	if not profile then return end
	local view = Progression.QuestView(player, profile)
	local ready = false
	for _, quest in view do
		if quest.Progress >= quest.Goal and not quest.Claimed then ready = true end
	end
	player:SetAttribute("QuestReady", ready)
end

local function advance(player, event, amount)
	local day = Daily.Today()
	local list = questsFor(player.UserId, day)
	local finished
	local updated = Data.Change(player, function(saved)
		local q = questState(saved, day)
		local changed = false
		finished = nil
		for i, quest in list do
			if quest.Event == event and q.P[i] < quest.Goal then
				q.P[i] = math.min(quest.Goal, q.P[i] + (amount or 1))
				changed = true
				if q.P[i] >= quest.Goal then finished = quest end
			end
		end
		if not changed then return false end
		saved.Quests = q
		return true
	end)
	if updated then
		if finished then player:SetAttribute("ProgressNotice", "📜 Quest complete: " .. finished.Text .. "! Claim it in 📜 Quests") end
		refreshQuestFlag(player)
	end
end

function Progression.ClaimQuest(player, index)
	if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > 3 then return false, "Unknown quest" end
	local day = Daily.Today()
	local list = questsFor(player.UserId, day)
	local message
	local updated = Data.Change(player, function(saved)
		local q = questState(saved, day)
		local quest = list[index]
		if q.C[index] then message = "Already claimed" return false end
		if q.P[index] < quest.Goal then message = "Not finished yet" return false end
		local multiplier = Progression.RewardMultiplier(saved)
		local reward = math.floor(quest.Reward * multiplier)
		q.C[index] = true
		saved.Coins += reward
		message = "+" .. reward .. " coins"
		if q.C[1] and q.C[2] and q.C[3] and not q.Bonus then
			q.Bonus = true
			local bonus = math.floor(ALL_DONE_BONUS * multiplier)
			saved.Coins += bonus
			message ..= " · 🎉 All quests done! +" .. bonus .. " bonus"
		end
		saved.Quests = q
		return true
	end)
	refreshQuestFlag(player)
	return updated ~= nil, message
end

-- REBIRTH ----------------------------------------------------------------------
local function nameTag(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local rebirths = player:GetAttribute("Rebirths") or 0
	if not head then return end
	local old = head:FindFirstChild("RebirthTag")
	if old then old:Destroy() end
	if rebirths <= 0 then return end
	local gui = Instance.new("BillboardGui")
	gui.Name = "RebirthTag"
	gui.Size = UDim2.fromScale(5, 1)
	gui.StudsOffset = Vector3.new(0, 3.4, 0)
	gui.MaxDistance = 60
	gui.LightInfluence = 0
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(255, 220, 90)
	text.TextStrokeTransparency = .2
	text.Text = string.rep("⭐", math.min(rebirths, 3)) .. " Rebirth " .. rebirths
	text.Parent = gui
	gui.Parent = head
end

function Progression.Rebirth(player)
	local message
	local updated = Data.Change(player, function(saved)
		local cost = Progression.RebirthCost(saved)
		if (saved.Lab or 1) < 4 then message = "Unlock all 6 Lab slots first" return false end
		if saved.Coins < cost then message = "You need " .. cost .. " coins to rebirth" return false end
		saved.Rebirths = (saved.Rebirths or 0) + 1
		saved.Coins = 0
		saved.Lab = 1
		saved.LabPower = 0
		local keep = {}
		for slot = 1, 3 do keep[tostring(slot)] = saved.Favorites[tostring(slot)] end
		saved.Favorites = keep
		saved.LabCollect = os.time()
		message = "🌟 REBIRTH " .. saved.Rebirths .. "! Lab income ×" .. (1 + .5 * saved.Rebirths) .. " forever"
		return true
	end)
	if updated then
		player:SetAttribute("Rebirths", updated.Rebirths)
		nameTag(player)
		CreatureLab.Refresh(player)
		refreshQuestFlag(player)
	end
	return updated ~= nil, message
end

-- JOIN: starter gift, first-fusion flag, invite reward ---------------------------
local function rewardInvite(newcomer, inviter)
	local key = tostring(newcomer.UserId)
	local paid = Data.Change(inviter, function(saved)
		saved.Referrals = type(saved.Referrals) == "table" and table.clone(saved.Referrals) or {}
		if saved.Referrals[key] then return false end
		saved.Referrals[key] = true
		saved.Coins += INVITE_REWARD
		return true
	end)
	if paid then
		inviter:SetAttribute("ProgressNotice", "👋 " .. newcomer.DisplayName .. " joined from your invite! +" .. INVITE_REWARD .. " coins")
		Data.Change(newcomer, function(saved)
			saved.Coins += INVITE_REWARD
			return true
		end)
		task.delay(6, function()
			if newcomer.Parent == Players then
				newcomer:SetAttribute("ProgressNotice", "👋 Thanks for joining " .. inviter.DisplayName .. "! +" .. INVITE_REWARD .. " coins")
			end
		end)
	end
end

local function joined(player)
	local deadline = os.clock() + 15
	repeat task.wait(.25) until Data.Get(player) or os.clock() > deadline or player.Parent ~= Players
	local profile = Data.Get(player)
	if not profile or player.Parent ~= Players then return end
	player:SetAttribute("Rebirths", profile.Rebirths or 0)
	player.CharacterAdded:Connect(function() task.wait(.5) nameTag(player) end)
	nameTag(player)
	if not profile.FirstFuseDone then player:SetAttribute("FirstFusePending", true) end
	if not profile.StarterGift then
		local recipe = Catalog.ById[STARTER]
		local gifted = Data.Change(player, function(saved)
			if saved.StarterGift then return false end
			saved.StarterGift = true
			saved.Book[STARTER] = saved.Book[STARTER] or {}
			return true
		end)
		if gifted and recipe then
			task.wait(3) -- let the Lab plot get assigned first
			CreatureLab.AutoPlace(player, recipe)
			task.delay(4, function()
				if player.Parent == Players then
					player:SetAttribute("ProgressNotice", "🎁 Welcome gift: " .. recipe.Name .. " (Rare) is in your Lab earning coins!")
				end
			end)
		end
	end
	refreshQuestFlag(player)
	local ok, joinData = pcall(function() return player:GetJoinData() end)
	local referrer = ok and joinData and tonumber(joinData.ReferredByPlayerId)
	if referrer and referrer > 0 and referrer ~= player.UserId then
		local inviter = Players:GetPlayerByUserId(referrer)
		if inviter then rewardInvite(player, inviter) end
	end
end

function Progression.Start()
	Hooks.On("Fuse", function(player, recipe, mutation, isNew)
		advance(player, "Fuse", 1)
		if isNew then advance(player, "New", 1) end
		local rank = tierRank[recipe.Tier] or 1
		if rank >= 2 then advance(player, "RarePlus", 1) end
		if rank >= 3 then advance(player, "EpicPlus", 1) end
	end)
	Hooks.On("Survive", function(player) advance(player, "Survive", 1) end)
	Hooks.On("Collect", function(player, amount) advance(player, "Collect", amount) end)
	Hooks.On("Steal", function(player) advance(player, "Steal", 1) end)
	Hooks.On("FirstFuse", function(player)
		Data.Change(player, function(saved)
			if saved.FirstFuseDone then return false end
			saved.FirstFuseDone = true
			return true
		end)
	end)
	Players.PlayerAdded:Connect(joined)
	for _, player in Players:GetPlayers() do task.spawn(joined, player) end
end

return Progression
