local ShopUI = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
-- [Modules]
local SharedState = require(ReplicatedStorage.Modules.UI.SharedState)
local ItemsData = require(ReplicatedStorage.Modules.DataTables.ItemsData)
local GamepassData = require(ReplicatedStorage.Modules.DataTables.GamepassData)
local EventHandler = require(ReplicatedStorage.Modules.NetworkManager.EventHandler).new("Client")
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

local CATEGORY_MAP = {
	Items = "Item",
	Pets = "Pet",
	Trails = "Trail"
}

-----------------------------
function ShopUI:Init()
	self.playerInventory = {Items = {}, Pets = {}, Trails = {}}
	self.shopFrame = SharedState.shopFrame.Main
	self.itemFrame = self.shopFrame.Items
	self.petFrame = self.shopFrame.Pets
	self.trailFrame = self.shopFrame.Trails
	self.gamepassFrame = self.shopFrame.Gamepass
	self.templateFrame = self.shopFrame.TemplatesFrame

	self.singleTemplate = self.templateFrame.Template
	self.lockedTemplate = self.templateFrame.LockedTemplate
	self.topGamepass = self.gamepassFrame.TopGamepass
	self.listGamepass = self.gamepassFrame.ListGamepass
end

-- [ Inventory ]
function ShopUI:SetInventory(inventory)
	self.playerInventory = inventory or {Items = {}, Pets = {}, Trails = {}}
	self:MarkPurchasedItems()
end

function ShopUI:GetItemData(itemId)
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

function ShopUI:ApplyRarityGradient(object, rarity)
	if not RARITY_COLORS[rarity] then return end

	local gradient = object:FindFirstChild("UIGradient")
	if gradient then
		gradient.Color = RARITY_COLORS[rarity]
	end
end


-- [ Create Templates ]
function ShopUI:SingleTemplate_CREATE(itemType, itemData)
	local clone = self.singleTemplate:Clone()
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
	local priceLabel = button.PriceFrame.TextLabel
	local RarityValue = button.RarityValue

	textLabel.Text = itemData.Name
	priceLabel.Text = itemData.Price
	imageLabel.Image = `rbxassetid://{itemData.Image}`
	RarityValue.Value = itemData.Rarity or "Common"
	
	SharedState.textGradients.ApplyRarityGradient(textLabel, RarityValue.Value)
	ButtonActions.ShopPurchaseHandler(button, itemData.Id, itemType, itemData.Price)
	
end

function ShopUI:LockedTemplate_CREATE(itemType, itemData)
	local clone = self.lockedTemplate:Clone()
	clone.Visible = true

	if itemType == "Item" then
		clone.Parent = self.itemFrame
	elseif itemType == "Pet" then
		clone.Parent = self.petFrame
	elseif itemType == "Trail" then
		clone.Parent = self.trailFrame
	end

	local button = clone.ImageButton
	local imageLabel = button.Item
	local requirementLabel = button.RequirementLabel
	local rarityValue = button.RarityValue

	requirementLabel.Text = itemData.Requirement
	imageLabel.Image = `rbxassetid://{itemData.Image}`
	rarityValue.Value = itemData.Rarity or "Common"
	self:ApplyRarityGradient(requirementLabel, rarityValue.Value)
end

function ShopUI:SingleGamepass_CREATE(gamepass)
	local clone = self.topGamepass:Clone()
	clone.Visible = true
	clone.Parent = self.gamepassFrame

	local button = clone.ImageButton
	local itemLabel = clone.ItemLabel
	local imageLabel = clone.ImageLabel
	local descriptionLabel = clone.DescriptionLabel
	local priceLabel = clone.Robux.Frame.TextLabel

	itemLabel.Text = gamepass.Name
	imageLabel.Image = `rbxassetid://{gamepass.Image}`
	descriptionLabel.Text = gamepass.Description
	priceLabel.Text = `{utf8.char(0xE002)}{gamepass.Price}`
	self:ApplyRarityGradient(itemLabel, "Legendary")
end

function ShopUI:DoubleGamepass_CREATE(gamepass)
	local clone = self.listGamepass.Template:Clone()
	clone.Visible = true
	clone.Parent = self.listGamepass

	local itemLabel = clone.TextLabel
	local imageLabel = clone.ImageLabel
	local priceLabel = clone.Robux.Frame.TextLabel

	itemLabel.Text = gamepass.Name
	imageLabel.Image = `rbxassetid://{gamepass.Image}`
	priceLabel.Text = `{utf8.char(0xE002)}{gamepass.Price}`
	self:ApplyRarityGradient(itemLabel, "Common")
end

-- [ Main Functions ]
function ShopUI:MarkPurchasedItems()
	for _, frame in ipairs({self.itemFrame, self.petFrame, self.trailFrame}) do
		for _, item in ipairs(frame:GetChildren()) do
			if item:IsA("Frame") then
				local button = item.ImageButton
				local itemName = button and button.TextLabel and button.TextLabel.Text

				if itemName then
					local isPurchased = false
					for category in pairs(CATEGORY_MAP) do
						for _, id in ipairs(self.playerInventory[category] or {}) do
							local data = self:GetItemData(id)
							if data and data.Name == itemName then
								isPurchased = true
								break
							end
						end
						if isPurchased then break end
					end

					button.AutoButtonColor = not isPurchased
					button.BackgroundColor3 = isPurchased and Color3.fromRGB(100, 100, 100) or Color3.new(1, 1, 1)
				end
			end
		end
	end
end

function ShopUI:CreateItemsFromData()
	for category, items in pairs(ItemsData) do
		local mappedCategory = CATEGORY_MAP[category]
		if mappedCategory then
			for _, item in ipairs(items) do
				if not item.Locked then
					self:SingleTemplate_CREATE(mappedCategory, item)
				else
					self:LockedTemplate_CREATE(mappedCategory, item)
				end
			end
		end
	end
end

function ShopUI:CreateGamepassesFromData()
	for _, gamepass in ipairs(GamepassData) do
		if gamepass.IsFeatured then
			self:SingleGamepass_CREATE(gamepass)
		else
			self:DoubleGamepass_CREATE(gamepass)
		end
	end
end

function ShopUI:Start()
	self:CreateItemsFromData()

	if GamepassData then
		self:CreateGamepassesFromData()
	else
		self:SingleGamepass_CREATE({
			Name = "V.I.P", 
			Price = 250, 
			Image = 17409640887, 
			Description = "- 2x EXP\n- VIP Perks"
		})
		self:DoubleGamepass_CREATE({
			Name = "Limited Trail", 
			Price = 500, 
			Image = 120808178966425
		})
	end

	self.ACTIVE_COLOR = Color3.fromRGB(255, 191, 0)
	self.GAMEPASS_COLOR = Color3.fromRGB(64, 191, 93)

	self.CATEGORIES = {
		Items = {
			Button = SharedState.shopFrame.ShopCategory.Items.ImageButton,
			Frame = self.itemFrame
		},
		Gamepass = {
			Button = SharedState.shopFrame.ShopCategory.Gamepass.ImageButton,
			Frame = self.gamepassFrame
		},
		Pets = {
			Button = SharedState.shopFrame.ShopCategory.Pets.ImageButton,
			Frame = self.petFrame
		},
		Trails = {
			Button = SharedState.shopFrame.ShopCategory.Trails.ImageButton,
			Frame = self.trailFrame
		}
	}
	function ShopUI:SetActiveCategory(category)
		for name, data in pairs(self.CATEGORIES) do
			data.Frame.Visible = (name == category)
		end

		for name, data in pairs(self.CATEGORIES) do
			local pressed = (name == category)
			local pressedColor = (name == "Gamepass") and self.GAMEPASS_COLOR or self.ACTIVE_COLOR

			if pressed then
				GUIanim.SetToggled(data.Button, true, pressedColor)
			else
				GUIanim.SetToggled(data.Button, false)
			end
		end
	end
	for category, data in pairs(self.CATEGORIES) do
		local pressedColor = (category == "Gamepass") and self.GAMEPASS_COLOR or self.ACTIVE_COLOR
		GUIanim.ToggleHoverSize(data.Button, 1.05, 1, 0.2, 0.3, pressedColor, "ShopCategory")

		data.Button.MouseButton1Click:Connect(function()
			SharedState.ClickUI:Play()
			self:SetActiveCategory(category)
		end)
	end

	-- Initialize with default category
	self:SetActiveCategory("Items")
	self:SetInventory(EventHandler:FireServer("RequestInventory"))
end

return ShopUI