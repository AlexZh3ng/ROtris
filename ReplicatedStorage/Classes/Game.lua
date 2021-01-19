local Game = {}
Game.__index = Game

function Game.new(gameID, creator) 
	local gameFolder = Instance.new("Folder", game.Workspace)
	gameFolder.Name = gameID
	local self = {
	["id"] = gameID,
	["creator"] = creator,
	["players"] = {},
	["alivePlayers"] = {},
	["run"] = false,
	["timer"] = false,
	["startTime"] = nil,
	["shapes"] = nil,
	["folder"] = gameFolder,
	["leaderboard"] = {},
	["garbage"] = 0,
	["lastGarbage"] = tick(),
	["gameEnded"] = tick(),
	["firstGarbage"] = false,
	["fallTime"] = 25
	}
	
	setmetatable(self, Game)
	return self
end

function Game:Reset()
	self.garbage = 0
	self.lastGarbage = tick()
	self.timer = false
	self.run = true
	self.leaderboard = {}
	self.firstGarbage = false
	self.fallTime = 25
end

function Game:AddPlayer(player)
	table.insert(self.players, player)
end

function Game:RemovePlayer(player)
	local playerExist = table.find(self.players, player)
	local playerBoard = self.folder:FindFirstChild(player.Name)
	if playerBoard then
		playerBoard:Destroy()
	end
	if playerExist then
		table.remove(self.players, playerExist)
		local playerAlive = table.find(self.alivePlayers, player) 
		if playerAlive then
			table.remove(self.alivePlayers, playerExist)
		end
	end
end

function Game:AppendLeaderboard(player)
	--[[local inLeaderboard = table.find(self.leaderboard, player) 
	if inLeaderboard then
		table.remove(self.leaderboard, inLeaderboard)
	end]]
	table.insert(self.leaderboard, player)
end

function Game:PlayerDied(player)
	local playerExist = table.find(self.alivePlayers, player)
	if playerExist then
		table.remove(self.alivePlayers, playerExist)
	end
end

function Game:SetShapes(shapes)
	self.shapes = shapes
end

function Game:GetPlayers()
	local alivePlayers =  {}
	for i, v in pairs(self.players) do
		table.insert(alivePlayers, v)
	end
	return alivePlayers
end
return Game
