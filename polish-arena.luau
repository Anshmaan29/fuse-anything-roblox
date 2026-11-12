local arena = workspace:WaitForChild("FuseArena")
assert(not arena:FindFirstChild("Toyworks"))
local art = Instance.new("Folder")
art.Name = "Toyworks"
local rgb=Color3.fromRGB
local ink,blue,lavender,mint,coral,gold,cream=rgb(40,33,76),rgb(86,71,171),rgb(172,153,253),rgb(96,249,197),rgb(255,116,139),rgb(255,185,81),rgb(255,245,209)
local function part(name, size, pose, color, shape, material)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color=name,size,pose,color
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
	p.CastShadow=false
	p.Shape=shape or Enum.PartType.Block
	p.Material=material or Enum.Material.SmoothPlastic
	p.Parent=art
	return p
end
local function disk(name, diameter,depth,p,color,material)
	return part(name,Vector3.new(depth,diameter,diameter),CFrame.new(p)*CFrame.Angles(0,0,math.pi/2),color,Enum.PartType.Cylinder,material)
end
local function sign(p, name, color, fontSize, side)
	local board=Instance.new("SurfaceGui",p)
	board.Face=side or Enum.NormalId.Front
	board.PixelsPerStud=32
	board.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
	local label=Instance.new("TextLabel",board)
	label.Size=UDim2.fromScale(1,1)
	label.BackgroundTransparency=1
	label.Text=name
	label.Font=Enum.Font.GothamBlack
	label.TextColor3=color
	label.TextSize=fontSize
	label.TextScaled=true
end

arena.ArenaShell.Color=ink
arena.ArenaFloor.Color=blue
arena.Pot.Color=ink
arena.PotRim.Color=mint
arena.PotFoot.Color=rgb(66,50,131)
arena.Brew.Color=rgb(133,255,182)
arena.Brew.Transparency=.13
disk("OuterTrim",130,.6,Vector3.new(0,-.98,0),lavender)
disk("ApronTrim",38,.15,Vector3.new(0,1.05,0),mint)
disk("PotCasing",17.25,.45,Vector3.new(0,5.38,0),blue)
disk("PotBottomTrim",16.8,.42,Vector3.new(0,2.24,0),lavender)
for i=0,15 do
	local angle=i*math.pi/8
	local direction=Vector3.new(math.cos(angle),0,math.sin(angle))
	local p=direction*8.59+Vector3.new(0,4.8,0)
	part("Rivet",Vector3.new(.4,.37,.4),CFrame.new(p),gold,Enum.PartType.Ball)
end
for _,side in {-1,1} do
	local pose=CFrame.new(side*9,4.45,0)*CFrame.Angles(0,side*math.pi/2,0)
	for _,y in {-.7,.7} do
		part("PotHandle",Vector3.new(2.9,.44,.53),pose*CFrame.new(0,y,-.55),gold)
	end
	for _,x in {-1.32,1.32} do
		part("PotHandle",Vector3.new(.46,1.55,.55),pose*CFrame.new(x,0,-.55),gold)
	end
end
local boil=Instance.new("ParticleEmitter",arena.Brew)
boil.Name="BrewBubbles"
boil.Rate=9
boil.Lifetime=NumberRange.new(.8,1.5)
boil.Speed=NumberRange.new(2,5)
boil.SpreadAngle=Vector2.new(18,18)
boil.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(.78,.78),NumberSequenceKeypoint.new(1,0)})
boil.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.14),NumberSequenceKeypoint.new(1,1)})
boil.Color=ColorSequence.new(mint,cream)
boil.LightEmission=.6

for i=0,11 do
	local a=i*math.pi/6
	local radial=Vector3.new(math.cos(a),0,math.sin(a))
	local p=radial*58
	local pose=CFrame.lookAt(p+Vector3.new(0,1.07,0),p+radial+Vector3.new(0,1.07,0))
	for n=-1,1 do
		part("LaneDash",Vector3.new(1.6,.08,.52),pose*CFrame.new(n*2.6,0,0),i%2==0 and mint or gold)
	end
	if i%2==0 then
		local top=radial*42+Vector3.new(0,7.62,0)
		disk("PlatformTrim",14.2,.23,top,ink)
		local base=radial*42
		disk("PlatformStem",2.15,6,base+Vector3.new(0,4,0),lavender)
		disk("PlatformFoot",5.3,.44,base+Vector3.new(0,1.14,0),ink)
	end
end

local lab=Vector3.new(0,11,-100)
local marquee=arena.LabSign
marquee.Color=ink
sign(marquee,"FUSE ANYTHING!",cream,64,Enum.NormalId.Back)
for side=-1,1,2 do
	local p=lab+Vector3.new(side*14,2.8,10)
	part("LabPillar",Vector3.new(2,6,2),CFrame.new(p),lavender)
	disk("LabBeacon",2.35,.42,p+Vector3.new(0,3.04,0),mint,Enum.Material.Neon)
end
local bench=part("LabBench",Vector3.new(18,2.2,3.15),CFrame.new(lab+Vector3.new(0,1.4,9)),ink)
part("LabBenchTop",Vector3.new(18.7,.3,3.5),bench.CFrame*CFrame.new(0,1.17,0),lavender)
sign(bench,"YOUR FUSION LAB",cream,34)
for i=-1,1 do
	disk("StatueSocket",3.7,.37,lab+Vector3.new(i*5.6,2.98,9),blue)
end
for i=1,5 do
	local p=lab+Vector3.new(-14,.57,-4+i*2)
	part("LabStripe",Vector3.new(5.8,.11,.39),CFrame.new(p)*CFrame.Angles(0,math.pi/6,0),cream)
end

local rng=Random.new(314)
for i=1,20 do
	local angle=i*math.pi*2/20
	local distance=rng:NextNumber(117,190)
	local center=Vector3.new(math.cos(angle)*distance,rng:NextNumber(-32,-10),math.sin(angle)*distance)
	local size=rng:NextNumber(11,30)
	disk("BackdropIsland",size,4,center,({ink,blue,lavender})[i%3+1])
	disk("BackdropTop",size*.91,.42,center+Vector3.new(0,2.05,0),({lavender,mint,coral})[i%3+1])
	for n=1,3 do
		local p=center+Vector3.new(rng:NextNumber(-size*.24,size*.24),rng:NextNumber(3,7),rng:NextNumber(-size*.24,size*.24))
		part("BackdropCandy",Vector3.new(3,3,3),CFrame.new(p),({mint,gold,coral})[n],Enum.PartType.Ball)
	end
end
local lighting=game:GetService("Lighting")
local bloom=Instance.new("BloomEffect",lighting)
bloom.Name="BrewGlow"
bloom.Intensity=.25
bloom.Size=22
bloom.Threshold=1.15
local grade=Instance.new("ColorCorrectionEffect",lighting)
grade.Name="ToyColor"
grade.Saturation=.09
grade.Contrast=.05
grade.TintColor=rgb(255,247,251)
art.Parent=arena
return #art:GetChildren()
