-- Smooth Teleport Tween with Bypass - Very Smooth & Safe
-- Advanced teleportation system with anti-cheat bypass and smooth movement

-- Service caching for optimal performance
local Services = {
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace")
}

-- Cached references
local LocalPlayer = Services.Players.LocalPlayer
local TweenService = Services.TweenService

-- Teleport configuration
local TeleportConfig = {
    -- Speed settings (lower = slower/safer, higher = faster)
    Speed = 100, -- Units per second
    MaxSpeed = 250, -- Maximum speed limit
    MinSpeed = 50,  -- Minimum speed limit
    
    -- Bypass settings
    BypassEnabled = true,
    ChunkSize = 50, -- Distance per tween chunk for bypass
    ChunkDelay = 0.1, -- Delay between chunks
    
    -- Smoothness settings
    EasingStyle = Enum.EasingStyle.Quint,
    EasingDirection = Enum.EasingDirection.Out,
    
    -- Safety settings
    CollisionCheck = true,
    HeightOffset = 5, -- Safety height above ground
    MaxDistance = 2000, -- Maximum single teleport distance
}

-- State tracking
local activeTweens = {}
local teleportInProgress = false

-- Utility functions
local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function getCharacter()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character, character.HumanoidRootPart
    end
    return nil, nil
end

-- Advanced path calculation with bypass
local function calculatePath(startPos, endPos)
    local distance = getDistance(startPos, endPos)
    local path = {}
    
    if not TeleportConfig.BypassEnabled or distance <= TeleportConfig.ChunkSize then
        -- Direct path for short distances
        table.insert(path, {position = endPos, duration = distance / TeleportConfig.Speed})
        return path
    end
    
    -- Calculate chunks for bypass
    local direction = (endPos - startPos).Unit
    local chunks = math.ceil(distance / TeleportConfig.ChunkSize)
    
    for i = 1, chunks do
        local progress = i / chunks
        local chunkPos = startPos + direction * (distance * progress)
        
        -- Add slight height variation for more natural movement
        if TeleportConfig.CollisionCheck then
            chunkPos = chunkPos + Vector3.new(0, TeleportConfig.HeightOffset, 0)
        end
        
        local chunkDistance = math.min(TeleportConfig.ChunkSize, distance - (i-1) * TeleportConfig.ChunkSize)
        local duration = chunkDistance / TeleportConfig.Speed
        
        table.insert(path, {
            position = chunkPos,
            duration = duration,
            delay = i > 1 and TeleportConfig.ChunkDelay or 0
        })
    end
    
    return path
end

-- Smooth tween creation
local function createSmoothTween(humanoidRootPart, targetCFrame, duration)
    local tweenInfo = TweenInfo.new(
        duration,
        TeleportConfig.EasingStyle,
        TeleportConfig.EasingDirection,
        0, -- No repeat
        false, -- No reverse
        0 -- No delay
    )
    
    return TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
end

-- Safety checks
local function isValidTeleport(startPos, endPos)
    local distance = getDistance(startPos, endPos)
    
    if distance > TeleportConfig.MaxDistance then
        warn("Teleport distance too large:", distance, "units. Max allowed:", TeleportConfig.MaxDistance)
        return false
    end
    
    if distance < 1 then
        warn("Teleport distance too small")
        return false
    end
    
    return true
end

-- Main teleport function with bypass and smoothness
local function TeleportTween(targetPosition, options)
    if teleportInProgress then
        warn("Teleport already in progress")
        return false
    end
    
    -- Get character and validate
    local character, humanoidRootPart = getCharacter()
    if not character or not humanoidRootPart then
        warn("Character or HumanoidRootPart not found")
        return false
    end
    
    -- Handle different input types
    local targetPos
    if typeof(targetPosition) == "Vector3" then
        targetPos = targetPosition
    elseif typeof(targetPosition) == "CFrame" then
        targetPos = targetPosition.Position
    elseif typeof(targetPosition) == "Instance" and targetPosition:IsA("BasePart") then
        targetPos = targetPosition.Position
    else
        warn("Invalid target position type")
        return false
    end
    
    -- Apply options
    options = options or {}
    local speed = options.speed or TeleportConfig.Speed
    local bypassEnabled = options.bypass ~= false -- Default true
    local heightOffset = options.heightOffset or TeleportConfig.HeightOffset
    
    -- Clamp speed
    speed = math.clamp(speed, TeleportConfig.MinSpeed, TeleportConfig.MaxSpeed)
    
    -- Get current position
    local currentPos = humanoidRootPart.Position
    
    -- Safety checks
    if not isValidTeleport(currentPos, targetPos) then
        return false
    end
    
    -- Add height offset if requested
    if heightOffset > 0 then
        targetPos = targetPos + Vector3.new(0, heightOffset, 0)
    end
    
    teleportInProgress = true
    
    -- Calculate path
    local path = calculatePath(currentPos, targetPos)
    
    print("Starting smooth teleport to", targetPos, "with", #path, "chunks")
    
    -- Execute path
    local success = true
    for i, chunk in ipairs(path) do
        if not teleportInProgress then
            success = false
            break
        end
        
        -- Wait for delay if specified
        if chunk.delay and chunk.delay > 0 then
            task.wait(chunk.delay)
        end
        
        -- Create and play tween
        local targetCFrame = CFrame.new(chunk.position)
        local tween = createSmoothTween(humanoidRootPart, targetCFrame, chunk.duration)
        
        -- Store active tween
        table.insert(activeTweens, tween)
        
        -- Play tween
        tween:Play()
        
        -- Wait for completion
        local completed = false
        local connection
        connection = tween.Completed:Connect(function()
            completed = true
            connection:Disconnect()
        end)
        
        -- Wait with timeout
        local timeout = chunk.duration + 1
        local elapsed = 0
        while not completed and elapsed < timeout and teleportInProgress do
            task.wait(0.1)
            elapsed = elapsed + 0.1
        end
        
        -- Remove from active tweens
        for j, activeTween in ipairs(activeTweens) do
            if activeTween == tween then
                table.remove(activeTweens, j)
                break
            end
        end
        
        if not completed then
            warn("Tween chunk", i, "timed out")
            success = false
            break
        end
    end
    
    teleportInProgress = false
    
    if success then
        print("Teleport completed successfully")
    else
        warn("Teleport failed or was cancelled")
    end
    
    return success
end

-- Utility functions for easier usage
local function QuickTeleport(targetPosition, speed)
    return TeleportTween(targetPosition, {speed = speed or 150, bypass = true})
end

local function SafeTeleport(targetPosition)
    return TeleportTween(targetPosition, {speed = 75, bypass = true, heightOffset = 10})
end

local function FastTeleport(targetPosition)
    return TeleportTween(targetPosition, {speed = 200, bypass = true})
end

local function InstantTeleport(targetPosition)
    local character, humanoidRootPart = getCharacter()
    if not character or not humanoidRootPart then
        return false
    end
    
    local targetPos
    if typeof(targetPosition) == "Vector3" then
        targetPos = targetPosition
    elseif typeof(targetPosition) == "CFrame" then
        targetPos = targetPosition.Position
    else
        return false
    end
    
    humanoidRootPart.CFrame = CFrame.new(targetPos)
    return true
end

-- Stop all active teleports
local function StopTeleport()
    teleportInProgress = false
    
    for _, tween in ipairs(activeTweens) do
        if tween then
            tween:Cancel()
        end
    end
    
    activeTweens = {}
    print("All teleports stopped")
end

-- Configuration functions
local function SetTeleportSpeed(speed)
    TeleportConfig.Speed = math.clamp(speed, TeleportConfig.MinSpeed, TeleportConfig.MaxSpeed)
    print("Teleport speed set to:", TeleportConfig.Speed)
end

local function SetBypassEnabled(enabled)
    TeleportConfig.BypassEnabled = enabled
    print("Bypass enabled:", enabled)
end

local function SetChunkSize(size)
    TeleportConfig.ChunkSize = math.max(10, size)
    print("Chunk size set to:", TeleportConfig.ChunkSize)
end

-- Export functions globally
getgenv().TeleportTween = TeleportTween
getgenv().QuickTeleport = QuickTeleport
getgenv().SafeTeleport = SafeTeleport
getgenv().FastTeleport = FastTeleport
getgenv().InstantTeleport = InstantTeleport
getgenv().StopTeleport = StopTeleport
getgenv().SetTeleportSpeed = SetTeleportSpeed
getgenv().SetBypassEnabled = SetBypassEnabled
getgenv().SetChunkSize = SetChunkSize

-- Also create a module for script usage
local TeleportModule = {
    Teleport = TeleportTween,
    Quick = QuickTeleport,
    Safe = SafeTeleport,
    Fast = FastTeleport,
    Instant = InstantTeleport,
    Stop = StopTeleport,
    SetSpeed = SetTeleportSpeed,
    SetBypass = SetBypassEnabled,
    SetChunkSize = SetChunkSize,
    Config = TeleportConfig
}

print("🔧 Teleport Module Loaded - By XvasX")
print("🚀 Smooth Teleport Tween System Loaded!")
print("📋 Available Functions:")
print("  • TeleportTween(position, options) - Main function")
print("  • QuickTeleport(position) - Balanced speed")
print("  • SafeTeleport(position) - Slow and safe")
print("  • FastTeleport(position) - Fast movement")
print("  • InstantTeleport(position) - No tween")
print("  • StopTeleport() - Cancel all teleports")
print("💡 Example: TeleportTween(Vector3.new(100, 50, 100))")

return TeleportModule