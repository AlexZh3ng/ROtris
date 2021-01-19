local player = game.Players.LocalPlayer
local main = script.Parent.Stats
local body = script.Parent.Stats.Body

local stats = player:WaitForChild("Stats")

function update()
	body.Games.Text = "Games Played: "..stats.Game.Value
	body.Wins.Text = "Games Won: "..stats.Win.Value
	body.Lines.Text = "Lines Sent: "..stats.Line.Value
	body.Received.Text = "Lines Received: "..stats.Received.Value
	body.Placed.Text = "Blocks Placed: "..stats.Placed.Value
	body.MaxCombo.Text = "Max Combo: "..stats.MaxCombo.Value
	body.MaxLines.Text = "Max Lines Sent: "..stats.MaxLines.Value
end

stats.Save.Changed:Connect(update)

script.Parent.Menu.Buttons.Stats.MouseButton1Click:Connect(function()
	main.Visible = true
end)

main.Title.Exit.MouseButton1Click:Connect(function()
	main.Visible = false
end)

update()	