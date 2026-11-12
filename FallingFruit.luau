local Models = require(script.Parent.Parent.Models)
local Ability = require(script.Parent.Parent.AbilityService)
local Fruit = {Name = "Falling Fruit"}
local random = Random.new()
local active

function Fruit.Start(context)
	local folder = Instance.new("Folder", context.arena)
	folder.Name = "FruitStorm"
	active = folder
	local query = RaycastParams.new()
	query.FilterType = Enum.RaycastFilterType.Include
	query.FilterDescendantsInstances = context.arena:GetChildren()
	task.spawn(function()
		while active == folder do
			local characters = context.characters()
			for i = 1, math.clamp(#characters,2,6) do
				local x, z = random:NextNumber(-36,36), random:NextNumber(-36,36)
				if characters[i] then
					local p = characters[i].HumanoidRootPart.Position
					x, z = p.X + random:NextNumber(-4,4), p.Z + random:NextNumber(-4,4)
				end
				if Vector3.new(x,0,z).Magnitude > 60 then continue end
				local ray = workspace:Raycast(Vector3.new(x,35,z),Vector3.new(0,-40,0),query)
				local ground = Vector3.new(x, ray and ray.Position.Y or 1, z)
				local marker = Models.part(folder, "Incoming", Vector3.new(.12,11,11), CFrame.new(ground + Vector3.new(0,.12,0)) * CFrame.Angles(0,0,math.pi/2), Color3.fromRGB(255,107,78),"Cylinder")
				marker.Material = Enum.Material.Neon
				marker.Transparency = .28
				task.delay(1.35,function()
					if active ~= folder then return end
					local fruit = Models.part(folder, "Fruit", Vector3.new(4.3,4.3,4.3), ground+Vector3.new(0,28,0),Color3.fromRGB(255,88,130),"Ball")
					for step = 1,10 do
						task.wait(.05)
						if active ~= folder then return end
						fruit.Position = ground + Vector3.new(0,2.1+26*(1-(step/10)^2),0)
					end
					for _, character in context.characters() do
						local delta = character.HumanoidRootPart.Position - ground
						local flat = Vector3.new(delta.X,0,delta.Z)
						if flat.Magnitude <= 5.5 and delta.Y < 7 then
							character.Humanoid:TakeDamage(34)
							local away = flat.Magnitude > .1 and flat.Unit or Vector3.xAxis
							Ability.Knock(character, away*29 + Vector3.new(0,23,0))
						end
					end
					marker:Destroy()
					game:GetService("Debris"):AddItem(fruit,.3)
				end)
			end
			task.wait(2.7)
		end
	end)
end

function Fruit.Stop()
	if active then
		active:Destroy()
		active = nil
	end
end

return Fruit
