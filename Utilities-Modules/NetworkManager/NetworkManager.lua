local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkManager = {}

function NetworkManager.FireAllClients(Character, RemoteName, RenderDistance, PathData, ...)
	local Remote = ReplicatedStorage.Remotes[RemoteName]
	Remote:FireAllClients(Character, RenderDistance, PathData, ...)
end

function NetworkManager.FireServer(RemoteName, ...)
	local Remote = ReplicatedStorage.Remotes[RemoteName]
	Remote:FireServer(...)
end

function NetworkManager.FireClient(Player, Character, RemoteName, RenderDistance, PathData, ...)
	local Remote = ReplicatedStorage.Remotes[RemoteName]
	Remote:FireClient(Player, Character, RenderDistance, PathData, ...)
end


return NetworkManager
