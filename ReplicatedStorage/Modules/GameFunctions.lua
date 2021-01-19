local module = {}

--combo starts at 1
local combo = {0, 1, 1, 1, 2, 2, 3, 3, 4, 4, 4, 5}
local clears = {0, 1, 2, 4}
local tspinCombo = {2, 3, 4}

--Shared
function module.newLine(i, grid, gameGrid) 
	table.insert(grid, i, {})
	if gameGrid then
		table.insert(gameGrid, i, {})
	end
	for j = 1, 10 do 
		table.insert(grid[i], ".")
		if gameGrid then
			table.insert(gameGrid[i], " ")	
		end
	end
end

function module.placePieces(blockPositions, grid, gameGrid) 
	local tempDead = false
	for i = 1, 4 do 
		if not gameGrid and grid[blockPositions[i][1]][blockPositions[i][2]] ~= "." then
			--print("ERROR FROM SERVER!!!!!!!!")
			print(blockPositions[i][1], blockPositions[i][2])
			tempDead = true
		end
		grid[blockPositions[i][1]][blockPositions[i][2]] = "1"
		if gameGrid then
			gameGrid[blockPositions[i][1]][blockPositions[i][2]].placed = true
		end
	end
	return tempDead
end

--Shared
function module.getClearables(grid) 
	local clearables = {}
	for i = 24, 1, -1 do
		if not table.find(grid[i], ".") and not table.find(grid[i], "2")then 
			table.insert(clearables, i)
		end
	end
	return clearables
end

--Shared 
function module.clearLines(lines, grid, gameGrid) 
	if gameGrid then
		local down = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
		for i, line in pairs(lines) do
			--adds to down table
			for i = line - 1, 1, -1 do
				if not table.find(lines, i) then
					down[i] = down[i] + 1
				end
			end
			--destroy blocks 
			for i = 1, 10 do
				gameGrid[line][i].block:Destroy() 
			end
		end
		--Moves blocks down
		for i = 1, 24 do
			if down[i] > 0 then 
				for j = 1, 10 do
					if grid[i][j] == "1" then
						gameGrid[i][j]:addPosition(0, down[i])
					end
				end
			end
		end
	end
	--Change data structures
	table.sort(lines) 
	for i, line in pairs(lines) do
		table.remove(grid, line)
		if gameGrid then
			table.remove(gameGrid, line)
		end
		module.newLine(1, grid, gameGrid)
	end
end

function module.alive(grid, danger)
	local count = 0 
	for i = 1, 4 do
		for j = 1, 10 do
			if grid[i][j] == "1" then
				count = count + 1
				if j >= 4 and j <= 7 then 
					return false
				end
			end
		end
	end
	if count - danger == 4 then
		return false
	end
	return count
end

function module.getShapes(times)
	local nextShapes = {}
	for i = 1, times do
		local temp = {1,2,3,4,5,6,7}
		while #temp > 0 do
			local index = math.random(1, #temp)
			table.insert(nextShapes, temp[index])
			table.remove(temp, index)
		end
	end
	return nextShapes
end

function module.addShapes(nextShapes, times)
	for i = 1, times do
		local temp = {1,2,3,4,5,6,7}
		while #temp > 0 do
			local index = math.random(1, #temp)
			table.insert(nextShapes, temp[index])
			table.remove(temp, index)
		end
	end
end

function module.isPerfectClear(grid)
	for i, v in pairs(grid) do 
		if table.find(v, "1") then
			return false
		end
	end
	return true
end

function module.getNoLines(grid, noLines, noCombo, tspin, backtoback)
	local sumLines = 0
	sumLines = sumLines + clears[noLines]
	if noCombo > 12 then
		sumLines = sumLines + 5
	else
		sumLines = sumLines + combo[noCombo]
	end
	if module.isPerfectClear(grid) then
		sumLines = sumLines + 10
	end 
	if backtoback then
		print("BACKTOBACK")
		sumLines = sumLines + 1
	end
	if tspin then
		sumLines = sumLines + tspinCombo[noLines]
	end
	return sumLines
end

function module.sendLines(queue, grid, pos)
	for i = 1, #queue do 
		local newLine = {{"1", "1", "1", "1", "1", "1", "1", "1", "1", "1"}, {"2", "2", "2", "2", "2", "2", "2", "2", "2", "2"}}
		table.remove(grid, 1)
		if queue[i] then
			newLine[1][queue[i]] = "." 
			table.insert(grid, pos, newLine[1])
		else
			table.insert(grid, pos, newLine[2])
		end
	end
end

function module.trimQueue(queue)
	if #queue >= 20 then
		for i = #queue, 21, -1 do 
			table.remove(queue, i)
		end
	end
	return queue
end

function module.removeQueue(queue, sumLines)
	for i = #queue, #queue - sumLines + 1, -1 do 
		table.remove(queue, i)
	end
end

return module
