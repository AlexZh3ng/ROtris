local DS2 = require(game.ServerScriptService:WaitForChild("DatastoreModule"))
local IM = require(game.ReplicatedStorage.Modules:WaitForChild("InventoryManager"))
local RE = game.ReplicatedStorage.Remotes.DataLoad
local BadgeService = game:GetService("BadgeService")
local controlNames = {"Left", "Right", "Soft Drop", "Hard Drop", "Right Rotate", "Hold", "Left Rotate"}

game.Players.PlayerAdded:Connect(function(player)
	local stats = DS2("Main", player)
	local dataTable = stats:GetTable({0, 0, 0, 0, 0, 0, 0, {1, 6}, 1, {"Left", "Right", "Down", "Space", "Up", "C" ,"Z"}})
	
	local wins = dataTable[1]
	local games = dataTable[2]
	local lines = dataTable[3]
	local received = dataTable[4]
	local placed = dataTable[5]
	local maxCombo = dataTable[6]
	local maxLines = dataTable[7]
	local skinsOwned = dataTable[8]
	local selectedSkin = dataTable[9]
	local controls = dataTable[10]
	
	local folder =  Instance.new("Folder", player)
	folder.Name = "Stats"
	local win = Instance.new("IntValue", folder)
	win.Name = "Win"
	win.Value = wins
	local gam = Instance.new("IntValue", folder)
	gam.Name = "Game"
	gam.Value = games
	local line = Instance.new("IntValue", folder)
	line.Name = "Line"
	line.Value = lines
	local rec = Instance.new("IntValue", folder)
	rec.Name = "Received"
	rec.Value = received
	local place = Instance.new("IntValue", folder)
	place.Name = "Placed"
	place.Value = placed
	local mxCombo = Instance.new("IntValue", folder)
	mxCombo.Name = "MaxCombo"
	mxCombo.Value = maxCombo
	local mxLines = Instance.new("IntValue", folder)
	mxLines.Name = "MaxLines"
	mxLines.Value = maxLines
	local saveButton = Instance.new("IntValue", folder)
	saveButton.Name = "Save"
	saveButton.Value = 0
	
	local inventory = Instance.new("Folder", player)
	inventory.Name = "Inventory"
	for i, v in pairs(skinsOwned) do
		IM.AddSkin(player, v)
	end
	
	local selected = Instance.new("IntValue", player)
	selected.Value = selectedSkin
	selected.Name = "Equip"
	
	local controlFolder = Instance.new("Folder", player)
	controlFolder.Name = "Controls"

	for i, v in pairs(controls) do
		local intV = Instance.new("StringValue", controlFolder)
		intV.Name = controlNames[i]
		intV.Value = v
	end
	
	local saveControls = Instance.new("IntValue", controlFolder)
	saveControls.Name = "Save"
	saveControls.Value = 0
	
	local function saveStats()
		--[[
		print("Saving stats! Wins: "..wins.. " games: "..games.." Lines: "..lines.." Received: "..received.." Placed: "..placed.." Max Combo: "..maxCombo.. " Max Lines: "..maxLines, "Selected Skin: "..selectedSkin)
		print("Skins owned: ")
		for i, v in pairs(skinsOwned) do
			print(v)
		end]]
		stats:Set({wins, games, lines, received, placed, maxCombo, maxLines, skinsOwned, selectedSkin, controls})
	end
	
	saveButton:GetPropertyChangedSignal("Value"):Connect(function()
		wins,games,lines,received,placed,maxCombo,maxLines = win.Value, gam.Value, line.Value, rec.Value, place.Value, mxCombo.Value, mxLines.Value
		saveStats()
	end)
	
	inventory.ChildAdded:Connect(function(child)
		wait()
		local skinID = child.Value
		if not table.find(skinsOwned, skinID) then
			table.insert(skinsOwned, skinID)
		else
			print("ERROR? Added skin already owned by "..player.Name)
		end
		saveStats()
	end)
	
	selected:GetPropertyChangedSignal("Value"):Connect(function()
		selectedSkin = selected.Value
		saveStats()
	end)
	
	saveControls:GetPropertyChangedSignal("Value"):Connect(function()
		controls = {controlFolder.Left.Value, controlFolder.Right.Value, controlFolder["Soft Drop"].Value, controlFolder["Hard Drop"].Value, controlFolder["Right Rotate"].Value, controlFolder.Hold.Value, controlFolder["Left Rotate"].Value}
		saveStats()
	end)
	
	RE:FireClient(player, "start", skinsOwned, selectedSkin)
	RE:FireClient(player, "controls", controls, controlNames)
	if not BadgeService:UserHasBadgeAsync(player.UserId, 2124583735) then
		BadgeService:AwardBadge(player.UserId, 2124583735)
	end
	wait(3)
	player.Character:Destroy()
end)