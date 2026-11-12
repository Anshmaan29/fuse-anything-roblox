local storage = game:GetService("ReplicatedStorage")
local Catalog = require(storage.Shared.Catalog)
local Models = require(script.Parent.Models)
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Fusion = {}

local traits = {
	Fast = {21, 50}, Floaty = {16, 65}, Heavy = {14, 47},
	Bouncy = {17, 60}, Slippery = {19, 52},
}

function Fusion.Resolve(first, second)
	return assert(Catalog.ById[first.Id.."+"..second.Id], "Invalid fusion pair")
end

function Fusion.Triple(base, third)
	local recipe=table.clone(base)
	recipe.Third=third
	recipe.TripleId=base.Id.."+"..third.Id
	recipe.Name=base.Name.." "..third.DisplayName
	recipe.Subtitle=base.Subtitle.." + "..third.DisplayName
	return recipe
end

function Fusion.Mutation(roll)
	if roll < .02 then return "Golden" end
	if roll < .05 then return "Giant" end
	if roll < .08 then return "Tiny" end
	if roll < .085 then return "Rainbow" end
end

function Fusion.Paint(part, recipe, mutation, index)
	if part:IsA("MeshPart") and part.TextureID ~= "" then
		if mutation == "Golden" or mutation == "Rainbow" then
			part.TextureID = ""
		else
			return
		end
	end
	if mutation == "Golden" then
		part.Color = Color3.fromRGB(255,199,74)
		part.Material = Enum.Material.Metal
	elseif mutation == "Rainbow" then
		part.Color = Color3.fromHSV((index*.19)%1,.69,1)
	elseif recipe.Paint then
		part.Color = part.Color:Lerp(recipe.Paint,.48)
	end
end

function Fusion.Apply(character, recipe, mutation, player)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	local head = character:FindFirstChild("Head")
	if not humanoid or not torso or not head then return false end
	local costume = Instance.new("Folder")
	costume.Name = "FusionCostume"
	for _, object in character:GetDescendants() do
		if object:IsA("BasePart") or object:IsA("Decal") then
			object.Transparency = 1
		end
	end
	local scaleFactor = mutation == "Giant" and 1.45 or mutation == "Tiny" and .69 or 1
	local function mount(ingredient, limb, scale, offset)
		if not limb then return end
		local model = storage.Assets[ingredient.Model]:Clone()
		local pivot = model:GetPivot()
		model:ScaleTo(scale*scaleFactor)
		model:PivotTo(limb.CFrame * CFrame.new(offset) * pivot.Rotation)
		for index, part in model:GetChildren() do
			Fusion.Paint(part,recipe,mutation,index)
			part.Massless = true
			part.Anchored = false
			local weld = Instance.new("WeldConstraint", part)
			weld.Part0 = limb
			weld.Part1 = part
		end
		model.Parent = costume
	end
	mount(recipe.Body, torso, 1.35, Vector3.new(0,-.3,0))
	mount(recipe.Head, head, .88, Vector3.new(0,.63,0))
	if recipe.Third then mount(recipe.Third,torso,.73,Vector3.new(0,0,1.55)) end
	local headColor = recipe.Head.Color
	for _, side in {"Left","Right"} do
		local leg = character:FindFirstChild(side.."LowerLeg") or character:FindFirstChild(side.." Leg")
		if leg then
			local boot = Models.part(costume, side.."Boot", Vector3.new(.95,1.18,1.3)*scaleFactor, leg.CFrame * CFrame.new(0,-.1,-.12), headColor, recipe.Head.Shape == "Ball" and "Ball" or "Block")
			Fusion.Paint(boot,recipe,mutation,side == "Left" and 2 or 4)
			boot.Massless = true
			boot.Anchored = false
			local weld = Instance.new("WeldConstraint", boot)
			weld.Part0 = leg
			weld.Part1 = boot
		end
	end
	local headMesh = storage.Assets[recipe.Head.Model]:FindFirstChildWhichIsA("MeshPart")
	for x = -.45, headMesh and -1 or .45, .9 do -- no extra dot-eyes on AI models
		local eye = Models.part(costume, "Eye", Vector3.new(.31,.38,.22), head.CFrame * CFrame.new(x,.73,-1.03), Color3.fromRGB(35,28,60), "Ball")
		eye.Massless = true
		eye.Anchored = false
		local weld = Instance.new("WeldConstraint", eye)
		weld.Part0 = head
		weld.Part1 = eye
	end
	costume.Parent = character
	local movement = traits[recipe.Trait]
	humanoid.WalkSpeed = movement[1]
	humanoid.UseJumpPower = true
	humanoid.JumpPower = movement[2]
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	local poof = Instance.new("ParticleEmitter", head)
	poof.Rate = 0
	poof.TimeScale = .48
	poof.Lifetime = NumberRange.new(.35,.7)
	poof.Speed = NumberRange.new(10,19)
	poof.SpreadAngle = Vector2.new(180,180)
	local gold=player and player:GetAttribute("PassFusionFX") and Color3.fromRGB(255,195,75)
	poof.Color = gold and ColorSequence.new(gold,Color3.fromRGB(255,238,158)) or ColorSequence.new(recipe.Body.Color,headColor)
	poof.LightEmission = .5
	poof:Emit(52)
	TweenService:Create(poof,TweenInfo.new(.7),{TimeScale=1}):Play()
	local sound = Instance.new("Sound",head)
	sound.SoundId = "rbxasset://sounds/impact_explosion_03.mp3"
	sound.PlaybackSpeed = 1.65
	sound.Volume = .27
	sound:Play()
	local pulse = Models.part(workspace.FuseArena,"FusionPulse",Vector3.new(.12,2,2),
		CFrame.new(torso.Position-Vector3.new(0,1.5,0))*CFrame.Angles(0,0,math.pi/2),gold or recipe.Paint or headColor,"Cylinder")
	pulse.Material=Enum.Material.Neon
	pulse.Transparency=.36
	TweenService:Create(pulse,TweenInfo.new(.55,Enum.EasingStyle.Quart),{
		Size=Vector3.new(.12,19,19),Transparency=1,
	}):Play()
	local chime=Instance.new("Sound",head)
	chime.SoundId="rbxasset://sounds/action_jump.mp3"
	chime.PlaybackSpeed=mutation and 2.2 or 1.6
	chime.Volume=.23
	chime:Play()
	Debris:AddItem(pulse,.65)
	Debris:AddItem(poof,2)
	Debris:AddItem(sound,3)
	Debris:AddItem(chime,3)
	if player and player:GetAttribute("PassTrail") then
		local top=Instance.new("Attachment",torso)
		local bottom=Instance.new("Attachment",torso)
		top.Position,bottom.Position=Vector3.new(0,.7,1.45),Vector3.new(0,-.66,1.45)
		local trail=Instance.new("Trail",torso)
		trail.Attachment0,trail.Attachment1=top,bottom
		trail.Color=ColorSequence.new(Color3.fromRGB(112,250,195))
		trail.Lifetime=.36
		trail.MinLength=.45
		trail.LightEmission=.55
		trail.Transparency=NumberSequence.new(.25,1)
	end
	return true
end

return Fusion
