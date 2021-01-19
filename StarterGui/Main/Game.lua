--Global variables
local currentColor
local currentPiece
local currentTexture
local newGrid
local placed = true
local inLobby
local inMenu = true
local rotation = 1
local index
local lastAction
local tspin 
local forceDescend 
local skin = 1
local player = game.Players.LocalPlayer
local queue, unclearableQueue, bottom, sendQueue, sendUQueue 
local combo
local gameId = 1
local attack, receive, gameTime

--Classes/modules
local BlockData = require(game.ReplicatedStorage.Modules.BlockData)
local Block = require(game.ReplicatedStorage.Classes.Block)
local GameFunctions = require(game.ReplicatedStorage.Modules.GameFunctions)
local SkinData = require(game.ReplicatedStorage.Modules.SkinData)
local SoundModule = require(game.ReplicatedStorage.Modules.Sound)
local InventoryManager = require(game.ReplicatedStorage.Modules.InventoryManager)
local shapes = BlockData:getShapes()
local colors = BlockData:getColors()
local wallKicks = BlockData:getKicks()

--Services
local MPS = game:GetService("MarketplaceService")
local RunService = game:GetService('RunService')
local TS = game:GetService("TweenService")

--Remotes
local GameEvent = game.ReplicatedStorage.Remotes.GameEvent
local DataTransfer = game.ReplicatedStorage.Remotes.DataTransfer
local SkinRE = game.ReplicatedStorage.Remotes.DataLoad
local DataConfirm = game.ReplicatedStorage.Remotes.DataConfirm

--structures and game loop
local grid = {}
local gameGrid = {}
local nextShapes = {}
local blockPositions = {}
local shadowPositions = {}
local shadowBlocks = {}
local holding = nil
local hold = false
local canHold = true
local inPractice = true
local topCorner = {0, 0}
local shadowDistance = 0

--UI
local holdUI, nextBlocks, blockFolder, queueUI, buttons, stats
local screen = script.Parent.AbsoluteSize 
local x = screen.X
local y = screen.Y
local playerUI = script.Parent.Background.Player
local otherUI = script.Parent.Background.Others
local UIAssets = game.ReplicatedStorage.UI
local SkinSelect = script.Parent.SkinSelect
local menu = script.Parent.Menu
local menuButtons = menu.Buttons
local skinBlocks, textures
local gridSize = y * 0.88
local blockSize = 0.05
local left = 0 
local top = 0
local newLeaderboard
local chatBar = player.PlayerGui.Chat.Frame.ChatBarParentFrame.Frame.BoxFrame.Frame.ChatBar

--Controls
local UIS = game:GetService("UserInputService")
local mouse = player:GetMouse()

local leftControl, rightControl, rightRotateControl, softDropControl, hardDropControl, holdControl
local leftDown = false
local rightDown = false
local leftStart = false
local rightStart = false
local spaceHold = false
local upHold = false
local cHold = false
local leftTime = 0 
local rightTime = 0

function setControls()
	local currentControls = InventoryManager.getControls(player)
	leftControl, rightControl, softDropControl, hardDropControl, rightRotateControl, holdControl = currentControls[1], currentControls[2], currentControls[3], currentControls[4], currentControls[5], currentControls[6]
end

function adjustOtherBoards(n)
	local rows = math.ceil((-1 + math.sqrt(1 + 4 * n))/2)
	local cols = math.ceil(math.sqrt(n))
	if cols == 1 then 
		cols = 2
	end
	otherUI.UIGridLayout.CellSize = UDim2.new(0.44/(cols-1), 0, 0.88/rows, 0)
	otherUI.UIGridLayout.CellPadding = UDim2.new(0.12/(1 + cols), 0, 0.12/(1 + rows))
end
function loadSkins()
	SkinSelect.Body:WaitForChild(SkinData.getNumSkins())
	local productIds = SkinData.getProductIds()
	local ownedSkins = InventoryManager.getSkins(player)
	for i, v in pairs(SkinSelect.Body:GetChildren()) do
		if v:IsA("ImageButton") then  
			v.MouseButton1Down:Connect(function()
				local skinId = tonumber(v.Name)
				if table.find(ownedSkins, skinId) then
					for i, v in pairs(SkinSelect.Body:GetChildren()) do
						if v:IsA("ImageButton") then
							v.Select.ImageColor3 = Color3.new(255, 255, 255)
						end
					end
					v.Select.ImageColor3 = Color3.new(0, 0, 255)
					SkinRE:FireServer("equip", skinId)
				else
					MPS:PromptProductPurchase(player, productIds[skinId])
				end
			end)
		end
	end
	SkinSelect.Body.ChildAdded:Connect(function(v)
		v.MouseButton1Down:Connect(function()
			local skinId = tonumber(v.Name)
			for i, v in pairs(SkinSelect.Body:GetChildren()) do
				if v:IsA("ImageButton") then
					v.Select.ImageColor3 = Color3.new(255, 255, 255)
				end
			end
			v.Select.ImageColor3 = Color3.new(0, 0, 255)
			SkinRE:FireServer("equip", skinId)
		end)
	end)
end

function createGrid(gridSize, parent)
	local newGrid = UIAssets.Grid:Clone()
	newGrid.Parent = parent
	blockFolder = newGrid.BlockFolder
	left = newGrid.AbsolutePosition.X 
	top = newGrid.AbsolutePosition.Y
	buttons = UIAssets.Buttons:Clone()
	buttons.practice.Visible = false
	buttons.customize.Visible = false
	buttons.Parent = parent
	buttons.Position = UDim2.new(left/(x/2), 0, (top + newGrid.AbsoluteSize.Y)/y, 0)
	buttons.Size = UDim2.new(newGrid.AbsoluteSize.X / (x/2), 0, (1-newGrid.AbsoluteSize.Y/y)/2, 0)
	buttons.practice.MouseButton1Click:Connect(function()
		buttons.practice.Visible = false
		buttons.customize.Visible = false
		inPractice = true
		startGame()
	end)
	buttons.customize.MouseButton1Click:Connect(function()
		SkinSelect.Visible = true
		SkinSelect.Position = UDim2.new(0.5, 0, 0, 0)
	end)
	buttons.exit.MouseButton1Click:Connect(function()
		if heartbeat then
			heartbeat:Disconnect()
		end
		playerUI:ClearAllChildren()
		--otherUI:ClearAllChildren()
		for i, v in pairs(otherUI:GetChildren()) do
			if v:IsA("Frame") then
				v:Destroy()
			end
		end
		menu.Visible = true
		if script.Parent.Background:FindFirstChild("Leaderboard") then
			script.Parent.Background.Leaderboard:Destroy()
		end
		if inLobby then
			DataTransfer:FireServer("leave")
			inLobby = false
		end
		inMenu = true
	end)
	holdUI = UIAssets.BlockBase:Clone()
	holdUI.Name = "Hold"
	holdUI.Parent = parent
	holdUI.AnchorPoint = Vector2.new(1, 0)
	--if newGrid.AbsolutePosition.X - 10 < gridSize * 4 / 20 then
	--	holdUI.Size = UDim2.new(0, newGrid.AbsolutePosition.X - 10, 0, (newGrid.AbsolutePosition.X - 10)/2)
	--else
	holdUI.Size = UDim2.new(0.09, 0, 0.09, 0)
	--end
	holdUI.Position = UDim2.new(newGrid.AbsolutePosition.X /(x/2) - 5 / (x/2), 0, 0.105, 0)
	nextBlocks = UIAssets.NextBlocks:Clone()
	nextBlocks.Parent = parent 
	nextBlocks.Size = UDim2.new(0.32, 0, 0.63, 0)
	nextBlocks.Position = UDim2.new((newGrid.AbsolutePosition.X + newGrid.AbsoluteSize.X * 1.1)/(x/2), 0, 0.105, 0)
	nextBlocks.UIListLayout.Padding = UDim.new(0.09, 0)
	queueUI = UIAssets.Queue:Clone()
	queueUI.Parent = newGrid
	stats = UIAssets.Stats:Clone()
	stats.Parent = parent
	stats.Size = UDim2.new(newGrid.AbsolutePosition.X /(x/2), 0, 0.15, 0)
	stats.Position = UDim2.new(0, 0, 0.605, 0)
	return newGrid 
end

function updateStats(tim, atk, rcv)
	local minutes = math.floor(tim / 60)
	local seconds = math.floor((tim % 60) * 100)/100
	if seconds < 10 then
		seconds = "0"..seconds
	end
	if minutes == 0 then 
		stats.Time.Text = "Time: ".. seconds
	else
		stats.Time.Text = "Time: ".. minutes .. ":" .. seconds
	end
	stats.Sent.Text = "Lines Sent: "..atk
	stats.Received.Text = "Received: "..rcv
end

function updateText(place)
	local placeColors = { Color3.new(212/255, 175/255,55/255), Color3.new(192/255, 192/255, 192/255), Color3.new(205/255, 127/255, 50/255) }
	local suffixes = {"st", "nd", "rd"}
	if place <= 3 then
		newGrid.Banner.Place.Text = place..suffixes[place]
		newGrid.Banner.Place.TextColor3 = placeColors[place] 
	else
		newGrid.Banner.Place.Text = place.."th"
		newGrid.Banner.Place.TextColor3 = Color3.new(1, 1, 1) 
	end
end

function playAnimation()
	newGrid.Animation.Visible = true
	newGrid.Animation.Text.Text = "Ready!"
	SoundModule.playSound("start", 1)
	wait(1)
	newGrid.Animation.Text.Text = "Go!"
	SoundModule.playSound("start", 2)
	wait(1)
	newGrid.Animation.Visible = false
end

function guiAfterHold()
	for i, v in pairs(blockPositions) do
		gameGrid[v[1]][v[2]].block:Destroy()
		grid[v[1]][v[2]] = "."
	end
	holdUI.Image = skinBlocks[nextShapes[index]]
end

function queueGui(size)
	queueUI.Size = UDim2.new(0, 2, size * blockSize, 0)
end

function boardQueue(queue)
	for _ = 1, #queue do 
		for j = 1, 10 do 
			if gameGrid[1][j] ~= " " then
				gameGrid[1][j].block:Destroy()
			end
		end
		table.remove(gameGrid, 1)
	end
	for i = 1, bottom - #queue do
		for j = 1, 10 do
			if gameGrid[i][j] ~= " " then
				gameGrid[i][j]:addPosition(0, -#queue)
			end
		end
	end
	
	for i = 1, #queue do
		local newLine = {}
		local color, clearable, text
		if queue[i] then
			color = Color3.new(153/255, 153/255, 153/255)
			clearable = true
			text = textures[8]
		else
			color = Color3.new(106/255, 106/255, 106/255)
			clearable = false
			text = textures[9]
		end 
		for j = 1, 10 do
			if j ~= queue[i] then
				table.insert(newLine, Block.new(bottom - #queue + i, j, clearable, true, color, blockSize, blockFolder, true, 0, text))
			else
				table.insert(newLine, " ")
			end
		end 
		table.insert(gameGrid, bottom - #queue + i, newLine)
	end
end

function updateNextBlocks()
	for i = 1, 5 do
		if not nextShapes[index + i] then
			print(index, i)
		end
		nextBlocks:FindFirstChild(i).Image = skinBlocks[nextShapes[index + i]]
	end
end

function sendBoard() 
	local sendBlocks = {}
	for i, v in pairs(blockFolder:GetChildren()) do
		if v.Visible then
			table.insert(sendBlocks, {v.Position.X.Scale/0.1 + 1, v.Position.Y.Scale/0.05 + 5, v.BackgroundColor3, v.Image, v.ImageTransparency})
		end
	end
	DataTransfer:FireServer("gameBoard", sendBlocks)
end

function updateOtherBoards()
	for i, v in pairs(otherUI:GetChildren()) do
		if v:IsA("GuiObject") then
			v:Destroy()
		end
	end
	for i, v in pairs(game.Workspace:FindFirstChild(gameId):GetChildren()) do
		if v.Name ~= player.Name and v.Name ~= "Leaderboard" then --
			local playerBoard = v:Clone() 
			playerBoard.Parent = otherUI
			local nameTag = UIAssets.NameTag:Clone()
			nameTag.Parent = playerBoard
			nameTag.Text = v.Name
			nameTag.Size = UDim2.new(1, 0, 0, playerBoard.AbsoluteSize.Y/20)
		end
	end
end
function createDataStructures() 
	grid = {} 
	gameGrid = {}
	for i = 1, 24 do
		GameFunctions.newLine(i, grid, gameGrid)
	end
end

function newPiece(piece, color, newGrid, high, texture)
	topCorner = {high + 1, 4}
	blockPositions = {}
	if high == 2 then
		for temp = 1, 4 do 
			if string.sub(piece[1][3], temp, temp) == "0" then
				if grid[5][temp + 3] == "1" then
					newPiece(piece, color, newGrid, 1, texture)
					return
				end
			end
		end
	end
	for i = 1, #piece[1] do
		for j = 1, #piece[1][i] do
			if string.sub(piece[1][i], j, j) == "0" then --and gameGrid[i][j] ==then
				grid[high+i][3+j] = "0"
				local visible = high+i >= 5
				gameGrid[high+i][3+j] = Block.new(high+i, 3+j, true, false, color, blockSize, blockFolder, visible, 0, texture)
				table.insert(blockPositions, {high + i, 3 + j})
			end
		end
	end
end

--del
function printGrid()
	for i = 1, #grid do
		print(i.." "..grid[i][1].." "..grid[i][2].." "..grid[i][3].." "..grid[i][4].." "..grid[i][5].." "..grid[i][6].." "..grid[i][7].." "..grid[i][8].." "..grid[i][9].." "..grid[i][10])
	end
end

--del
function printPositions()
	print(#gameGrid)
	local count = 0
	for i = 1, #gameGrid do 
		for j = 1, #gameGrid[i] do 
			if gameGrid[i][j] ~= " " then
				count = count + 1
				print(i, j, gameGrid[i][j])
			end
		end
	end
end

--del
function checkPositions()
	local count = 0
	for i = 1, #gameGrid do 
		for j = 1, #gameGrid[i] do 
			if gameGrid[i][j] ~= " " then
				count = count + 1
			end
		end
	end
end

function canMove(pos, x, y)
	for i = 4, 1, -1 do
		local i2 = pos[i][1] + y 
		local j2 = pos[i][2] + x
		if j2 < 1 or j2 > 10 then return false end
		if i2 > 24 then return false end 
		if grid[i2][j2] == "1" or grid[i2][j2] == "2" then return false end 
	end
	return true
end

function move(x, y)
	topCorner[2] = topCorner[2] + x
	topCorner[1] = topCorner[1] + y
	local newBlockPositions = {}
	for i, v in pairs(blockPositions) do 
		table.insert(newBlockPositions, {v[1] + y, v[2] + x})
	end
	swap(newBlockPositions)
	if x ~= 0 then
		drawShadow()
	end
end

function drawShadow() 
	for i, v in pairs(shadowBlocks) do
		v.block:Destroy()
	end
	shadowBlocks = {}
	shadowPositions = {}
	for i = 0, 24 do 
		if not canMove(blockPositions, 0, i) then 
			for _, v in pairs(blockPositions) do
				table.insert(shadowPositions, {v[1] + i - 1, v[2]})
				table.insert(shadowBlocks, Block.new(v[1] + i - 1, v[2], false, false, currentColor, blockSize, blockFolder, v[1] + i - 1 >= 5, 0.5, ""))
			end
			break
		end
	end	
end

function swap(places)
	for i, v in pairs(blockPositions) do
		if grid[v[1]][v[2]] ~= "0" then
			print("ERROR???")
			printGrid()
			printPositions()
		end
		gameGrid[v[1]][v[2]].block:Destroy()
		gameGrid[v[1]][v[2]] = " "
		grid[v[1]][v[2]] = "."
	end
	for i, v in pairs(places) do
		gameGrid[v[1]][v[2]] = Block.new(v[1], v[2], true, false, currentColor, blockSize, blockFolder, v[1] >= 5, 0, currentTexture)
		grid[v[1]][v[2]] = "0"
	end
	blockPositions = places
end

function getOffset(positions)
	local blockIndex = table.find(shapes, currentPiece)
	for i, v in pairs(wallKicks[blockIndex][rotation]) do
		if canMove(positions, v[1], v[2]) then
			for j, w in pairs(positions) do
				w[1] = w[1] + v[2]
				w[2] = w[2] + v[1]
			end
			topCorner[1] = topCorner[1] + v[2]
			topCorner[2] = topCorner[2] + v[1]
			if nextShapes[index] == 1 then
				if not canMove(positions, 1, 0) and not canMove(positions, -1, 0) and not canMove(positions, 0, -1) then
					print("TSPIN!")
					tspin = true
				else
					tspin = false
				end
			end
			return positions
		end
	end
	return false
end

function rotate() 
	local newPositions = {}
	local nextRotation = currentPiece[rotation % #currentPiece + 1]
	for i = 1, 4 do 
		for j = 1, 4 do
			if string.sub(nextRotation[i], j, j) == "0" then 
				table.insert(newPositions, {topCorner[1] + i - 1, topCorner[2] + j - 1})
			end
		end
	end
	local offsettedPositions = getOffset(newPositions)
	if offsettedPositions then
		swap(newPositions)
		rotation = rotation % #currentPiece + 1
		drawShadow()
	end
	--printPositions()
end

function processControls() 
	local chatting = chatBar:IsFocused()
	if UIS:IsKeyDown(Enum.KeyCode[leftControl]) and not chatting then
		if not canMove(blockPositions, 0, 1) then
			lastAction = tick()
		end
		--Situation 1: first time clicking left 
		if not leftDown then 
			rightStart = false
			leftStart = true
			leftDown = true 
			leftTime = tick()
			if canMove(blockPositions, -1, 0) then 
				move(-1, 0)
			end
		elseif tick() - leftTime >= 0.3 and canMove(blockPositions, -1, 0) and not rightStart then 
			move(-1, 0)
		end
	else
		leftDown = false 
		leftStart = false
	end
	if UIS:IsKeyDown(Enum.KeyCode[rightControl]) and not chatting then
		if not canMove(blockPositions, 0, 1) then
			lastAction = tick()
		end
		--Situation 1: first time clicking right
		if not rightDown then 
			leftStart = false
			rightStart = true
			rightDown = true 
			rightTime = tick()
			if canMove(blockPositions, 1, 0) then 
				move(1, 0)
			end
		elseif tick() - rightTime >= 0.3 and canMove(blockPositions, 1, 0) and not leftStart then 
			move(1, 0)
		end
	else
		rightDown = false 
		rightStart = false
	end
	if UIS:IsKeyDown(Enum.KeyCode[softDropControl]) and canMove(blockPositions, 0,1) and not chatting then
		move(0,1)
		lastAction = tick()
	end
	if UIS:IsKeyDown(Enum.KeyCode[rightRotateControl]) and not chatting then
		if not upHold then
			if not canMove(blockPositions, 0, 1) then
				lastAction = tick()
			end
			rotate()
			upHold = true
		end
	else
		upHold = false
	end
	if UIS:IsKeyDown(Enum.KeyCode[holdControl]) and not chatting then
		if not cHold and canHold then
			cHold = true
			hold = true
			canHold = false
			placed = true
			forceDescend = false
			guiAfterHold()
			if holding then
				nextShapes[index], holding = holding, nextShapes[index]
				index = index - 1
			else
				holding = nextShapes[index]
			end
			if not inPractice then
				GameEvent:FireServer("hold", nil)
			end
		end
	else
		cHold = false
	end
	if forceDescend then
		swap(shadowPositions)
		forceDescend = false
		placed = true
		lastAction = tick()
	end
	
	if UIS:IsKeyDown(Enum.KeyCode[hardDropControl]) and not chatting then
		if not spaceHold and not placed then
			swap(shadowPositions)
			forceDescend = false
			spaceHold = true
			placed = true
			lastAction = tick()
		end
	else
		spaceHold = false
	end
end

--put on server
function startGame(n) 
	skin = player.Equip.Value
	playerUI:ClearAllChildren()
	setControls()
	newGrid = createGrid(gridSize, playerUI)
	skinBlocks = SkinData.getBlocks(skin)
	textures = SkinData.getTextures(skin)
	playAnimation()
	createDataStructures()
	local firstPiece = true
	local fallTime = 1
	local boardTime = tick()
	local danger = 0
	local sumLines = 0
	local lastBlock = nil
	attack, receive, index, combo, bottom, gameTime, lastAction, holding, placed, sendQueue, sendUQueue, forceDescend, tspin, queue, unclearableQueue = 0, 0, 0, 0, 24, tick(), tick(),  nil, true, false, false, false, false, {}, {}
	if inPractice then
		nextShapes = GameFunctions.getShapes(2)
	end
	if script.Parent.Background:FindFirstChild("Leaderboard") then
		script.Parent.Background.Leaderboard:Destroy()
	end
	if not inPractice then
		adjustOtherBoards(n)
	end
	heartbeat = RunService.Heartbeat:Connect(function()
		if not inPractice and tick() - boardTime >= 0.2 then
			sendBoard()
			boardTime = tick()
		end
		updateStats(tick() - gameTime, attack, receive)
		if placed then
			lastAction = tick()
			sendUQueue = false
			index = index + 1 
			placed = false
			currentPiece = shapes[nextShapes[index]]
			currentColor = colors[nextShapes[index]]
			currentTexture = textures[nextShapes[index]]
			rotation = 1
			if inPractice and #nextShapes - 7 == index then
				GameFunctions.addShapes(nextShapes, 2)
			end
			if not firstPiece and not hold then
				updateNextBlocks()
				canHold = true
				GameFunctions.placePieces(blockPositions, grid, gameGrid)
				if unclearableQueue then
					boardQueue(unclearableQueue)
					GameFunctions.sendLines(unclearableQueue, grid, bottom)
					bottom = bottom - #unclearableQueue
					unclearableQueue = nil
					sendUQueue = true
				end
				if not inPractice then
					GameEvent:FireServer("place", {blockPositions, sendUQueue, #queue > 0, tspin})
				end
			else
				updateNextBlocks()
			end
			firstPiece = false
			local lines = GameFunctions.getClearables(grid)
			if lines[1] then
				GameFunctions.clearLines(lines, grid, gameGrid)
				combo = combo + 1
				sumLines = GameFunctions.getNoLines(grid, #lines, combo, tspin, lastBlock and lastBlock == nextShapes[index-1])
				attack = attack + sumLines
				if #queue > 0 then
					if sumLines <= #queue then
						GameFunctions.removeQueue(queue, sumLines)
						queueGui(#queue)
					else
						queue = {}
						queueGui(0)
					end
				end
				lastBlock = nextShapes[index - 1]
				SoundModule.playSound("combo", combo)
			else
				if not hold then
					lastBlock = nil
					combo = 0
					if not firstPiece then
						SoundModule.playSound("place", nil)
					end
				end
				if #queue > 0 and not hold then
					queue = GameFunctions.trimQueue(queue)
					boardQueue(queue)
					GameFunctions.sendLines(queue, grid, bottom)
					receive = receive + #queue
					queue = {}
					queueGui(0)
				end
			end
			danger = GameFunctions.alive(grid, danger)
			if not danger and inPractice then
				buttons.practice.Visible = true
				heartbeat:Disconnect()
				return
			end
			newPiece(currentPiece, currentColor, newGrid, 2, currentTexture)
			drawShadow()
			hold = false
			tspin = false
		else
			if tick() - lastAction >= fallTime then
				if canMove(blockPositions, 0, 1) then
					move(0, 1)
					lastAction = tick()
				else
					placed = true
				end
			end
			if not placed then
				processControls()
			end
		end
	end)
end

--Events
GameEvent.OnClientEvent:Connect(function(command, data)
	if command == "start" then
		inPractice = false
		if heartbeat then
			heartbeat:Disconnect()
		end
		startGame(data)
	elseif command == "dead" then
		sendBoard()
		inPractice = true
		buttons.practice.Visible = true
		newGrid.Banner.Visible = true
		updateText(data)
		heartbeat:Disconnect()
	elseif command == "leaderboard" then
		newLeaderboard = game.Workspace:FindFirstChild(gameId).Leaderboard:Clone()
		newLeaderboard.Parent = script.Parent.Background
		heartbeat:Disconnect()
	end
end)

DataTransfer.OnClientEvent:Connect(function(command, data)
	if command == "blocks" then
		nextShapes = data
	--[[elseif command == "updateQueue" then
		queue = data
		if queue then
			queueGui(#queue) 
		end]]
	elseif command == "unclearableQueue" then
		unclearableQueue = data
	elseif command == "fall" then
		forceDescend = DataConfirm:InvokeServer("drop")
	end
end)

function DataBack(command, data)
	if command == "queue" then
		if data then
			queueGui(#data) 
		end
		queue = data 
		return true
	end
end

DataConfirm.OnClientInvoke = DataBack

menuButtons.Play.MouseButton1Down:Connect(function()
	menu.Visible = false
	GameEvent:FireServer("join", gameId)
	inPractice = true
	inLobby = true
	local tempGrid = createGrid(gridSize, playerUI)
	buttons.practice.Visible = true
	tempGrid.Banner.Visible = true 
	tempGrid.Banner.Place.Text = ""
	inMenu = false
	adjustOtherBoards(#game.Workspace:FindFirstChild(gameId):GetChildren() - 1)
end)

menuButtons.Practice.MouseButton1Down:Connect(function()
	inMenu = false
	menu.Visible = false
	inPractice = true
	startGame()
end)

loadSkins()

clock = tick()
otherBoards = RunService.Heartbeat:Connect(function()
	if inLobby and tick() - clock >= 0.2 then
		updateOtherBoards()
		clock = tick()
	end
end)

local clock2, fallingBlocks = tick(), {}
local counter = 2

function randomNum() 
	counter = counter % 2 + 1
	local ranges = {{2, 22}, {67, 87}}
	return math.random(ranges[counter][1], ranges[counter][2])/100
end

menuAnimation = RunService.Heartbeat:Connect(function()
	if inMenu then
		if tick() - clock2 >= 2 then
			local fallingBlock = UIAssets.FallingBlock:Clone()
			fallingBlock.Parent = menu.Animations
			fallingBlock.Position = UDim2.new(randomNum(), 0, -0.2, 0)
			fallingBlock.Image = SkinData.getRandomImage()
			local goal = {}
			goal.Position = UDim2.new(fallingBlock.Position.X.Scale, 0, 1, 0)
			local tween = TS:Create(fallingBlock, TweenInfo.new(10, 0), goal)
			tween:Play()
			clock2 = tick()
			table.insert(fallingBlocks, {fallingBlock, clock2})
		end
		if fallingBlocks[1] and tick() - fallingBlocks[1][2] >= 10 then
			fallingBlocks[1][1]:Destroy()
			table.remove(fallingBlocks, 1)
		end
	end
end)