-- Polarcanse Anti-Cheat System  [Client-Side]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local rem = game.ReplicatedStorage:WaitForChild("PolarcanseRemotes"):WaitForChild("ClientReport")

local function watch(char)
	local hum = char:WaitForChild("Humanoid")
	local baseSpeed = hum.WalkSpeed
	local baseJump = hum.JumpPower

	while hum.Parent do
		task.wait(0.5)

		if hum.WalkSpeed > baseSpeed + 15 then
			rem:FireServer(" Speed Hacking")
		end

		if hum.JumpPower > baseJump + 18 then
			rem:FireServer(" Jump Hacking")
		end
	end
end

player.CharacterAdded:Connect(watch)
if player.Character then
	watch(player.Character)
end
