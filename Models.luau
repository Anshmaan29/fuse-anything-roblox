local Models = {}
local ink = Color3.fromRGB(34, 34, 65)
local cream = Color3.fromRGB(255, 241, 202)

function Models.part(parent, name, size, offset, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = typeof(offset) == "CFrame" and offset or CFrame.new(offset)
	part.Color = color
	part.Shape = Enum.PartType[shape or "Block"]
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local white = Color3.fromRGB(250,245,226)
local leaf = Color3.fromRGB(73,204,132)
local chrome = Color3.fromRGB(171,213,239)

-- size, position, accent, and primitive for the toy's defining details
local details = {
	banana={{1.1,.8,1.55,-.87,.37,0,"Body","Ball"},{1.1,.8,1.55,.87,.37,0,"Body","Ball"},{.48,.55,.47,1.18,.7,0,"Ink"}},
	mushroom={{1.28,1.65,1.22,0,-.57,0,"White","Ball"},{.41,.22,.41,-.64,.94,-.28,"White","Ball"},{.36,.22,.36,.57,.89,.27,"White","Ball"}},
	teacup={{1.32,1.36,.4,1.23,.22,0,"White","Ball"},{2.18,.14,2.12,0,1.31,0,"Ink","Ball"}},
	bowling_ball={{.37,.37,.17,-.46,.54,-1.01,"Ink","Ball"},{.37,.37,.17,.35,.54,-1.01,"Ink","Ball"},{.37,.37,.17,0,-.01,-1.15,"Ink","Ball"}},
	snowman={{1.5,1.5,1.5,0,1.13,0,"White","Ball"},{1.74,.32,1.72,0,.65,0,"Ink","Ball"},{.4,.3,.65,0,1.21,-.8,"Orange","Ball"}},
	crayon={{1.05,.8,1.05,0,1.55,0,"White","Ball"},{2.25,.73,2.25,0,-.36,0,"White","Ball"}},
	waffle={{.25,.26,2.33,-.71,1.23,0,"White"},{.25,.26,2.33,.71,1.23,0,"White"},{2.68,.26,.25,0,1.23,-.64,"White"},{2.68,.26,.25,0,1.23,.64,"White"}},
	bubble={{1.2,1.2,1.2,1.14,-.52,0,"Body","Ball"},{.71,.24,.12,-.55,.63,-.9,"White","Ball"}},
	magnet={{.85,.74,2.31,-.9,.9,0,"Chrome"},{.85,.74,2.31,.9,.9,0,"Chrome"},{.88,.91,2.29,0,.69,0,"Ink"}},
	pineapple={{.65,1.32,.65,-.45,1.27,0,"Leaf","Ball"},{.65,1.73,.65,0,1.48,0,"Leaf","Ball"},{.65,1.32,.65,.45,1.27,0,"Leaf","Ball"}},
	skate={{.54,.76,.76,-.86,-1.2,-.9,"Ink","Ball"},{.54,.76,.76,.86,-1.2,-.9,"Ink","Ball"},{.54,.76,.76,-.86,-1.2,.9,"Ink","Ball"},{.54,.76,.76,.86,-1.2,.9,"Ink","Ball"},{2.44,.33,2.31,0,-.8,0,"White"}},
	kettle={{.85,1.14,.8,0,1.25,0,"Chrome","Ball"},{.61,.76,1.68,0,.51,-1.1,"Chrome","Ball"},{.49,1.65,1.07,0,.39,1.1,"Ink","Ball"}},
	comet={{1.22,1.22,2.7,0,.1,1.3,"Chrome","Ball"},{.67,.67,2.7,.5,.27,2.03,"White","Ball"}},
	cupcake={{2.57,1.35,2.57,0,.86,0,"White","Ball"},{.62,.62,.62,0,1.64,0,"Orange","Ball"}},
	bell={{2.95,.45,2.52,0,-.8,0,"White","Ball"},{.81,.71,.81,0,-1.14,0,"Ink","Ball"},{.68,.62,.68,0,1.13,0,"Chrome","Ball"}},
	beach_ball={{.46,2.37,2.15,0,0,0,"White","Ball"},{2.54,2.37,.46,0,0,0,"Orange","Ball"}},
	strawberry={{.83,.62,.83,0,1.16,0,"Leaf","Ball"},{.19,.31,.15,-.55,.37,-1.02,"White","Ball"},{.19,.31,.15,.58,.1,-1.02,"White","Ball"},{.19,.31,.15,-.12,-.58,-1.02,"White","Ball"}},
	taco={{2.42,.49,.99,0,.74,-.15,"Leaf","Ball"},{2.22,.26,.76,0,.95,-.09,"Orange","Ball"}},
	lantern={{2.39,.36,2.39,0,-1.32,0,"Ink","Ball"},{2.57,.36,2.57,0,1.32,0,"Ink","Ball"},{.67,.72,.67,0,1.64,0,"White","Ball"}},
	watering_can={{.71,.76,1.73,0,.39,-1.19,"Body","Ball"},{.98,.83,.48,0,.64,-2,"White","Ball"},{.53,1.49,1.1,0,.33,1.36,"White","Ball"}},
	pretzel={{1.55,1.41,.6,-.49,.58,0,"White","Ball"},{1.55,1.41,.6,.49,.58,0,"Body","Ball"},{.43,.22,.16,.5,.42,-1.1,"White"}},
	planet={{3.65,.23,3.37,0,-.07,0,"White","Ball"},{.55,.55,.55,1.42,.81,1.04,"Chrome","Ball"}},
	whistle={{1.23,.78,1.51,0,.49,-1.42,"Chrome"},{.6,.19,.32,0,.9,-1.69,"Ink"}},
	mailbox={{.17,1.19,.25,1.42,.67,.25,"Orange"},{.22,.41,.77,1.43,1.21,.11,"Orange"},{1.35,.31,.12,0,.3,-1.18,"Ink"}},
	beanie={{2.77,.54,2.27,0,-.75,0,"White","Ball"},{.79,.79,.79,0,1.31,0,"Body","Ball"}},
	soda={{2.37,.2,2.37,0,1.37,0,"Chrome","Ball"},{.67,.14,.98,0,1.5,0,"Ink","Ball"},{.97,.87,.17,0,.02,-1.25,"White","Ball"}},
	spool={{2.67,.41,2.67,0,-1.29,0,"White","Ball"},{2.67,.41,2.67,0,1.29,0,"White","Ball"},{.71,.17,.71,0,1.52,0,"Ink","Ball"}},
	kite={{.43,.43,1.35,0,-1.17,.74,"Orange","Ball"},{.47,.42,1.22,0,-1.53,1.35,"White","Ball"}},
	dice={{.35,.35,.13,-.55,.55,-1.16,"Ink","Ball"},{.35,.35,.13,0,0,-1.16,"Ink","Ball"},{.35,.35,.13,.55,-.55,-1.16,"Ink","Ball"}},
	hourglass={{2.57,.28,2.57,0,-1.24,0,"Ink","Ball"},{2.57,.28,2.57,0,1.24,0,"Ink","Ball"},{1.67,.5,1.67,0,-.68,0,"White","Ball"}},
}

function Models.create(ingredient)
	local model = Instance.new("Model")
	model.Name = ingredient.Model
	local coreSize = Vector3.new(2.7, 2.45, 2.25)
	local core = Models.part(model, "Core", coreSize, Vector3.zero, ingredient.Color, ingredient.Shape)
	model.PrimaryPart = core
	if ingredient.Shape == "Cylinder" then
		core.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	end

	local function detail(name, size, x, y, z, color, shape)
		return Models.part(model, name, Vector3.new(table.unpack(size)), Vector3.new(x,y,z), color, shape)
	end
	local id = ingredient.Id
	if id == "duck" then
		detail("Head", {1.4,1.4,1.4}, 0,.7,-.65,ingredient.Color,"Ball")
		detail("Bill", {1,.4,.65}, 0,.5,-1.4,Color3.fromRGB(255,133,51),"Ball")
	elseif id == "toaster" then
		for x = -.55,.55,1.1 do detail("Slot", {.32,.07,1.48}, x,1.24,0,ink) end
		detail("Lever", {.45,.26,.47}, 1.48,.35,0,ink)
	elseif id == "potato" then
		for _, p in {Vector3.new(-.5,.65,-.91),Vector3.new(.64,.2,-.96),Vector3.new(.15,-.65,-.97)} do
			Models.part(model,"Dimple",Vector3.new(.22,.18,.16),p,ink,"Ball")
		end
	elseif id == "rocket" then
		detail("Nose", {1.45,1.4,1.45}, 0,1.25,0,cream,"Ball")
		for x = -1.16,1.16,2.32 do detail("Fin", {.43,.9,1.13}, x,-.95,.12,cream) end
		detail("Window", {.76,.76,.25}, 0,.3,-1.12,ink,"Ball")
	elseif id == "sock" then
		core.Size = Vector3.new(1.65,2.7,1.6)
		detail("Toe", {1.65,1.22,2.6}, 0,-.8,-.67,ingredient.Color,"Ball")
		detail("Cuff", {1.72,.55,1.66}, 0,1.15,0,cream)
	elseif id == "cactus" then
		for x = -1,1,2 do detail("Arm", {.68,1.55,.73}, x*1.26,.1+x*.28,0,ingredient.Color,"Ball") end
		detail("Flower", {.7,.5,.7}, .35,1.55,0,Color3.fromRGB(253,102,172),"Ball")
	elseif id == "donut" then
		core.Transparency = 1
		for n = 1, 9 do
			local a = n * math.pi * 2 / 9
			detail("Icing", {.92,.92,.82}, math.sin(a)*.92, math.cos(a)*.92, 0,ingredient.Color,"Ball")
			detail("Sprinkle",{.2,.1,.08},math.sin(a)*1.02,math.cos(a)*1.02,-.4,n%2==0 and cream or ink)
		end
	elseif id == "battery" then
		detail("Cap",{1.2,.37,1.2},0,1.51,0,cream)
		detail("Charge",{.79,.2,.12},0,.1,-1.16,ink)
		detail("Charge",{.2,.79,.12},0,.1,-1.16,ink)
	elseif id == "jelly" then
		core.Transparency = .18
		detail("Bubble",{.53,.53,.53},.4,.8,-.42,cream,"Ball")
	elseif id == "traffic_cone" then
		core.Size = Vector3.new(2.9,.36,2.9)
		core.CFrame = CFrame.new(0,-.95,0)
		for n = 0, 5 do
			local width = 2.13 - n*.28
			detail("Cone",{width,.39,width},0,-.65+n*.36,0,n==2 and cream or ingredient.Color)
		end
	else
		local colors={Body=ingredient.Color,White=white,Ink=ink,Leaf=leaf,Chrome=chrome,Orange=Color3.fromRGB(255,146,65)}
		for _,shape in details[id] or {} do
			detail("Accent",{shape[1],shape[2],shape[3]},shape[4],shape[5],shape[6],colors[shape[7]],shape[8])
		end
		if id=="banana" or id=="taco" or id=="waffle" then core.Size *= Vector3.new(1.14,.54,.89) end
		if id=="bubble" then core.Transparency=.36; core.Reflectance=.18 end
		if id=="kite" then core.Size=Vector3.new(2.04,2.04,.25); core.CFrame*=CFrame.Angles(0,0,math.pi/4) end
		if id=="pretzel" then core.Size=Vector3.new(2.62,1.45,.77) end
	end
	return model
end

return Models
