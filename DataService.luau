local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Data = {}
local profiles = {}
local receiptLifetime = 2 * 24 * 60 * 60
local studioStores = {}

function Data.Store(name, ordered)
	if not RunService:IsStudio() then
		local service = game:GetService("DataStoreService")
		return ordered and service:GetOrderedDataStore(name) or service:GetDataStore(name)
	end
	if not studioStores[name] then studioStores[name] = {} end
	local values = studioStores[name]
	return {
		GetAsync = function(_, key) return values[key] end,
		UpdateAsync = function(_, key, update)
			local value = update(values[key])
			if value ~= nil then values[key] = value end
			return value
		end,
		Top = function()
			local rows = {}
			for key,value in values do table.insert(rows,{key=key,value=value}) end
			table.sort(rows,function(a,b) return a.value>b.value end)
			return rows
		end,
	}
end

local store = Data.Store("FuseCoinsV1")

function Data.Retry(callback)
	local lastError
	for attempt = 1, 3 do
		local ok, result = pcall(callback)
		if ok then return true, result end
		lastError = result
		if attempt < 3 then task.wait(2^(attempt-1)) end
	end
	warn("Fuse storage unavailable", lastError)
	return false
end

local function record(value)
	if value == nil then value = {Coins = 0, Receipts = {}} end
	assert(type(value) == "table" and type(value.Coins) == "number"
		and value.Coins >= 0 and value.Coins % 1 == 0 and type(value.Receipts) == "table",
		"Invalid coin record")
	local copy = table.clone(value)
	copy.Receipts = table.clone(value.Receipts)
	for _,key in {"Book","Codes","Favorites","Firsts","DailyBadges","PurchaseReceipts","Vouchers","VoucherHolds","Triples"} do
		copy[key] = value[key] and table.clone(value[key]) or {}
	end
	copy.Wins = value.Wins or 0
	copy.Lab = value.Lab or 1
	copy.Streak = value.Streak or 0
	copy.LastLogin = value.LastLogin or -1
	copy.LastRecipe = value.LastRecipe or -1
	return copy
end

local function showBalance(profile)
	if profile.player.Parent == Players then
		profile.player:SetAttribute("Coins",profile.balance + profile.pending)
	end
end

local function save(profile)
	if profile.saving or not profile.loaded or profile.pending == 0 then return end
	profile.saving = true
	local batch = profile.batch
	if not batch then
		batch = {
			id = HttpService:GenerateGUID(false),
			coins = profile.pending,
			expires = os.time() + receiptLifetime,
		}
		profile.batch = batch
	end
	if os.time() >= batch.expires then
		warn("Fuse coin batch expired before the save outcome could be verified")
		profile.saving = false
		return
	end
	local ok, value = Data.Retry(function()
		return store:UpdateAsync(profile.key,function(previous)
			local saved = record(previous)
			local receipts = table.clone(saved.Receipts)
			local now = os.time()
			for token, expires in receipts do
				if expires <= now then receipts[token] = nil end
			end
			if now >= batch.expires then return nil end
			local balance = saved.Coins
			if not receipts[batch.id] then
				balance += batch.coins
				receipts[batch.id] = batch.expires
			end
			saved.Coins, saved.Receipts = balance, receipts
			return saved
		end)
	end)
	if ok and value then
		profile.balance = value.Coins
		profile.record = value
		profile.pending -= batch.coins
		profile.batch = nil
		showBalance(profile)
	end
	profile.saving = false
end

local function flush(profile, deadline)
	while os.clock() < deadline and (not profile.loaded or profile.saving) do
		task.wait(.1)
	end
	if os.clock() < deadline then save(profile) end
	if os.clock() < deadline and profile.pending > 0 and not profile.batch then save(profile) end
end

local function loadPlayer(player)
	if profiles[player] then return end
	local profile = {player = player, key = tostring(player.UserId), balance = 0, pending = 0}
	profiles[player] = profile
	local ok, value = Data.Retry(function()
		return record(store:GetAsync(profile.key))
	end)
	if ok then
		profile.balance = value.Coins
		profile.record = value
	end
	profile.loaded = true
	showBalance(profile)
	if not ok then
		task.spawn(function()
			while player.Parent==Players and not profile.record do
				task.wait(20)
				if player.Parent~=Players or profile.record then return end
				local loaded,recovered=Data.Retry(function() return record(store:GetAsync(profile.key)) end)
				if loaded and not profile.record then
					profile.balance,profile.record=recovered.Coins,recovered
					showBalance(profile)
				end
			end
		end)
	end
end

function Data.Award(player, coins)
	local profile = profiles[player]
	if profile and coins > 0 then
		profile.pending += coins
		showBalance(profile)
	end
end

function Data.Get(player)
	local profile = profiles[player]
	return profile and profile.record
end

function Data.Change(player, change)
	local profile = profiles[player]
	if not profile then return nil,"Progress is loading" end
	local deadline = os.clock()+12
	while profile.saving or not profile.loaded do
		if os.clock() >= deadline then return nil,"Progress is busy. Try again." end
		task.wait(.08)
	end
	if not profile.record then return nil,"Progress is unavailable. Try again." end
	if profile.pending>0 then save(profile) end
	if profile.saving then return nil,"Progress is busy. Try again." end
	profile.saving = true
	local token = HttpService:GenerateGUID(false)
	local now = os.time()
	local message
	local ok,value = Data.Retry(function()
		return store:UpdateAsync(profile.key,function(previous)
			local saved = record(previous)
			if saved.Receipts[token] then return saved end
			local changed
			changed,message = change(saved)
			if not changed then return nil end
			for id,expires in saved.Receipts do
				if expires <= now then saved.Receipts[id] = nil end
			end
			saved.Receipts[token] = now+receiptLifetime
			return saved
		end)
	end)
	if ok and value then
		profile.record, profile.balance = value,value.Coins
		showBalance(profile)
	end
	profile.saving = false
	if not ok then return nil,"Progress is unavailable. Try again." end
	return value,message
end

function Data.Start()
	Players.PlayerAdded:Connect(loadPlayer)
	for _, player in Players:GetPlayers() do task.spawn(loadPlayer, player) end
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			flush(profile,os.clock()+24)
			if not profile.saving and profile.pending == 0 then profiles[player] = nil end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(60)
			for player, profile in profiles do
				task.spawn(function()
					save(profile)
					if player.Parent ~= Players and not profile.saving and profile.pending == 0 then profiles[player] = nil end
				end)
			end
		end
	end)
	game:BindToClose(function()
		local deadline = os.clock()+25
		local remaining = 0
		for _, profile in profiles do
			remaining += 1
			task.spawn(function()
				flush(profile,deadline)
				remaining -= 1
			end)
		end
		while remaining > 0 and os.clock() < deadline do task.wait(.1) end
	end)
end

return Data
