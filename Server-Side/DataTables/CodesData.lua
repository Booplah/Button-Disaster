local ServerStorage = game:GetService("ServerStorage")

local DataManager = require(ServerStorage.Modules.Managers.DataManager)

-- Inactive codes, 10klikes, sorryforshutdown, 20klikes

local ActiveCodes = {"35klikes", "tyforfollows", "55klikes", "shutdownsrry", "80klikes", "newgame"}

local Rewards = {}

Rewards["10klikes"] = function(Player)
	DataManager:AddItem(Player, "Locked Blue Pill", 1)
	return true
end

Rewards["sorryforshutdown"] = function(Player)
	DataManager:AddItem(Player, "Locked Soul Ticket", 1)
	return true
end

Rewards["20klikes"] = function(Player)
	DataManager:AddItem(Player, "Locked Weapon Reroll", 1)
	return true
end

Rewards["35klikes"] = function(Player)
	DataManager:AddItem(Player, "Locked Blue Pill", 1)
	DataManager:AddItem(Player, "Locked Weapon Reroll", 1)
	return true
end

Rewards["tyforfollows"] = function(Player)
	DataManager:AddItem(Player, "Locked Shikai/Res/Volt Reroll", 1)
	return true
end

Rewards["55klikes"] = function(Player)
	--DataManager:AddItem(Player, "Locked Shikai Model Reroll", 1)
	DataManager:AddItem(Player, "Locked Weapon Reroll", 1)
	return true
end

Rewards["shutdownsrry"] = function(Player)
	DataManager:AddItem(Player, "Locked Element Reroll", 1)
	return true
end

Rewards["80klikes"] = function(Player)
	DataManager:AddItem(Player, "Locked Blue Pill", 1)
	DataManager:AddItem(Player, "Locked Weapon Reroll", 1)
	DataManager:AddItem(Player, "Locked Shikai/Res/Volt Reroll", 1)
	return true
end

Rewards["newgame"] = function(Player)
	DataManager:AddItem(Player, "Locked Soul Ticket", 1)
	return true
end

local Codes = {}

function Codes:CheckCode(Player, Code)
	local Profile = DataManager:RequestProfile(Player)
	local MetaTags = DataManager:RequestProfileMetaTags(Player)
	if not MetaTags.UsedCodes then
		MetaTags.UsedCodes  = {}
	end

	local VerifiedCode = table.find(ActiveCodes, string.lower(Code)) and string.lower(Code)
	if VerifiedCode then
		if Profile.ClientData.UsedCodes and table.find(Profile.ClientData.UsedCodes, VerifiedCode) then
			return nil
		end

		if not table.find(MetaTags.UsedCodes, VerifiedCode) then
			table.insert(MetaTags.UsedCodes, VerifiedCode)
			return Rewards[VerifiedCode](Player)
		end
	end
end

return Codes
