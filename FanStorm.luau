local Models = require(script.Parent.Parent.Models)
local Fan = {Name = "Giant Fan Storm"}
local active

function Fan.Start(context)
	local folder = Instance.new("Folder",context.arena)
	folder.Name = "FanStorm"
	local session = {folder=folder,forces={}}
	active = session
	local center = CFrame.new(0,12,-57)
	local hub = Models.part(folder,"Hub",Vector3.new(5,5,5),center,Color3.fromRGB(255,188,77),"Ball")
	local blades = {}
	for i=1,4 do
		blades[i] = Models.part(folder,"Blade",Vector3.new(3,9,1),center,Color3.fromRGB(120,248,200))
	end
	task.spawn(function()
		while active == session do
			local elapsed = workspace:GetServerTimeNow()-context.startedAt
			local angle = math.floor(elapsed/10)*math.pi/2
			local position = CFrame.Angles(0,angle,0)*center
			hub.CFrame = position
			for i,blade in blades do
				blade.CFrame = position*CFrame.Angles(0,0,elapsed*5+i*math.pi/2)*CFrame.new(0,6,0)
			end
			local present = {}
			if elapsed>4 then
				for _,character in context.characters() do
					local root = character.HumanoidRootPart
					present[root]=true
					local gust = session.forces[root]
					if not gust then
						local anchor=Instance.new("Attachment",root)
						anchor.Name="WindAnchor"
						local force=Instance.new("VectorForce")
						force.Name="FanGust"
						force.Attachment0=anchor
						force.RelativeTo=Enum.ActuatorRelativeTo.World
						force.ApplyAtCenterOfMass=true
						force.Parent=root
						gust={force=force,anchor=anchor}
						session.forces[root]=gust
					end
					local strength=elapsed%5<1.35 and 130 or 77
					gust.force.Force=-position.LookVector*root.AssemblyMass*strength
				end
			end
			for root,gust in session.forces do
				if not present[root] then
					gust.force:Destroy()
					gust.anchor:Destroy()
					session.forces[root]=nil
				end
			end
			task.wait(.12)
		end
	end)
end

function Fan.Stop()
	local session=active
	active=nil
	if not session then return end
	for _,gust in session.forces do
		gust.force:Destroy()
		gust.anchor:Destroy()
	end
	session.folder:Destroy()
end

return Fan
