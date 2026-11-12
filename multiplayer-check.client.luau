if game:GetService("StudioTestService"):GetTestArgs() ~= "FuseMVP" then return end
local player = game.Players.LocalPlayer
local action = game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"):WaitForChild("Action")
player:GetAttributeChangedSignal("FuseTestAction"):Connect(function()
	for _ = 1, 8 do action:FireServer() end
end)
