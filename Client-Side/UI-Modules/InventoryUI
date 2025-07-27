local InventoryModule = {}
-- [Services]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- [Modules]
local SharedState = require(script.Parent.SharedState)
local EventHandler = require(ReplicatedStorage.Modules.NetworkManager.EventHandler).new("Client")
local ItemsData = require(game.ReplicatedStorage.Modules.DataTables.ItemsData)
local GUIanim = require(ReplicatedStorage.Modules.Utility.GUIanim)
local ButtonActions = require(ReplicatedStorage.Modules.UI.SharedState.ButtonActions)

-- [Constants]
local RARITY_COLORS = {
	Common = SharedState.textGradients.Common,
	Uncommon = SharedState.textGradients.Uncommon,
	Rare = SharedState.textGradients.Rare,
	Legendary = SharedState.textGradients.Legendary,
	Exotic = SharedState.textGradients.Exotic
}


-----------------------------
function InventoryModule:Init()
	self.InventoryFrame = SharedState.InventoryFrame.Main
	self.itemFrame = self.InventoryFrame.Items
	self.petFrame = self.InventoryFrame.Pets
	self.trailFrame = self.InventoryFrame.Trails

	self:SetInventory({Items = {}, Pets = {}, Trails = {}})

	task.spawn(function()
		local inventory = EventHandler:FireServer("RequestInventory")
		self:SetInventory(inventory or {})
	end)
	
end

-- [Load Inventory]
function InventoryModule:SetInventory(inventory)
	self.playerInventory = inventory
	self.equippedItems = inventory.Equipped or {
		Item = "",
		Pet = "",
		Trail = ""
	}

	-- Update ButtonActions with equipped items
	ButtonActions.InventoryUpdateEquip(self.equippedItems)
	self:LoadInventory()
end

function InventoryModule:ApplyRarityGradient(object, rarity)
	if not RARITY_COLORS[rarity] then return end
	local gradient = object:FindFirstChild("UIGradient")
	if gradient then
		gradient.Color = RARITY_COLORS[rarity]
	end
end

function InventoryModule:GetItemData(itemId)
	for _, categoryItems in pairs(ItemsData) do
		if type(categoryItems) == "table" then
			for _, item in ipairs(categoryItems) do
				if item.Id == itemId then
					return item
				end
			end
		end
	end
	return nil
end

-- [ Create Template ]
function InventoryModule:CreateInventoryItem(itemType, itemData)    
	local template = self.InventoryFrame.TemplatesFrame.Template
	if not template then return end
	
	
	
	local clone = template:Clone()
	clone.Visible = true

	if itemType == "Item" then
		clone.Parent = self.itemFrame
	elseif itemType == "Pet" then
		clone.Parent = self.petFrame
	elseif itemType == "Trail" then
		clone.Parent = self.trailFrame
	end

	local button = clone.ImageButton
	local textLabel = button.TextLabel
	local imageLabel = button.ImageLabel
	button.Position = UDim2.new(0.5, 0, 0.5, 0)
	button.PriceFrame:Destroy()
	textLabel.Text = itemData.Name
	imageLabel.Image = `rbxassetid://{itemData.Image}`
	
	-- Set equipped state
	if self.equippedItems[itemType] == itemData.Id then
		button.Image = SharedState.EQUIPPED_IMAGE
		ButtonActions.equippedButtons[itemType] = button
	else
		button.Image = SharedState.NORMAL_IMAGE
	end
	
	self:ApplyRarityGradient(textLabel, itemData.Rarity)
	ButtonActions.SetupEquipInventory(button, itemData, itemType)
	
end

-- [ Main Functions ]
function InventoryModule:ClearInventoryFrames()
	for _, frame in ipairs({self.itemFrame, self.petFrame, self.trailFrame}) do
		for _, child in ipairs(frame:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
	end
end

function InventoryModule:LoadInventory()
	self:ClearInventoryFrames()

	for _, id in ipairs(self.playerInventory.Items or {}) do
		local itemData = self:GetItemData(id)
		if itemData then
			self:CreateInventoryItem("Item", itemData)
		end
	end

	for _, id in ipairs(self.playerInventory.Pets or {}) do
		local petData = self:GetItemData(id)
		if petData then
			self:CreateInventoryItem("Pet", petData)
		end
	end

	for _, id in ipairs(self.playerInventory.Trails or {}) do
		local trailData = self:GetItemData(id)
		if trailData then
			self:CreateInventoryItem("Trail", trailData)
		end
	end
end

function InventoryModule:Start()
	self.ACTIVE_COLOR = Color3.fromRGB(255, 191, 0)
	self.GAMEPASS_COLOR = Color3.fromRGB(64, 191, 93)

	self.CATEGORIES = {
		Items = {
			Button = SharedState.InventoryFrame.ShopCategory.Items.ImageButton,
			Frame = self.itemFrame
		},
		Pets = {
			Button = SharedState.InventoryFrame.ShopCategory.Pets.ImageButton,
			Frame = self.petFrame
		},
		Trails = {
			Button = SharedState.InventoryFrame.ShopCategory.Trails.ImageButton,
			Frame = self.trailFrame
		}
	}
	function InventoryModule:SetActiveCategory(category)
		for name, data in pairs(self.CATEGORIES) do
			data.Frame.Visible = (name == category)
		end

		for name, data in pairs(self.CATEGORIES) do
			local pressed = (name == category)
			if pressed then
				GUIanim.SetToggled(data.Button, true, self.ACTIVE_COLOR)
			else
				GUIanim.SetToggled(data.Button, false)
			end
		end
	end
	for category, data in pairs(self.CATEGORIES) do
		GUIanim.ToggleHoverSize(data.Button, 1.05, 1, 0.2, 0.3, self.ACTIVE_COLOR, "InventoryCategory")

		data.Button.MouseButton1Click:Connect(function()
			SharedState.ClickUI:Play()
			self:SetActiveCategory(category)
		end)
	end

	-- Initialize with default category
	self:SetActiveCategory("Items")
end

return InventoryModule