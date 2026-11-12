-- Victory dance after surviving a round, and a big emote button in the lobby.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Roblox's own R15 emote animations (free for every game)
local DANCES = {"rbxassetid://507771019", "rbxassetid://507776043", "rbxassetid://507777268"}
local CHEER = "rbxassetid://507770677"
local WAVE = "rbxassetid://507770239"

local function play(id, duration)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator or humanoid.RigType ~= Enum.HumanoidRigType.R15 then return end
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local ok, track = pcall(animator.LoadAnimation, animator, animation)
	if not ok then return end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	track:Play(.2)
	local moved
	moved = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if humanoid.MoveDirection.Magnitude > .1 then track:Stop(.2) moved:Disconnect() end
	end)
	task.delay(duration, function() track:Stop(.3) if moved.Connected then moved:Disconnect() end end)
end

-- After a round, survivors respawn in the lobby: celebrate!
local lastStatus
player:GetAttributeChangedSignal("RoundStatus"):Connect(function()
	lastStatus = player:GetAttribute("RoundStatus") or lastStatus
end)
player.CharacterAdded:Connect(function(character)
	if lastStatus ~= "Survived" then return end
	lastStatus = nil
	character:WaitForChild("Humanoid"):WaitForChild("Animator")
	task.wait(.6)
	play(math.random() < .3 and CHEER or DANCES[math.random(#DANCES)], 4)
end)

-- Emote button (bottom-left, above the side bar area)
local gui = Instance.new("ScreenGui")
gui.Name = "EmoteButtons"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")
local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(1, 1)
holder.Position = UDim2.new(1, -12, 1, -150)
holder.Size = UDim2.fromOffset(60, 136)
holder.BackgroundTransparency = 1
holder.Parent = gui
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 8)
list.Parent = holder
local function emoteButton(icon, id)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(60, 60)
	b.BackgroundColor3 = Color3.fromRGB(255, 160, 210)
	b.Text = icon
	b.TextScaled = true
	b.Font = Enum.Font.FredokaOne
	b.AutoButtonColor = false
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = Color3.fromRGB(45, 20, 80)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	pad.Parent = b
	b.Activated:Connect(function()
		local sc = b:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", b)
		sc.Scale = .8
		TweenService:Create(sc, TweenInfo.new(.3, Enum.EasingStyle.Back), {Scale = 1}):Play()
		play(id == "dance" and DANCES[math.random(#DANCES)] or id, 5)
	end)
	b.Parent = holder
end
emoteButton("💃", "dance")
emoteButton("👋", WAVE)

-- hide while you're a creature in a round (abilities need the space)
local function update()
	holder.Visible = player:GetAttribute("RoundStatus") ~= "Playing"
end
player:GetAttributeChangedSignal("RoundStatus"):Connect(update)
update()
