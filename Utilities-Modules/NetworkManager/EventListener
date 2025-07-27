	local EventListener = {}
	EventListener.__index = EventListener

	local RunService = game:GetService("RunService")
	local rs = game:GetService("ReplicatedStorage")

	-- Constructor
	function EventListener.new(handlers, trace)
	local self = setmetatable({}, EventListener)
	--print("EventListener created  nby: " .. trace)

	local remotes = {
		async = rs.Modules.NetworkManager.Asynchronous,
		unreliable = rs.Modules.NetworkManager.Unreliable,
		sync = rs.Modules.NetworkManager.Synchronous
	}

	if RunService:IsClient() then
		-- Client-side listeners
		remotes.async.OnClientEvent:Connect(function(handlerName, funcName, ...)
			local handler = handlers[funcName]
			if handler then
				local success, err = pcall(handler, ...)
				if not success then
					warn("Client async error ["..funcName.."]: " .. err)
				end
			else
				warn("No async handler for: " .. tostring(funcName))
			end
		end)

		remotes.unreliable.OnClientEvent:Connect(function(handlerName, funcName, ...)
			local handler = handlers[funcName]
			if handler then
				local success, err = pcall(handler, ...)
				if not success then
					warn("Client unreliable error ["..funcName.."]: " .. err)
				end
			end
		end)

		remotes.sync.OnClientInvoke = function(handlerName, funcName, ...)
			local handler = handlers[funcName]
			if handler then
				return handler(...)
			end
			return nil
		end
	else
		-- Server-side listeners
		remotes.async.OnServerEvent:Connect(function(player, handlerName, funcName, ...)
			local handler = handlers[funcName]
			if handler then
				local success, err = pcall(handler, player, ...)
				if not success then
					warn("Server async error ["..funcName.."] from "..player.Name..": " .. err)
				end
			else
				warn("No async handler for: " .. tostring(funcName))
			end
		end)

		remotes.unreliable.OnServerEvent:Connect(function(player, handlerName, funcName, ...)
			local handler = handlers[funcName]
			if handler then
				local success, err = pcall(handler, player, ...)
				if not success then
					warn("Server unreliable error ["..funcName.."] from "..player.Name..": " .. err)
				end
			end
		end)

		remotes.sync.OnServerInvoke = function(player, handlerName, funcName, ...)
			local handler = handlers[funcName]
			if handler then
				return handler(player, ...)
			end
			return nil
		end
	end

	return self
	end

	return EventListener