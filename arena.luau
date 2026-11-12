local workspace = game.Workspace
local lighting = game.Lighting
assert(not workspace:FindFirstChild("FuseArena"), "FuseArena already exists")

local arena = Instance.new("Folder")
arena.Name = "FuseArena"
local colors = {
	ink = Color3.fromRGB(34, 34, 65),
	plum = Color3.fromRGB(95, 70, 153),
	lavender = Color3.fromRGB(178, 153, 250),
	mint = Color3.fromRGB(98, 248, 189),
	cream = Color3.fromRGB(255, 241, 202),
	tangerine = Color3.fromRGB(255, 142, 70),
}
local function part(name, size, position, color, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = CFrame.new(position)
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Shape = shape or Enum.PartType.Block
	p.Parent = arena
	return p
end
local function disk(name, diameter, depth, position, color)
	local p = part(name, Vector3.new(depth, diameter, diameter), position, color, Enum.PartType.Cylinder)
	p.CFrame *= CFrame.Angles(0, 0, math.pi/2)
	return p
end
local function sign(name, message, size, position, color, textColor)
	local board = part(name, size, position, color)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 32
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = message
	label.TextColor3 = textColor
	label.TextScaled = true
	label.Parent = gui
end

disk("ArenaShell", 132, 5, Vector3.new(0, -3.5, 0), colors.ink)
disk("ArenaFloor", 128, 2, Vector3.new(0, 0, 0), colors.plum)
disk("PotApron", 37, .25, Vector3.new(0, 1.1, 0), colors.lavender)
disk("PotFoot", 13, 1.4, Vector3.new(0, 1.8, 0), colors.ink)
disk("Pot", 17, 4.5, Vector3.new(0, 3.8, 0), colors.ink)
disk("PotRim", 18, .85, Vector3.new(0, 6.1, 0), colors.mint)
local brew = disk("Brew", 14.8, .25, Vector3.new(0, 6.6, 0), colors.mint)
brew.Material = Enum.Material.Neon
local light = Instance.new("PointLight", brew)
light.Color = colors.mint
light.Range = 20
light.Brightness = 1.6
sign("PotLabel", "FUSE POT", Vector3.new(11, 2, .35), Vector3.new(0, 4, -8.1), colors.mint, colors.ink)
for index = 0, 3 do
	local angle = index * math.pi / 2
	local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
	for step = 1, 3 do
		local p = part("PotStep", Vector3.new(7, .9, 2.6), direction * (17 - step * 2.5) + Vector3.new(0, 1.5 + step * 1.0, 0), colors.cream)
		p.CFrame = CFrame.lookAt(p.Position, p.Position + direction)
	end
end

for index = 0, 11 do
	local angle = index * math.pi / 6
	local radial = Vector3.new(math.cos(angle), 0, math.sin(angle))
	local pillar = radial * 61
	disk("Bumper", 6, 4, pillar + Vector3.new(0, 3, 0), colors.ink)
	disk("BumperCap", 6.2, .7, pillar + Vector3.new(0, 5.2, 0), index % 2 == 0 and colors.mint or colors.tangerine)
	if index % 2 == 0 then
		local ledge = radial * 42
		disk("LavaPlatform", 14, 1.25, ledge + Vector3.new(0, 8.2, 0), colors.tangerine)
		disk("StepHigh", 9, 1.1, ledge - radial * 10 + Vector3.new(0, 5.7, 0), colors.lavender)
		disk("StepLow", 8, 1, ledge - radial * 18 + Vector3.new(0, 3.2, 0), colors.cream)
	end
end

local lobby = Vector3.new(0, 9, -100)
disk("LabBase", 40, 4, lobby, colors.ink)
disk("LabFloor", 38, 1, lobby + Vector3.new(0, 2, 0), colors.mint)
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if not spawn then
	spawn = Instance.new("SpawnLocation", arena)
end
spawn.Name = "LabSpawn"
spawn.Position = lobby + Vector3.new(0, 2.8, 0)
spawn.Size = Vector3.new(6, .5, 6)
spawn.Anchored = true
spawn.Transparency = 1
spawn.CanCollide = false
spawn.Duration = 0
spawn.Parent = arena
sign("LabSign", "FUSE ANYTHING!", Vector3.new(28, 4.5, 1), lobby + Vector3.new(0, 8, 14), colors.ink, colors.cream)
for side = -1, 1, 2 do
	part("LabSignPost", Vector3.new(1, 6, 1), lobby + Vector3.new(11 * side, 4.5, 14), colors.ink)
end
for i = 1, 5 do
	disk("LabObbyPad", 7, 1, lobby + Vector3.new(15 + i * 6, 2 + (i % 3) * 1.1, -4 + (i % 2) * 3), i % 2 == 0 and colors.cream or colors.tangerine)
end

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.CanCollide = false
	baseplate.CanQuery = false
	baseplate.CanTouch = false
	baseplate.Transparency = 1
end
workspace.StreamingEnabled = true
lighting.ClockTime = 14
lighting.Brightness = 2.3
lighting.Ambient = Color3.fromRGB(132, 120, 165)
lighting.OutdoorAmbient = Color3.fromRGB(165, 151, 182)
lighting.GlobalShadows = true
lighting.LightingStyle = Enum.LightingStyle.Realistic
lighting.ShadowSoftness = .7
game.StarterGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
local atmosphere = lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", lighting)
atmosphere.Density = .24
atmosphere.Color = Color3.fromRGB(226, 220, 255)
atmosphere.Decay = Color3.fromRGB(163, 147, 215)
arena.Parent = workspace
return #arena:GetChildren()
