local Build = loadstring(game:HttpGet("https://raw.githubusercontent.com/GplateGummy/JJSAutoBuild/refs/heads/main/BuildModule.Lua"))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugRemote = ReplicatedStorage:WaitForChild("Knit"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("DebugService"):WaitForChild("RE"):WaitForChild("Debug")

local PartsData = {
	{ "Wedge", Vector3.new(30.5, -19.25, 0),  Vector3.new(90, 0, -90), Vector3.new(500, 16, 7) },
	{ "Wedge", Vector3.new(17.5, -12.25, 0),  Vector3.new(90, 0, -90), Vector3.new(500, 10, 7) },
	{ "Wedge", Vector3.new(6.5, -0.25, 0),    Vector3.new(90, 0, -90), Vector3.new(500, 12, 17) },
	{ "Wedge", Vector3.new(-4.5, 12.25, 0),   Vector3.new(90, 0, -90), Vector3.new(500, 10, 8) },
	{ "Part",  Vector3.new(-5, -12.25, 0),    Vector3.new(0, 0, 0),    Vector3.new(35, 7, 500) },
	{ "Part",  Vector3.new(-2, -19.25, 0),    Vector3.new(0, 0, 0),    Vector3.new(49, 7, 500) },
	{ "Part",  Vector3.new(-11, -0.25, 0),    Vector3.new(0, 0, 0),    Vector3.new(23, 17, 500) },
	{ "Wedge", Vector3.new(-17.5, 19.25, 0),  Vector3.new(90, 0, -90), Vector3.new(500, 16, 6) },
	{ "Part",  Vector3.new(-16, 12.25, 0),    Vector3.new(0, 0, 0),    Vector3.new(13, 8, 500) },
	{ "Wedge", Vector3.new(-24, 11.25, 0),    Vector3.new(180, 90, 0), Vector3.new(500, 10, 3) },
	{ "Wedge", Vector3.new(-24.5, -10.75, 0), Vector3.new(90, 0, 90),  Vector3.new(500, 4, 10) },
	{ "Wedge", Vector3.new(-27.5, 19.25, 0),  Vector3.new(-90, 0, 90), Vector3.new(500, 4, 6) },
	{ "Wedge", Vector3.new(-31.5, -19.25, 0), Vector3.new(0, 90, 0),   Vector3.new(500, 7, 10) }
}

local StartPos = Vector3.new(400, 21, 0)
local GoalPos = Vector3.new(-400, 21, 0)
local LifeSpan = 8
local NetworkRate = 0.02

local FloodStartY = -20
local FloodGoalY = 2
local FloodMaxLevel = math.abs(FloodGoalY - FloodStartY)

local WrappedParts = {}

for I, Data in ipairs(PartsData) do
	local P = Build.Instance.new(Data[1])
	if P then
		P.Size = Data[4]
		P.Color = Color3.fromRGB(60, 90, 255)
		P.Material = Enum.Material.Glass
		P.Transparency = 0.5
		P.Breakable = false
		P.CanCollide = false
		WrappedParts[I] = P
	end
end

local FloodPart = Build.Instance.new("Part")
FloodPart.Size = Vector3.new(600, 0.1, 600)
FloodPart.Color = Color3.fromRGB(40, 70, 200)
FloodPart.Material = Enum.Material.Glass
FloodPart.Transparency = 0.6
FloodPart.CanCollide = false
FloodPart.Position = Vector3.new(0, FloodStartY, 0)

local TimeElapsed = 0
local LastUpdate = 0
local Connection = nil

Connection = RunService.Heartbeat:Connect(function(Dt)
	TimeElapsed += Dt
	local Alpha = math.min(TimeElapsed / LifeSpan, 1)
	local CurrentOffset = StartPos:Lerp(GoalPos, Alpha)
	local CurrentLevel = Alpha * FloodMaxLevel
	local FloodsIze = Vector3.new(600, CurrentLevel, 600)
	local FloodPos = Vector3.new(0, FloodStartY + (CurrentLevel / 2), 0)
	LastUpdate += Dt
	if LastUpdate >= NetworkRate then
		LastUpdate = 0
		for I, P in ipairs(WrappedParts) do
			local Data = PartsData[I]
			P.CFrame = CFrame.new(CurrentOffset + Data[2]) * CFrame.Angles(math.rad(Data[3].X), math.rad(Data[3].Y), math.rad(Data[3].Z))
		end
		FloodPart.Size = FloodsIze
		FloodPart.Position = FloodPos
	end
	if Alpha >= 1 then
		Connection:Disconnect()
		for _, P in ipairs(WrappedParts) do P:Destroy() end
		FloodPart:Destroy()
		return
	end
	for _, Player in ipairs(Players:GetPlayers()) do
		local Char = Player.Character
		local HrP = Char and Char:FindFirstChild("HumanoidRootPart")
		if HrP then
			local Killed = false
			for I, P in ipairs(WrappedParts) do
				local Data = PartsData[I]
				local Size = Data[4]
				local Cf = CFrame.new(CurrentOffset + Data[2]) * CFrame.Angles(math.rad(Data[3].X), math.rad(Data[3].Y), math.rad(Data[3].Z))
				local LocalHrp = Cf:PointToObjectSpace(HrP.Position)
				if math.abs(LocalHrp.X) <= Size.X / 2 and math.abs(LocalHrp.Y) <= Size.Y / 2 and math.abs(LocalHrp.Z) <= Size.Z / 2 then
					DebugRemote:FireServer("Kill", Player)
					Killed = true
					break
				end
			end
			if not Killed then
				local RelFlood = HrP.Position.Y - (FloodPos.Y + (FloodsIze.Y / 2))
				if RelFlood < 0 and math.abs(HrP.Position.X) <= 300 and math.abs(HrP.Position.Z) <= 300 then
					DebugRemote:FireServer("Kill", Player)
				end
			end
		end
	end
end)
