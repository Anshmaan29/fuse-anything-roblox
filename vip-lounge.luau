local arena=workspace.FuseArena
assert(not arena:FindFirstChild("VIPDeck"))
local rgb=Color3.fromRGB
local gold,cream,purple=rgb(255,195,80),rgb(255,245,210),rgb(63,44,113)
local center=Vector3.new(-43,18,-112)
local function part(name,size,pose,color,shape,solid)
	local p=Instance.new("Part")
	p.Name,p.Size,p.CFrame,p.Color=name,size,pose,color
	p.Shape=shape or Enum.PartType.Block
	p.Anchored=true
	p.CanCollide=solid==true
	p.CanTouch=false
	p.Parent=arena
	return p
end
local function disk(name,y,d,height,color,solid)
	return part(name,Vector3.new(height,d,d),CFrame.new(center+Vector3.new(0,y,0))*CFrame.Angles(0,0,math.pi/2),color,Enum.PartType.Cylinder,solid)
end
local deck=disk("VIPDeck",0,24,1.3,purple,true)
disk("VIPTrim",-.68,24.7,.38,gold,false)
disk("VIPFoundation",-1.5,23,1.2,purple,false)
for _,x in {-8,8} do
	local p=center+Vector3.new(x,2.3,6)
	part("VIPBeacon",Vector3.new(.94,4.5,.94),CFrame.new(p),cream)
	local orb=part("VIPOrb",Vector3.new(1.75,1.75,1.75),CFrame.new(p+Vector3.new(0,2.35,0)),gold,Enum.PartType.Ball)
	orb.Material=Enum.Material.Neon
end
local board=part("VIPSign",Vector3.new(14,3,.5),CFrame.new(center+Vector3.new(0,4.7,7.5)),purple)
for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
	local gui=Instance.new("SurfaceGui",board)
	gui.Face=face
	local text=Instance.new("TextLabel",gui)
	text.Size=UDim2.fromScale(1,1)
	text.BackgroundTransparency=1
	text.Font=Enum.Font.GothamBlack
	text.TextScaled=true
	text.TextColor3=gold
	text.Text="VIP LOUNGE"
end
-- Teleport to the center above this marker without inheriting the disk's rotation.
local marker=part("VIPSpawn",Vector3.new(.5,.5,.5),CFrame.new(center)*CFrame.Angles(0,math.pi,0),gold)
marker.Transparency=1
return deck.Name
