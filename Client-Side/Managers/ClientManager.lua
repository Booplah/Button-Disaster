-- [Services]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [Modules]
local InventoryUI = require(ReplicatedStorage.Modules.UI.InventoryUI)
local ShopUI = require(ReplicatedStorage.Modules.UI.ShopUI)
local SettingsUI = require(ReplicatedStorage.Modules.UI.SettingsUI)
local SettingsManager = require(ReplicatedStorage.Modules.UI.SettingsUI.SettingsManager)
local EventHandler = require(ReplicatedStorage.Modules.NetworkManager.EventHandler).new("Client")
--local ModuleLoader = require(ReplicatedStorage.Modules.Utility.ModuleLoader)

-- [Private Variables]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local settingsLog = {}


local Handlers = {
	[`UpdateInventory`] = function(inventory)
		ShopUI:SetInventory(inventory)
		--print(inventory)
		InventoryUI:SetInventory(inventory)
	end,
	[`UpdateSettingsClient`] = function(Settings)
		SettingsUI:SetSettings(Settings) -- only updates visuals
	end,
}

local EventListener = require(ReplicatedStorage.Modules.NetworkManager.EventListener).new(Handlers, script.Name)