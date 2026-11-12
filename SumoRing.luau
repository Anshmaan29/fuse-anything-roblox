local Models = require(script.Parent.Parent.Models)
local Sumo = {Name = "Sumo Ring"}
local ring

function Sumo.Start(context)
	ring = Models.part(context.arena,"SumoZone",Vector3.new(.14,124,124),
		CFrame.new(0,1.08,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(249,179,83),"Cylinder")
	ring.Material = Enum.Material.Neon
	ring.Transparency = .52
	local zone = ring
	task.spawn(function()
		while ring == zone do
			local elapsed = workspace:GetServerTimeNow()-context.startedAt
			local radius = math.max(16,62-math.max(0,elapsed-7)*.88)
			zone.Size = Vector3.new(.14,radius*2,radius*2)
			for _,character in context.characters() do
				local root = character.HumanoidRootPart
				local flat = Vector3.new(root.Position.X,0,root.Position.Z)
				if flat.Magnitude > radius then
					character.Humanoid:TakeDamage(13)
					root:ApplyImpulse((flat.Unit*15+Vector3.new(0,7,0))*root.AssemblyMass)
				end
			end
			task.wait(.5)
		end
	end)
end

function Sumo.Stop()
	if ring then ring:Destroy(); ring = nil end
end

return Sumo
