-- Makes creatures on Lab pedestals bounce and slowly turn (only on this screen).
local RunService = game:GetService("RunService")
local labs = workspace:WaitForChild("CreatureLabs")
local bases = setmetatable({}, {__mode = "k"})
local list = {}

local function gather()
	table.clear(list)
	for _, model in labs:GetDescendants() do
		if model:IsA("Model") and model:GetAttribute("Bob") then
			if not bases[model] then bases[model] = {model:GetPivot(), math.random() * 6} end
			table.insert(list, model)
		end
	end
end

gather()
labs.DescendantAdded:Connect(function() task.defer(gather) end)
labs.DescendantRemoving:Connect(function() task.defer(gather) end)

local me = game:GetService("Players").LocalPlayer
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local camera = workspace.CurrentCamera
	local root = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
	for _, model in list do
		local base = bases[model]
		if base and model.Parent and (camera.CFrame.Position - base[1].Position).Magnitude < 120 then
			local near = root and (root.Position - base[1].Position).Magnitude < 14
			if near then
				-- happy wave: faster hops, wiggle side to side and turn to face you
				local hop = math.abs(math.sin(t * 6 + base[2])) * 1.2
				local look = Vector3.new(root.Position.X, base[1].Position.Y, root.Position.Z)
				local facing = CFrame.lookAt(base[1].Position, look)
				model:PivotTo(facing * CFrame.new(0, hop, 0) * CFrame.Angles(0, 0, math.sin(t * 9) * .25))
			else
				local phase = t * 2.2 + base[2]
				local hop = math.abs(math.sin(phase)) * .6
				model:PivotTo(base[1] * CFrame.new(0, hop, 0) * CFrame.Angles(0, math.sin(t * .6 + base[2]) * .5, 0))
			end
		end
	end
end)

-- Hide the "Steal" prompt on your OWN creatures
local player = game:GetService("Players").LocalPlayer
local function checkPrompt(prompt)
	if not prompt:IsA("ProximityPrompt") then return end
	local plot = prompt:FindFirstAncestorOfClass("Model")
	while plot and not plot:GetAttribute("PlotIndex") do plot = plot.Parent and plot.Parent:FindFirstAncestorOfClass("Model") end
	prompt.Enabled = not (plot and plot:GetAttribute("Owner") == player.UserId)
end
for _, d in labs:GetDescendants() do checkPrompt(d) end
labs.DescendantAdded:Connect(checkPrompt)

-- Big banner while you carry a stolen creature
local gui = Instance.new("ScreenGui")
gui.Name = "StealBanner"
gui.ResetOnSpawn = false
gui.DisplayOrder = 15
gui.Parent = player:WaitForChild("PlayerGui")
local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(.5, 0)
banner.Position = UDim2.fromScale(.5, .2)
banner.Size = UDim2.fromScale(.6, .07)
banner.BackgroundTransparency = 1
banner.Font = Enum.Font.FredokaOne
banner.TextScaled = true
banner.TextColor3 = Color3.fromRGB(255, 120, 200)
banner.TextStrokeTransparency = 0
banner.Visible = false
banner.Parent = gui
local function carryChanged()
	local name = player:GetAttribute("Carrying")
	banner.Visible = name ~= nil
	if name then banner.Text = "🦹 Carrying " .. name .. "! Run to YOUR Lab's green pad!" end
end
player:GetAttributeChangedSignal("Carrying"):Connect(carryChanged)
