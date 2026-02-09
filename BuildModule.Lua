local BuildModule = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("BuildEvent")

local Batch = { Move = {}, Color = {}, Material = {}, Transparency = {}, Collide = {}, Breakable = {}, LogicProp = {}, Delete = {} }
local isQueued = false

local function fireBatch()
    isQueued = false

    if next(Batch.Move) then
        local moveEntries = {}
        for part, data in pairs(Batch.Move) do table.insert(moveEntries, { part, data.cf, data.size }) end
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
            BuildEvent:FireServer(
                "LogicProp", parts, propName, val)
        end
    end

    if #Batch.Delete > 0 then
        BuildEvent:FireServer("Delete", Batch.Delete)
    end

    for k, v in pairs(Batch) do
        Batch[k] = {}
    end

    Batch.LogicProp = {}
end

local function queue()
    if not isQueued then
        isQueued = true
        task.defer(fireBatch)
    end
end

local function wrap(realPart)
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)

    local state = {
        cf = (typeof(realPart) ~= "string" and realPart:IsA("BasePart")) and realPart.CFrame or CFrame.new(),
        size = (typeof(realPart) ~= "string" and realPart:IsA("BasePart")) and
            realPart.Size or Vector3.new(1, 1, 1)
    }

    mt.__index = realPart
    mt.__newindex = function(_, key, val)
        queue()
        if key == "CFrame" or key == "Position" or key == "Orientation" or key == "Rotation" then
            if key == "CFrame" then
                state.cf = val
            elseif key == "Position" then
                state.cf = CFrame.new(val) *
                    state.cf.Rotation
            elseif key == "Orientation" or key == "Rotation" then
                state.cf = state.cf *
                    CFrame.Angles(math.rad(val.X), math.rad(val.Y), math.rad(val.Z))
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
            Batch.Transparency[tostring(val)] = Batch.Transparency[tostring(val)] or {}
            table.insert(Batch.Transparency[tostring(val)], realPart)
        elseif key == "Breakable" then
            Batch.Breakable[val] = Batch.Breakable[val] or {}
            table.insert(Batch.Breakable[val], realPart)
        else
            Batch.LogicProp[key] = Batch.LogicProp[key] or {}
            Batch.LogicProp[key][tostring(val)] = Batch.LogicProp[key][tostring(val)] or {}
            table.insert(Batch.LogicProp[key][tostring(val)], realPart)
        end
    end

    return proxy
end

BuildModule.Instance = {
    new = function(className, pos)
        BuildEvent:FireServer("Create", className, pos or Vector3.new(0, 0, 0))
        return wrap(className)
    end
}

function BuildModule:Delete(part)
    queue()
    table.insert(Batch.Delete, part)
end

setmetatable(BuildModule, { __call = function(_, part) return wrap(part) end })

return BuildModule
