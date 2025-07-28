local SettingsUI = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")
local TweenService = game:GetService("TweenService")

local SharedState = require(ReplicatedStorage.Modules.UI.SharedState)
local ButtonActions = require(game.ReplicatedStorage.Modules.UI.SharedState.ButtonActions)
local EventHandler = SharedState.EventHandler
local TextGradients = SharedState.textGradients
local SettingsManager = require(ReplicatedStorage.Modules.UI.SettingsUI.SettingsManager)

function SettingsUI:Init()
	self.settingFrame = SharedState.SettingsFrame.Main:WaitForChild("ScrollingFrame")
	-- [Template]
	self.Stats = self.settingFrame:WaitForChild("StatFrame")
	self.ButtonTemplate = self.settingFrame:WaitForChild("ButtonTemplate")
	self.SwitchTemplate = self.settingFrame:WaitForChild("SwitchTemplate")
	
	self.settings = {}
	self.switchInstances = {}
	
	self.settings = EventHandler:InvokeServer("RequestSettings")

end

function SettingsUI:SetSettings(Settings)
	self.settings = Settings or {self.settings}

	-- Update all switch visuals
	for settingName, switchData in pairs(self.switchInstances) do
		local state = self.settings[settingName]
		local button = switchData.button

		if state then
			TweenService:Create(button.Frame, TweenInfo.new(0.2), {
				Position = switchData.originalPosition,
				BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			}):Play()
			button.Frame.TextLabel.Text = "ON"
		else
			TweenService:Create(button.Frame, TweenInfo.new(0.2), {
				Position = switchData.offPosition,
				BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			}):Play()
			button.Frame.TextLabel.Text = "OFF"
		end
	end
end

function SettingsUI:ButtonTemplate_CREATE(labelText: string, onclick: (() -> ())?)
	local clone = self.ButtonTemplate:Clone()
	clone.Visible = true
	clone.Parent = self.settingFrame
	
	local button = clone:WaitForChild("TextButton")
	local textLabel = clone:WaitForChild("TextLabel")
	
	if textLabel then
		textLabel.Text = labelText
	end

	if onclick then
		button.MouseButton1Click:Connect(onclick)
	else
		button.MouseButton1Click:Connect(function()

		end)
	end
end

function SettingsUI:SwitchTemplate_CREATE(settingName, labelText, onCallback, offCallback)
	local clone = self.SwitchTemplate:Clone()
	clone.Visible = true
	clone.Parent = self.settingFrame

	local button = clone:WaitForChild("TextButton")
	local textLabel = clone:FindFirstChild("TextLabel")
	local state = self.settings[settingName]

	if textLabel then
		textLabel.Text = labelText
	end

	local originalPosition = button.Frame.Position
	local offPosition = UDim2.new(
		originalPosition.X.Scale + 0.5,
		originalPosition.X.Offset,
		originalPosition.Y.Scale,
		originalPosition.Y.Offset
	)

	-- Store switch data for later updates
	self.switchInstances[settingName] = {
		button = button,
		originalPosition = originalPosition,
		offPosition = offPosition,
		onCallback = onCallback,
		offCallback = offCallback
	}

	local function updateVisual()
		if state then
			TweenService:Create(button.Frame, TweenInfo.new(0.2), {
				Position = originalPosition,
				BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			}):Play()
			button.Frame.TextLabel.Text = "ON"
			if onCallback then onCallback() end
		else
			TweenService:Create(button.Frame, TweenInfo.new(0.2), {
				Position = offPosition,
				BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			}):Play()
			button.Frame.TextLabel.Text = "OFF"
			if offCallback then offCallback() end
		end
	end

	-- Set initial state
	updateVisual()

	button.MouseButton1Click:Connect(function()
		state = not state
		self.settings[settingName] = state
		updateVisual()

		-- Save to server
		EventHandler:FireServer("UpdateSetting", settingName, state)
		SharedState.ClickUI:Play()
	end)
end

function SettingsUI:StatsTemplate_CREATE(labelText: string, valueNumber: number)
	local clone = self.Stats.Template:Clone()
	clone.Visible = true
	clone.Parent = self.Stats

	local textLabel = clone:WaitForChild("TextLabel")
	local textValue = clone:WaitForChild("TextNum")

	if textLabel then
		textLabel.Text = labelText
	end

	if textValue then
		textValue.Text = tostring(valueNumber)
	end
end

function SettingsUI:Start()
	warn("SettingsUI Initialized")

	local SettingsTable = {}
	self:SwitchTemplate_CREATE("MusicEnabled", "Enable Music", 
		function() -- On
			--print("Enabled: MusicEnabled")
		end,
		function() -- Off
			--print("Disabled: MusicEnabled")
		end
	)

	self:SwitchTemplate_CREATE("DeathSFXMuted", "Mute Death SFX", 
		function() -- On
			--print("Enabled: DeathSFXMuted")
		end,
		function() -- Off
			--print("Disabled: DeathSFXMuted")
		end
	)

	self:SwitchTemplate_CREATE("LowGraphics", "Low Graphics", 
		function() -- On
			--print("Enabled: LowGraphics")
		end,
		function() -- Off
			--print("Disabled: LowGraphics")
		end
	)

	self:SwitchTemplate_CREATE("HideGUI", "Hide GUI", 
		function() -- On
			--print("Enabled: HideGUI")
		end,
		function() -- Off
			--print("Disabled: HideGUI")
		end
	)
	
	ButtonActions.SetupColorVFX()
	self:ButtonTemplate_CREATE("Change VFX Color", function()
		SharedState.SettingsFrame:WaitForChild("ColorPicker").Visible = true
	end)
	
	self:ButtonTemplate_CREATE("Some other shit", function()
		print("yeah just some other shit")
	end)

	self:StatsTemplate_CREATE("Games Played", 100)
	
	
end

return SettingsUI