-- LobbyUIModule.lua
local LobbyUIModule = {}
local SharedState = require(script.Parent.SharedState)
function LobbyUIModule:Init()
	self.uiConfig = {
		Shop = {
			button = SharedState.LobbyUI.Category:WaitForChild("ShopButton"),
			frame = SharedState.shopFrame,
			openFunc = SharedState.WipeOpenUI,
			closeFunc = SharedState.WipeCloseUI,
			exitButton = SharedState.shopFrame.Main:WaitForChild("Exit"),
			sound = false
		},
		Lobby = {
			button = SharedState.LobbyUI.Category:WaitForChild("InventoryButton"),
			frame = SharedState.InventoryFrame,
			openFunc = SharedState.WipeOpenUI,
			closeFunc = SharedState.WipeCloseUI,
			exitButton = SharedState.InventoryFrame.Main:WaitForChild("Exit"),
			sound = false
		},
		Quest = {
			button = SharedState.LobbyUI.Category:WaitForChild("QuestButton"),
			frame = SharedState.QuestFrame,
			openFunc = SharedState.WipeOpenUI,
			closeFunc = SharedState.WipeCloseUI,
			exitButton = SharedState.QuestFrame.Main:WaitForChild("Exit"),
			sound = true
		},
		Daily = {
			button = SharedState.LobbyUI.TopCategory:WaitForChild("DailyRewards"),
			frame = SharedState.DailyFrame,
			openFunc = SharedState.WipeOpenUI,
			closeFunc = SharedState.WipeCloseUI,
			exitButton = SharedState.DailyFrame.Main:WaitForChild("Exit"),
			sound = true
		},
		Settings = {
			button = SharedState.LobbyUI.Category.Frame:WaitForChild("SettingsButton"),
			frame = SharedState.SettingsFrame,
			openFunc = SharedState.WipeOpenUI,
			closeFunc = SharedState.WipeCloseUI,
			exitButton = SharedState.SettingsFrame.Main:WaitForChild("Exit"),
			sound = true
		},
		Codes = {
			button = SharedState.LobbyUI.TopCategory:WaitForChild("Codes"),
			frame = SharedState.CodesFrame,
			openFunc = SharedState.WipeOpenUI,
			closeFunc = SharedState.WipeCloseUI,
			exitButton = SharedState.CodesFrame.Main:WaitForChild("Exit"),
			sound = true
		},
		
		--

	}
	-- Close Frames First
	for i,v in pairs(self.uiConfig) do
		v.frame.Visible = false
	end
	
end

function LobbyUIModule:Start()
	local function closeAllFramesExcept(categoryName)
		for name, data in pairs(self.uiConfig) do
			if data.frame and name ~= categoryName and data.frame.Visible then
				SharedState.WipeCloseUI(data.frame)
			end
		end
	end

	for name, config in pairs(self.uiConfig) do
		SharedState.GUIanim.ToggleHoverSize(config.button, 1.05, 0.9, 0.2, 0.3)
		config.button.MouseButton1Click:Connect(function()
			closeAllFramesExcept(name)
			config.openFunc(config.frame)
		end)

		if config.exitButton then
			SharedState.GUIanim.ToggleHoverSize(config.exitButton, 1.05, 0.9, 0.2, 0.3)
			config.exitButton.MouseButton1Click:Connect(function()
				config.closeFunc(config.frame)
			end)
		end
	end
	
	
	
	
	
end

return LobbyUIModule