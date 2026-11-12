local Players = game:GetService("Players")
local storage = game:GetService("ReplicatedStorage")
local Ingredients = require(storage.Shared.Ingredients)
local Models = require(script.Parent.Models)
local random = Random.new()
local pool = {}
local active
local Pickup = {}

function Pickup.BuildAssets()
	for _, ingredient in Ingredients do
		if not storage.Assets:FindFirstChild(ingredient.Model) then
			Models.create(ingredient).Parent = storage.Assets
		end
	end
end

local function release(session, model)
	session.connections[model]:Disconnect()
	session.connections[model] = nil
	model.Parent = nil
	local available = pool[model.Name]
	if #available < 8 then
		table.insert(available, model)
	else
		model:Destroy()
	end
end

function Pickup.Stop()
	local session = active
	active = nil
	if not session then return end
	for model in session.connections do release(session,model) end
	session.folder:Destroy()
end

local function createPickup(ingredient)
	local model = storage.Assets[ingredient.Model]:Clone()
	local hit = Models.part(model, "Pickup", Vector3.new(4, 3.8, 4), model:GetPivot().Position, ingredient.Color)
	hit.Transparency = 1
	hit.CanTouch = true
	local label = Instance.new("BillboardGui", hit)
	label.Size = UDim2.fromOffset(96, 25)
	label.StudsOffset = Vector3.new(0,2.5,0)
	label.MaxDistance = 35
	label.AlwaysOnTop = true
	local title = Instance.new("TextLabel", label)
	title.Size = UDim2.fromScale(1,1)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1,1,1)
	title.TextStrokeTransparency = .2
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.Text = ingredient.DisplayName
	return model
end

function Pickup.Spawn(ingredient, position, delayFromSky, blockedPlayer)
	local session = active
	if not session or (delayFromSky and #session.folder:GetChildren() >= 44) then return end
	local available = pool[ingredient.Model]
	if not available then
		available = {}
		pool[ingredient.Model] = available
	end
	local model = table.remove(available) or createPickup(ingredient)
	local hit = model.Pickup
	local landing = CFrame.new(position) * model:GetPivot().Rotation
	model:PivotTo(delayFromSky and (landing + Vector3.new(0,25,0)) or landing)
	local spawnTime = workspace:GetServerTimeNow()
	local ready = not delayFromSky
	local connection
	connection = hit.Touched:Connect(function(part)
		if active ~= session or session.connections[model] ~= connection or not ready then return end
		local character = part:FindFirstAncestorOfClass("Model")
		local player = Players:GetPlayerFromCharacter(character)
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not player or not root or (root.Position - hit.Position).Magnitude > 5 then return end
		if blockedPlayer == player and workspace:GetServerTimeNow() - spawnTime < 1.5 then return end
		if session.claim(player, ingredient) then release(session,model) end
	end)
	session.connections[model] = connection
	model.Parent = session.folder
	if delayFromSky then
		task.spawn(function()
			for step = 1, 12 do
				task.wait(.055)
				if active ~= session then return end
				model:PivotTo(landing + Vector3.new(0,25 * (1 - (step/12)^2),0))
			end
			ready = true
		end)
	end
end

function Pickup.Start(claim)
	Pickup.Stop()
	local folder = Instance.new("Folder", workspace.FuseArena)
	folder.Name = "Ingredients"
	local session = {folder = folder, claim = claim, connections = {}}
	active = session
	local batch = table.clone(Ingredients)
	task.spawn(function()
		while active == session do
			for i = #batch, 2, -1 do
				local j = random:NextInteger(1, i)
				batch[i], batch[j] = batch[j], batch[i]
			end
			for index, ingredient in batch do
				if active ~= session then return end
				local angle = (index + random:NextNumber(0,.7)) * math.pi * 2 / #batch
				local radius = random:NextNumber(20,48)
				Pickup.Spawn(ingredient, Vector3.new(math.cos(angle)*radius, 2.6, math.sin(angle)*radius), true)
			end
			task.wait(6)
		end
	end)
end

return Pickup
