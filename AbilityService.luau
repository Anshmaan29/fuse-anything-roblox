local Models = require(script.Parent.Models)
local Ability = {}

local function ragdoll(character, humanoid)
	local joints = {}
	local needsNeck = humanoid.RequiresNeck
	humanoid.RequiresNeck = false
	humanoid.PlatformStand = true
	for _, motor in character:GetDescendants() do
		if motor:IsA("Motor6D") and motor.Enabled and motor.Part0 and motor.Part1
			and motor.Part0.Name ~= "HumanoidRootPart" then
			local first = Instance.new("Attachment",motor.Part0)
			local second = Instance.new("Attachment",motor.Part1)
			first.CFrame, second.CFrame = motor.C0, motor.C1
			local socket = Instance.new("BallSocketConstraint",motor.Part0)
			socket.Attachment0, socket.Attachment1 = first, second
			socket.LimitsEnabled = true
			socket.UpperAngle = 55
			table.insert(joints,{motor,first,second,socket})
			motor.Enabled = false
		end
	end
	return function()
		for _, joint in joints do
			joint[1].Enabled = true
			joint[4]:Destroy()
			joint[2]:Destroy()
			joint[3]:Destroy()
		end
		humanoid.RequiresNeck = needsNeck
		humanoid.PlatformStand = false
	end
end

function Ability.Knock(character, velocity)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then return end
	root:ApplyImpulse(velocity * root.AssemblyMass)
	if character:GetAttribute("Stunned") then return end
	character:SetAttribute("Stunned", true)
	local restore = ragdoll(character,humanoid)
	task.delay(.55, function()
		if character.Parent then
			character:SetAttribute("Stunned", nil)
			if humanoid.Health > 0 then restore() end
		end
	end)
end

function Ability.Use(name, character, nearby, aim)
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then return false end
	local forward = aim or root.CFrame.LookVector
	if name == "Dash" then
		root:ApplyImpulse((forward * 58 + Vector3.new(0,8,0)) * root.AssemblyMass)
	elseif name == "Rocket Flight" then
		local attachment = Instance.new("Attachment",root)
		local flight = Instance.new("LinearVelocity",root)
		flight.Attachment0 = attachment
		flight.VectorVelocity = forward*27 + Vector3.new(0,10,0)
		flight.MaxForce = root.AssemblyMass*650
		game:GetService("Debris"):AddItem(attachment,3)
		game:GetService("Debris"):AddItem(flight,3)
	elseif name == "Bounce" then
		root:ApplyImpulse(Vector3.new(0,74,0) * root.AssemblyMass)
	elseif name == "Ground Slam" then
		root:ApplyImpulse(Vector3.new(0,-60,0) * root.AssemblyMass)
		local ring = Models.part(workspace.FuseArena, "SlamFX", Vector3.new(.18,16,16), CFrame.new(root.Position - Vector3.new(0,2.5,0)) * CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(255,191,105),"Cylinder")
		ring.Material = Enum.Material.Neon
		ring.Transparency = .35
		game:GetService("Debris"):AddItem(ring,.35)
		for _, target in nearby(root.Position, 11) do
			local delta = target.HumanoidRootPart.Position - root.Position
			local flat = Vector3.new(delta.X,0,delta.Z)
			local direction = flat.Magnitude > .01 and flat.Unit or forward
			Ability.Knock(target, direction*37 + Vector3.new(0,22,0))
		end
	elseif name == "Glide" then
		-- float gently forward for 3 seconds
		local attachment = Instance.new("Attachment",root)
		local lift = Instance.new("VectorForce",root)
		lift.Attachment0 = attachment
		lift.RelativeTo = Enum.ActuatorRelativeTo.World
		lift.Force = Vector3.new(0, root.AssemblyMass * workspace.Gravity * .82, 0)
		root:ApplyImpulse((forward * 30 + Vector3.new(0,28,0)) * root.AssemblyMass)
		game:GetService("Debris"):AddItem(attachment,3)
		game:GetService("Debris"):AddItem(lift,3)
	elseif name == "Blast" then
		-- fire a shockwave forward that launches anyone in front
		local beam = Models.part(workspace.FuseArena, "BlastFX", Vector3.new(4,4,18), CFrame.lookAt(root.Position + forward*9, root.Position + forward*18), Color3.fromRGB(120,255,200), "Block")
		beam.Material = Enum.Material.Neon
		beam.Transparency = .45
		game:GetService("Debris"):AddItem(beam,.25)
		for _, target in nearby(root.Position, 18) do
			local delta = target.HumanoidRootPart.Position - root.Position
			if delta.Magnitude > .01 and delta.Unit:Dot(forward) > .55 then
				Ability.Knock(target, forward*48 + Vector3.new(0,20,0))
			end
		end
	elseif name == "Magnet" then
		-- yank nearby rivals toward you
		local ring = Models.part(workspace.FuseArena, "MagnetFX", Vector3.new(.18,30,30), CFrame.new(root.Position - Vector3.new(0,2.5,0)) * CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(255,90,140), "Cylinder")
		ring.Material = Enum.Material.Neon
		ring.Transparency = .5
		game:GetService("Debris"):AddItem(ring,.35)
		for _, target in nearby(root.Position, 16) do
			local delta = root.Position - target.HumanoidRootPart.Position
			local flat = Vector3.new(delta.X,0,delta.Z)
			if flat.Magnitude > .01 then Ability.Knock(target, flat.Unit*34 + Vector3.new(0,14,0)) end
		end
	elseif name == "Spin" then
		-- spin attack: flings everyone close sideways
		local swirl = Models.part(workspace.FuseArena, "SpinFX", Vector3.new(.18,18,18), CFrame.new(root.Position - Vector3.new(0,1.5,0)) * CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(255,220,90), "Cylinder")
		swirl.Material = Enum.Material.Neon
		swirl.Transparency = .45
		game:GetService("Debris"):AddItem(swirl,.3)
		for _, target in nearby(root.Position, 9) do
			local delta = target.HumanoidRootPart.Position - root.Position
			local flat = Vector3.new(delta.X,0,delta.Z)
			if flat.Magnitude > .01 then
				local side = flat.Unit:Cross(Vector3.yAxis)
				Ability.Knock(target, (flat.Unit*24 + side*30) + Vector3.new(0,18,0))
			end
		end
	elseif name == "Blink" then
		-- teleport a short hop forward, stopping before walls
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {character}
		local hit = workspace:Raycast(root.Position, forward * 20, params)
		local distance = hit and math.max(0, hit.Distance - 3) or 20
		local puff = Models.part(workspace.FuseArena, "BlinkFX", Vector3.new(5,5,5), CFrame.new(root.Position), Color3.fromRGB(190,140,255), "Ball")
		puff.Material = Enum.Material.Neon
		puff.Transparency = .4
		game:GetService("Debris"):AddItem(puff,.3)
		character:PivotTo(character:GetPivot() + forward * distance + Vector3.new(0,1,0))
	else
		return false
	end
	return true
end

return Ability
