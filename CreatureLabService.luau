-- Creature Lab: every player gets a plot behind the lobby. Their best fusions stand on
-- pedestals and earn coins every minute, even while offline (capped).
-- Visitors can steal a COPY of a creature by carrying it home (owner keeps theirs,
-- but loses 20% of their waiting coins). Owners defend by tagging the thief or locking.
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local storage = game:GetService("ReplicatedStorage")
local Catalog = require(storage.Shared.Catalog)
local Data = require(script.Parent.DataService)
local Hooks = require(script.Parent.Hooks)

local Lab = {}
Lab.Rates = {Common = 2, Rare = 4, Epic = 8, Legendary = 16, Mythic = 32} -- coins per minute
Lab.MutationBoost = {Rainbow = 3, Golden = 2, Giant = 1.5, Tiny = 1.25}
Lab.OfflineCap = 6 * 60 * 60 -- seconds of stored income
local mutationOrder = {"Rainbow", "Golden", "Giant", "Tiny"}
local STEAL_TIME, STEAL_COOLDOWN, STOLEN_SHARE = 30, 45, .2
local LOCK_TIME, LOCK_COOLDOWN = 60, 180
local tierColors = {
	Common = Color3.fromRGB(200,200,220), Rare = Color3.fromRGB(110,200,255), Epic = Color3.fromRGB(200,120,255),
	Legendary = Color3.fromRGB(255,190,70), Mythic = Color3.fromRGB(255,90,170),
}

local owners = {} -- plot -> player
local plotOf = {} -- player -> plot
local lastCollect, lastSteal = {}, {}
local carrying = {} -- thief -> {victim, plot, slot, recipe, deadline, model}
local hidden = {} -- plot -> {slot = true} while a creature is being carried away
local lockedUntil, lockReadyAt = {}, {}

local function notify(player, text)
	if player and player.Parent == Players then player:SetAttribute("ProgressNotice", text) end
end

function Lab.Slots(level) return math.clamp((level or 1) + 2, 3, 6) end
function Lab.Multiplier(profile) return (1 + .25 * (profile.LabPower or 0)) * (1 + .5 * (profile.Rebirths or 0)) end
function Lab.PowerCost(profile) return math.floor(150 * 1.55 ^ (profile.LabPower or 0)) end

function Lab.BestMutation(profile, id)
	local entry = profile.Book[id or ""]
	if not entry then return nil end
	for _, mutation in mutationOrder do
		if entry[mutation] then return mutation end
	end
end

function Lab.CreatureRate(profile, id)
	local recipe = Catalog.ById[id or ""]
	if not recipe then return 0 end
	local mutation = Lab.BestMutation(profile, id)
	return (Lab.Rates[recipe.Tier] or 1) * (mutation and Lab.MutationBoost[mutation] or 1)
end

function Lab.Rate(profile)
	local total = 0
	for slot = 1, Lab.Slots(profile.Lab) do
		total += Lab.CreatureRate(profile, profile.Favorites[tostring(slot)])
	end
	return total * Lab.Multiplier(profile)
end

function Lab.Pending(profile)
	local last = profile.LabCollect or os.time()
	local seconds = math.clamp(os.time() - last, 0, Lab.OfflineCap)
	return math.floor(Lab.Rate(profile) * seconds / 60)
end

-- Call inside a Data.Change callback before changing slots, so income is banked at the old rate.
function Lab.Settle(saved)
	if saved.LabCollect then saved.Coins += Lab.Pending(saved) end
	saved.LabCollect = os.time()
end

local function locked(plot)
	local owner = owners[plot]
	if not owner then return true end
	if owner:GetAttribute("RoundStatus") == "Playing" then return true, "shielded while its owner is in a round" end
	if (lockedUntil[plot] or 0) > os.clock() then return true, "locked" end
	return false
end

local function paintMutation(model, mutation)
	if not mutation then return end
	local index = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			index += 1
			if mutation == "Golden" then
				if part:IsA("MeshPart") then part.TextureID = "" end
				part.Color = Color3.fromRGB(255, 199, 74)
				part.Material = Enum.Material.Metal
			elseif mutation == "Rainbow" then
				if part:IsA("MeshPart") then part.TextureID = "" end
				part.Color = Color3.fromHSV((index * .19) % 1, .65, 1)
				part.Material = Enum.Material.Glass
			end
		end
	end
	if mutation == "Golden" or mutation == "Rainbow" then
		local core = model:FindFirstChildWhichIsA("BasePart", true)
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = mutation == "Golden" and ColorSequence.new(Color3.fromRGB(255, 225, 120))
			or ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255,90,90)), ColorSequenceKeypoint.new(.5, Color3.fromRGB(90,255,160)), ColorSequenceKeypoint.new(1, Color3.fromRGB(120,120,255))})
		sparkle.Rate = 6
		sparkle.Lifetime = NumberRange.new(.8, 1.4)
		sparkle.Speed = NumberRange.new(1, 3)
		sparkle.Size = NumberSequence.new(.5)
		sparkle.LightEmission = .8
		sparkle.Parent = core
	end
end

local function creature(recipe, mutation)
	local model = Instance.new("Model")
	model.Name = recipe.Name
	local height = 0
	local size = mutation == "Giant" and 1.35 or mutation == "Tiny" and .7 or 1
	for index, ingredient in {recipe.Body, recipe.Head} do
		local asset = storage.Assets:FindFirstChild(ingredient.Model)
		if asset then
			local piece = asset:Clone()
			piece:ScaleTo((index == 1 and 2.1 or 1.35) * size)
			local _, box = piece:GetBoundingBox()
			piece:PivotTo(CFrame.new(0, height + box.Y / 2 - (index == 2 and box.Y * .25 or 0), 0) * piece:GetPivot().Rotation)
			height += box.Y * (index == 1 and 1 or .75)
			for _, part in piece:GetDescendants() do
				if part:IsA("BasePart") then part.Anchored = true part.CanCollide = false part.CanQuery = false part.CanTouch = false end
			end
			piece.Parent = model
		end
	end
	paintMutation(model, mutation)
	return model, height
end

local function tag(parent, name, color, subtitle)
	local gui = Instance.new("BillboardGui")
	gui.Size = subtitle == "" and UDim2.fromScale(4, .8) or UDim2.fromScale(7, 2.2) -- in studs, so labels shrink with distance
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1, 0)
	gui.MaxDistance = subtitle == "" and 30 or 80
	gui.LightInfluence = 0
	local title = Instance.new("TextLabel")
	title.Size = subtitle == "" and UDim2.fromScale(1, 1) or UDim2.new(1, 0, .55, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = color
	title.TextStrokeTransparency = .3
	title.Text = name
	title.Parent = gui
	local income = title:Clone()
	income.Position = UDim2.fromScale(0, .55)
	income.Size = UDim2.new(1, 0, .45, 0)
	income.TextColor3 = Color3.fromRGB(255, 225, 90)
	income.Text = subtitle
	income.Parent = gui
	gui.Parent = parent
end

local function anchorAt(shelf, position)
	local anchor = Instance.new("Part")
	anchor.Name = "Tag" anchor.Transparency = 1 anchor.Anchored = true anchor.CanCollide = false anchor.CanQuery = false anchor.CanTouch = false
	anchor.Size = Vector3.one * .2
	anchor.Position = position
	anchor.Parent = shelf
	return anchor
end

local steal -- forward declaration

function Lab.Refresh(player)
	local plot = plotOf[player]
	local profile = Data.Get(player)
	if not plot or not profile then return end
	local shelf = plot:FindFirstChild("Creatures") or Instance.new("Folder", plot)
	shelf.Name = "Creatures"
	shelf:ClearAllChildren()
	local slots = Lab.Slots(profile.Lab)
	local multiplier = Lab.Multiplier(profile)
	for slot = 1, 6 do
		local pedestal = plot:FindFirstChild("Pedestal" .. slot)
		if not pedestal then continue end
		local old = pedestal:FindFirstChild("StealPrompt")
		if old then old:Destroy() end
		local unlocked = slot <= slots
		pedestal.Transparency = unlocked and 0 or .55
		pedestal.Material = unlocked and Enum.Material.SmoothPlastic or Enum.Material.Glass
		local id = unlocked and profile.Favorites[tostring(slot)]
		local recipe = id and Catalog.ById[id]
		local top = pedestal.Position + Vector3.new(0, pedestal.Size.X / 2, 0)
		if recipe and hidden[plot] and hidden[plot][slot] then
			pedestal.Color = Color3.fromRGB(255, 90, 110)
			tag(anchorAt(shelf, top + Vector3.new(0, 1.5, 0)), "😱 Being stolen!", Color3.fromRGB(255, 120, 130), "Catch the thief!")
		elseif recipe then
			local mutation = Lab.BestMutation(profile, id)
			local model, height = creature(recipe, mutation)
			model:PivotTo(CFrame.new(top) * CFrame.Angles(0, math.pi, 0))
			model:SetAttribute("Bob", true)
			model.Parent = shelf
			pedestal.Color = tierColors[recipe.Tier] or pedestal.Color
			local rate = math.floor(Lab.CreatureRate(profile, id) * multiplier * 10) / 10
			local name = mutation and (mutation == "Golden" and "✨ " or mutation == "Rainbow" and "🌈 " or "") .. mutation .. " " .. recipe.Name or recipe.Name
			tag(anchorAt(shelf, top + Vector3.new(0, height + .6, 0)), name, tierColors[recipe.Tier] or Color3.new(1,1,1), "+" .. rate .. " coins/min")
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "StealPrompt"
			prompt.ActionText = "Steal a copy"
			prompt.ObjectText = recipe.Name
			prompt.HoldDuration = 2
			prompt.MaxActivationDistance = 9
			prompt.RequiresLineOfSight = false
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt:SetAttribute("Slot", slot)
			prompt.Parent = pedestal
			prompt.Triggered:Connect(function(thief) steal(thief, plot, slot) end)
		else
			pedestal.Color = Color3.fromRGB(160, 140, 230)
			tag(anchorAt(shelf, top + Vector3.new(0, 1.5, 0)), unlocked and "Empty slot" or "🔒 Upgrade Lab", Color3.fromRGB(200, 190, 240), unlocked and "Fuse to fill me!" or "")
		end
	end
end

local function burst(part, color, amount)
	local b = Instance.new("ParticleEmitter")
	b.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	b.Color = ColorSequence.new(color)
	b.Speed = NumberRange.new(12, 22)
	b.SpreadAngle = Vector2.new(50, 50)
	b.EmissionDirection = Enum.NormalId.Top
	b.Lifetime = NumberRange.new(.6, 1)
	b.Rate = 0
	b.Parent = part
	b:Emit(amount)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	sound.Volume = .5
	sound.Parent = part
	sound:Play()
	Debris:AddItem(b, 2)
	Debris:AddItem(sound, 2)
end

local function collect(player)
	local now = os.clock()
	if now - (lastCollect[player] or 0) < 1.5 then return end
	lastCollect[player] = now
	local gained = 0
	local updated = Data.Change(player, function(saved)
		local amount = (saved.LabCollect and Lab.Pending(saved) or 0) * (player:GetAttribute("PassLabIncome") and 2 or 1)
		if amount <= 0 then return false end
		saved.LabCollect = os.time()
		saved.Coins += amount
		gained = amount
		return true
	end)
	if updated and gained > 0 then
		notify(player, "Collected " .. gained .. " coins from your Lab!")
		Hooks.Fire("Collect", player, gained)
		local plot = plotOf[player]
		local pad = plot and plot:FindFirstChild("CollectPad")
		if pad then burst(pad, Color3.fromRGB(255, 220, 80), math.clamp(gained, 15, 80)) end
	end
end

-- STEALING -------------------------------------------------------------------
local function endCarry(thief, result)
	local job = carrying[thief]
	if not job then return end
	carrying[thief] = nil
	if job.model then job.model:Destroy() end
	if hidden[job.plot] then hidden[job.plot][job.slot] = nil end
	local humanoid = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and job.speed then humanoid.WalkSpeed = job.speed end
	thief:SetAttribute("Carrying", nil)
	if job.victim.Parent == Players then Lab.Refresh(job.victim) end
	if result == "success" then
		local loot = 0
		Data.Change(job.victim, function(saved)
			if not saved.LabCollect then return false end
			local pending = Lab.Pending(saved)
			loot = math.floor(pending * STOLEN_SHARE)
			if loot <= 0 then return false end
			-- move their collect time forward so their waiting coins drop by the stolen share
			local rate = Lab.Rate(saved)
			if rate > 0 then saved.LabCollect += math.ceil(loot / rate * 60) end
			return true
		end)
		Data.Change(thief, function(saved)
			saved.Book[job.recipe.Id] = saved.Book[job.recipe.Id] or {}
			saved.Coins += loot
			return true
		end)
		Lab.AutoPlace(thief, job.recipe)
		Hooks.Fire("Steal", thief)
		notify(thief, "🦹 You stole a copy of " .. job.recipe.Name .. "!" .. (loot > 0 and (" +" .. loot .. " coins") or ""))
		notify(job.victim, "😤 " .. thief.DisplayName .. " stole a copy of your " .. job.recipe.Name .. "! Lock your Lab next time.")
		local pad = plotOf[thief] and plotOf[thief]:FindFirstChild("CollectPad")
		if pad then burst(pad, Color3.fromRGB(255, 120, 200), 60) end
	elseif result == "caught" then
		notify(thief, "🚨 Caught! " .. job.victim.DisplayName .. " got their creature back.")
		notify(job.victim, "🛡️ You caught " .. thief.DisplayName .. "! Your creature is safe.")
		local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
		if root then root:ApplyImpulse(Vector3.new(0, 60, 0) * root.AssemblyMass) end
	else
		notify(thief, "⏰ The " .. job.recipe.Name .. " ran back home. Be faster next time!")
	end
end

steal = function(thief, plot, slot)
	local victim = owners[plot]
	if not victim or victim == thief or carrying[thief] then return end
	if not plotOf[thief] then return notify(thief, "You need your own Lab to steal") end
	if thief:GetAttribute("RoundStatus") == "Playing" then return end
	local isLocked, why = locked(plot)
	if isLocked then return notify(thief, "This Lab is " .. (why or "locked") .. "!") end
	if os.clock() - (lastSteal[thief] or -999) < STEAL_COOLDOWN then
		return notify(thief, "Catch your breath! Steal again in " .. math.ceil(STEAL_COOLDOWN - (os.clock() - lastSteal[thief])) .. "s")
	end
	if hidden[plot] and hidden[plot][slot] then return end
	local profile = Data.Get(victim)
	local recipe = profile and Catalog.ById[profile.Favorites[tostring(slot)] or ""]
	local character = thief.Character
	local head = character and character:FindFirstChild("Head")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not recipe or not head or not humanoid then return end
	lastSteal[thief] = os.clock()
	hidden[plot] = hidden[plot] or {}
	hidden[plot][slot] = true
	-- carry a small copy above the thief's head
	local model = creature(recipe, nil)
	model:ScaleTo(.55)
	model:PivotTo(head.CFrame * CFrame.new(0, 2.6, 0))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0, weld.Part1 = head, part
			weld.Parent = part
		end
	end
	model.Parent = character
	local job = {victim = victim, plot = plot, slot = slot, recipe = recipe, deadline = os.clock() + STEAL_TIME, model = model, speed = humanoid.WalkSpeed}
	carrying[thief] = job
	humanoid.WalkSpeed = math.max(10, humanoid.WalkSpeed * .75)
	thief:SetAttribute("Carrying", recipe.Name)
	Lab.Refresh(victim)
	notify(thief, "🏃 Run it to YOUR Lab's green pad! " .. STEAL_TIME .. "s")
	notify(victim, "⚠️ " .. thief.DisplayName .. " is stealing your " .. recipe.Name .. "! Tag them to get it back!")
end

local function lockLab(player)
	local plot = plotOf[player]
	if not plot then return end
	local now = os.clock()
	if (lockedUntil[plot] or 0) > now then return end
	if (lockReadyAt[player] or 0) > now then
		return notify(player, "Lock recharging: " .. math.ceil(lockReadyAt[player] - now) .. "s")
	end
	lockedUntil[plot] = now + LOCK_TIME
	lockReadyAt[player] = now + LOCK_TIME + LOCK_COOLDOWN
	notify(player, "🔒 Lab locked for " .. LOCK_TIME .. "s")
	local base = plot.Base
	local wall = Instance.new("Part")
	wall.Name = "LockField"
	wall.Size = Vector3.new(base.Size.X + 1, 12, base.Size.Z + 1)
	wall.CFrame = base.CFrame + Vector3.new(0, 7, 0)
	wall.Color = Color3.fromRGB(255, 80, 110)
	wall.Material = Enum.Material.ForceField
	wall.Transparency = .3
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.CanTouch = false
	wall.Parent = plot
	Debris:AddItem(wall, LOCK_TIME)
end

-- PLOTS ----------------------------------------------------------------------
local function setOwner(plot, player)
	owners[plot] = player
	lockedUntil[plot] = nil
	local field = plot:FindFirstChild("LockField")
	if field then field:Destroy() end
	local label = plot.OwnerSign.Gui.Owner
	label.Text = player and (player.DisplayName .. "'s Lab") or "Empty Lab"
	plot:SetAttribute("Owner", player and player.UserId or 0)
	if not player then
		hidden[plot] = nil
		local shelf = plot:FindFirstChild("Creatures")
		if shelf then shelf:ClearAllChildren() end
		for slot = 1, 6 do
			local pedestal = plot:FindFirstChild("Pedestal" .. slot)
			if pedestal then
				pedestal.Color = Color3.fromRGB(160, 140, 230)
				pedestal.Transparency = 0
				local prompt = pedestal:FindFirstChild("StealPrompt")
				if prompt then prompt:Destroy() end
			end
		end
	end
end

local function board(part, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Board"
	gui.Size = UDim2.fromOffset(220, 70)
	gui.StudsOffset = offset
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = color
	text.TextStrokeTransparency = .2
	text.Text = ""
	text.Parent = gui
	gui.Parent = part
	return text
end

local function assign(player)
	local deadline = os.clock() + 15
	repeat task.wait(.2) until Data.Get(player) or os.clock() > deadline or player.Parent ~= Players
	if player.Parent ~= Players or plotOf[player] then return end
	local profile = Data.Get(player)
	if not profile then return end
	local free
	for _, plot in workspace.CreatureLabs:GetChildren() do
		if plot:IsA("Model") and plot:GetAttribute("PlotIndex") and not owners[plot] then
			if not free or plot:GetAttribute("PlotIndex") < free:GetAttribute("PlotIndex") then free = plot end
		end
	end
	if not free then return end
	plotOf[player] = free
	setOwner(free, player)
	player:SetAttribute("LabPlot", free:GetAttribute("PlotIndex"))
	if not profile.LabCollect then
		Data.Change(player, function(saved)
			if saved.LabCollect then return false end
			saved.LabCollect = os.time()
			return true
		end)
	else
		local waiting = Lab.Pending(profile)
		if waiting > 0 then
			task.delay(4, function()
				notify(player, "Welcome back! Your creatures earned " .. waiting .. " coins. Tap 🧪 My Lab to collect!")
			end)
		end
	end
	Lab.Refresh(player)
end

-- Puts a new discovery on a pedestal: an empty slot first, otherwise it replaces a weaker creature.
function Lab.AutoPlace(player, recipe)
	local already = false
	local placed = Data.Change(player, function(saved)
		local slots = Lab.Slots(saved.Lab)
		local newRate = Lab.CreatureRate(saved, recipe.Id)
		local weakest, weakestRate
		for slot = 1, slots do
			local id = saved.Favorites[tostring(slot)]
			if id == recipe.Id then already = true return false end
			local rate = id and Lab.CreatureRate(saved, id) or -1
			if not weakest or rate < weakestRate then weakest, weakestRate = slot, rate end
		end
		if not weakest or weakestRate >= newRate then return false end
		Lab.Settle(saved)
		saved.Favorites[tostring(weakest)] = recipe.Id
		return true
	end)
	if placed or already then Lab.Refresh(player) end -- `already` may have a new mutation to show
	if placed then
		task.delay(2.5, function()
			local profile = Data.Get(player)
			local rate = profile and Lab.CreatureRate(profile, recipe.Id) or 0
			notify(player, recipe.Name .. " moved into your Lab! +" .. rate .. " coins/min")
		end)
	end
end

function Lab.Start()
	local remotes = storage.Shared.Remotes
	for _, plot in workspace.CreatureLabs:GetChildren() do
		if not (plot:IsA("Model") and plot:GetAttribute("PlotIndex")) then continue end
		setOwner(plot, nil)
		local padText = board(plot.CollectPad, Vector3.new(0, 4, 0), Color3.fromRGB(255, 230, 90))
		local lockText = plot.LockButton.Label.Text
		plot.CollectPad.Touched:Connect(function(part)
			local player = Players:GetPlayerFromCharacter(part.Parent)
			if not player then return end
			if carrying[player] and plotOf[player] == plot then task.spawn(endCarry, player, "success") return end
			if owners[plot] == player then collect(player) end
		end)
		plot.LockButton.Touched:Connect(function(part)
			local player = Players:GetPlayerFromCharacter(part.Parent)
			if player and owners[plot] == player then lockLab(player) end
		end)
		task.spawn(function()
			while plot.Parent do
				local owner = owners[plot]
				local profile = owner and Data.Get(owner)
				if profile then
					local boost = owner:GetAttribute("PassLabIncome") and 2 or 1
					padText.Text = "💰 " .. Lab.Pending(profile) * boost .. "\n+" .. (math.floor(Lab.Rate(profile) * boost * 10) / 10) .. "/min" .. (boost > 1 and " (2×)" or "") .. " · step to collect"
					local now = os.clock()
					local left = (lockedUntil[plot] or 0) - now
					local ready = (lockReadyAt[owner] or 0) - now
					lockText.Text = left > 0 and ("🔒 LOCKED " .. math.ceil(left) .. "s") or ready > 0 and ("🔓 Lock in " .. math.ceil(ready) .. "s") or "🔒 LOCK LAB"
				else
					padText.Text = ""
					lockText.Text = ""
				end
				task.wait(.5)
			end
		end)
	end
	-- steal race: success at home pad (handled by touch), caught by owner, or timeout
	task.spawn(function()
		while true do
			task.wait(.2)
			for thief, job in carrying do
				local root = thief.Character and thief.Character:FindFirstChild("HumanoidRootPart")
				local humanoid = thief.Character and thief.Character:FindFirstChildOfClass("Humanoid")
				local ownerRoot = job.victim.Character and job.victim.Character:FindFirstChild("HumanoidRootPart")
				if thief.Parent ~= Players or not root or not humanoid or humanoid.Health <= 0 then
					task.spawn(endCarry, thief, "dropped")
				elseif ownerRoot and (ownerRoot.Position - root.Position).Magnitude < 5.5 then
					task.spawn(endCarry, thief, "caught")
				elseif os.clock() > job.deadline then
					task.spawn(endCarry, thief, "timeout")
				else
					local home = plotOf[thief] and plotOf[thief]:FindFirstChild("CollectPad")
					if home and (home.Position - root.Position).Magnitude < 5 then task.spawn(endCarry, thief, "success") end
				end
			end
		end
	end)
	remotes.GoLab.OnServerEvent:Connect(function(player)
		local plot = plotOf[player]
		local character = player.Character
		if not plot or not character or player:GetAttribute("RoundStatus") == "Playing" or carrying[player] then return end
		character:PivotTo(CFrame.new(plot.CollectPad.Position + Vector3.new(0, 4, -5)) * CFrame.Angles(0, 0, 0))
	end)
	Players.PlayerAdded:Connect(assign)
	for _, player in Players:GetPlayers() do task.spawn(assign, player) end
	Players.PlayerRemoving:Connect(function(player)
		endCarry(player, "dropped")
		for thief, job in carrying do
			if job.victim == player then endCarry(thief, "dropped") end
		end
		local plot = plotOf[player]
		plotOf[player], lastCollect[player], lastSteal[player], lockReadyAt[player] = nil, nil, nil, nil
		if plot then setOwner(plot, nil) end
	end)
end

return Lab
