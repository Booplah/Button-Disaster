--!strict
--[[	
	-- FEATURES --
	Supports module priority by setting an attribute "LoaderPriority" on the ModuleScript with a number value. Larger number == higher priority.
	
	DEFAULT FILTERING BEHAVIOR:
	Run-context specific loading. If, for the purpose of organization, modules need to be located in the same folder but have certain ones
	required by client/server contexts, you can set boolean attributes like "ClientOnly" or "ServerOnly" to have the client/server ignore modules.
	
	You can also set a boolean attribute "IgnoreLoader" on a ModuleScript have the module loader ignore it.
	
	Modules that are not a direct child of a container or whose ancestry are not folders that lead back to a container will not be loaded.
	
	If you do not like this default filtering behavior, you can pass your own filtering predicate to the StartCustom() function and define your own
	behavior. Otherwise, use the Start() function for the default behavior.
	--------------
]]

-----------------------------
-- SERVICES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-----------------------------
-- VARIABLES --
-----------------------------
local actorForServer = script.ActorForServer
local actorForClient = script.ActorForClient
local isClient = RunService:IsClient()
local require = require
local loadedEvent: RemoteEvent
if isClient then
	loadedEvent = script:WaitForChild("LoadedEvent")
else
	loadedEvent = Instance.new("RemoteEvent")
	loadedEvent.Name = "LoadedEvent"
	loadedEvent.Parent = script
end

local tracker = {
	Load = {} :: { [ModuleScript]: any },
	Init = {} :: { [ModuleScript]: boolean },
	Start = {} :: { [ModuleScript]: boolean }
}

local trackerForActors = {
	Load = {} :: { [ModuleScript]: Actor },
	Init = {},
	Start = {}
}

export type LoaderSettings = {
	YIELD_THRESHOLD: number, -- how long the loader will wait for :Init() or :Start() to yield before warning and cancelling it
	VERBOSE_LOADING: boolean,
	WAIT_FOR_SERVER: boolean,
}

export type KeepModulePredicate = (container: Instance, module: ModuleScript) -> (boolean)

-- CONSTANTS --
local SETTINGS: LoaderSettings = {
	FOLDER_SEARCH_DEPTH = 1,
	YIELD_THRESHOLD = 10,
	VERBOSE_LOADING = false,
	WAIT_FOR_SERVER = true,
}

local PRINT_IDENTIFIER = if isClient then "[C]" else "[S]"
local LOADED_IDENTIFIER = if isClient then "Client" else "Server"
local ACTOR_PARENT = if isClient then game:GetService("Players").LocalPlayer.PlayerScripts else game:GetService("ServerScriptService")

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-- <strong><code>!YIELDS!</code></strong>
local function waitForEither<Func, T...>(eventYes: RBXScriptSignal, eventNo: RBXScriptSignal): boolean
	local thread = coroutine.running()

	local connection1: any = nil
	local connection2: any = nil

	connection1 = eventYes:Once(function(...)
		if connection1 == nil then
			return
		end

		connection1:Disconnect()
		connection2:Disconnect()
		connection1 = nil
		connection2 = nil

		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, true, ...)
		end
	end)

	connection2 = eventNo:Once(function(...)
		if connection2 == nil then
			return
		end

		connection1:Disconnect()
		connection2:Disconnect()
		connection1 = nil
		connection2 = nil

		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, false, ...)
		end
	end)

	return coroutine.yield()
end

-- Returns a new array that is the result of array1 and array2
local function mergeArrays(array1: {[number]: any}, array2: {[number]: any})
	local length = #array2
	local newArray = table.clone(array2)
	for i, v in ipairs(array1) do
		newArray[length + i] = v
	end
	return newArray
end

local function filter<T>(t: { T }, predicate: (T, any, { T }) -> boolean): { T }
	assert(type(t) == "table", "First argument must be a table")
	assert(type(predicate) == "function", "Second argument must be a function")
	local newT = table.create(#t)
	if #t > 0 then
		local n = 0
		for i, v in t do
			if predicate(v, i, t) then
				n += 1
				newT[n] = v
			end
		end
	else
		for k, v in t do
			if predicate(v, k, t) then
				newT[k] = v
			end
		end
	end
	return newT
end

-- Returns the 'depth' of <code>descendant</code> in the child hierarchy of <code>root</code>.
-- If the descendant is not found in <code>root</code>, then this function will return 0.
local function getDepthInHierarchy(descendant: Instance, root: Instance): number
	local depth = 0
	local current: Instance? = descendant
	while current and current ~= root do
		current = current.Parent
		depth += 1
	end
	if not current then
		depth = 0
	end
	return depth
end

local function findAllFromClass(class: string, searchIn: Instance, searchDepth: number?): { any }
	assert(class and typeof(class) == "string", "class is invalid or nil")
	assert(searchIn and typeof(searchIn) == "Instance", "searchIn is invalid or nil")

	local foundObjects = {}

	if searchDepth then
		for _, object in pairs(searchIn:GetDescendants()) do
			if object:IsA(class) and getDepthInHierarchy(object, searchIn) <= searchDepth then
				table.insert(foundObjects, object)
			end
		end
	else
		for _, object in pairs(searchIn:GetDescendants()) do
			if object:IsA(class) then
				table.insert(foundObjects, object)
			end
		end
	end

	return foundObjects
end

local function keepModule(container: Instance, module: ModuleScript): boolean
	if module:GetAttribute("ClientOnly") and RunService:IsServer() then
		return false
	elseif module:GetAttribute("ServerOnly") and RunService:IsClient() then
		return false
	elseif module:GetAttribute("IgnoreLoader") then
		return false
	end
	local ancestor = module.Parent
	while ancestor do
		if ancestor == container then
			-- The ancestry should eventually lead to the container (if ancestors were always folders)
			return true
		elseif not ancestor:IsA("Folder") then
			return false
		end
		ancestor = ancestor.Parent
	end
	return false
end

local function newPrint(...)
	print(PRINT_IDENTIFIER, ...)
end

local function newWarn(...)
	warn(PRINT_IDENTIFIER, ...)
end

local function loadModule(module: ModuleScript)
	if module:GetAttribute("Parallel") then
		-- This module needs to be run in parallel, so create new actor and script.
		local newActorSystem = if isClient then actorForClient:Clone() else actorForServer:Clone()
		local actorScript = newActorSystem:FindFirstChildWhichIsA("BaseScript")

		actorScript.Name = `Required{module.Name}`
		newActorSystem.Parent = ACTOR_PARENT

		if not actorScript:GetAttribute("Loaded") then
			actorScript:GetAttributeChangedSignal("Loaded"):Wait()
		end

		newActorSystem:SendMessage("RequireModule", module)

		if SETTINGS.VERBOSE_LOADING then
			newPrint(("Loading PARALLEL module '%s'"):format(module.Name))
		end

		local startTime = tick()
		if not actorScript:GetAttribute("Required") then
			actorScript:GetAttributeChangedSignal("Required"):Wait()
		end
		local endTime = tick()

		if SETTINGS.VERBOSE_LOADING and not actorScript:GetAttribute("Errored") then
			newPrint(`Loaded PARALLEL module {module.Name}`, ("(%.3f seconds)"):format(endTime - startTime))
		elseif actorScript:GetAttribute("Errored") then
			newWarn(`\nFailed to load PARALLEL module {module.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
		end

		trackerForActors.Load[module] = newActorSystem
		tracker.Load[module] = true
		tracker.Init[module] = true
		tracker.Start[module] = true
		return
	end

	--if SETTINGS.VERBOSE_LOADING then
	--	newPrint(("Loading module '%s'"):format(module.Name))
	--end
	
	local startTime = tick()
	local success, result = pcall(function()
		local loadedModule = require(module)
		tracker.Load[module] = loadedModule

		if loadedModule.Init then
			tracker.Init[module] = false
		end
		if loadedModule.Start then
			tracker.Start[module] = false
		end
	end)
	local endTime = tick()

	if SETTINGS.VERBOSE_LOADING and success then
		newPrint(`Loaded - {module.Name}`, ("(%.3f seconds)"):format(endTime - startTime))
	elseif not success then
		newWarn(`\nFailed Load: {module.Name}`, ("(%.3f seconds)\n%s"):format(endTime - startTime, result))
	end
end

local function initializeModule(loadedModule, module: ModuleScript)
	if trackerForActors.Load[module] then
		local actorScript: BaseScript = trackerForActors.Load[module]:FindFirstChildWhichIsA("BaseScript") :: any
		trackerForActors.Load[module]:SendMessage("InitModule")

		if SETTINGS.VERBOSE_LOADING then
			newPrint(("Initializing PARALLEL module '%s'"):format(actorScript.Name))
		end

		local startTime = tick()
		if not actorScript:GetAttribute("Initialized") then
			actorScript:GetAttributeChangedSignal("Initialized"):Wait()
		end
		local endTime = tick()

		if SETTINGS.VERBOSE_LOADING and not actorScript:GetAttribute("Errored") then
			newPrint(`Initialized PARALLEL module {actorScript.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
		elseif actorScript:GetAttribute("Errored") then
			newWarn(`\nFailed to init PARALLEL module {actorScript.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
		end
		return
	end

	if not loadedModule.Init then
		return
	end

	--if SETTINGS.VERBOSE_LOADING then
	--	newPrint(("Initializing module '%s'"):format(module.Name))
	--end
	local thread = coroutine.running()
	local startTime = tick()
	local endTime
	local success, result: any = pcall(function()
		return task.spawn(function()
			loadedModule:Init()
			tracker.Init[module] = true
			endTime = tick()
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread)
			end
		end)
	end)
	if not endTime then
		endTime = tick()
	end
	if success and coroutine.status(result) == "suspended" then
		local delayedThread = task.delay(SETTINGS.YIELD_THRESHOLD, function()
			if coroutine.status(result) == "suspended" then
				task.cancel(result)
				endTime = tick()
			end
			if SETTINGS.VERBOSE_LOADING then
				newWarn(`\nFailed to init module {module.Name}`, ("(took %.3f seconds)\n%s"):format(endTime - startTime, ":Init() yielded for too long!"))
			end
			task.spawn(thread)
		end)
		coroutine.yield()
		if coroutine.status(delayedThread) == "suspended" then
			task.cancel(delayedThread)
		end
	end

	if SETTINGS.VERBOSE_LOADING and success then
		newPrint(`Initialized - {module.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
	elseif not success then
		newWarn(`\nFailed Initialize: {module.Name}`, ("(took %.3f seconds)\n%s"):format(endTime - startTime, result))
	end
end

local function startModule(loadedModule, module: ModuleScript)
	if trackerForActors.Load[module] then
		local actorScript: BaseScript = trackerForActors.Load[module]:FindFirstChildWhichIsA("BaseScript") :: any
		trackerForActors.Load[module]:SendMessage("StartModule")

		--if SETTINGS.VERBOSE_LOADING then
		--	newPrint(("Starting PARALLEL module '%s'"):format(actorScript.Name))
		--end

		local startTime = tick()
		if not actorScript:GetAttribute("Started") then
			actorScript:GetAttributeChangedSignal("Started"):Wait()
		end
		local endTime = tick()

		if SETTINGS.VERBOSE_LOADING and not actorScript:GetAttribute("Errored") then
			newPrint(`Started PARALLEL module {actorScript.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
		elseif actorScript:GetAttribute("Errored") then
			newWarn(`\nFailed to start PARALLEL module {actorScript.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
		end
		return
	end

	if not loadedModule.Start then
		return
	end

	--if SETTINGS.VERBOSE_LOADING then
	--	newPrint(("Starting module '%s'"):format(module.Name))
	--end

	local thread = coroutine.running()
	local startTime = tick()
	local endTime
	local success, result: any = pcall(function()
		return task.spawn(function()
			loadedModule:Start()
			tracker.Start[module] = true
			endTime = tick()
			if coroutine.status(thread) == "suspended" then
				task.spawn(thread)
			end
		end)
	end)
	if not endTime then
		endTime = tick()
	end
	if success and coroutine.status(result) == "suspended" then
		local delayedThread = task.delay(SETTINGS.YIELD_THRESHOLD, function()
			if coroutine.status(result) == "suspended" then
				task.cancel(result)
				endTime = tick()
			end
			if SETTINGS.VERBOSE_LOADING then
				newWarn(`\nFailed to start module {module.Name}`, ("(took %.3f seconds)\n%s"):format(endTime - startTime, ":Start() yielded for too long!"))
			end
			task.spawn(thread)
		end)
		coroutine.yield()
		if coroutine.status(delayedThread) == "suspended" then
			task.cancel(delayedThread)
		end
	end

	if SETTINGS.VERBOSE_LOADING and success then
		newPrint(`Started - {module.Name}`, ("(took %.3f seconds)"):format(endTime - startTime))
	elseif not success then
		newWarn(`\nFailed to start module {module.Name}`, ("(took %.3f seconds)\n%s"):format(endTime - startTime, result))
	end
end

-- Gets all modules to be loaded in order.
local function getModules(containers: { Instance }): { ModuleScript }
	local totalModules = {}
	for _, container in ipairs(containers) do
		local modules = findAllFromClass("ModuleScript", container)
		modules = filter(modules, function(module)
			return keepModule(container, module)
		end)
		totalModules = mergeArrays(totalModules, modules)
	end
	table.sort(totalModules, function(a, b)
		local aPriority = a:GetAttribute("LoaderPriority")
		local bPriority = b:GetAttribute("LoaderPriority")

		if aPriority and bPriority then
			return aPriority > bPriority
		elseif aPriority and not bPriority then
			return true
		elseif bPriority and not aPriority then
			return false
		else
			return false
		end
	end)
	return totalModules
end

-----------------------------
-- MAIN --
-----------------------------

-- Start the loader with the default module filtering behavior.
local function start(...: Instance)
	local containers = {...}
	if isClient and SETTINGS.WAIT_FOR_SERVER and not workspace:GetAttribute("ServerLoaded") then
		workspace:GetAttributeChangedSignal("ServerLoaded"):Wait()
	end

	if SETTINGS.VERBOSE_LOADING then
		newWarn("=== LOADING MODULES ===")
		local modules = getModules(containers)
		for _, module in modules do
			loadModule(module)
		end

		newWarn("=== INITIALIZING MODULES ===")
		for _, module in modules do
			if not tracker.Load[module] then
				continue
			end
			initializeModule(tracker.Load[module], module)
		end

		newWarn("=== STARTING MODULES ===")
		for _, module in modules do
			if not tracker.Load[module] then
				continue
			end
			startModule(tracker.Load[module], module)
		end

		newWarn("=== LOADING FINISHED ===")
	else
		local modules = getModules(containers)
		for _, module in modules do
			loadModule(module)
		end
		for _, module in modules do
			if not tracker.Load[module] then
				continue
			end
			if tracker.Load[module] then
				initializeModule(tracker.Load[module], module)
			end
		end
		for _, module in modules do
			if not tracker.Load[module] then
				continue
			end
			if tracker.Load[module] then
				startModule(tracker.Load[module], module)
			end
		end
	end

	workspace:SetAttribute(`{LOADED_IDENTIFIER}Loaded`, true)
	if RunService:IsClient() then
		loadedEvent:FireServer()
	end
end

-- Start the loader with your own custom module filtering behavior for determining what modules should be loaded.
local function startCustom(_keepModule: KeepModulePredicate, ...: Instance)
	keepModule = _keepModule
	start(...)
end

local function isClientLoaded(player: Player): boolean
	return player:GetAttribute("_ModulesLoaded") == true
end

-- <strong><code>!YIELDS!</code></strong>
-- Yields until the client has loaded all their modules.
-- Returns true if loaded or returns false if player left.
local function waitForLoadedClient(player: Player): boolean
	if not player:GetAttribute("_ModulesLoaded") then
		return waitForEither(player:GetAttributeChangedSignal("_ModulesLoaded"), player:GetPropertyChangedSignal("Parent"))
	end
	return true
end

local function changeSettings(settings: LoaderSettings)
	SETTINGS = settings
end

if not isClient then
	loadedEvent.OnServerEvent:Connect(function(player)
		player:SetAttribute("_ModulesLoaded", true)
	end)
end

return {
	Start = start,
	StartCustom = startCustom,
	ChangeSettings = changeSettings,
	IsClientLoaded = isClientLoaded,
	WaitForLoadedClient = waitForLoadedClient
}