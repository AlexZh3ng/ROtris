local Block = {}
Block.__index = Block
local blockAsset = game.ReplicatedStorage.UI.Block

function Block.new(y, x, clearable, placed, color, size, grid, visible, transparency, image) 
	local block = blockAsset:Clone() 
	block.Position = UDim2.new((x - 1) * size * 2, 0, (y - 5) * size, 0)
	block.Size = UDim2.new(size*2, 0, size, 0)
	block.Parent = grid
	block.BackgroundColor3 = color
	block.BackgroundTransparency = transparency
	block.ImageTransparency = transparency
	block.Visible = visible
	block.Transparency = transparency
	block.Image = image
	if image ~= "" then
		block.BackgroundTransparency = 1
	end
	local self = {
	["x"] = x,
	["y"] = y, 
	["clearable"] = clearable,
	["placed"] = placed,
	["rotation"] = 0,
	["block"] = block, 
	["size"] = size,
	}
	setmetatable(self, Block)
	return self
end

function Block:addPosition(x, y)
	self.block.Position = self.block.Position + UDim2.new(x*self.size*2, 0,self.size*y, 0)
	self.x = self.x + x
	self.y = self.y + y
	self.block.Visible = self.y > 4
end

return Block
