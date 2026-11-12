-- Left-side icon bar like popular Roblox games: Book, My Lab, Shop, Daily, Ranks, Music.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local storage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remotes = storage:WaitForChild("Shared"):WaitForChild("Remotes")
local goLab = remotes:WaitForChild("GoLab")
local playerGui = player:WaitForChild("PlayerGui")
local progress = playerGui:WaitForChild("FuseProgress")
local openTab = progress:WaitForChild("OpenTab")
local rgb = Color3.fromRGB

local gui = Instance.new("ScreenGui")
gui.Name = "FuseSideBar"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = playerGui

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0, .5)
bar.Position = UDim2.new(0, 10, .52, 0)
bar.Size = UDim2.fromOffset(74, 0)
bar.AutomaticSize = Enum.AutomaticSize.Y
bar.BackgroundTransparency = 1
bar.Parent = gui
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = bar
local scale = Instance.new("UIScale")
scale.Parent = bar
local function fit()
	local height = workspace.CurrentCamera.ViewportSize.Y
	scale.Scale = math.clamp(height / 640, .55, 1)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
fit()

local function iconButton(order, icon, caption, color)
	local b = Instance.new("TextButton")
	b.Name = caption
	b.LayoutOrder = order
	b.Size = UDim2.fromOffset(74, 66)
	b.BackgroundColor3 = color
	b.AutoButtonColor = false
	b.Text = ""
	b:SetAttribute("Fancy", true)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 16)
	local emoji = Instance.new("TextLabel")
	emoji.Name = "Icon"
	emoji.BackgroundTransparency = 1
	emoji.Size = UDim2.new(1, 0, .64, 0)
	emoji.Position = UDim2.fromScale(0, .02)
	emoji.TextScaled = true
	emoji.Font = Enum.Font.FredokaOne
	emoji.Text = icon
	emoji.Parent = b
	local text = Instance.new("TextLabel")
	text.Name = "Caption"
	text.BackgroundTransparency = 1
	text.Size = UDim2.new(1, -6, .3, 0)
	text.Position = UDim2.new(0, 3, .66, 0)
	text.TextScaled = true
	text.Font = Enum.Font.FredokaOne
	text.TextColor3 = rgb(255, 255, 255)
	text.Text = caption
	local ts = Instance.new("UIStroke")
	ts.Thickness = 1.6
	ts.Color = rgb(40, 20, 70)
	ts.Parent = text
	text.Parent = b
	b.Parent = bar
	return b
end

local book = iconButton(1, "📖", "Book", rgb(120, 110, 255))
local lab = iconButton(2, "🧪", "My Lab", rgb(70, 215, 140))
local shop = iconButton(3, "🛒", "Shop", rgb(255, 170, 60))
local daily = iconButton(4, "🎁", "Daily", rgb(255, 95, 150))
local ranks = iconButton(5, "🏆", "Ranks", rgb(80, 180, 255))
local quests = iconButton(6, "📜", "Quests", rgb(255, 200, 70))
local invite = iconButton(7, "👋", "Invite", rgb(90, 220, 220))
local music = iconButton(8, "🔊", "Music", rgb(150, 120, 200))

book.Activated:Connect(function() openTab:Fire("Book") end)
shop.Activated:Connect(function() openTab:Fire("Shop") end)
daily.Activated:Connect(function() openTab:Fire("Daily") end)
ranks.Activated:Connect(function() openTab:Fire("Ranks") end)
quests.Activated:Connect(function() openTab:Fire("Quests") end)
invite.Activated:Connect(function()
	-- Roblox's built-in friend invite. Rewards are paid on the server when a friend joins.
	local SocialService = game:GetService("SocialService")
	local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
	if ok and can then
		local options = Instance.new("ExperienceInviteOptions")
		options.PromptMessage = "Fuse creatures with me! We both get 250 coins 🪙"
		pcall(SocialService.PromptGameInvite, SocialService, player, options)
	else
		player:SetAttribute("ProgressNotice", "Invites aren't available on this device right now")
	end
end)
lab.Activated:Connect(function()
	if player:GetAttribute("RoundStatus") == "Playing" then return end
	goLab:FireServer()
end)
music.Activated:Connect(function()
	local muted = not player:GetAttribute("MusicMuted")
	player:SetAttribute("MusicMuted", muted)
	music.Icon.Text = muted and "🔇" or "🔊"
end)

-- Gentle attention pulse on the Daily button while a reward is waiting
task.spawn(function()
	while true do
		task.wait(2.5)
		for _, pair in {{daily, "DailyReady"}, {quests, "QuestReady"}} do
			local button, flag = pair[1], pair[2]
			if player:GetAttribute(flag) then
				local s = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", button)
				TweenService:Create(s, TweenInfo.new(.18, Enum.EasingStyle.Back), {Scale = 1.15}):Play()
				task.delay(.2, function() TweenService:Create(s, TweenInfo.new(.2), {Scale = 1}):Play() end)
			end
		end
		if false then
			local s = daily:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", daily)
			TweenService:Create(s, TweenInfo.new(.18, Enum.EasingStyle.Back), {Scale = 1.15}):Play()
			task.wait(.2)
			TweenService:Create(s, TweenInfo.new(.2), {Scale = 1}):Play()
		end
	end
end)

local function visible()
	local allowed = progress:GetAttribute("MenuAllowed")
	bar.Visible = allowed ~= false
end
progress:GetAttributeChangedSignal("MenuAllowed"):Connect(visible)
visible()
