local ServerHandler = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataManager = require(ServerStorage.Modules.Managers.DataManager)
local EventHandler = require(ReplicatedStorage.Modules.NetworkManager.EventHandler).new("Server")
local CodesData = require(ServerStorage.Modules.DataTables.CodesData)

function ServerHandler:Init()
	local Handlers = {
		
		-- [UI Related]
		[`PurchaseItem`] = function(player, itemId, itemType, price)
			price = tonumber(price) or 0
			local Success, Error = DataManager.PurchaseItemValidate(player, itemId, itemType, price)

			if Success then
				DataManager.RemoveCash(player, price)
				DataManager.UpdatePlayerInventory(player)
				return true 
			else 
				warn("Purchase failed:", Error)
			end
			return false, Error
		end,
		[`RequestInventory`] = function(player)
			local inventory = DataManager.GetPlayerInventory(player)
			return inventory
		end,
		[`EquipItem`] = function(player, itemType, itemData)
			local profile = DataManager.GetProfile(player)
			if not profile then return false end

			profile.Data.Inventory.Equipped[itemType] = itemData.Id
		end,
		[`UnequipItem`] = function(player, itemType)
			local profile = DataManager.GetProfile(player)
			if not profile then return false end

			if profile.Data.Inventory.Equipped then
				profile.Data.Inventory.Equipped[itemType] = nil
			end
		end,
		["RequestSettings"] = function(player)
			local Settings = DataManager.GetPlayerSettings(player)
			return Settings
		end,

		["UpdateSetting"] = function(player, settingName, value)
			local profile = DataManager.GetProfile(player)
			if profile and profile.Data.SettingsData[settingName] ~= nil then
				print(`Settings Changed: {settingName} = {value}`)
				profile.Data.SettingsData[settingName] = value
				DataManager.UpdateSettingsClient(player)
				return true
			end
			return false
		end,
		--=====================================================================--
		[`RedeemCode`] = function(player, code)
			local success, message = CodesData:RedeemCode(player, code)
			print(message)
			return success, message
		end,
		
	}
	local EventListener = require(ReplicatedStorage.Modules.NetworkManager.EventListener).new(Handlers, script.Name)
end

function ServerHandler:Start()
end
return ServerHandler