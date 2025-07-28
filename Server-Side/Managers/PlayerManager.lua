local PlayerLoader = {}

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local ContentProvider = game:GetService("ContentProvider")

local DataManager = require(ServerStorage.Modules.Managers.DataManager)
local EventHandler = require(ReplicatedStorage.Modules.NetworkManager.EventHandler).new("Client")

function GiveInstance(player)
	local InLobby = Instance.new("BoolValue")
	InLobby.Name = "InLobby"
	InLobby.Parent = player
	InLobby.Value = true
end

function PlayerAdded(Player)
	DataManager:LoadProfile(Player)
	
	repeat task.wait(1) until Player:GetAttribute("PlayerLoaded") == true
	if DataManager.WaitForProfile(Player) then
		EventHandler:FireClient(Player, "LoadClients")
		DataManager.UpdateSettingsClient(Player)
		DataManager.UpdatePlayerInventory(Player)
		GiveInstance(Player)
	end 
end

function PlayerRemoved(Player)
	DataManager:PlayerRemoving(Player)
end

function PlayerLoader:Init()
	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoved)
	
	for _, Player in ipairs(Players:GetPlayers()) do
		PlayerAdded(Player)
	end
end

function PlayerLoader:Start()
end


return PlayerLoader