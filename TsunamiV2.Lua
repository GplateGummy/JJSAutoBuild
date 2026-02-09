local Build = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/GplateGummy/JJSAutoBuild/refs/heads/main/BuildModule.Lua"))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DebugRemote = ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("DebugService"):WaitForChild("RE"):WaitForChild("Debug")

local PartsData = {
	[1] = {
		[1] = "Wedge",
		[2] = Vector3.new(30.5, -19.25, 0),
		[3] = Vector3.new(90, 0, -90),
		[4] = Vector3.new(500, 16, 7)
	},
	[2] = {
		[1] = "Wedge",
		[2] = Vector3.new(17.5, -12.25, 0),
		[3] = Vector3.new(90, 0, -90),
		[4] = Vector3.new(500, 10, 7)
	},
	[3] = {
		[1] = "Wedge",
		[2] = Vector3.new(6.5, -0.25, 0),
		[3] = Vector3.new(90, 0, -90),
		[4] = Vector3.new(500, 12, 17)
	},
	[4] = {
		[1] = "Wedge",
		[2] = Vector3.new(-4.5, 12.25, 0),
		[3] = Vector3.new(90, 0, -90),
		[4] = Vector3.new(500, 10, 8)
	},
	[5] = {
		[1] = "Part",
		[2] = Vector3.new(-5, -12.25, 0),
		[3] = Vector3.new(0, 0, 0),
		[4] = Vector3.new(35, 7, 500)
	},
	[6] = {
		[1] = "Part",
		[2] = Vector3.new(-2, -19.25, 0),
		[3] = Vector3.new(0, 0, 0),
		[4] = Vector3.new(49, 7, 500)
	},
	[7] = {
		[1] = "Part",
		[2] = Vector3.new(-11, -0.25, 0),
		[3] = Vector3.new(0, 0, 0),
		[4] = Vector3.new(23, 17, 500)
	},
	[8] = {
		[1] = "Wedge",
		[2] = Vector3.new(-17.5, 19.25, 0),
		[3] = Vector3.new(90, 0, -90),
		[4] = Vector3.new(500, 16, 6)
	},
	[9] = {
		[1] = "Part",
		[2] = Vector3.new(-16, 12.25, 0),
		[3] = Vector3.new(0, 0, 0),
		[4] = Vector3.new(13, 8, 500)
	},
	[10] = {
		[1] = "Wedge",
		[2] = Vector3.new(-24, 11.25, 0),
		[3] = Vector3.new(180, 90, 0),
		[4] = Vector3.new(500, 10, 3)
	},
	[11] = {
		[1] = "Wedge",
		[2] = Vector3.new(-24.5, -10.75, 0),
		[3] = Vector3.new(90, 0, 90),
		[4] = Vector3.new(500, 4, 10)
	},
	[12] = {
		[1] = "Wedge",
		[2] = Vector3.new(-27.5, 19.25, 0),
		[3] = Vector3.new(-90, 0, 90),
		[4] = Vector3.new(500, 4, 6)
	},
	[13] = {
		[1] = "Wedge",
		[2] = Vector3.new(-31.5, -19.25, 0),
		[3] = Vector3.new(0, 90, 0),
		[4] = Vector3.new(500, 7, 10)
	}
}

local START_POS = Vector3.new(400, 25, 0)
local GOAL_POS = Vector3.new(-400, 25, 0)
local LIFE_SPAN = 8
local NETWORK_RATE = 0.02

local WrappedParts = {}
for i, data in ipairs(PartsData) do
	local p = Build.Instance.new(data[1])
	if p then
		p.Size = data[4]
		p.Color = Color3.fromRGB(60, 90, 255)
		p.Material = Enum.Material.Glass
		p.Transparency = 0.5
		p.Breakable = false
		p.CanCollide = false
		WrappedParts[i] = p
	end
end

local timeElapsed = 0
local lastUpdate = 0
local connection

connection = RunService.Heartbeat:Connect(function(dt)
	timeElapsed += dt
	local alpha = math.min(timeElapsed / LIFE_SPAN, 1)

	local currentOffset = START_POS:Lerp(GOAL_POS, alpha)

	lastUpdate += dt
	if lastUpdate >= NETWORK_RATE then
		lastUpdate = 0
		for i, p in ipairs(WrappedParts) do
			local data = PartsData[i]
			local relPos = data[2]
			local relRot = data[3]
			p.CFrame = CFrame.new(currentOffset + relPos) * CFrame.Angles(math.rad(relRot.X), math.rad(relRot.Y), math.rad(relRot.Z))
		end
	end

	if alpha >= 1 then
		connection:Disconnect()
		for _, p in ipairs(WrappedParts) do p:Destroy() end
		return
	end

	for _, Player in ipairs(game:GetService("Players"):GetPlayers()) do
		local char = Player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			for i, p in ipairs(WrappedParts) do
				local data = PartsData[i]
				local size = data[4]
				local relPos = currentOffset + data[2]
				local cf = CFrame.new(relPos) * CFrame.Angles(math.rad(data[3].X), math.rad(data[3].Y), math.rad(data[3].Z))

				local localHRP = cf:PointToObjectSpace(hrp.Position)
				if math.abs(localHRP.X) <= size.X / 2 and math.abs(localHRP.Y) <= size.Y / 2 and math.abs(localHRP.Z) <= size.Z / 2 then
					DebugRemote:FireServer("Kill", Player)
					break
				end
			end
		end
	end
end)
