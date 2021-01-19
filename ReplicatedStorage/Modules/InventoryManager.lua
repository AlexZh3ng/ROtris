local module = {}

function module.AddSkin(plr, skinID)
	if plr:IsA("Player") and plr:FindFirstChild("Inventory") then
		local a = Instance.new("IntValue", plr.Inventory)
		a.Value = skinID
		a.Name = skinID
	end	
end

function module.getSkins(player)
	local inv = {}
	if player:IsA("Player") and player:FindFirstChild("Inventory") then
		for i, v in pairs(player.Inventory:GetChildren()) do
			table.insert(inv, v.Value)
		end
	end
	return inv
end

function module.getNoSkins(plr)
	return #plr.Inventory:GetChildren()
end

function module.equipSkin(plr, skinId)
	if plr:IsA("Player") and plr:FindFirstChild("Equip") and plr.Inventory:FindFirstChild(skinId) then
		plr.Equip.Value = skinId
	end
end

function module.getControls(player)
	local controlFolder = player.Controls
	return {controlFolder.Left.Value, controlFolder.Right.Value, controlFolder["Soft Drop"].Value, controlFolder["Hard Drop"].Value, controlFolder["Right Rotate"].Value, controlFolder.Hold.Value, controlFolder["Left Rotate"].Value}
end

function module.setControl(player, control, newValue)
	player.Controls:FindFirstChild(control).Value = newValue
	player.Controls.Save.Value = player.Controls.Save.Value + 1
end

return module
