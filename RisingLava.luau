local Models = require(script.Parent.Parent.Models)
local Lava = {Name = "Rising Lava"}
local surface

function Lava.Start(context)
	surface = Models.part(context.arena, "RisingLava", Vector3.new(.55,129,129),
		CFrame.new(0,.25,0)*CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(255,102,53), "Cylinder")
	surface.Material = Enum.Material.Neon
	local lava = surface
	task.spawn(function()
		while surface == lava do
			local elapsed = workspace:GetServerTimeNow() - context.startedAt
			local height = math.clamp((elapsed-7)/36,0,1)*6 + .25
			lava.Position = Vector3.new(0,height,0)
			if elapsed > 8 then
				for _, character in context.characters() do
					local root = character.HumanoidRootPart
					if root.Position.Y - 2.5 < height and Vector3.new(root.Position.X,0,root.Position.Z).Magnitude < 66 then
						character.Humanoid:TakeDamage(15)
					end
				end
			end
			task.wait(.45)
		end
	end)
end

function Lava.Stop()
	if surface then
		surface:Destroy()
		surface = nil
	end
end

return Lava
