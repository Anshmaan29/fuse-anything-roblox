local storage = game:GetService("ReplicatedStorage")
local Catalog = require(storage.Shared.Catalog)
local Config = require(storage.Shared.Config)
local Daily = {}

function Daily.Today()
	local day = math.floor(os.time()/86400)
	local recipe = Catalog.Ordered[Random.new(day*7919+311):NextInteger(1,#Catalog.Ordered)]
	return day,recipe
end

function Daily.Hint()
	local _,recipe = Daily.Today()
	return "Start with "..recipe.Body.DisplayName..". The second item starts with "..recipe.Head.DisplayName:sub(1,1).."."
end

function Daily.Badge(player)
	if game:GetService("RunService"):IsStudio() or Config.DailyBadgeId <= 0 then return end
	local badge = game:GetService("BadgeService")
	task.spawn(function()
		local ok,err = pcall(function()
			if not badge:UserHasBadgeAsync(player.UserId,Config.DailyBadgeId) then
				assert(badge:AwardBadgeAsync(player.UserId,Config.DailyBadgeId),"Badge award declined")
			end
		end)
		if not ok then warn("Daily mystery badge could not be awarded",err) end
	end)
end

return Daily
