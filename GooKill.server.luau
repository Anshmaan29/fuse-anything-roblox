-- Anyone who falls into the green goo pit is knocked out and respawns.
local Players = game:GetService("Players")
local goo = workspace:WaitForChild("LabWorld"):WaitForChild("Goo")
goo.CanTouch = true

goo.Touched:Connect(function(part)
	local character = part:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and Players:GetPlayerFromCharacter(character) then
		humanoid.Health = 0
	end
end)

-- Safety net: catch anyone who somehow slips below the goo.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 and root.Position.Y < -16 then
				humanoid.Health = 0
			end
		end
	end
end)
