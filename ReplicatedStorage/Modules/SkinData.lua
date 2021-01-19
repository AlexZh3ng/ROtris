local module = {}
--local shapes = {t, o, i, lBlue, lOrange, zGreen, zRed}
local blocks = {
{"http://www.roblox.com/asset/?id=5022698277", "http://www.roblox.com/asset/?id=5022696248", "http://www.roblox.com/asset/?id=5022697701", "http://www.roblox.com/asset/?id=5022697318", "http://www.roblox.com/asset/?id=5022696642", "http://www.roblox.com/asset/?id=5022695879", "http://www.roblox.com/asset/?id=5022695511"};
{"rbxassetid://5200537368", "rbxassetid://5200537113", "rbxassetid://5200536371", "rbxassetid://5200805646", "rbxassetid://5200536808", "rbxassetid://5200818725", "rbxassetid://5200537915"};
{"rbxassetid://5205095838", "rbxassetid://5205096561", "rbxassetid://5205095142", "rbxassetid://5205096235", "rbxassetid://5205095526", "rbxassetid://5205094572", "rbxassetid://5407059767"};
{"rbxassetid://5205101453", "rbxassetid://5205102053", "rbxassetid://5205100953", "rbxassetid://5205100446", "rbxassetid://5205101212", "rbxassetid://5205100715", "rbxassetid://5205101730"};
{"rbxassetid://5406912134", "rbxassetid://5406913129", "rbxassetid://5406911167", "rbxassetid://5406910218", "rbxassetid://5406911602", "rbxassetid://5406910665", "rbxassetid://5406912581"};
{"rbxassetid://5406919886", "rbxassetid://5406920893", "rbxassetid://5406918981", "rbxassetid://5451030403", "rbxassetid://5451030516", "rbxassetid://5406918563", "rbxassetid://5406920429"};
	{"rbxassetid://5406929924", "rbxassetid://5406930937", "rbxassetid://5406928589", "rbxassetid://5406927704", "rbxassetid://5406929439", "rbxassetid://5406928134", "rbxassetid://5406930392"};
	{"rbxassetid://5406941420", "rbxassetid://5406941794", "rbxassetid://5406941100", "rbxassetid://5406940829", "rbxassetid://5406941278", "rbxassetid://5406940960", "rbxassetid://5406941611"};
}

local textures = {
{"", "", "", "", "", "", "", "", ""};
{"rbxassetid://5200535277", "rbxassetid://5200533914", "rbxassetid://5200534702", "rbxassetid://5200535033", "rbxassetid://5200533679", "rbxassetid://5200534422", "rbxassetid://5200533316", "rbxassetid://5200535492", "rbxassetid://5200535720"};
{"rbxassetid://5205092534", "rbxassetid://5205091418", "rbxassetid://5205092037", "rbxassetid://5205092284", "rbxassetid://5205091222", "rbxassetid://5205091816", "rbxassetid://5205090973", "rbxassetid://5205092777", "rbxassetid://5205093017"};
{"rbxassetid://5205098851", "rbxassetid://5205097974", "rbxassetid://5205098379", "rbxassetid://5205098605", "rbxassetid://5205097759", "rbxassetid://5205098189", "rbxassetid://5205097531", "rbxassetid://5205099209", "rbxassetid://5205099479"};
{"rbxassetid://5406908879", "rbxassetid://5406906828", "rbxassetid://5406907958", "rbxassetid://5406908366", "rbxassetid://5406906404", "rbxassetid://5406907332", "rbxassetid://5406905985", "rbxassetid://5406909272", "rbxassetid://5406909751"};
{"rbxassetid://5406916888", "rbxassetid://5406915257", "rbxassetid://5406916129", "rbxassetid://5406916501", "rbxassetid://5406914802", "rbxassetid://5406915704", "rbxassetid://5406914314", "rbxassetid://5406917309", "rbxassetid://5406917738"};
	{"rbxassetid://5406924993", "rbxassetid://5406922518", "rbxassetid://5406924228", "rbxassetid://5406924616", "rbxassetid://5406922088", "rbxassetid://5406923712", "rbxassetid://5406921679", "rbxassetid://5406926756", "rbxassetid://5406927229"};
	{"rbxassetid://5406940393", "rbxassetid://5406939902", "rbxassetid://5406940196", "rbxassetid://5406940297", "rbxassetid://5406939782", "rbxassetid://5406940038", "rbxassetid://5406939668", "rbxassetid://5406940513", "rbxassetid://5406940657"}
}

function module.getBlocks(i)
	return blocks[i]
end

function module.getTextures(i)
	return textures[i]
end

function module.getNumSkins()
	return #blocks
end

function module.getProductIds()
	local ids = {"", 1042441748, 1042442218, 1042442502, 1042442839, 1042443114, 1042443511, 1042443855}
	return ids
end

function module.getRandomImage()
	return blocks[math.random(1, #blocks)][math.random(1, 7)]
end

return module
