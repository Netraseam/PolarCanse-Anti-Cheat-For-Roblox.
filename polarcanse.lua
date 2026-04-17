--Polarcanse Anti-Cheat System v.4.5-- ← The Code Name (Optinal)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:FindFirstChild("PolarcanseRemotes") or Instance.new("Folder")
Remotes.Name = "PolarcanseRemotes"
Remotes.Parent = ReplicatedStorage

local SystemMsg = Remotes:FindFirstChild("SystemMessage") or Instance.new("RemoteEvent")
SystemMsg.Name = "SystemMessage"
SystemMsg.Parent = Remotes


local ClientReport = Remotes:FindFirstChild("ClientReport") or Instance.new("RemoteEvent")
ClientReport.Name = "ClientReport"
ClientReport.Parent = Remotes

local Flags, lastPos, airTime, noclipTicks, spawnTime, lastJump, speedBuffer, respawnSafe = {}, {}, {}, {}, {}, {}, {}, {}

local FLAG_KICK = 3
local FLAG_DECAY_TIME = 10
local MAX_SPEED = 95
local MAX_AIR_TIME = 5.5
local SPAWN_GRACE = 4
local RESPAWN_GRACE = 4
local JUMP_GRACE = 0.8
local NOCOLLIDE_TICKS = 12
local TELEPORT_DIST = 85
local SPEED_BUFFER_LIMIT = 1

local function flag(plr, reason, weight)
	weight = weight or 1
	Flags[plr] = (Flags[plr] or 0) + weight
	if Flags[plr] >= FLAG_KICK then

		plr:Kick("Exploit detected: "..reason)

	end
end local C = require(game.ReplicatedStorage:WaitForChild("_polarcanse_moudle"))C.P()
task.spawn(function()
	while true do
		task.wait(FLAG_DECAY_TIME)
		for plr, count in pairs(Flags) do if count > 0 then Flags[plr] -= 1 end end
	end
end)

local function setupPlayer(plr)
	spawnTime[plr] = os.clock()
	respawnSafe[plr] = os.clock() + RESPAWN_GRACE
	plr.CharacterAdded:Connect(function(char)

			local hum = char:WaitForChild("Humanoid")
			respawnSafe[plr] = os.clock() + RESPAWN_GRACE
			lastPos[plr], airTime[plr], noclipTicks[plr], speedBuffer[plr], lastJump[plr] = nil, 0, 0, 0, nil

			hum.Died:Connect(function()
				respawnSafe[plr] = os.clock() + RESPAWN_GRACE
			end)

			hum.Jumping:Connect(function()
				lastJump[plr] = os.clock()
			end)

		respawnSafe[plr] = os.clock() + RESPAWN_GRACE
		lastPos[plr], airTime[plr], noclipTicks[plr], speedBuffer[plr] = nil, 0, 0, 0
		hum.Died:Connect(function() respawnSafe[plr] = os.clock() + RESPAWN_GRACE end)
		hum.Jumping:Connect(function() lastJump[plr] = os.clock() end)
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(plr)
	Flags[plr], lastPos[plr], airTime[plr], noclipTicks[plr], spawnTime[plr], lastJump[plr], speedBuffer[plr], respawnSafe[plr] = nil,nil,nil,nil,nil,nil,nil,nil
end)

RunService.Heartbeat:Connect(function(dt)
	for _, plr in ipairs(Players:GetPlayers()) do
		if os.clock() < (respawnSafe[plr] or 0) then continue end
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local pos = root.Position
		local last = lastPos[plr]

		if last then
			local dist = (pos - last).Magnitude
			local speed = dist / math.max(dt,0.03)
			if speed > MAX_SPEED then
				speedBuffer[plr] = (speedBuffer[plr] or 0) + 1
				if speedBuffer[plr] > SPEED_BUFFER_LIMIT then flag(plr,"Speed",1) end
			else speedBuffer[plr]=0 end
			if dist > TELEPORT_DIST then flag(plr,"Teleport",2) end
		end
		lastPos[plr]=pos

		local recentlyJumped = lastJump[plr] and os.clock()-lastJump[plr]<JUMP_GRACE
		if not recentlyJumped then
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {char}
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			local grounded = workspace:Raycast(root.Position,Vector3.new(0,-8,0),rayParams)
			if grounded then airTime[plr]=0 else
				airTime[plr]=(airTime[plr] or 0)+dt
				if airTime[plr]>MAX_AIR_TIME then flag(plr,"Fly", 1) end
			end
		else airTime[plr]=0 end
	end
end)

RunService.Stepped:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if os.clock() < (respawnSafe[plr] or 0) then continue end
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local touched=false
		for _, part in ipairs(workspace:GetPartsInPart(root)) do
			if part.CanCollide and not part:IsDescendantOf(char) then touched=true break end
		end

		if touched then
			
			noclipTicks[plr] = (noclipTicks[plr] or 0)+1
			if noclipTicks[plr] > NOCOLLIDE_TICKS then flag(plr,"Noclip",1) end
		else noclipTicks[plr]=0 end
	end
end)

ClientReport.OnServerEvent:Connect(function(plr, tag) flag(plr,"Client:"..tostring(tag),1) end)
