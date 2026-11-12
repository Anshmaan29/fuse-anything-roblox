local art=workspace.FuseArena.Toyworks
assert(not art:FindFirstChild("Set"))
local set=Instance.new("Folder",art)
set.Name="Set"
local rgb=Color3.fromRGB
local ink,lavender,mint,coral,gold,cream=rgb(37,31,73),rgb(169,150,247),rgb(104,247,194),rgb(254,118,145),rgb(255,187,92),rgb(255,244,218)

local function prop(name,size,pose,color,shape,material)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color=name,size,pose,color
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
	p.CastShadow=false
	p.Shape=shape or Enum.PartType.Block
	p.Material=material or Enum.Material.SmoothPlastic
	p.Parent=set
	return p
end
local function cylinder(name,diameter,height,pose,color,material)
	return prop(name,Vector3.new(height,diameter,diameter),pose*CFrame.Angles(0,0,math.pi/2),color,Enum.PartType.Cylinder,material)
end
local function plaque(name,pose,text,width,height,background,foreground)
	local plate=prop(name,Vector3.new(width,height,.4),pose,background)
	for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
		local gui=Instance.new("SurfaceGui",plate)
		gui.Face=face
		gui.PixelsPerStud=42
		gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
		local title=Instance.new("TextLabel",gui)
		title.Position=UDim2.fromScale(.04,.03)
		title.Size=UDim2.fromScale(.92,.94)
		title.BackgroundTransparency=1
		title.Font=Enum.Font.GothamBlack
		title.TextColor3=foreground
		title.TextScaled=true
		title.Text=text
	end
end

for i=0,3 do
	local pose=CFrame.Angles(0,i*math.pi/2,0)
	plaque("PotBadge",pose*CFrame.new(0,4.35,-8.53),"FUSE",5.7,1.63,ink,mint)
	for _,x in {-2.55,2.55} do
		prop("BadgeBolt",Vector3.new(.21,.21,.23),pose*CFrame.new(x,4.3,-8.8),gold,Enum.PartType.Ball)
	end
end
for _,side in {-1,1} do
	local p=Vector3.new(side*76,-7,17)
	local pose=CFrame.new(p)
	local liquid=side<0 and mint or coral
	cylinder("ReactorBase",14,3.1,pose*CFrame.new(0,-5,0),ink)
	cylinder("ReactorTank",11,13,pose*CFrame.new(0,2.1,0),lavender)
	cylinder("ReactorLiquid",11.3,5.2,pose*CFrame.new(0,2.2,0),liquid,Enum.Material.Neon).Transparency=.26
	cylinder("ReactorCap",13,.9,pose*CFrame.new(0,8.75,0),ink)
	cylinder("ReactorCapTrim",11.75,.41,pose*CFrame.new(0,9.39,0),liquid,Enum.Material.Neon)
	for n=0,3 do
		local angle=n*math.pi/2
		prop("ReactorBrace",Vector3.new(.64,12,.64),pose*CFrame.Angles(0,angle,0)*CFrame.new(0,2.2,-5.3),ink)
	end
	local pipePose=pose*CFrame.new(0,-3,0)*CFrame.Angles(0,0,math.pi/2)
	cylinder("ReactorPipe",2.1,14,pipePose*CFrame.new(0,side*6,0),gold)
	plaque("ReactorNumber",pose*CFrame.new(0,7,-5.56),side<0 and "01" or "02",4.4,2.3,ink,cream)
end

local root=Vector3.new(0,10,-100)
local start=root+Vector3.new(0,1.54,-7)
for i=1,5 do
	local width=6+(i%2)*.7
	prop("WelcomeMark",Vector3.new(width,.08,.45),CFrame.new(start+Vector3.new(0,0,i*1.4)),i%2==0 and cream or lavender)
end
plaque("LabInstructions",CFrame.new(root+Vector3.new(0,5,8.9)),"GRAB  •  FUSE  •  SURVIVE",18,1.5,ink,gold)
workspace.FuseArena.LabSpawn.CFrame *= CFrame.Angles(0,math.pi,0)
for _,object in workspace.FuseArena.LabSpawn:GetChildren() do
 if object:IsA("Decal") then object:Destroy() end
end
return #set:GetChildren()
