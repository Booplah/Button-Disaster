local SettingsManager = {}
local settingCallbacks = {}

function SettingsManager.SetCallback(settingName, onCallback, offCallback)
	settingCallbacks[settingName] = {
		on = onCallback,
		off = offCallback
	}
end

function SettingsManager.UpdateSetting(settingName, state)
	local callback = settingCallbacks[settingName]
	if callback then
		if state and callback.on then
			callback.on()
		elseif not state and callback.off then
			callback.off()
		end
	end
end

return SettingsManager