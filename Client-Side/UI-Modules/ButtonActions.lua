local ButtonActions = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
-- Client --
local TweenService = game:GetService("TweenService")

-- [Modules]
local SharedState = require(ReplicatedStorage.Modules.UI.SharedState)
local ItemsData = require(ReplicatedStorage.Modules.DataTables.ItemsData)
local GamepassData = require(ReplicatedStorage.Modules.DataTables.GamepassData)
local EventHandler = SharedState.EventHandler
local GUIanim = SharedState.GUIanim
local TextGradients = SharedState.textGradients

-- [ UI Related ]
local buyFrame = SharedState.BuyFrame
-- [ Private Variables ]
local currentItem = nil
-- EQUIPPED IMAGE
local EQUIPPED_IMAGE = "rbxassetid://104984361325727"
local NORMAL_IMAGE = "rbxassetid://77689879347020"
local equippedItems = { Item = "", Pet = "", Trail = "" }
local equippedButtons = {}


local function getItemDataById(itemId)
	for _, category in pairs(ItemsData) do
		if type(category) == "table" then
			for _, item in ipairs(category) do
				if item.Id == itemId then
					return item end end end end
	return nil
end

-- [ Shop ]
function ButtonActions.ShopPurchaseHandler(button, itemId, itemType, price)
	local Main = buyFrame.Main
	local BuySlots = Main.BuySlots
	local ItemLabel = Main.ItemLabel
	local cashLabel = BuySlots.Cash.ImageButton.Frame.TextLabel
	local robuxLabel = BuySlots.Robux.ImageButton.Frame.TextLabel
	local imageLabel = Main.ImageLabel
	local DescriptionLabel = Main.DescriptionLabel
	local RarityLabel = Main.RarityLabel
	local exitBtn = Main.Exit
	local item = getItemDataById(itemId)

	GUIanim.ToggleHoverSize(button, 1.05, 0.9, 0.2, 0.3)
	button.MouseButton1Click:Connect(function()
		if not item then return end
		buyFrame.Visible = true
		SharedState.GUIanim.AppearanceWipe(Main, .2, 40)
		currentItem = { id = itemId, type = itemType, price = price, robuxPrice = item.RobuxPrice or 0}
		ItemLabel.Text = item.Name
		cashLabel.Text = item.Price
		robuxLabel.Text = `{utf8.char(0xE002)}{item.RobuxPrice}`
		imageLabel.Image = `rbxassetid://{item.Image}`
		DescriptionLabel.Text = item.Description
		RarityLabel.Text = item.Rarity
		SharedState.textGradients.ApplyRarityGradient(RarityLabel, item.Rarity)
		SharedState.textGradients.ApplyRarityGradient(Main.UIStroke, item.Rarity)
		GUIanim.ToggleHoverSize(BuySlots.Cash.ImageButton, 1.05, 0.9, 0.2, 0.3)
		
		-- [ Cash Buy Handler ]
		BuySlots.Cash.ImageButton.MouseButton1Click:Connect(function()
			if currentItem then
				SharedState.WipeCloseUI(Main)
				buyFrame.Visible = false
				EventHandler:FireServer("PurchaseItem", currentItem.id, currentItem.type, currentItem.price)
				currentItem = nil
			end
		end)
		GUIanim.ToggleHoverSize(BuySlots.Robux.ImageButton, 1.05, 0.9, 0.2, 0.3)
		-- [ Robux Buy Handler ]
		BuySlots.Robux.ImageButton.MouseButton1Click:Connect(function()
			if currentItem then
				warn(`Attemping to buy {currentItem.robuxPrice}`)
				buyFrame.Visible = false
				currentItem = nil
			end
		end)
		

		GUIanim.ToggleHoverSize(exitBtn, 1.05, 0.9, 0.2, 0.3)
		exitBtn.MouseButton1Click:Connect(function()
			SharedState.WipeCloseUI(Main)
			buyFrame.Visible = false
		end)
	end)
end

-- [ Inventory ]
function ButtonActions.InventoryUpdateEquip(equippedData)
	equippedItems = equippedData or {
		Item = "",
		Pet = "",
		Trail = ""
	}

	-- Reset all equipped buttons to normal image
	for _, button in pairs(equippedButtons) do
		if button and button.Parent then
			button.Image = NORMAL_IMAGE
		end
	end

	-- Clear the table
	ButtonActions.equippedButtons = {}
end
function ButtonActions.SetupEquipInventory(button, itemData, itemType)
	GUIanim.ToggleHoverSize(button, 1.05, 0.9, 0.2, 0.3)

	-- Set initial state
	if equippedItems[itemType] == itemData.Id then
		button.Image = EQUIPPED_IMAGE
		equippedButtons[itemType] = button
	else
		button.Image = NORMAL_IMAGE
	end

	button.MouseButton1Click:Connect(function()
		local currentEquipped = equippedItems[itemType]
		local currentButton = equippedButtons[itemType]

		if currentEquipped == itemData.Id then
			-- Unequip if clicking the same item
			EventHandler:InvokeServer("UnequipItem", itemType)
			print("Unequipping Item")
			button.Image = NORMAL_IMAGE
			equippedItems[itemType] = ""
			equippedButtons[itemType] = nil
		else
			-- Equip new item
			EventHandler:InvokeServer("EquipItem", itemType, itemData)
			print("Equipping new item")
			-- Unequip previous item of same type
			if currentButton then
				currentButton.Image = NORMAL_IMAGE
			end

			-- Set new equipped item
			button.Image = EQUIPPED_IMAGE
			equippedItems[itemType] = itemData.Id
			equippedButtons[itemType] = button
		end

		SharedState.ClickUI:Play()
	end)
end

-- [ Settings ]


return ButtonActions
