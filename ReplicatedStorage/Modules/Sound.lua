local module = {}

local sounds = game.ReplicatedStorage.Sound

local combos = sounds.Combo
local comboNames = {"e4", "f#4", "g#4", "a4", "b4", "c#5", "d#5", "e5"}

local place = sounds.Place

local start = sounds.Start
local startNames = {"c3", "c4"}

function module.playSound(soundType, num)
	if soundType == "combo" then
		if num >= 8 then
			combos["e5"]:Play()
		else
			combos:FindFirstChild(comboNames[num]):Play()
		end
	elseif soundType == "place" then
		place:Play()
	elseif soundType == "start" then
		start:FindFirstChild(startNames[num]):Play()
	end
end

return module
