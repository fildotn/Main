-- Item ESP Script with Highlight, Nametags, and Distance
-- Monitors folders for items and automatically creates ESP

-- Settings
local settings = {
    -- ESP Features
    showHighlight = true,
    showNames = true,
    showDistance = true,
    
    -- Colors
    highlightFillColor = Color3.fromRGB(0, 255, 0),
    highlightOutlineColor = Color3.fromRGB(255, 255, 255),
    nameColor = Color3.fromRGB(255, 255, 255),
    distanceColor = Color3.fromRGB(200, 200, 200),
    
    -- Transparency
    highlightFillTransparency = 0.7,
    highlightOutlineTransparency = 0,
    
    -- Text
    textSize = 14,
    textFont = 2,
    
    -- Distance
    maxDistance = 1000,
    
    -- Folders to monitor (add folder names here)
    foldersToMonitor = {
        "Items",
        "Weapons",
        "Collectibles",
        "Tools",
        "Drops"
    }
}

-- Services
local runService = game:GetService("RunService")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")

-- Variables
local localPlayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local itemCache = {}
local monitoredFolders = {}

-- Functions
local newVector2, newColor3 = Vector2.new, Color3.new

-- Drawing function with fallback
local function newDrawing(drawType)
    local success, result = pcall(function()
        if _G.Drawing and _G.Drawing.new then
            return _G.Drawing.new(drawType)
        else
            error("Drawing not supported")
        end
    end)
    
    if success then
        return result
    else
        return {
            Visible = false,
            Remove = function() end,
            Size = newVector2(0, 0),
            Position = newVector2(0, 0),
            Color = Color3.new(),
            Thickness = 1,
            Filled = false,
            ZIndex = 1,
            Transparency = 1,
            Text = "",
            Font = 1,
            Center = false,
            Outline = false,
            OutlineColor = Color3.new()
        }
    end
end

-- World to viewport function
local function wtvp(pos)
    if not pos then return newVector2(0, 0), false, 0 end
    local success, a, b = pcall(function() 
        return camera:WorldToViewportPoint(pos) 
    end)
    if success and a then
        return newVector2(a.X, a.Y), b, a.Z
    else
        return newVector2(0, 0), false, 0
    end
end

-- Get distance function
local function getDistance(item)
    if not item or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return math.huge
    end
    
    local itemPosition = item:IsA("Model") and item:GetPrimaryPartCFrame().Position or item.Position
    local playerPosition = localPlayer.Character.HumanoidRootPart.Position
    
    return (itemPosition - playerPosition).Magnitude
end

-- Get item position
local function getItemPosition(item)
    if item:IsA("Model") then
        local primaryPart = item.PrimaryPart
        if primaryPart then
            return primaryPart.Position
        else
            -- Try to find a main part
            local humanoidRootPart = item:FindFirstChild("HumanoidRootPart")
            local torso = item:FindFirstChild("Torso")
            local head = item:FindFirstChild("Head")
            local part = humanoidRootPart or torso or head or item:FindFirstChildOfClass("BasePart")
            if part then
                return part.Position
            end
        end
    elseif item:IsA("BasePart") then
        return item.Position
    end
    return nil
end

-- Create highlight for item
local function createHighlight(item)
    if not item or not settings.showHighlight then return nil end
    
    local success, highlight = pcall(function()
        local highlight = Instance.new("Highlight")
        highlight.Name = "ItemESPHighlight"
        highlight.FillColor = settings.highlightFillColor
        highlight.OutlineColor = settings.highlightOutlineColor
        highlight.FillTransparency = settings.highlightFillTransparency
        highlight.OutlineTransparency = settings.highlightOutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Adornee = item
        highlight.Parent = item
        return highlight
    end)
    
    return success and highlight or nil
end

-- Remove highlight from item
local function removeHighlight(item)
    if item then
        local highlight = item:FindFirstChild("ItemESPHighlight")
        if highlight then
            highlight:Destroy()
        end
    end
end

-- Create ESP for item
local function createItemEsp(item)
    if not item or itemCache[item] then return end
    
    local esp = {
        item = item,
        highlight = nil,
        nameText = nil,
        distanceText = nil
    }
    
    -- Create highlight
    if settings.showHighlight then
        esp.highlight = createHighlight(item)
    end
    
    -- Create name text
    if settings.showNames then
        esp.nameText = newDrawing("Text")
        esp.nameText.Size = settings.textSize
        esp.nameText.Font = settings.textFont
        esp.nameText.Color = settings.nameColor
        esp.nameText.Text = item.Name
        esp.nameText.Visible = false
        esp.nameText.Center = true
        esp.nameText.Outline = true
        esp.nameText.OutlineColor = newColor3()
        esp.nameText.ZIndex = 3
    end
    
    -- Create distance text
    if settings.showDistance then
        esp.distanceText = newDrawing("Text")
        esp.distanceText.Size = settings.textSize - 2
        esp.distanceText.Font = settings.textFont
        esp.distanceText.Color = settings.distanceColor
        esp.distanceText.Text = "0m"
        esp.distanceText.Visible = false
        esp.distanceText.Center = true
        esp.distanceText.Outline = true
        esp.distanceText.OutlineColor = newColor3()
        esp.distanceText.ZIndex = 3
    end
    
    itemCache[item] = esp
    print("Created ESP for item:", item.Name)
end

-- Remove ESP for item
local function removeItemEsp(item)
    local esp = itemCache[item]
    if esp then
        -- Remove highlight
        removeHighlight(item)
        
        -- Remove text elements
        if esp.nameText then esp.nameText:Remove() end
        if esp.distanceText then esp.distanceText:Remove() end
        
        itemCache[item] = nil
        print("Removed ESP for item:", item.Name)
    end
end

-- Update ESP for item
local function updateItemEsp(item, esp)
    if not item or not item.Parent then
        -- Item was deleted
        removeItemEsp(item)
        return
    end
    
    local itemPos = getItemPosition(item)
    if not itemPos then return end
    
    local distance = getDistance(item)
    
    -- Hide if too far
    if distance > settings.maxDistance then
        if esp.nameText then esp.nameText.Visible = false end
        if esp.distanceText then esp.distanceText.Visible = false end
        return
    end
    
    local position, visible, depth = wtvp(itemPos)
    
    -- Update name text
    if settings.showNames and esp.nameText then
        esp.nameText.Visible = visible
        if visible then
            esp.nameText.Position = newVector2(position.X, position.Y - 20)
        end
    end
    
    -- Update distance text
    if settings.showDistance and esp.distanceText then
        esp.distanceText.Visible = visible
        if visible then
            esp.distanceText.Text = math.floor(distance) .. "m"
            esp.distanceText.Position = newVector2(position.X, position.Y + 5)
        end
    end
end

-- Check if item should be monitored
local function shouldMonitorItem(item)
    -- Check if item is in a monitored folder
    local parent = item.Parent
    if parent and table.find(settings.foldersToMonitor, parent.Name) then
        return true
    end
    
    -- Additional checks can be added here
    -- For example, check item names, classes, etc.
    
    return false
end

-- Scan folder for items
local function scanFolder(folder)
    if not folder then return end
    
    for _, item in pairs(folder:GetChildren()) do
        if shouldMonitorItem(item) then
            createItemEsp(item)
        end
    end
end

-- Setup folder monitoring
local function setupFolderMonitoring()
    for _, folderName in pairs(settings.foldersToMonitor) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            monitoredFolders[folderName] = folder
            
            -- Scan existing items
            scanFolder(folder)
            
            -- Monitor for new items
            folder.ChildAdded:Connect(function(item)
                wait(0.1) -- Small delay to ensure item is fully loaded
                if shouldMonitorItem(item) then
                    createItemEsp(item)
                end
            end)
            
            -- Monitor for removed items
            folder.ChildRemoved:Connect(function(item)
                removeItemEsp(item)
            end)
            
            print("Monitoring folder:", folderName)
        else
            -- Try to find folder when it's created
            workspace.ChildAdded:Connect(function(child)
                if child.Name == folderName and child:IsA("Folder") then
                    monitoredFolders[folderName] = child
                    scanFolder(child)
                    
                    child.ChildAdded:Connect(function(item)
                        wait(0.1)
                        if shouldMonitorItem(item) then
                            createItemEsp(item)
                        end
                    end)
                    
                    child.ChildRemoved:Connect(function(item)
                        removeItemEsp(item)
                    end)
                    
                    print("Found and monitoring folder:", folderName)
                end
            end)
        end
    end
end

-- Main render loop
runService:BindToRenderStep("ItemESP", Enum.RenderPriority.Camera.Value, function()
    local success = pcall(function()
        for item, esp in pairs(itemCache) do
            if item and item.Parent then
                updateItemEsp(item, esp)
            else
                -- Clean up deleted items
                removeItemEsp(item)
            end
        end
    end)
    
    if not success then
        warn("Item ESP Error occurred in render loop")
    end
end)

-- Cleanup function
local function cleanup()
    -- Remove all ESP elements
    for item, esp in pairs(itemCache) do
        removeItemEsp(item)
    end
    
    -- Unbind render step
    runService:UnbindFromRenderStep("ItemESP")
    
    print("Item ESP cleaned up")
end

-- Initialize
setupFolderMonitoring()

-- Auto-scan workspace for items not in folders (optional)
local function scanWorkspaceItems()
    for _, item in pairs(workspace:GetChildren()) do
        -- Check if it's an item-like object (customize this logic)
        if item:IsA("Model") or item:IsA("Tool") or item:IsA("BasePart") then
            -- Add your custom logic here for identifying items
            -- For example, check if item name contains certain keywords
            local itemKeywords = {"Weapon", "Item", "Collectible", "Drop", "Loot"}
            for _, keyword in pairs(itemKeywords) do
                if string.find(item.Name:lower(), keyword:lower()) then
                    createItemEsp(item)
                    break
                end
            end
        end
    end
end

-- Optional: Scan workspace for loose items
-- scanWorkspaceItems()

-- Handle player leaving (cleanup)
players.PlayerRemoving:Connect(function(player)
    if player == localPlayer then
        cleanup()
    end
end)

print("Item ESP with Highlight, Nametags, and Distance loaded!")
print("Monitoring folders:", table.concat(settings.foldersToMonitor, ", "))
print("Features: Highlight ESP, Name Tags, Distance Display")
print("Settings:")
print("- settings.showHighlight (true/false)")
print("- settings.showNames (true/false)")
print("- settings.showDistance (true/false)")
print("- settings.maxDistance (number)")
print("- Customize colors and folders in settings table")

return {
    settings = settings,
    cleanup = cleanup,
    addFolder = function(folderName)
        table.insert(settings.foldersToMonitor, folderName)
        setupFolderMonitoring()
    end,
    removeFolder = function(folderName)
        local index = table.find(settings.foldersToMonitor, folderName)
        if index then
            table.remove(settings.foldersToMonitor, index)
        end
    end
}
