local SkinData = require(game.ReplicatedStorage.Modules.SkinData)
local blockData = require(game.ReplicatedStorage.Modules.BlockData)
local InventoryManager = require(game.ReplicatedStorage.Modules.InventoryManager)

local UIS = game:GetService("UserInputService")

local RE = game.ReplicatedStorage.Remotes.DataLoad
local skinBase = game.ReplicatedStorage.UI.SkinBlock
local blockBase = game.ReplicatedStorage.UI.SkinSelectBase
local SkinSelect = script.Parent.SkinSelect
local ControlSelect = script.Parent.Controls
local ControlChange = script.Parent.ControlChange
local bad = script.Parent.Error

local shapeColors = blockData.getColors()

local ownedSkins = {}

local player = game.Players.LocalPlayer

function generateTable(j)
	local t = {}
	for i = 1, j do
		table.insert(t, i)
	end
	return t
end

function fillBase(base, skinID)
	local order = {7, 5, 2, 6, 3, 4, 1, 8, 9}
	local texture = SkinData.getTextures(skinID)
	local count = 1
	for i, v in pairs(order) do
		
		local a = blockBase:Clone() 
		a.Parent = base
		a.Image = texture[v]
		a.LayoutOrder = count
		if skinID == 1 then
			a.BackgroundTransparency = 0 
			a.BackgroundColor3 = shapeColors[v]
		end
		count = count + 1
	end
end

SkinSelect.Title.Exit.MouseButton1Click:Connect(function()
	SkinSelect.Visible = false
end)

script.Parent.Menu.Buttons.Skins.MouseButton1Click:Connect(function()
	SkinSelect.Position = UDim2.new(0.25, 0, 0, 0)
	SkinSelect.Visible = true
end)

script.Parent.Menu.Buttons.Controls.MouseButton1Click:Connect(function()
	ControlSelect.Position = UDim2.new(0.25, 0, 0, 0)
	ControlSelect.Visible = true
end)

ControlSelect.Title.Exit.MouseButton1Click:Connect(function()
	ControlSelect.Visible = false
	ControlChange.Visible = false
end)

ControlChange.Title.Exit.MouseButton1Click:Connect(function()
	ControlChange.Visible = false
end)
RE.OnClientEvent:Connect(function(command, owned, selected)
	if command == "start" then
		ownedSkins = owned
		local numSkins = SkinData.getNumSkins()
		local skinTable = generateTable(numSkins)	
		for i, v in pairs(owned) do
			table.remove(skinTable, table.find(skinTable, v))
			local newBlock = skinBase:Clone()
			newBlock.Parent = SkinSelect.Body
			newBlock.Name = v
			newBlock.Lock.Visible = false
			newBlock.LayoutOrder = i
			if v == selected then
				newBlock.Select.ImageColor3 = Color3.new(0, 0, 255)
			end
			fillBase(newBlock, v)
		end
		for i, v in pairs(skinTable) do
			local newBlock = skinBase:Clone()
			newBlock.Parent = SkinSelect.Body
			newBlock.Name = v
			newBlock.LayoutOrder = #owned + i
			fillBase(newBlock, v)
		end
	elseif command == "purchase" then
		local numSkins = SkinData.getNumSkins()
		table.insert(ownedSkins, owned)
		SkinSelect.Body:FindFirstChild(owned):Destroy()
		for i, v in pairs(SkinSelect.Body:GetChildren()) do
			if not table.find(ownedSkins, tonumber(v.Name)) and v:IsA("ImageButton") then
				v.LayoutOrder = v.LayoutOrder + 1
			end
		end
		local newBlock = skinBase:Clone()
		newBlock.Lock.Visible = false
		newBlock.Parent = SkinSelect.Body
		newBlock.Name = owned
		newBlock.LayoutOrder = #ownedSkins
		fillBase(newBlock, owned)
		for i, v in pairs(SkinSelect.Body:GetChildren()) do
			if v:IsA("ImageButton") then
				v.Select.ImageColor3 = Color3.new(255, 255, 255)
			end
		end
		newBlock.Select.ImageColor3 = Color3.new(0, 0, 255)
	elseif command == "controls" then
		for i, v in pairs(selected) do
			local button = ControlSelect.Body:FindFirstChild(v).Change 
			button.Text = owned[i]
			button.MouseButton1Down:Connect(function()
				ControlChange.Visible = true
				ControlChange.Title.Text = "Change "..v.." button"
				ControlChange.Body.Text = button.Text
				UIS.InputBegan:connect(function(key)
					if key.UserInputType == Enum.UserInputType.Keyboard and ControlChange.Visible and ControlChange.Body.Text == button.Text then
						local allControls = InventoryManager.getControls(player)
						if not table.find(allControls, key.KeyCode.Name) then
							button.Text = key.KeyCode.Name
							RE:FireServer("controls", {v, key.KeyCode.Name})
							ControlChange.Visible = false
						else
							bad.Visible = true
							wait(1)
							bad.Visible = false
						end
					end
				end)
			end)
		end
	end
end)