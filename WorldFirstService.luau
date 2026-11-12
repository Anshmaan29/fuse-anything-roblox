local Data = require(script.Parent.DataService)
local HttpService = game:GetService("HttpService")
local claims = Data.Store("FuseWorldFirstV1")
local WorldFirst = {}

function WorldFirst.Claim(player, recipe)
	local key = recipe.Id
	local candidate = {UserId=player.UserId,Name=player.Name,Token=HttpService:GenerateGUID(false)}
	local ok,owner = Data.Retry(function()
		return claims:UpdateAsync(key,function(previous) return previous or candidate end)
	end)
	if ok then return owner, owner.Token == candidate.Token end
end

return WorldFirst
