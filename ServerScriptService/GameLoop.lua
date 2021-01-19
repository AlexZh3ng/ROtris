--Classes/modules
local Game = require(game.ReplicatedStorage.Classes.Game)
local GameFunctions = require(game.ReplicatedStorage.Modules.GameFunctions)
local Block = require(game.ReplicatedStorage.Classes.Block)

--Data structures
local games = {}  --dict?
local gameBoards = {} --dict?
local playerData = {} --dict

--Remotes
local GameEvent = game.ReplicatedStorage.Remotes.GameEvent
local DataTransfer = game.ReplicatedStorage.Remotes.DataTransfer
local DataConfirm = game.ReplicatedStorage.Remotes.DataConfirm

--UI
local defaultLeaderboard = game.ReplicatedStorage.UI.Leaderboard
local leaderboardBase = game.ReplicatedStorage.UI.Place
local Grid = game.ReplicatedStorage.UI.Grid

--Create default game
local defaultRoom = Game.new(1, nil) --GameID, creator
games[1] = defaultRoom

--Functions
function constructLeaderboard(parent, leaderboard)
	for i = #leaderboard, 1, -1 do
		local place = leaderboardBase:Clone() 
		place.Parent = parent 
		place:FindFirstChild("Name").Text = leaderboard[i].Name
		place.Rank.Text = #leaderboard + 1 - i
		place.Received.Text = playerData[leaderboard[i]]["received"]
		place.Sent.Text = playerData[leaderboard[i]]["sent"]
		place.Wins.Text = leaderboard[i].Stats.Win.Value
	end
end

function canMove(grid, pos, x, y)
	for i = 4, 1, -1 do
		local i2 = pos[i][1] + y 
		local j2 = pos[i][2] + x
		if j2 < 1 or j2 > 10 then return false end
		if i2 > 24 then return false end 
		if grid[i2][j2] == "1" or grid[i2][j2] == "2" then return false end 
	end
	return true
end

function updateStats(player, stats)
	local folder = player.Stats
	folder.Game.Value = folder.Game.Value + 1
	folder.Line.Value = folder.Line.Value + stats[1]
	folder.Received.Value = folder.Received.Value + stats[2]
	folder.Placed.Value = folder.Placed.Value + stats[3]
	if stats[4] > folder.MaxCombo.Value then
		folder.MaxCombo.Value = stats[4]
	end
	if stats[1] > folder.MaxLines.Value then
		folder.MaxLines.Value = stats[1]
	end
	folder.Save.Value = folder.Save.Value + 1
end

function createDataStructures(player) 
	gameBoards[player] = {} 
	for i = 1, 24 do
		GameFunctions.newLine(i, gameBoards[player], nil)
	end
end

function addQueue(player, lines, place)
	if not playerData[player]["queueable"] then
		print("NOT QUEUABLE!")
		repeat
			wait()
		until playerData[player]["queueable"] == true	
	end
	
	local tempQueue = {}
	for i, v in pairs(playerData[player]["queue"]) do
		table.insert(tempQueue, v)
	end
	for i = 1, lines do 
		if place then 
			table.insert(tempQueue, #tempQueue + 1, place)
		else
			table.insert(tempQueue, 1, place) --useless
		end
	end
	playerData[player]["queueable"] = false
	DataConfirm:InvokeClient(player, "queue", tempQueue)
	playerData[player]["queue"] = tempQueue
	playerData[player]["queueable"] = true
	--DataTransfer:FireClient(player, "updateQueue", playerData[player]["queue"])
end

function printGrid(grid)
	for i = 1, #grid do
		print(i.." "..grid[i][1].." "..grid[i][2].." "..grid[i][3].." "..grid[i][4].." "..grid[i][5].." "..grid[i][6].." "..grid[i][7].." "..grid[i][8].." "..grid[i][9].." "..grid[i][10])
	end
end

--Events
--Command: join, data = room id?
--Command: place, data = blockPositions
GameEvent.OnServerEvent:Connect(function(player, command, data)
	if command == "join" then 
		games[data]:AddPlayer(player)
		playerData[player] = {["inGame"] = false, ["gameID"] = data, ["danger"] = 0, ["index"] = 1, ["hold"] = nil, ["canHold"] = true, ["block"] = nil, ["combo"] = 0, ["received"] = 0, ["sent"] = 0, ["lastBlockClear"] = 0, ["queue"] = {}, ["unclearableQueue"] = {}, ["bottom"] = 24, ["placed"] = 0, ["maxCombo"] = 0}
	elseif command == "place" then 
		if not playerData[player]["inGame"] then return end
		playerData[player]["lastAction"] = tick()
		playerData[player]["dropped"] = false
		local blockPositions, sendUQueue, sendQueue, tspin = data[1], data[2], data[3], data[4]
		local curGame = games[playerData[player]["gameID"]]
		playerData[player]["placed"] = playerData[player]["placed"] + 1
		--check for t-spin too
		--Do check and stuff by sending in topCorner, block# and rotation (all in 1 data table)
		if canMove(gameBoards[player], blockPositions, 0, 1) then
			print("BLOCK IN THE AIR?", player.Name)
		end
		playerData[player]["index"] = playerData[player]["index"] + 1
		playerData[player]["canHold"] = true
		local tempDead = false
		if GameFunctions.placePieces(blockPositions, gameBoards[player], nil) then
			tempDead = true
		end
		if #playerData[player]["unclearableQueue"] > 0 and sendUQueue then
			GameFunctions.sendLines(playerData[player]["unclearableQueue"] , gameBoards[player], playerData[player]["bottom"])
			--print(playerData[player]["bottom"], playerData[player]["unclearableQueue"], #playerData[player]["unclearableQueue"])
			playerData[player]["bottom"] = playerData[player]["bottom"] - #playerData[player]["unclearableQueue"]
			playerData[player]["unclearableQueue"] = {}
		end
		local lines = GameFunctions.getClearables(gameBoards[player])
		--print(#lines)
		if lines[1] then
			GameFunctions.clearLines(lines, gameBoards[player], nil)
			playerData[player]["combo"] = playerData[player]["combo"] + 1	
			if playerData[player]["combo"] > playerData[player]["maxCombo"] then
				playerData[player]["maxCombo"] = playerData[player]["combo"]
			end
			local sumLines = GameFunctions.getNoLines(gameBoards[player], #lines, playerData[player]["combo"], tspin, playerData[player]["lastBlock"] and playerData[player]["lastBlock"] == playerData[player]["block"])
			--check for back-to-back (need block) 
			local nextPlayer = curGame.alivePlayers[table.find(curGame.alivePlayers, player) % #curGame.alivePlayers + 1]
			--print(#playerData[player]["queue"], sumLines)
			--addQueue(nextPlayer, sumLines, math.random(1, 10))
			--print("SERVER queue "..#playerData[player]["queue"])
			if #playerData[player]["queue"] > 0 and sendQueue then
				if sumLines <= #playerData[player]["queue"] then 
					GameFunctions.removeQueue(playerData[player]["queue"], sumLines)
				else
					playerData[player]["queue"] = {}
					addQueue(nextPlayer, sumLines - #playerData[player]["queue"], math.random(1, 10))
					playerData[player]["sent"] = playerData[player]["sent"] + sumLines - #playerData[player]["queue"]
				end
			else
				addQueue(nextPlayer, sumLines, math.random(1, 10))
				playerData[player]["sent"] = playerData[player]["sent"] + sumLines
			end
			playerData[player]["lastBlock"] = playerData[player]["block"]
		else
			playerData[player]["combo"] = 0
			playerData[player]["lastBlock"] = nil
			if #playerData[player]["queue"] > 0 and sendQueue then
				playerData[player]["received"] = playerData[player]["received"] + #playerData[player]["queue"]
				playerData[player]["queue"] = GameFunctions.trimQueue(playerData[player]["queue"])
				GameFunctions.sendLines(playerData[player]["queue"], gameBoards[player], playerData[player]["bottom"])
				--print("updating from server")
				--printGrid(gameBoards[player])
				playerData[player]["queue"] = {}
			end
		end	
		playerData[player]["danger"] = GameFunctions.alive(gameBoards[player], playerData[player]["danger"])
		playerData[player]["block"] = games[playerData[player]["gameID"]].shapes[playerData[player]["index"]]
		if not playerData[player]["danger"] then
			games[playerData[player]["gameID"]]:PlayerDied(player)
			GameEvent:FireClient(player, "dead", #games[playerData[player]["gameID"]].alivePlayers + 1) --SEND LEADERBOARD PLACE
			games[playerData[player]["gameID"]]:AppendLeaderboard(player)
			--table.insert(games[playerData[player]["leaderboard"]], {player, playerData[player]["sent"], playerData[player]["recieved"]})
		end
		if tempDead then
			print("ERROR OCCURED!")
			if player.Name == "WildAsians" then
				print("Board after error: (Gametime) ", tick() - games[1].startTime)
				printGrid(gameBoards[player])
			end
		end
	elseif command == "hold" then
		if not playerData[player]["canHold"] then return end
		playerData[player]["lastAction"] = tick()
		playerData[player]["dropped"] = false
		playerData[player]["canHold"] = false
		local curBlock = playerData[player]["hold"]
		playerData[player]["hold"] = games[playerData[player]["gameID"]].shapes[playerData[player]["index"]]
		if not curBlock then
			playerData[player]["index"] = playerData[player]["index"] + 1
			playerData[player]["block"] = games[playerData[player]["gameID"]].shapes[playerData[player]["index"]]
		else
			playerData[player]["block"] = curBlock
		end
	end
end)

DataTransfer.OnServerEvent:Connect(function(player, command, data)
	if command == "gameBoard" then
		local playerBoard = games[playerData[player]["gameID"]].folder:FindFirstChild(player.Name)
		playerBoard.BlockFolder:ClearAllChildren()
		for i, block in pairs(data) do 
			Block.new(block[2], block[1], true, true, block[3], 0.05, playerBoard.BlockFolder, true, block[5], block[4])
		end
	elseif command == "leave" then
		local id = playerData[player]["gameID"]
		--games[id]:PlayerDied(player)
		games[id]:RemovePlayer(player)
	end
end)

function DataBack(player, command)
	if command == "drop" then
		print(tick() - playerData[player]["lastAction"])
		if tick() - playerData[player]["lastAction"] >= games[playerData[player]["gameID"]].fallTime then
			return true
		end
		return false
	end
end
DataConfirm.OnServerInvoke = DataBack

game.Players.PlayerRemoving:Connect(function(player)
	local hasData = playerData[player]
	if hasData and hasData["gameID"] then
		games[hasData["gameID"]]:RemovePlayer(player)
	end
end)

while true do
	for id, gameObject in pairs(games) do
		if not gameObject.run and #gameObject.players >= 2 and tick() - gameObject.gameEnded >= 3 then
			gameObject:Reset()
			gameObject.alivePlayers = gameObject:GetPlayers()
			local newShapes = GameFunctions.getShapes(100)
			gameObject:SetShapes(newShapes)
			gameObject.folder:ClearAllChildren()
			local newLeaderboard = defaultLeaderboard:Clone()
			newLeaderboard.Parent = gameObject.folder
			for i, player in pairs(gameObject.players) do
				local playerGridUI = Grid:Clone()
				playerGridUI.Parent = gameObject.folder
				playerGridUI.Name = player.Name
				local numPlayers = #gameObject.players-1 if numPlayers == 0 then numPlayers = 1 end
				GameEvent:FireClient(player, "start", numPlayers)
				DataTransfer:FireClient(player, "blocks", newShapes)
				createDataStructures(player)
				playerData[player] = {["inGame"] = true, ["gameID"] = gameObject.id, ["danger"] = 0, ["index"] = 1, ["hold"] = nil, ["canHold"] = true, ["block"] = newShapes[1], lastBlock = nil, ["combo"] = 0, ["received"] = 0, ["sent"] = 0, ["lastBlockClear"] = 0, ["queue"] = {}, ["queueable"] = true, ["unclearableQueue"] = {}, ["bottom"] = 24, ["placed"] = 0, ["maxCombo"] = 0, ["lastAction"] = tick(), ["dropped"] = false}
			end
			gameObject.startTime = tick()
		end
		if gameObject.run and not gameObject.timer and tick() - 2 >= gameObject.startTime then
			gameObject.timer = true
			gameObject.startTime = tick()
			--print("FROM SERVER", tick())
		end
		if gameObject.run then
			for i, player in pairs(gameObject.alivePlayers) do
				if tick() - playerData[player]["lastAction"] >= gameObject.fallTime and not playerData[player]["dropped"] then
					DataTransfer:FireClient(player, "fall")
					playerData[player]["dropped"] = true
				end
			end 
		end
		if gameObject.run and #gameObject.alivePlayers <= 1 and tick() - gameObject.startTime >= 2 then
			if gameObject.alivePlayers[1] then
				GameEvent:FireClient(gameObject.alivePlayers[1], "dead", 1)
				gameObject:AppendLeaderboard(gameObject.alivePlayers[1])
			end
			local winner = gameObject.leaderboard[#gameObject.leaderboard]
			if winner then
				print("Winner: "..winner.Name)
				winner.Stats.Win.Value = winner.Stats.Win.Value + 1
			end
			constructLeaderboard(gameObject.folder.Leaderboard, gameObject.leaderboard)
			gameObject.run = false 
			for i, player in pairs(gameObject.players) do
				updateStats(player, {playerData[player]["sent"], playerData[player]["received"], playerData[player]["placed"], playerData[player]["maxCombo"]})
				GameEvent:FireClient(player, "leaderboard")
			end
			gameObject.gameEnded = tick()
		end
		if gameObject.run and not gameObject.firstGarbage and tick() - gameObject.startTime >= 120 and tick() - gameObject.lastGarbage >= 2 and gameObject.garbage <= 12 then
			print("Sending garbage")
			gameObject.fallTime = 10
			gameObject.lastGarbage = tick()
			gameObject.garbage = gameObject.garbage + 1
			for i, player in pairs(gameObject.alivePlayers) do
				table.insert(playerData[player]["unclearableQueue"], false)
				DataTransfer:FireClient(player, "unclearableQueue", playerData[player]["unclearableQueue"])
			end
			if gameObject.garbage == 12 then 
				gameObject.firstGarbage = true
			end
		end
		if gameObject.run and gameObject.firstGarbage and tick() - gameObject.startTime >= 165 and tick() - gameObject.lastGarbage >= 2 and gameObject.garbage <= 20 then
			print("Sending garbage")
			gameObject.fallTime = 4
			gameObject.lastGarbage = tick()
			gameObject.garbage = gameObject.garbage + 1
			for i, player in pairs(gameObject.alivePlayers) do
				DataTransfer:FireClient(player, "unclearableQueue", playerData[player]["unclearableQueue"])
				table.insert(playerData[player]["unclearableQueue"], false)
			end
		end
	end
	wait()
end
