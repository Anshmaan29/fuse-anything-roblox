-- First-time guide: one big, bouncing instruction at a time for a player's first rounds.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local storage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local shared = storage:WaitForChild("Shared")
local GUIDE_UNTIL = 4 -- show while the player has fewer discoveries than this

local gui = Instance.new("ScreenGui")
gui.Name = "Guide"
gui.ResetOnSpawn = false
gui.DisplayOrder = 12
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(.5, .5)
label.Position = UDim2.fromScale(.5, .29)
label.Size = UDim2.fromScale(.7, .075)
label.BackgroundTransparency = 1
label.Font = Enum.Font.FredokaOne
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.Visible = false
label.Parent = gui
local stroke = Instance.new("UIStroke")
stroke.Thickness = 4
stroke.Color = Color3.fromRGB(45, 20, 80)
stroke.Parent = label
local gradient = Instance.new("UIGradient")
gradient.Rotation = 90
gradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 160), Color3.fromRGB(255, 170, 60))
gradient.Parent = label
local scale = Instance.new("UIScale")
scale.Parent = label

local current = ""
local function show(text)
	if text == current then return end
	current = text
	label.Visible = text ~= ""
	if text == "" then return end
	label.Text = text
	scale.Scale = .3
	TweenService:Create(scale, TweenInfo.new(.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

-- gentle pulse so the eye keeps finding it
task.spawn(function()
	while true do
		task.wait(1.4)
		if label.Visible then
			TweenService:Create(scale, TweenInfo.new(.25, Enum.EasingStyle.Sine), {Scale = 1.08}):Play()
			task.wait(.25)
			TweenService:Create(scale, TweenInfo.new(.25, Enum.EasingStyle.Sine), {Scale = 1}):Play()
		end
	end
end)

while true do
	task.wait(.25)
	local discoveries = player:GetAttribute("Discoveries") or 0
	if discoveries >= GUIDE_UNTIL then show("") continue end
	local phase = shared:GetAttribute("Phase")
	local status = player:GetAttribute("RoundStatus")
	local playing = status == "Playing"
	local items = (player:GetAttribute("Ingredient1") and 1 or 0) + (player:GetAttribute("Ingredient2") and 1 or 0)
	local creature = player:GetAttribute("Creature")
	if playing and phase == "Grab" and items < 2 then
		show("👉 GRAB 2 THINGS!  (" .. items .. "/2)")
	elseif playing and (phase == "Grab" or phase == "Fuse") and not creature then
		show("🧪 JUMP INTO THE GLOWING POT!")
	elseif playing and phase == "Fuse" and creature then
		show("✨ You became " .. creature .. "!")
	elseif playing and phase == "Chaos" and creature then
		show("💥 SURVIVE! Tap your ability button!")
	elseif playing and phase == "Chaos" then
		show("💥 SURVIVE! Jump onto the glowing platforms!")
	elseif phase == "Reward" and status == "Survived" then
		show("🏆 You survived! Your creature went to 🧪 My Lab")
	elseif phase == "Lobby" then
		show("⏳ A round starts soon — get ready!")
	elseif not playing and phase ~= "Lobby" then
		show("👀 Next round soon! Tap 🧪 My Lab to see your creatures")
	else
		show("")
	end
end
