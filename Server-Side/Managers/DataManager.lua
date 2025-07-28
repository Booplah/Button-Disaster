-- [Services]
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DatastoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService('HttpService')
local EventHandler = require(ReplicatedStorage.Modules.NetworkManager.EventHandler).new("Server")
-- [Data Tables]

local ProfileService = require(script.ProfileStore)

-- [Player Data Template]
local ProfileTemplate = {
	ClientData = {
		Cash = 5000,
		Gems = 0,
		Levels = 0,
		EXP = 0,
		LastLogin = 0,
		LoginStreak = 0,
		DailyRewardClaimed = false,
		CodesRedeemed = {},
	};
	
	Inventory = {
		Equipped = { Item = "", Pet = "", Trail = "" };
		Items = {},
		Pets = {},
		Trails = {},
		ChestsOpened = 0,
	},

	SettingsData = {
		VFXcolor = "Default",
		MusicEnabled = false,  -- Default to enabled
		DeathSFXMuted = false,
		LowGraphics = false,
		HideGUI = false
	};

	StatsData = {
		Wins = 0,
		Deaths = 0,
		TimesPlayed = 0,
		WinRate = 0.0,
		Achievements = {},
	};

	Gamepasses = {};
	
	ServerData = {
		Banned = false,
		Strikes = 0,
	};

}

local ProfileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)
local DataManager = {}
local Profiles = {} -- [player] = profile


-- [Player Data Functions]
function DataManager.GetProfile(player)
	return Profiles[player]
end

function DataManager.ClearProfile(player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
		Profiles[player] = nil
		return true
	end
	return false
end

function DataManager.WipeData(player : Player)
	ProfileStore:WipeProfileAsync("Player_" .. player.UserId)
end

function DataManager.ApplyAttributes(player, data)
	for key, value in pairs(data) do
		if typeof(value) == "number" or typeof(value) == "string" or typeof(value) == "boolean" then
			player:SetAttribute(key, value)
		end
	end
end

-- [Currency Management]
function DataManager.AddCash(player, amount)
	local profile = Profiles[player]
	if profile and profile.Data then
		profile.Data.ClientData.Cash = (profile.Data.ClientData.Cash or 0) + amount
		player:SetAttribute("Cash", profile.Data.ClientData.Cash)
		return true
	end
	return false
end

function DataManager.RemoveCash(player, amount)
	local profile = Profiles[player]
	if profile and profile.Data then
		profile.Data.ClientData.Cash = (profile.Data.ClientData.Cash or 0) - amount
		player:SetAttribute("Cash", profile.Data.ClientData.Cash)
		print(`\n{amount} Removed, \nNew Amount: {profile.Data.ClientData.Cash}`)
		return true
	end
	return false
end

-- [Progression System]
function DataManager.AddEXP(player, amount)
	local profile = Profiles[player]
	if profile and profile.Data then
		profile.Data.ClientData.EXP = (profile.Data.ClientData.EXP or 0) + amount
		player:SetAttribute("EXP", profile.Data.ClientData.EXP)
		return true
	end
	return false
end

function DataManager.SetLevel(player, level)
	local profile = Profiles[player]
	if profile and profile.Data then
		profile.Data.ClientData.Level = level
		player:SetAttribute("Level", level)
		return true
	end
	return false
end

-- [Stats Tracking]
function DataManager.AddWin(player)
	local profile = Profiles[player]
	if profile and profile.Data then
		profile.Data.StatsData.Wins += 1
		player:SetAttribute("Wins", profile.Data.StatsData.Wins)

		local streak = (player:GetAttribute("WinStreak") or 0) + 1
		player:SetAttribute("WinStreak", streak)
		return true
	end
	return false
end

function DataManager.ResetStreak(player)
	player:SetAttribute("WinStreak", 0)
	return true
end

-- [Inventory System]
function DataManager.AddItemToInventory(player, itemId, itemType)
	local profile = Profiles[player]
	if not profile then return false end

	local inventoryType
	if itemType == "Item" then
		inventoryType = "Items"
	elseif itemType == "Pet" then
		inventoryType = "Pets"
	elseif itemType == "Trail" then
		inventoryType = "Trails"
	else
		return false
	end

	for _, existingId in ipairs(profile.Data.Inventory[inventoryType] or {}) do
		if existingId == itemId then
			return false, "Already owned"
		end
	end

	table.insert(profile.Data.Inventory[inventoryType], itemId)
	return true
end

function DataManager.GetPlayerInventory(player)
	local profile = Profiles[player]
	if profile and profile.Data then
		return {
			Items = profile.Data.Inventory.Items or {},
			Pets = profile.Data.Inventory.Pets or {},
			Trails = profile.Data.Inventory.Trails or {},
			Equipped = profile.Data.Inventory.Equipped or { Item = "", Pet = "", Trail = "" },
		}
	end
	return {
		Items = {}, 
		Pets = {}, 
		Trails = {} ,
		Equipped = { Item = "", Pet = "", Trail = "" }
	}
end

function DataManager.EquipItem(player, itemType, itemId)
	local profile = Profiles[player]
	if not profile then return false end

	-- Create equipped data if not exists
	if not profile.Data.Equipped then
		profile.Data.Equipped = {
			Item = "",
			Pet = "",
			Trail = ""
		}
	end

	-- Set equipped item
	profile.Data.Equipped[itemType] = itemId

	-- Update client
	DataManager.UpdatePlayerInventory(player)
	return true
end

-- [Shop System]
function DataManager.UnequipItem(player, itemType)
	local profile = Profiles[player]
	if not profile then return false end

	if profile.Data.Equipped then
		profile.Data.Equipped[itemType] = ""
	end

	-- Update client
	DataManager.UpdatePlayerInventory(player)
	return true
end

function DataManager.UpdatePlayerInventory(player)
	local inventory = DataManager.GetPlayerInventory(player)
	EventHandler:FireClient(player, "UpdateInventory", inventory)
end

function DataManager.PurchaseItemValidate(player, itemId, itemType, price)
	local profile = Profiles[player]
	if not profile then 
		return false, "Profile not loaded" 
	end

	for _, existingId in ipairs(profile.Data.Inventory[itemType] or {}) do
		if existingId == itemId then
			return false, "Already owned"
		end
	end

	if type(price) ~= "number" or price <= 0 then
		return false, "Invalid price"
	end

	local currentCash = profile.Data.ClientData.Cash or 0
	if currentCash < price then
		return false, "Not enough cash"
	end

	local added, reason = DataManager.AddItemToInventory(player, itemId, itemType)
	if not added then
		return false, reason or "Inventory error"
	end

	return true
end

-- [Settings System]
function DataManager.GetPlayerSettings(player)
	local profile = Profiles[player]
	if profile and profile.Data then
		return {
			MusicEnabled    = profile.Data.SettingsData.MusicEnabled,
			DeathSFXMuted   = profile.Data.SettingsData.DeathSFXMuted,
			LowGraphics     = profile.Data.SettingsData.LowGraphics,
			HideGUI         = profile.Data.SettingsData.HideGUI,
			VFXcolor        = profile.Data.SettingsData.VFXcolor,
		}
	end
end

function DataManager.UpdateSettingsClient(player)
	local profile = Profiles[player]
	if profile and profile.Data then
		local Settings = DataManager.GetPlayerSettings(player)
		EventHandler:FireClient(player, "UpdateSettingsClient", Settings)
	end
end

-- [Code Redemption System]
function DataManager.HasRedeemedCode(player, code)
	local profile = Profiles[player]
	if profile and profile.Data then
		local redeemedCodes = profile.Data.ClientData.CodesRedeemed or {}
		return table.find(redeemedCodes, code) ~= nil
	end
	return false
end

function DataManager.MarkCodeRedeemed(player, code)
	local profile = Profiles[player]
	if profile and profile.Data then
		profile.Data.ClientData.CodesRedeemed = profile.Data.ClientData.CodesRedeemed or {}
		table.insert(profile.Data.ClientData.CodesRedeemed, code)
		return true
	end
	return false
end

function DataManager.RedeemCodeReward(player, code)
	-- This will be implemented in CodesData
	return false, "Code not implemented"
end
--

function DataManager:RequestProfileMetaTags(Player)
	local profile = Profiles[Player]
	if profile then
		return profile.MetaData.MetaTags
	end
end

function DataManager.WaitForProfile(player)
	if player:GetAttribute("PlayerLoaded", true) then
		return true
	end
	return false
end

-- [Loads Data when joining]
function DataManager:LoadProfile(player: Player)
	player:SetAttribute("PlayerLoaded", false)
	
	--DataManager.WipeData(player)
	--warn("Profile Wiped")	
	--wait(2)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick()
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			warn("Profile Loaded")
			player:SetAttribute("PlayerLoaded", true)
			return true
		else
			profile:Release()
		end
	else
		player:Kick()
	end
	return false
end

-- [Releases Data when Leaving]
function DataManager:PlayerRemoving(player)
	local profile = Profiles[player]
	if profile then
		profile:Release()
	end
end



return DataManager