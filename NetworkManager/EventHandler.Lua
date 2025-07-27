	local EventHandler = {}
	EventHandler.__index = EventHandler

	local RunService = game:GetService("RunService")
	local rs = game:GetService("ReplicatedStorage")

	-- Constructor
	function EventHandler.new(name)
	local self = setmetatable({}, EventHandler)
	
	self.remotes = {
		async = rs.Modules.NetworkManager.Asynchronous,
		unreliable = rs.Modules.NetworkManager.Unreliable,
		sync = rs.Modules.NetworkManager.Synchronous
	}

	self.name = name
	return self
	end

	-- Server → Client (Async, Reliable)
	function EventHandler:FireClient(client, funcName, ...)
	if not RunService:IsServer() then
		warn("FireClient can only be called from server")
		return
	end
	self.remotes.async:FireClient(client, self.name, funcName, ...)
	end

	-- Server → Client (Async, Unreliable)
	function EventHandler:FireClientUnreliable(client, funcName, ...)
	if not RunService:IsServer() then
		warn("FireClientUnreliable can only be called from server")
		return
	end
	self.remotes.unreliable:FireClient(client, self.name, funcName, ...)
	end

	-- Server → All Clients (Async, Reliable)
	function EventHandler:FireAllClients(funcName, ...)
	if not RunService:IsServer() then
		warn("FireAllClients can only be called from server")
		return
	end
	self.remotes.async:FireAllClients(self.name, funcName, ...)
	end

	-- Server → All Clients (Async, Unreliable)
	function EventHandler:FireAllClientsUnreliable(funcName, ...)
	if not RunService:IsServer() then
		warn("FireAllClientsUnreliable can only be called from server")
		return
	end
	self.remotes.unreliable:FireAllClients(self.name, funcName, ...)
	end

	-- Server → Client (Sync)
	function EventHandler:InvokeClient(client, funcName, ...)
	if not RunService:IsServer() then
		warn("InvokeClient can only be called from server")
		return nil
	end
	return self.remotes.sync:InvokeClient(client, self.name, funcName, ...)
	end

	-- Client → Server (Async)
	function EventHandler:FireServer(funcName, ...)
	if not RunService:IsClient() then
		warn("FireServer can only be called from client")
		return
	end
	self.remotes.async:FireServer(self.name, funcName, ...)
	end

	-- Client → Server (Sync)
	function EventHandler:InvokeServer(funcName, ...)
	if not RunService:IsClient() then
		warn("InvokeServer can only be called from client")
		return nil
	end
	return self.remotes.sync:InvokeServer(self.name, funcName, ...)
	end

	return EventHandler