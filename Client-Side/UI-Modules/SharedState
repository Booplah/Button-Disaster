-- [IMPORTANT]

-- SharedState.lua
local SharedState = {}

-- [ Services ]
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")

-- [ Modules ]
SharedState.GUIanim = require(ReplicatedStorage.Modules.Utility.GUIanim)
SharedState.textGradients = require(ReplicatedStorage.Modules.Utility.TextGradients)
SharedState.EventHandler = require(ReplicatedStorage.Modules.NetworkManager.EventHandler).new("Client")
-- [ Variables ]
SharedState.ClickUI = SoundService.SFX.ClickUI
local player = Players.LocalPlayer
-- [ Constants ]
SharedState.EQUIPPED_IMAGE = "rbxassetid://104984361325727"
SharedState.NORMAL_IMAGE = "rbxassetid://77689879347020"

-- [ Type Check ] - IMPORTANT
local StarterGUI = player:WaitForChild("PlayerGui")
--local StarterGUI = StarterGui

-- [ UI References ]
SharedState.GameUI = StarterGUI:WaitForChild("GameUI")
SharedState.LobbyUI = StarterGUI:WaitForChild("LobbyUI")
SharedState.BuyFrame = SharedState.GameUI:WaitForChild("BuyFrame")
SharedState.shopFrame = SharedState.GameUI:WaitForChild("Shop")
SharedState.InventoryFrame = SharedState.GameUI:WaitForChild("Inventory")
SharedState.QuestFrame = SharedState.GameUI:WaitForChild("Quest Rewards")
SharedState.DailyFrame = SharedState.GameUI:WaitForChild("Daily Rewards")
SharedState.SettingsFrame = SharedState.GameUI:WaitForChild("Settings")
SharedState.CodesFrame = SharedState.GameUI:WaitForChild("Codes")

-- [ Blur Effect ]
SharedState.Blur = Lighting:WaitForChild("Blur")
SharedState.Blur.Enabled = false
SharedState.Blur.Size = 15

-- [ Shared Functions ]
function SharedState.DebounceCall(delayTime, callback)
	if not SharedState.debounceCanClick then return end
	SharedState.debounceCanClick = false
	callback()
	task.delay(delayTime, function()
		SharedState.debounceCanClick = true
	end)
end

function SharedState.WipeCloseUI(selectedFrame)
	SharedState.ClickUI:Play()
	SharedState.GUIanim.AppearanceWipeReverse(selectedFrame, .05, 30)
	SharedState.Blur.Enabled = false
	
end

function SharedState.WipeOpenUI(selectedFrame)
	SharedState.ClickUI:Play()
	if selectedFrame.Visible then
		SharedState.WipeCloseUI(selectedFrame)
	else
		SharedState.GUIanim.AppearanceWipe(selectedFrame, .2, 40)
		SharedState.Blur.Enabled = true
	end
end

return SharedState