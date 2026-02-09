local BuildModule = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuildEvent")

local Batch = { Move = {}, Color = {}, Material = {}, Transparency = {}, Collide = {}, Breakable = {}, LogicProp = {}, Delete = {} }
local isQueued = false

local Map = workspace:WaitForChild("Map")
local CoreBuildable = Map:WaitForChild("Core"):WaitForChild("Buildable")
local DestructibleBuildable = Map:WaitForChild("Destructible"):WaitForChild("Buildable")

local usedPositions = {}

local function getPosKey(vec)
	return string.format("%.2f,%.2f,%.2f", vec.X, vec.Y, vec.Z)
end

local function getRandomPosition()
	local position
	local attempts = 0
	repeat
		position = Vector3.new(
			math.random(-500, 500), 
			math.random(1500, 2500), 
			math.random(-500, 500)
		)
		attempts += 1
	until not usedPositions[getPosKey(position)] or attempts > 100
	
	usedPositions[getPosKey(position)] = true
	return position
end

local function fireBatch()
	isQueued = false

	if next(Batch.Move) then
		local moveEntries = {}
		for part, data in pairs(Batch.Move) do 
			table.insert(moveEntries, { part, data.cf, data.size }) 
		end
		BuildEvent:FireServer("Move", moveEntries)
	end

	for action, groups in pairs(Batch) do
		if action ~= "Move" and action ~= "LogicProp" and action ~= "Delete" then
			for val, parts in pairs(groups) do
				if #parts > 0 then
					if action == "Collide" then
						BuildEvent:FireServer("Collide", parts, nil, val)
					else
						BuildEvent:FireServer(action, parts, val)
					end
				end
			end
		end
	end

	for propName, values in pairs(Batch.LogicProp) do
		for val, parts in pairs(values) do
			BuildEvent:FireServer("LogicProp", parts, propName, val)
		end
	end

	if #Batch.Delete > 0 then
		BuildEvent:FireServer("Delete", Batch.Delete)
	end

	for k in pairs(Batch) do
		Batch[k] = {}
	end
end

local function queue()
	if not isQueued then
		isQueued = true
		task.defer(fireBatch)
	end
end

function BuildModule.Wrap(realPart)
	local wrapper = {}
	local state = {
		part = realPart,
		cf = realPart:IsA("BasePart") and realPart.CFrame or CFrame.new(),
		size = realPart:IsA("BasePart") and realPart.Size or Vector3.new(1, 1, 1)
	}

	setmetatable(wrapper, {
		__index = function(_, key)
			if key == "Destroy" or key == "Delete" then
				return function()
					queue()
					table.insert(Batch.Delete, realPart)
				end
			end
			return state[key] or realPart[key]
		end,
		__newindex = function(_, key, val)
			queue()
			if key == "CFrame" or key == "Position" or key == "Orientation" or key == "Rotation" then
				if key == "CFrame" then
					state.cf = val
				elseif key == "Position" then
					local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = state.cf:GetComponents()
					state.cf = CFrame.new(val.X, val.Y, val.Z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
				elseif key == "Orientation" then
					state.cf = CFrame.new(state.cf.Position) * CFrame.Angles(math.rad(val.X), math.rad(val.Y), math.rad(val.Z))
				elseif key == "Rotation" then
					state.cf = CFrame.new(state.cf.Position) * CFrame.Angles(val.X, val.Y, val.Z)
				end
				Batch.Move[realPart] = { cf = state.cf, size = state.size }
			elseif key == "Size" then
				state.size = val
				Batch.Move[realPart] = { cf = state.cf, size = state.size }
			elseif key == "Color" then
				Batch.Color[val] = Batch.Color[val] or {}
				table.insert(Batch.Color[val], realPart)
			elseif key == "Material" then
				local mName = typeof(val) == "EnumItem" and val.Name or val
				Batch.Material[mName] = Batch.Material[mName] or {}
				table.insert(Batch.Material[mName], realPart)
			elseif key == "CanCollide" then
				Batch.Collide[val] = Batch.Collide[val] or {}
				table.insert(Batch.Collide[val], realPart)
			elseif key == "Transparency" then
				local tVal = tostring(val)
				Batch.Transparency[tVal] = Batch.Transparency[tVal] or {}
				table.insert(Batch.Transparency[tVal], realPart)
			elseif key == "Breakable" then
				Batch.Breakable[val] = Batch.Breakable[val] or {}
				table.insert(Batch.Breakable[val], realPart)
			else
				local propKey = tostring(val)
				Batch.LogicProp[key] = Batch.LogicProp[key] or {}
				Batch.LogicProp[key][propKey] = Batch.LogicProp[key][propKey] or {}
				table.insert(Batch.LogicProp[key][propKey], realPart)
			end
		end
	})
	return wrapper
end

local function waitForPartAtPosition(position, timeout)
	local foundPart = nil
	local start = tick()
	
	local function checkPart(part)
		if part:IsA("BasePart") and (part.Position - position).Magnitude < 0.1 then
			foundPart = part
		end
	end
	
	local c1 = CoreBuildable.ChildAdded:Connect(checkPart)
	local c2 = DestructibleBuildable.ChildAdded:Connect(checkPart)
	
	BuildEvent:FireServer("Create", "Part", position)
	
	repeat task.wait() until foundPart or (tick() - start) > timeout
	
	c1:Disconnect()
	c2:Disconnect()
	usedPositions[getPosKey(position)] = nil
	
	return foundPart
end

BuildModule.Instance = {
	new = function(className)
		local spawnPos = getRandomPosition()
		local realPart = waitForPartAtPosition(spawnPos, 2)
		if realPart then
			return BuildModule.Wrap(realPart)
		end
		warn("BuildModule: Part creation failed at", spawnPos)
		return nil
	end
}

setmetatable(BuildModule, { __call = function(_, part) return BuildModule.Wrap(part) end })

return BuildModule
