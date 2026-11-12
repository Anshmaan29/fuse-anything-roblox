-- Small feel-good effects: coin popups and a camera punch when you transform.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "Juice"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local function popup(text, color)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(.5, .5)
	label.Position = UDim2.fromScale(.5 + (math.random() - .5) * .12, .42)
	label.Size = UDim2.fromScale(.32, .09)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.fromRGB(45, 20, 80)
	stroke.Parent = label
	local scale = Instance.new("UIScale")
	scale.Scale = .2
	scale.Parent = label
	label.Parent = gui
	TweenService:Create(scale, TweenInfo.new(.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	task.delay(.7, function()
		TweenService:Create(label, TweenInfo.new(.6), {Position = label.Position - UDim2.fromScale(0, .1), TextTransparency = 1}):Play()
		TweenService:Create(stroke, TweenInfo.new(.6), {Transparency = 1}):Play()
		task.wait(.65)
		label:Destroy()
	end)
end

local lastCoins = player:GetAttribute("Coins")
player:GetAttributeChangedSignal("Coins"):Connect(function()
	local now = player:GetAttribute("Coins")
	if lastCoins and now and now > lastCoins then
		popup("+" .. (now - lastCoins) .. " 🪙", Color3.fromRGB(255, 220, 70))
	end
	lastCoins = now
end)

local function shake(duration, strength)
	local camera = workspace.CurrentCamera
	local start = os.clock()
	local baseFov = camera.FieldOfView
	camera.FieldOfView = baseFov - 12
	TweenService:Create(camera, TweenInfo.new(.5, Enum.EasingStyle.Back), {FieldOfView = baseFov}):Play()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local t = os.clock() - start
		if t > duration then connection:Disconnect() return end
		local power = strength * (1 - t / duration)
		camera.CFrame *= CFrame.Angles(math.rad((math.random() - .5) * power), math.rad((math.random() - .5) * power), 0)
	end)
end

local function watch(character)
	character.ChildAdded:Connect(function(child)
		if child.Name == "FusionCostume" then
			shake(.45, 3)
			popup("🧪 FUSED!", Color3.fromRGB(120, 255, 190))
		end
	end)
end
if player.Character then watch(player.Character) end
player.CharacterAdded:Connect(watch)
