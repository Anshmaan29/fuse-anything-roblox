local tests = game:GetService("StudioTestService")
if tests:GetTestArgs() ~= "FuseMVP" then return end
local shared = game.ReplicatedStorage:WaitForChild("Shared")
local players = game:GetService("Players")
local function waitFor(predicate, seconds, message)
	local deadline = os.clock()+seconds
	repeat
		if predicate() then return end
		task.wait(.06)
	until os.clock()>deadline
	error(message)
end
local function phase(name, seconds)
	waitFor(function() return shared:GetAttribute("Phase")==name end,seconds,"Missing phase "..name)
end
local function collect(player, ids)
	for _, id in ids do
		local folder = workspace.FuseArena.Ingredients
		local item
		waitFor(function()
			item = folder:FindFirstChild(id)
			return item and item.Pickup.Position.Y < 4
		end,8,"Ingredient did not land: "..id)
		player.Character:PivotTo(CFrame.new(item.Pickup.Position+Vector3.new(0,3.4,0)))
		waitFor(function() return item.Parent == nil end,1.5,"Pickup failed: "..id)
	end
end

local ok, result = pcall(function()
	waitFor(function()
		local all = players:GetPlayers()
		return #all == 2 and all[1].Character and all[2].Character
	end,30,"Two players did not spawn")
	local a,b = table.unpack(players:GetPlayers())
	if shared:GetAttribute("Phase") == "Grab" and (a:GetAttribute("RoundStatus") ~= "Playing" or b:GetAttribute("RoundStatus") ~= "Playing") then
		phase("Lobby",106)
	end
	phase("Grab",13)
	assert(a:GetAttribute("RoundStatus")=="Playing" and b:GetAttribute("RoundStatus")=="Playing","Both players must join the same round")
	collect(b,{"duck","potato"})
	collect(a,{"toaster","jelly"})
	local p = Vector3.new(-15,5,-15)
	b.Character:PivotTo(CFrame.new(p+Vector3.new(0,0,-4)))
	a.Character:PivotTo(CFrame.lookAt(p,p+Vector3.new(0,0,-4)))
	task.wait(.2)
	a:SetAttribute("FuseTestAction",1)
	waitFor(function() return b:GetAttribute("Ingredient2")==nil end,2,"Slap did not remove the second pickup")
	assert(b:GetAttribute("Ingredient1")=="Duck","Slap removed the wrong ingredient")
	assert((a:GetAttribute("ActionReadyAt") or 0)>workspace:GetServerTimeNow(),"Slap cooldown missing")
	task.wait(.7)
	collect(b,{"rocket"})
	phase("Fuse",26)
	a.Character:PivotTo(CFrame.new(-3,11,0))
	b.Character:PivotTo(CFrame.new(3,11,0))
	waitFor(function() return a:GetAttribute("Creature")=="Toastelly" and b:GetAttribute("Creature")=="Duket" end,3,"Two ordered fusions were not created")
	phase("Chaos",7)
	a.Character:PivotTo(CFrame.new(42,12,0))
	b.Character:PivotTo(CFrame.new(-42,12,0))
	a:SetAttribute("FuseTestAction",2)
	b:SetAttribute("FuseTestAction",1)
	waitFor(function()
		return (a:GetAttribute("ActionReadyAt") or 0)>workspace:GetServerTimeNow()
			and (b:GetAttribute("ActionReadyAt") or 0)>workspace:GetServerTimeNow()
	end,2,"Ability cooldowns missing")
	local event=shared:GetAttribute("Event")
	local locations={Vector3.new(42,12,0),Vector3.new(-42,12,0),Vector3.new(21,12,36.37),Vector3.new(-21,12,-36.37)}
	local step=0
	b.Character.Humanoid.Health=0
	while shared:GetAttribute("Phase")=="Chaos" do
		assert(a.Character.Humanoid.Health>0,"Survival test player was eliminated")
		step+=1
		if event=="Falling Fruit" or step==1 then a.Character:PivotTo(CFrame.new(locations[step%#locations+1])) end
		task.wait(1)
	end
	phase("Reward",1)
	assert(a:GetAttribute("Coins")==55 and b:GetAttribute("Coins")==5,"Unexpected participant rewards")
	return "PASS · two clients · slap and drop · two ordered fusions · Ground Slam and Bounce · survivor 55 coins · eliminated 5 coins"
end)
local message=ok and result or ("FAIL · "..tostring(result))
shared:SetAttribute("MultiplayerSmoke",message)
print(message)
task.wait(4)
tests:EndTest(message)
