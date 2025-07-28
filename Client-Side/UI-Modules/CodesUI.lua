-- CodesModule.lua
local CodesModule = {}
local SharedState = require(script.Parent.SharedState)

function CodesModule:Init()
	self.Redeemtext = SharedState.CodesFrame.Main:WaitForChild("TextBox")
	self.RedeemButton = SharedState.CodesFrame.Main:WaitForChild("ImageButton")
end

function CodesModule:Start()
	SharedState.GUIanim.ToggleHoverSize(self.RedeemButton, 1.05, 0.9, 0.2, 0.3)

	self.RedeemButton.MouseButton1Click:Connect(function()
		print(`Attempted to Redeem: {self.Redeemtext.Text}`)
	end)
end

return CodesModule