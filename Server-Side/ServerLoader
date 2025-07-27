--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local ModuleLoader = require(ReplicatedStorage.Modules.Utility.ModuleLoader)

ModuleLoader.ChangeSettings({
	FOLDER_SEARCH_DEPTH = 1,
	YIELD_THRESHOLD = 0,
	VERBOSE_LOADING = false,
	WAIT_FOR_SERVER = true
})

ModuleLoader.Start(ServerStorage.Modules.Managers) -- pass any other containers for your custom services to the Start() function
