local Players = game:GetService("Players")
local storage = game:GetService("ReplicatedStorage")
local Config = require(storage.Shared.Config)
local cooldowns = require(storage.Shared.Abilities)
local ingredients = require(storage.Shared.Ingredients)
local Funnel = require(script.Parent.FunnelService)
local ingredientsById={}
for _,ingredient in ingredients do ingredientsById[ingredient.Id]=ingredient end
local Pickup = require(script.Parent.PickupService)
local Fusion = require(script.Parent.FusionService)
local Ability = require(script.Parent.AbilityService)
local Hooks = require(script.Parent.Hooks)
local events = {
	require(script.Parent.Events.RisingLava),require(script.Parent.Events.FallingFruit),
	require(script.Parent.Events.SumoRing),require(script.Parent.Events.FanStorm),
}
local Round = {}

function Round.Run(action, duo, retention, award)
	local arena = workspace:WaitForChild("FuseArena")
	local shared = storage.Shared
	local random = Random.new()
	local participants, lastRequest, invites, duoRate = {}, {}, {}, {}
	local phase, previousEvent = "Lobby", nil
	local closing = false
	local function clock()
		return workspace:GetServerTimeNow()
	end

	local function live(player, state)
		if state and state.driver then
			local driver = participants[state.driver]
			if not driver or driver.character ~= state.driver.Character then return end
			state,player = driver,state.driver
		end
		local character = state and state.character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if character and character == player.Character and humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart") then
			return character
		end
	end

	local function inventory(player, state)
		for i = 1,3 do
			local ingredient = state.items[i]
			player:SetAttribute("Ingredient"..i, ingredient and ingredient.DisplayName or nil)
		end
	end

	local function characters()
		local result = {}
		for player, state in participants do
			local character = live(player,state)
			if character and not state.driver then table.insert(result, character) end
		end
		return result
	end

	local function attach(player)
		player.RespawnLocation = arena.LabSpawn
		player:SetAttribute("RoundStatus","Spectating")
		local view = Instance.new("ObjectValue")
		view.Name = "DuoView"
		view.Parent = player
	end
	Players.PlayerAdded:Connect(attach)
	Players.PlayerRemoving:Connect(function(player)
		local state = participants[player]
		if state and state.partner then
			local partner = participants[state.partner]
			if partner and not partner.driver then
				partner.partner = nil
				state.partner:SetAttribute("DuoRole",nil)
			end
		end
		participants[player] = nil
		lastRequest[player],invites[player],duoRate[player] = nil,nil,nil
	end)
	for _, player in Players:GetPlayers() do attach(player) end

	action.OnServerEvent:Connect(function(player, requestedAim)
		local now = clock()
		if now - (lastRequest[player] or 0) < .18 then return end
		lastRequest[player] = now
		local state = participants[player]
		local character = live(player,state)
		if not character or character:GetAttribute("Stunned") or now < state.cooldown then return end
		if player:GetAttribute("DuoRole")=="Driver" then return end
		local root = character.HumanoidRootPart
		if phase == "Grab" then
			local target, nearest = nil, 9
			for other, candidate in participants do
				local rival = other ~= player and live(other,candidate)
				if rival then
					local delta = rival.HumanoidRootPart.Position - root.Position
					local distance = delta.Magnitude
					if distance > .05 and distance < nearest and root.CFrame.LookVector:Dot(delta.Unit) > .14 then
						target, nearest = other, distance
					end
				end
			end
			state.cooldown = now + cooldowns.Slap
			if target then
				local victim = participants[target]
				local rival = victim.character
				local index=#victim.items
				if victim.items[index]==victim.paidIngredient then index-=1 end
				local dropped = index>0 and table.remove(victim.items,index)
				if dropped then
					inventory(target,victim)
					local p = rival.HumanoidRootPart.Position + root.CFrame.LookVector * 4
					Pickup.Spawn(dropped, Vector3.new(p.X,2.6,p.Z), false, target)
					state.score += 1
				end
				Ability.Knock(rival,root.CFrame.LookVector * 30 + Vector3.new(0,17,0))
			end
		elseif phase == "Chaos" and state.fusion then
			local function nearby(position, radius)
				local result = {}
				for _, target in characters() do
					if target ~= character and (target.HumanoidRootPart.Position-position).Magnitude <= radius then
						table.insert(result,target)
					end
				end
				return result
			end
			local aim
			if state.driver and typeof(requestedAim)=="Vector3" then
				local flat = Vector3.new(requestedAim.X,0,requestedAim.Z)
				if flat.Magnitude>.01 and flat.Magnitude<=1.01 then aim=flat.Unit end
			end
			if Ability.Use(state.fusion.Ability,character,nearby,aim) then
				state.cooldown = now + cooldowns[state.fusion.Ability]
			end
		end
		player:SetAttribute("ActionReadyAt",state.cooldown)
	end)

	local function canPair(player)
		local state = participants[player]
		return live(player,state) and not state.partner and not state.fusion and #state.items>0
	end

	duo.OnServerEvent:Connect(function(player,actionName)
		local now = clock()
		if now-(duoRate[player] or -10)<.45 then return end
		duoRate[player]=now
		if (phase~="Grab" and phase~="Fuse") or not canPair(player) then return end
		if actionName=="Accept" or actionName=="Decline" then
			local invite=invites[player]
			invites[player]=nil
			player:SetAttribute("DuoInvite",nil)
			if not invite or now>invite.expires or not canPair(invite.from) then return end
			if actionName=="Decline" then
				invite.from:SetAttribute("DuoStatus","Invite declined")
				return
			end
			local offered,accepted=participants[invite.from].items,participants[player].items
			if #offered==1 and #accepted==1 and offered[1]==accepted[1] then
				player:SetAttribute("DuoStatus","Bring two different ingredients")
				invite.from:SetAttribute("DuoStatus","Bring two different ingredients")
				return
			end
			participants[player].partner=invite.from
			participants[invite.from].partner=player
			participants[player].invitedBy=invite.from
			player:SetAttribute("DuoStatus","Paired with "..invite.from.Name)
			invite.from:SetAttribute("DuoStatus","Paired with "..player.Name)
		elseif actionName=="Offer" then
			local position=participants[player].character.HumanoidRootPart.Position
			local nearest,distance=nil,17
			for other,state in participants do
				if other~=player and canPair(other) then
					local gap=(state.character.HumanoidRootPart.Position-position).Magnitude
					local pending=invites[other]
					if gap<distance and (not pending or pending.expires<now) then nearest,distance=other,gap end
				end
			end
			if nearest then
				invites[nearest]={from=player,expires=now+8}
				nearest:SetAttribute("DuoInvite",player.Name)
				nearest:SetAttribute("DuoInviteUntil",now+8)
				player:SetAttribute("DuoStatus","Invited "..nearest.Name)
			else
				player:SetAttribute("DuoStatus","Move near a player holding an item")
			end
		end
	end)

	local function reveal(player,state,recipe,mutation)
		state.fusion=recipe
		if mutation=="Golden" and player:GetAttribute("FirstFusePending") then
			player:SetAttribute("FirstFusePending",nil)
			Hooks.Fire("FirstFuse",player)
			task.delay(1.2,function() player:SetAttribute("ProgressNotice","✨ LUCKY FIRST FUSION: GOLDEN! It earns ×2 in your Lab") end)
		end
		state.score+=3
		player:SetAttribute("CreatureTier",recipe.Tier)
		player:SetAttribute("CreatureSubtitle",recipe.Subtitle)
		player:SetAttribute("Ability",recipe.Ability)
		player:SetAttribute("Mutation",mutation)
		player:SetAttribute("Creature",recipe.Name)
		Funnel.Fused(player)
		task.spawn(retention.Discover,player,recipe,mutation)
	end

	function Round.VIP(player)
		if not player:GetAttribute("PassVIP") or player:GetAttribute("RoundStatus")=="Playing" then
			return false,"VIP lounge is available in the lobby."
		end
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health<=0 then return false,"Wait for your character." end
		local destination=(root.Position-arena.VIPSpawn.Position).Magnitude<17 and arena.LabSpawn or arena.VIPSpawn
		character:PivotTo(destination.CFrame*CFrame.new(0,4,0))
		root.AssemblyLinearVelocity=Vector3.zero
		return true,destination==arena.VIPSpawn and "VIP lounge" or "Back in the Lab"
	end

	function Round.PrepareVoucher(player,kind,value)
		local state=participants[player]
		if not state then return nil,"Join a round first." end
		local function capacity()
			return player:GetAttribute("PassThirdHand") and 3 or 2
		end
		if kind=="Pick" then
			local ingredient=type(value)=="string" and ingredientsById[value]
			local function eligible()
				return ingredient and phase=="Grab" and participants[player]==state and live(player,state)
					and not state.usedPick and #state.items<capacity() and not table.find(state.items,ingredient)
			end
			if not eligible() then return nil,"Choose a new ingredient during Grab, with a free slot." end
			return function()
				if not eligible() then return false end
				table.insert(state.items,ingredient)
				state.usedPick,state.paidIngredient=true,ingredient
				inventory(player,state)
				return true
			end
		end
		local function eligible()
			local c=player.Character
			local humanoid=c and c:FindFirstChildOfClass("Humanoid")
			return phase=="Chaos" and shared:GetAttribute("EndsAt")-clock()>5
				and participants[player]==state and not state.partner and not state.driver and not state.usedRevive
				and player:GetAttribute("RoundStatus")=="Out" and not live(player,state) and c~=state.character
				and humanoid and humanoid.Health>0 and c:FindFirstChild("HumanoidRootPart") and c
		end
		if not eligible() then return nil,"After a solo elimination, wait to respawn. Revive closes 5s before Reward." end
		return function()
			local character=eligible()
			if not character then return false end
			character:PivotTo(CFrame.new(0,11,0))
			character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
			if state.fusion then
				Fusion.Apply(character,state.fusion,state.mutation,player)
			end
			state.character,state.usedRevive=character,true
			player:SetAttribute("RoundStatus","Playing")
			return true
		end
	end

	local function inPot(character)
		local p=character.HumanoidRootPart.Position
		return Vector3.new(p.X,0,p.Z).Magnitude<=7.5 and p.Y>=8.4 and p.Y<=15
	end

	game:BindToClose(function() closing = true end)
	local function stage(name, duration, eventName)
		phase = name
		local deadline = clock()+duration
		shared:SetAttribute("Event",eventName)
		shared:SetAttribute("EndsAt",deadline)
		shared:SetAttribute("Phase",phase)
		return deadline
	end

	local function waitStage(deadline, onTick)
		while not closing and clock() < deadline do
			if onTick then onTick() end
			task.wait(.12)
		end
	end

	local function outOfBounds()
		for player, state in participants do
			local character = live(player,state)
			if character then
				local p = character.HumanoidRootPart.Position
				if p.Y < -12 or Vector3.new(p.X,0,p.Z).Magnitude > 72 then
					Ability.Knock(character,Vector3.zero)
					character.Humanoid.Health = 0
				end
			elseif player:GetAttribute("RoundStatus") == "Playing" then
				player:SetAttribute("RoundStatus","Out")
			end
		end
	end

	while not closing do
		waitStage(stage("Lobby",Config.Intermission))
		if closing then break end
		if #Players:GetPlayers() == 0 then continue end

		for index, player in Players:GetPlayers() do
			if player:GetAttribute("LabMode") then continue end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				humanoid.BreakJointsOnDeath = false
				local angle = index * 2.399963
				local position = Vector3.new(math.cos(angle)*28,5,math.sin(angle)*28)
				character:PivotTo(CFrame.lookAt(position,Vector3.new(0,5,0)))
				root.AssemblyLinearVelocity = Vector3.zero
				participants[player] = {character = character, items = {}, score = 0, cooldown = 0}
				player:SetAttribute("RoundStatus","Playing")
			end
		end
		if next(participants) == nil then continue end
		local grabEnds = stage("Grab",Config.Grab)
		Pickup.Start(function(player, ingredient)
			local state = participants[player]
			local capacity=player:GetAttribute("PassThirdHand") and 3 or 2
			if phase ~= "Grab" or not live(player,state) or #state.items >= capacity or table.find(state.items,ingredient) then return false end
			table.insert(state.items,ingredient)
			inventory(player,state)
			return true
		end)
		waitStage(grabEnds,outOfBounds)
		Pickup.Stop()
		local fuseEnds = stage("Fuse",Config.Fuse)
		waitStage(fuseEnds,function()
			outOfBounds()
			for player,state in participants do
				local character = live(player,state)
				if not character or state.fusion or not inPot(character) then continue end
				local partner = state.partner
				local other = partner and participants[partner]
				local otherCharacter = partner and live(partner,other)
				local mutation
				if not state.usedPick and not (other and other.usedPick) then
					mutation=Fusion.Mutation(random:NextNumber())
				end
				if player:GetAttribute("FirstFusePending") and not state.items[3] then
					mutation="Golden" -- lucky first fusion; the flag is cleared in reveal() once it really happens
				end
				if otherCharacter and #other.items>0 and #state.items>0 and inPot(otherCharacter) and not other.fusion then
					-- The sender drives. The accepted player uses the ability.
					if state.invitedBy then continue end
					local first,second=state.items[1],other.items[1]
					if first==second then second=other.items[2] end
					if not second then second=first; first=state.items[2] end
					if first and second then
						local recipe=Fusion.Resolve(first,second)
						if Fusion.Apply(character,recipe,mutation,player) then
							state.mutation,other.mutation=mutation,mutation
							other.driver=player
							other.character:PivotTo(arena.LabSpawn.CFrame*CFrame.new(0,5,0))
							other.character.HumanoidRootPart.Anchored=true
							partner.ReplicationFocus=character.HumanoidRootPart
							partner.DuoView.Value=character
							player:SetAttribute("DuoRole","Driver")
							partner:SetAttribute("DuoRole","Ability")
							reveal(player,state,recipe,mutation)
							reveal(partner,other,recipe,mutation)
						end
						continue
					end
				end
				if #state.items>=2 and (not otherCharacter or other.fusion or clock()>fuseEnds-.55) then
					local recipe=Fusion.Resolve(state.items[1],state.items[2])
					if state.items[3] then
						recipe=Fusion.Triple(recipe,state.items[3])
						mutation=nil
					end
					if Fusion.Apply(character,recipe,mutation,player) then
						state.mutation=mutation
						reveal(player,state,recipe,mutation)
					end
				end
			end
		end)

		local eligible = {}
		for _,candidate in events do
			if candidate~=previousEvent then table.insert(eligible,candidate) end
		end
		local event = eligible[random:NextInteger(1,#eligible)]
		previousEvent = event
		local chaosEnds = stage("Chaos",Config.Chaos,event.Name)
		event.Start({arena = arena, startedAt = chaosEnds-Config.Chaos, characters = characters})
		waitStage(chaosEnds,outOfBounds)
		event.Stop()
		if closing then break end

		local rewardEnds = stage("Reward",Config.Reward,event.Name)
		local bestScore = 0
		for player, state in participants do
			state.survived = live(player,state) ~= nil
			if state.survived then state.score += 5 end
			bestScore = math.max(bestScore,state.score)
		end
		for player, state in participants do
			local coins = state.survived and Config.SurviveCoins or 0
			if state.fusion then coins += Config.FusionCoins end
			if state.score > 0 and state.score == bestScore then coins += Config.TopCoins end
			if state.survived and player:GetAttribute("DuoRole") and state.partner and participants[state.partner] then
				coins *= 2
			end
			if player:GetAttribute("PassDoubleCoins") then coins*=2 end
			coins=math.floor(coins*(1+.25*(player:GetAttribute("Rebirths") or 0)))
			award(player,coins)
			Funnel.Finished(player)
			if state.survived then task.spawn(retention.Win,player) end
			player.DuoView.Value=nil
			player.ReplicationFocus=nil
			player:SetAttribute("RoundCoins",coins)
			player:SetAttribute("RoundStatus",state.survived and "Survived" or "Out")
			task.spawn(function()
				if player.Parent == Players then player:LoadCharacterAsync() end
			end)
		end
		waitStage(rewardEnds)
		for player, state in participants do
			table.clear(state.items)
			inventory(player,state)
			for _, attribute in {"Creature","CreatureTier","CreatureSubtitle","Ability","RoundCoins","ActionReadyAt","Mutation","DuoRole","DuoInvite","DuoInviteUntil","DuoStatus","ProgressNotice"} do
				player:SetAttribute(attribute,nil)
			end
			player:SetAttribute("RoundStatus","Spectating")
		end
		table.clear(participants)
		table.clear(invites)
	end
end

return Round
