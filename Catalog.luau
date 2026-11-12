local Ingredients = require(script.Parent.Ingredients)
local Recipes = require(script.Parent.Recipes)
local tiers = {"Common","Rare","Epic","Legendary","Mythic"}
local Catalog = {ById = {}, Ordered = {}}

for _, first in Ingredients do
	for _, second in Ingredients do
		if first == second then continue end
		local id = first.Id.."+"..second.Id
		local a,b = table.find(tiers,first.Tier),table.find(tiers,second.Tier)
		local tier = a == b and a >= 3 and math.min(#tiers,a+1) or math.max(a,b)
		local recipe = {
			Id=id, Name=first.NameStart..second.NameEnd,
			Subtitle=first.DisplayName.." + "..second.DisplayName,
			Tier=tiers[tier], Ability=first.Ability, Trait=second.Trait,
			Body=first, Head=second,
		}
		local secret = Recipes[id]
		if secret then
			for key,value in secret do recipe[key]=value end
			recipe.Secret = true
		end
		Catalog.ById[id]=recipe
		table.insert(Catalog.Ordered,recipe)
	end
end
assert(#Catalog.Ordered==#Ingredients*(#Ingredients-1))
return Catalog
