local MPS = game:GetService("MarketplaceService")
local IM = require(game.ReplicatedStorage.Modules:WaitForChild("InventoryManager"))
local SkinData = require(game.ReplicatedStorage.Modules:WaitForChild("SkinData"))
local SkinRE = game.ReplicatedStorage.Remotes.DataLoad
local skins = SkinData.getProductIds()

MPS.ProcessReceipt = function(Info)
	local plrId = Info.PlayerId
	local purchaseId = Info.ProductId
	local plr = game.Players:GetPlayerByUserId(plrId)
	if table.find(skins, purchaseId) and plr then
		local skinID = table.find(skins, purchaseId)
		IM.AddSkin(plr, skinID)
		IM.equipSkin(plr, skinID)
		SkinRE:FireClient(plr, "purchase", skinID)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

SkinRE.OnServerEvent:Connect(function(player, command, data)
	if command == "equip" then
		IM.equipSkin(player, data)
	elseif command == "controls" then
		IM.setControl(player, data[1], data[2])
	end
end)