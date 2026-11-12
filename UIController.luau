local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Sounds = require(script.Parent.Sounds)
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local storage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local shared = storage:WaitForChild("Shared")
local remotes = shared:WaitForChild("Remotes")
local Config = require(shared:WaitForChild("Config"))
local action = remotes:WaitForChild("Action")
local duo = remotes:WaitForChild("Duo")
local rgb = Color3.fromRGB
local ink, cream, mint = rgb(33,31,61), rgb(255,245,218), rgb(115,250,194)
local lavender, orange = rgb(207,192,255), rgb(255,178,115)

local gui = Instance.new("ScreenGui")
gui.Name = "FuseHUD"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")

local function roundCorners(parent, radius)
	local corner = Instance.new("UICorner",parent)
	corner.CornerRadius = UDim.new(0,radius)
end

local function panel(name, size, position, anchor, color)
	local frame = Instance.new("Frame",gui)
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = anchor
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	roundCorners(frame,15)
	local stroke = Instance.new("UIStroke",frame)
	stroke.Color = lavender
	stroke.Transparency = .6
	stroke.Thickness = 1.5
	return frame
end

local function text(parent, name, size, pos, font, fontSize, color)
	local label = Instance.new("TextLabel",parent)
	label.Name = name
	label.Size = size
	label.Position = pos
	label.BackgroundTransparency = 1
	label.Font = font
	label.TextSize = fontSize
	label.TextColor3 = color
	label.Text = ""
	return label
end
local heavy, bold = Enum.Font.GothamBlack, Enum.Font.GothamBold
local top = panel("Round",UDim2.new(1,-28,0,86),UDim2.new(.5,0,0,9),Vector2.new(.5,0),ink)
local sizeLimit = Instance.new("UISizeConstraint",top)
sizeLimit.MaxSize = Vector2.new(440,86)
local title = text(top,"Phase",UDim2.new(1,-104,0,27),UDim2.fromOffset(14,8),heavy,20,cream)
title.TextXAlignment = Enum.TextXAlignment.Left
local timer = text(top,"Time",UDim2.fromOffset(70,31),UDim2.new(1,-82,0,6),heavy,25,mint)
timer.TextXAlignment = Enum.TextXAlignment.Right
local instruction = text(top,"Instruction",UDim2.new(1,-28,0,21),UDim2.fromOffset(14,37),bold,14,lavender)
instruction.TextXAlignment = Enum.TextXAlignment.Left
local items = text(top,"Ingredients",UDim2.new(1,-123,0,19),UDim2.fromOffset(14,61),bold,13,mint)
items.TextXAlignment = Enum.TextXAlignment.Left
items.TextTruncate = Enum.TextTruncate.AtEnd
local coins = text(top,"Coins",UDim2.fromOffset(108,0),UDim2.new(1,-120,0,61),bold,13,orange)
coins.Size = UDim2.fromOffset(108,19)
coins.TextXAlignment = Enum.TextXAlignment.Right

local stageTrack=Instance.new("Frame",top)
stageTrack.Position=UDim2.new(0,14,1,-5)
stageTrack.Size=UDim2.new(1,-28,0,2)
stageTrack.BackgroundColor3=rgb(77,65,122)
stageTrack.BorderSizePixel=0
local stageFill=Instance.new("Frame",stageTrack)
stageFill.BorderSizePixel=0
stageFill.BackgroundColor3=mint

local potHint=Instance.new("BillboardGui",gui.Parent)
potHint.Name="PotHint"
potHint.ResetOnSpawn=false
potHint.Size=UDim2.fromOffset(124,40)
potHint.StudsOffsetWorldSpace=Vector3.new(0,5.4,0)
potHint.AlwaysOnTop=true
potHint.MaxDistance=105
local potLabel=text(potHint,"Hint",UDim2.fromScale(1,1),UDim2.new(),heavy,17,ink)
potLabel.Text="FUSE HERE ↓"
potLabel.BackgroundTransparency=0
potLabel.BackgroundColor3=mint
roundCorners(potLabel,10)

local pickupHint=potHint:Clone()
pickupHint.Name="PickupHint"
pickupHint.Hint.Text="GRAB THIS ↓"
pickupHint.Parent=gui.Parent
pickupHint.StudsOffsetWorldSpace=Vector3.new(0,2.8,0)
pickupHint.Enabled=false
local tutorialStarted,tutorialUntil,nextScan=false,0,0

local result = panel("FusionReveal",UDim2.new(1,-64,0,68),UDim2.new(.5,0,0,104),Vector2.new(.5,0),ink)
local resultLimit = Instance.new("UISizeConstraint",result)
resultLimit.MaxSize = Vector2.new(344,68)
local name = text(result,"Name",UDim2.new(1,-16,0,31),UDim2.fromOffset(8,5),heavy,24,mint)
local detail = text(result,"Detail",UDim2.new(1,-16,0,24),UDim2.fromOffset(8,36),bold,14,cream)
result.Visible = false
local revealScale=Instance.new("UIScale",result)

local button = Instance.new("TextButton",gui)
button.Name = "Action"
button.AnchorPoint = Vector2.new(1,1)
button.Size = UDim2.fromOffset(108,58)
button.Position = UDim2.new(1,-18,1,-22)
button.BackgroundColor3 = mint
button.TextColor3 = ink
button.Font = heavy
button.TextSize = 16
button.TextWrapped = true
button.AutoButtonColor = false
button.Visible = false
roundCorners(button,15)
local buttonStroke = Instance.new("UIStroke",button)
buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
buttonStroke.Thickness = 2
buttonStroke.Color = ink

local function chip(parent, caption, position, size, color)
	local control = Instance.new("TextButton",parent)
	control.Size, control.Position = size,position
	control.Text, control.TextColor3, control.TextSize = caption,ink,14
	control.Font = heavy
	control.BackgroundColor3 = color
	control.BorderSizePixel = 0
	roundCorners(control,11)
	return control
end

local duoOffer = chip(gui,"Invite Duo",UDim2.new(.5,-55,0,99),UDim2.fromOffset(110,44),lavender)
duoOffer.Name="InviteDuo"
duoOffer.Activated:Connect(function() duo:FireServer("Offer") end)
local invitation=panel("DuoInvite",UDim2.fromOffset(310,94),UDim2.new(.5,0,0,99),Vector2.new(.5,0),ink)
local invitationText=text(invitation,"Sender",UDim2.new(1,-14,0,31),UDim2.fromOffset(7,5),bold,15,cream)
local accept=chip(invitation,"Accept",UDim2.fromOffset(10,41),UDim2.fromOffset(141,44),mint)
local decline=chip(invitation,"Decline",UDim2.fromOffset(159,41),UDim2.fromOffset(141,44),lavender)
accept.Activated:Connect(function() duo:FireServer("Accept") end)
decline.Activated:Connect(function() duo:FireServer("Decline") end)
local paired=text(gui,"DuoStatus",UDim2.new(1,-30,0,27),UDim2.new(0,15,0,146),bold,14,cream)
paired.TextStrokeTransparency=.25
local banner=panel("WorldFirst",UDim2.new(1,-52,0,48),UDim2.new(.5,0,1,-15),Vector2.new(.5,1),ink)
Instance.new("UISizeConstraint",banner).MaxSize=Vector2.new(465,48)
local bannerText=text(banner,"Announcement",UDim2.new(1,-16,1,0),UDim2.fromOffset(8,0),heavy,15,orange)
bannerText.TextTruncate=Enum.TextTruncate.AtEnd
banner.Visible=false
local bannerUntil=0
local function announce(message)
	bannerText.Text=message
	bannerUntil=workspace:GetServerTimeNow()+5
end
remotes.WorldFirst.OnClientEvent:Connect(function(username,creature)
	announce("WORLD FIRST  ·  "..creature.."  ·  @"..username)
	Sounds.Play("First")
end)
player:GetAttributeChangedSignal("ProgressNotice"):Connect(function()
	local message=player:GetAttribute("ProgressNotice")
	if message then announce(message); Sounds.Play("Reward") end
end)
player:GetAttributeChangedSignal("Ingredient1"):Connect(function()
	if player:GetAttribute("Ingredient1") then Sounds.Play("Pickup") end
end)
player:GetAttributeChangedSignal("Ingredient2"):Connect(function()
	if player:GetAttribute("Ingredient2") then Sounds.Play("Pair") end
end)
shared:GetAttributeChangedSignal("Phase"):Connect(function()
	if shared:GetAttribute("Phase")=="Chaos" then Sounds.Play("Alarm") end
end)
player:GetAttributeChangedSignal("RoundCoins"):Connect(function()
	if (player:GetAttribute("RoundCoins") or 0)>0 then Sounds.Play("Reward") end
end)

local view = player:WaitForChild("DuoView")
local function follow()
	local character = view.Value or player.Character
	local humanoid = character and character:WaitForChild("Humanoid",3)
	if humanoid and character==(view.Value or player.Character) and workspace.CurrentCamera then
		workspace.CurrentCamera.CameraSubject=humanoid
	end
end
view:GetPropertyChangedSignal("Value"):Connect(follow)
player.CharacterAdded:Connect(function(character)
	character:WaitForChild("Humanoid")
	follow()
end)
local actionName, isReady
local function useAction()
	if isReady then
		local camera=workspace.CurrentCamera
		action:FireServer(camera and camera.CFrame.LookVector)
	end
end
button.Activated:Connect(useAction)
ContextActionService:BindAction("FuseAction",function(_, state)
	if not actionName then return Enum.ContextActionResult.Pass end
	if state == Enum.UserInputState.Begin then useAction() end
	return Enum.ContextActionResult.Sink
end,false,Enum.KeyCode.Q,Enum.KeyCode.ButtonX)

local revealUntil = 0
player:GetAttributeChangedSignal("Creature"):Connect(function()
	if not player:GetAttribute("Creature") then return end
	revealUntil = workspace:GetServerTimeNow()+3.4
	local camera=workspace.CurrentCamera
	if GuiService.ReducedMotionEnabled then return end
	revealScale.Scale=.78
	TweenService:Create(revealScale,TweenInfo.new(.42,Enum.EasingStyle.Back),{Scale=1}):Play()
	if not camera then return end
	local original=camera.FieldOfView
	local punch=TweenService:Create(camera,TweenInfo.new(.22,Enum.EasingStyle.Quint),{FieldOfView=original-12})
	punch:Play()
	punch.Completed:Once(function()
		TweenService:Create(camera,TweenInfo.new(.62,Enum.EasingStyle.Quart),{FieldOfView=original}):Play()
	end)
end)

local hints={
	["Rising Lava"]="Climb above the lava",
	["Falling Fruit"]="Move off the marked circles",
	["Sumo Ring"]="Stay inside the shrinking ring",
	["Giant Fan Storm"]="Run against the gusts",
}

while gui.Parent do
	local now = workspace:GetServerTimeNow()
	local phase = shared:GetAttribute("Phase") or "Lobby"
	local status = player:GetAttribute("RoundStatus")
	local playing = status == "Playing"
	local event = shared:GetAttribute("Event")
	local first, second = player:GetAttribute("Ingredient1"),player:GetAttribute("Ingredient2")
	local third = player:GetAttribute("Ingredient3")
	local arena=workspace:FindFirstChild("FuseArena")
	if phase=="Grab" and playing and not tutorialStarted then
		tutorialStarted=true
		if (player:GetAttribute("Discoveries") or 0)==0 then tutorialUntil=now+30 end
	end
	pickupHint.Enabled=playing and phase=="Grab" and second==nil and now<tutorialUntil
	if pickupHint.Enabled and now>=nextScan then
		nextScan=now+.35
		local objects=arena and arena:FindFirstChild("Ingredients")
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local best, distance=nil,math.huge
		local camera=workspace.CurrentCamera
		if objects and root and camera then
			for _,item in objects:GetChildren() do
				local hit=item:FindFirstChild("Pickup")
				local label=hit and hit:FindFirstChildWhichIsA("BillboardGui")
				local title=label and label:FindFirstChildWhichIsA("TextLabel")
				if hit and hit.Position.Y<8 and (not title or title.Text~=first) then
					local point,visible=camera:WorldToViewportPoint(hit.Position+pickupHint.StudsOffsetWorldSpace)
					local height=camera.ViewportSize.Y
					local inView=visible and point.Y>height*.47 and point.Y<height*.86
					local gap=(root.Position-hit.Position).Magnitude+(inView and 0 or 1000)
					if gap<distance then best,distance=hit,gap end
				end
			end
		end
		pickupHint.Adornee=best
	end
	if player:GetAttribute("PassPotSkin") and arena and not arena:GetAttribute("LocalCandySkin") then
		local rim,brew=arena:FindFirstChild("PotRim"),arena:FindFirstChild("Brew")
		if rim and brew then
			rim.Color=rgb(255,191,88)
			brew.Color=rgb(255,112,184)
			arena:SetAttribute("LocalCandySkin",true)
		end
	end
	local creature, ability = player:GetAttribute("Creature"),player:GetAttribute("Ability")
	local role = player:GetAttribute("DuoRole")
	local duoStatus = player:GetAttribute("DuoStatus") or ""
	local inDuoStage=playing and (phase=="Grab" or phase=="Fuse") and not creature and first~=nil
	local inviter=player:GetAttribute("DuoInvite")
	invitation.Visible=inDuoStage and inviter~=nil and now<(player:GetAttribute("DuoInviteUntil") or 0)
	invitationText.Text=inviter and (inviter.." wants to fuse with you") or ""
	duoOffer.Visible=inDuoStage and not invitation.Visible and not duoStatus:match("^Paired")
	paired.Visible=inDuoStage and not invitation.Visible and duoStatus~=""
	paired.Text=duoStatus
	banner.Visible=now<bannerUntil
	local time = math.max(0,math.ceil((shared:GetAttribute("EndsAt") or now)-now))
	timer.Text = string.format("%d:%02d",math.floor(time/60),time%60)
	title.Text = phase == "Chaos" and (event or "Chaos") or phase
	local duration=phase=="Lobby" and Config.Intermission or Config[phase]
	stageFill.Size=UDim2.fromScale(math.clamp(time/(duration or 1),0,1),1)
	stageFill.BackgroundColor3=phase=="Chaos" and orange or mint
	potHint.Enabled=playing and not creature and (phase=="Grab" or phase=="Fuse") and (second~=nil or duoStatus:match("^Paired")~=nil)
	if potHint.Enabled and not potHint.Adornee then
		local arena=workspace:FindFirstChild("FuseArena")
		potHint.Adornee=arena and arena:FindFirstChild("Brew")
	end
	coins.Text = tostring(player:GetAttribute("Coins") or 0).." coins"
	items.Text = creature and (creature.." · "..(player:GetAttribute("CreatureTier") or ""))
		or (first and (first.." + "..(second or "?")..(third and (" + "..third) or "")) or "0 / 2 ingredients")
	actionName = nil
	if phase == "Lobby" then
		instruction.Text = player:GetAttribute("LabMode") and "In the Lab · Join from the Lab tab" or "Next round soon"
	elseif phase == "Reward" then
		local earned = player:GetAttribute("RoundCoins")
		instruction.Text = earned and ((status == "Survived" and "Survived" or "Round over").."  +"..earned.." coins") or "Next round soon"
	elseif not playing then
		instruction.Text = status == "Out" and "You’re out for this round" or "Join in next round"
	elseif phase == "Grab" then
		instruction.Text = second and "Take your pair to the pot" or "Touch two different ingredients"
		actionName = "Slap"
	elseif phase == "Fuse" then
		instruction.Text = creature and "Get ready for chaos" or ((second or duoStatus:match("^Paired")) and "Jump into the Fuse Pot!" or "Get ready to dodge")
	elseif phase == "Chaos" then
		instruction.Text = role=="Driver" and "Drive · Your partner controls the ability"
			or role=="Ability" and "Aim and fire · Your partner drives" or (hints[event] or "Survive the chaos")
		actionName = role~="Driver" and ability or nil
	end
	local touch = UserInputService.TouchEnabled
	button.Position = touch and UDim2.new(1,-113,1,-28) or UDim2.new(1,-18,1,-22)
	local cooldown = math.ceil((player:GetAttribute("ActionReadyAt") or 0)-now)
	isReady = actionName ~= nil and cooldown <= 0
	button.Visible = actionName ~= nil
	button.Text = actionName and (cooldown > 0 and actionName.."\n"..cooldown.."s"
		or actionName..(touch and "" or "\n[Q]")) or ""
	button.BackgroundColor3 = isReady and mint or lavender
	result.Visible = creature ~= nil and now < revealUntil
	if result.Visible then
		name.Text = string.upper(creature)
		local mutation=player:GetAttribute("Mutation")
		name.TextColor3=mutation and orange or mint
		detail.Text = (player:GetAttribute("CreatureTier") or "").." · "..(mutation or (role and "Duo fusion") or player:GetAttribute("CreatureSubtitle") or "")
	end
	task.wait(.1)
end
