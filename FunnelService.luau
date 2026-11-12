local Analytics = game:GetService("AnalyticsService")
local Http = game:GetService("HttpService")
local Players = game:GetService("Players")
local studio = game:GetService("RunService"):IsStudio()
local Funnel = {}
local sessions = {}
local labels = {"Joined","First Fusion","First Round Finished","Round 3"}

local function step(player, session, number)
	if session.step+1~=number then return end
	session.step=number
	if not studio then
		local ok,err=pcall(Analytics.LogFunnelStepEvent,Analytics,player,"First Rounds",session.id,number,labels[number])
		if not ok then warn("Fuse funnel event failed",err) end
	end
end

local function attach(player)
	if sessions[player] then return end
	local session={id=Http:GenerateGUID(false),step=0,rounds=0}
	sessions[player]=session
	step(player,session,1)
end

function Funnel.Start()
	Players.PlayerAdded:Connect(attach)
	Players.PlayerRemoving:Connect(function(player) sessions[player]=nil end)
	for _,player in Players:GetPlayers() do attach(player) end
end

function Funnel.Fused(player)
	local session=sessions[player]
	if session then step(player,session,2) end
end

function Funnel.Finished(player)
	local session=sessions[player]
	if not session then return end
	session.rounds+=1
	step(player,session,3)
	if session.rounds>=3 then step(player,session,4) end
end

return Funnel
