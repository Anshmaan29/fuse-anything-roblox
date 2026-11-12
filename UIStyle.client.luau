-- Restyles every menu and HUD element into a chunky, bouncy "hit game" look:
-- rounded font, thick outlines, glossy gradients, and press/hover bounce.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local styled = {FuseHUD = true, FuseProgress = true, FuseSideBar = true}
local outline = Color3.fromRGB(38, 18, 72)
local font = Font.fromEnum(Enum.Font.FredokaOne)

local function gloss(object)
	if object:FindFirstChildOfClass("UIGradient") then return end
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(.55, Color3.fromRGB(235, 235, 235)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(185, 185, 200)),
	})
	g.Parent = object
end

local function stroke(object, thickness, mode)
	local s = object:FindFirstChildOfClass("UIStroke")
	if not s then s = Instance.new("UIStroke") s.Parent = object end
	s.Thickness = thickness
	s.Color = outline
	s.Transparency = 0
	s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
end

local function bounce(button)
	if button:GetAttribute("Bouncy") then return end
	button:SetAttribute("Bouncy", true)
	local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", button)
	local function to(value, time)
		TweenService:Create(scale, TweenInfo.new(time or .12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = value}):Play()
	end
	button.MouseEnter:Connect(function() to(1.06) end)
	button.MouseLeave:Connect(function() to(1) end)
	button.MouseButton1Down:Connect(function() to(.9, .08) end)
	button.MouseButton1Up:Connect(function() to(1.06) end)
	button.Activated:Connect(function()
		to(1.12, .1)
		task.delay(.12, function() to(1, .2) end)
	end)
end

local function style(object)
	if object:IsA("TextButton") then
		object.FontFace = font
		object.AutoButtonColor = false
		stroke(object, 3)
		gloss(object)
		if object.Text ~= "" then
			local textStroke = object:FindFirstChild("TextOutline")
			if not textStroke then
				object.TextStrokeColor3 = outline
				object.TextStrokeTransparency = object.TextColor3.R + object.TextColor3.G + object.TextColor3.B > 2 and .35 or 1
			end
		end
		bounce(object)
	elseif object:IsA("TextLabel") then
		object.FontFace = font
	elseif object:IsA("Frame") and (object.Name == "Round" or object.Parent and object.Parent.Name == "Progress") then
		-- main HUD panel and the menu window
		stroke(object, 4)
		if not object:FindFirstChildOfClass("UIGradient") then
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 150, 230))
			g.Parent = object
		end
	end
end

local function watch(gui)
	if not styled[gui.Name] then return end
	for _, d in gui:GetDescendants() do style(d) end
	gui.DescendantAdded:Connect(function(d) task.defer(style, d) end)
end
for _, g in playerGui:GetChildren() do watch(g) end
playerGui.ChildAdded:Connect(watch)
