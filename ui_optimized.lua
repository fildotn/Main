-- Optimized Kavo UI Library for Mimic.lua Integration
-- Fixed CoreGui issues and optimized for very smooth performance

local Kavo = {}

-- Service caching for optimal performance
local Services = {
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    HttpService = game:GetService("HttpService")
}

-- Safe CoreGui detection
local function getTargetParent()
    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    
    if success and coreGui then
        return coreGui
    else
        return Services.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Cached references
local tween = Services.TweenService
local tweeninfo = TweenInfo.new
local input = Services.UserInputService
local run = Services.RunService

-- Performance variables
local lastUpdate = 0
local updateInterval = 1/60 -- 60 FPS limit

local Utility = {}
local Objects = {}

-- Optimized dragging system with 60 FPS throttling
function Kavo:DraggingEnabled(frame, parent)
    parent = parent or frame
    
    local dragging = false
    local dragInput, mousePos, framePos
    local lastDragUpdate = 0

    frame.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = inputObject.Position
            framePos = parent.Position
            
            inputObject.Changed:Connect(function()
                if inputObject.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = inputObject
        end
    end)

    input.InputChanged:Connect(function(inputObject)
        if inputObject == dragInput and dragging then
            local currentTime = tick()
            if currentTime - lastDragUpdate >= updateInterval then
                lastDragUpdate = currentTime
                local delta = inputObject.Position - mousePos
                parent.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            end
        end
    end)
end

-- Optimized tween utility
function Utility:TweenObject(obj, properties, duration, easingStyle, easingDirection)
    local success = pcall(function()
        local info = tweeninfo(duration, easingStyle or Enum.EasingStyle.Linear, easingDirection or Enum.EasingDirection.InOut)
        tween:Create(obj, info, properties):Play()
    end)
    if not success then
        warn("Failed to tween object:", obj.Name or "Unknown")
    end
end

-- Theme definitions
local themes = {
    SchemeColor = Color3.fromRGB(74, 99, 135),
    Background = Color3.fromRGB(36, 37, 43),
    Header = Color3.fromRGB(28, 29, 34),
    TextColor = Color3.fromRGB(255,255,255),
    ElementColor = Color3.fromRGB(32, 32, 38)
}

local themeStyles = {
    DarkTheme = {
        SchemeColor = Color3.fromRGB(64, 64, 64),
        Background = Color3.fromRGB(0, 0, 0),
        Header = Color3.fromRGB(0, 0, 0),
        TextColor = Color3.fromRGB(255,255,255),
        ElementColor = Color3.fromRGB(20, 20, 20)
    },
    LightTheme = {
        SchemeColor = Color3.fromRGB(150, 150, 150),
        Background = Color3.fromRGB(255,255,255),
        Header = Color3.fromRGB(200, 200, 200),
        TextColor = Color3.fromRGB(0,0,0),
        ElementColor = Color3.fromRGB(224, 224, 224)
    },
    BloodTheme = {
        SchemeColor = Color3.fromRGB(227, 27, 27),
        Background = Color3.fromRGB(10, 10, 10),
        Header = Color3.fromRGB(5, 5, 5),
        TextColor = Color3.fromRGB(255,255,255),
        ElementColor = Color3.fromRGB(20, 20, 20)
    },
    GrapeTheme = {
        SchemeColor = Color3.fromRGB(166, 71, 214),
        Background = Color3.fromRGB(64, 50, 71),
        Header = Color3.fromRGB(36, 28, 41),
        TextColor = Color3.fromRGB(255,255,255),
        ElementColor = Color3.fromRGB(74, 58, 84)
    },
    Ocean = {
        SchemeColor = Color3.fromRGB(86, 76, 251),
        Background = Color3.fromRGB(26, 32, 58),
        Header = Color3.fromRGB(38, 45, 71),
        TextColor = Color3.fromRGB(200, 200, 200),
        ElementColor = Color3.fromRGB(38, 45, 71)
    },
    Midnight = {
        SchemeColor = Color3.fromRGB(26, 189, 158),
        Background = Color3.fromRGB(44, 62, 82),
        Header = Color3.fromRGB(57, 81, 105),
        TextColor = Color3.fromRGB(255, 255, 255),
        ElementColor = Color3.fromRGB(52, 74, 95)
    },
    Sentinel = {
        SchemeColor = Color3.fromRGB(230, 35, 69),
        Background = Color3.fromRGB(32, 32, 32),
        Header = Color3.fromRGB(24, 24, 24),
        TextColor = Color3.fromRGB(119, 209, 138),
        ElementColor = Color3.fromRGB(24, 24, 24)
    },
    Synapse = {
        SchemeColor = Color3.fromRGB(46, 48, 43),
        Background = Color3.fromRGB(13, 15, 12),
        Header = Color3.fromRGB(36, 38, 35),
        TextColor = Color3.fromRGB(152, 99, 53),
        ElementColor = Color3.fromRGB(24, 24, 24)
    },
    Serpent = {
        SchemeColor = Color3.fromRGB(0, 166, 58),
        Background = Color3.fromRGB(31, 41, 43),
        Header = Color3.fromRGB(22, 29, 31),
        TextColor = Color3.fromRGB(255,255,255),
        ElementColor = Color3.fromRGB(22, 29, 31)
    }
}

-- Generate unique library name
local LibName = tostring(math.random(1, 100))..tostring(math.random(1,50))..tostring(math.random(1, 100))

-- Safe UI toggle function
function Kavo:ToggleUI()
    local success = pcall(function()
        local targetParent = getTargetParent()
        local screenGui = targetParent:FindFirstChild(LibName)
        if screenGui then
            screenGui.Enabled = not screenGui.Enabled
        end
    end)
    if not success then
        warn("Failed to toggle UI")
    end
end

-- Main library creation function
function Kavo.CreateLib(kavName, themeList)
    kavName = kavName or "Library"
    
    -- Theme processing
    if not themeList then
        themeList = themes
    elseif type(themeList) == "string" then
        themeList = themeStyles[themeList] or themes
    end
    
    -- Validate theme
    themeList = themeList or {}
    local function validateTheme()
        themeList.SchemeColor = themeList.SchemeColor or Color3.fromRGB(74, 99, 135)
        themeList.Background = themeList.Background or Color3.fromRGB(36, 37, 43)
        themeList.Header = themeList.Header or Color3.fromRGB(28, 29, 34)
        themeList.TextColor = themeList.TextColor or Color3.fromRGB(255,255,255)
        themeList.ElementColor = themeList.ElementColor or Color3.fromRGB(32, 32, 38)
    end
    validateTheme()

    -- Get target parent safely
    local targetParent = getTargetParent()
    
    -- Clean up existing UI instances
    for i,v in pairs(targetParent:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name == kavName then
            v:Destroy()
        end
    end
    
    -- Create main UI elements
    local ScreenGui = Instance.new("ScreenGui")
    local Main = Instance.new("Frame")
    local MainCorner = Instance.new("UICorner")
    local MainHeader = Instance.new("Frame")
    local headerCover = Instance.new("UICorner")
    local coverup = Instance.new("Frame")
    local title = Instance.new("TextLabel")
    local close = Instance.new("ImageButton")
    local MainSide = Instance.new("Frame")
    local sideCorner = Instance.new("UICorner")
    local coverup_2 = Instance.new("Frame")
    local tabFrames = Instance.new("Frame")
    local tabListing = Instance.new("UIListLayout")
    local pages = Instance.new("Frame")
    local Pages = Instance.new("Folder")
    local infoContainer = Instance.new("Frame")

    -- Enable optimized dragging
    Kavo:DraggingEnabled(MainHeader, Main)

    -- Safe parent assignment
    local parentSuccess = pcall(function()
        ScreenGui.Parent = targetParent
    end)
    
    if not parentSuccess then
        warn("Failed to parent ScreenGui, using PlayerGui")
        ScreenGui.Parent = Services.Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    ScreenGui.Name = LibName
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    -- Setup main frame
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.BackgroundColor3 = themeList.Background
    Main.ClipsDescendants = true
    Main.Position = UDim2.new(0.336503863, 0, 0.275485456, 0)
    Main.Size = UDim2.new(0, 525, 0, 318)

    MainCorner.CornerRadius = UDim.new(0, 4)
    MainCorner.Name = "MainCorner"
    MainCorner.Parent = Main

    -- Setup header
    MainHeader.Name = "MainHeader"
    MainHeader.Parent = Main
    MainHeader.BackgroundColor3 = themeList.Header
    MainHeader.Size = UDim2.new(0, 525, 0, 29)
    
    headerCover.CornerRadius = UDim.new(0, 4)
    headerCover.Name = "headerCover"
    headerCover.Parent = MainHeader

    coverup.Name = "coverup"
    coverup.Parent = MainHeader
    coverup.BackgroundColor3 = themeList.Header
    coverup.BorderSizePixel = 0
    coverup.Position = UDim2.new(0, 0, 0.758620679, 0)
    coverup.Size = UDim2.new(0, 525, 0, 7)

    title.Name = "title"
    title.Parent = MainHeader
    title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1.000
    title.BorderSizePixel = 0
    title.Position = UDim2.new(0.0171428565, 0, 0.344827592, 0)
    title.Size = UDim2.new(0, 204, 0, 8)
    title.Font = Enum.Font.Gotham
    title.RichText = true
    title.Text = kavName
    title.TextColor3 = Color3.fromRGB(245, 245, 245)
    title.TextSize = 16.000
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Close button with safe image loading
    close.Name = "close"
    close.Parent = MainHeader
    close.BackgroundTransparency = 1.000
    close.Position = UDim2.new(0.949999988, 0, 0.137999997, 0)
    close.Size = UDim2.new(0, 21, 0, 21)
    close.ZIndex = 2
    
    -- Safe close button image
    pcall(function()
        close.Image = "rbxassetid://3926305904"
        close.ImageRectOffset = Vector2.new(284, 4)
        close.ImageRectSize = Vector2.new(24, 24)
    end)
    
    -- Optimized close function
    close.MouseButton1Click:Connect(function()
        pcall(function()
            Services.TweenService:Create(close, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                ImageTransparency = 1
            }):Play()
            
            task.wait(0.1)
            
            Services.TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0,0,0,0),
                Position = UDim2.new(0, Main.AbsolutePosition.X + (Main.AbsoluteSize.X / 2), 0, Main.AbsolutePosition.Y + (Main.AbsoluteSize.Y / 2))
            }):Play()
            
            task.wait(0.3)
            ScreenGui:Destroy()
        end)
    end)

    -- Setup sidebar
    MainSide.Name = "MainSide"
    MainSide.Parent = Main
    MainSide.BackgroundColor3 = themeList.Header
    MainSide.Position = UDim2.new(-7.4505806e-09, 0, 0.0911949649, 0)
    MainSide.Size = UDim2.new(0, 149, 0, 289)

    sideCorner.CornerRadius = UDim.new(0, 4)
    sideCorner.Name = "sideCorner"
    sideCorner.Parent = MainSide

    coverup_2.Name = "coverup"
    coverup_2.Parent = MainSide
    coverup_2.BackgroundColor3 = themeList.Header
    coverup_2.BorderSizePixel = 0
    coverup_2.Position = UDim2.new(0.949939311, 0, 0, 0)
    coverup_2.Size = UDim2.new(0, 7, 0, 289)

    tabFrames.Name = "tabFrames"
    tabFrames.Parent = MainSide
    tabFrames.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tabFrames.BackgroundTransparency = 1.000
    tabFrames.Position = UDim2.new(0.0438990258, 0, -0.00066378375, 0)
    tabFrames.Size = UDim2.new(0, 135, 0, 283)

    tabListing.Name = "tabListing"
    tabListing.Parent = tabFrames
    tabListing.SortOrder = Enum.SortOrder.LayoutOrder

    pages.Name = "pages"
    pages.Parent = Main
    pages.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    pages.BackgroundTransparency = 1.000
    pages.BorderSizePixel = 0
    pages.Position = UDim2.new(0.299047589, 0, 0.122641519, 0)
    pages.Size = UDim2.new(0, 360, 0, 269)

    Pages.Name = "Pages"
    Pages.Parent = pages

    infoContainer.Name = "infoContainer"
    infoContainer.Parent = Main
    infoContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    infoContainer.BackgroundTransparency = 1.000
    infoContainer.BorderColor3 = Color3.fromRGB(27, 42, 53)
    infoContainer.ClipsDescendants = true
    infoContainer.Position = UDim2.new(0.299047619, 0, 0.874213815, 0)
    infoContainer.Size = UDim2.new(0, 368, 0, 33)

    -- Optimized theme update system
    local themeConnections = {}
    local lastThemeUpdate = 0
    
    local function updateThemes()
        local currentTime = tick()
        if currentTime - lastThemeUpdate < updateInterval then
            return
        end
        lastThemeUpdate = currentTime
        
        pcall(function()
            Main.BackgroundColor3 = themeList.Background
            MainHeader.BackgroundColor3 = themeList.Header
            MainSide.BackgroundColor3 = themeList.Header
            coverup_2.BackgroundColor3 = themeList.Header
            coverup.BackgroundColor3 = themeList.Header
        end)
    end
    
    local themeConnection = run.Heartbeat:Connect(updateThemes)
    table.insert(themeConnections, themeConnection)

    -- Color change function
    function Kavo:ChangeColor(prope, color)
        pcall(function()
            if prope == "Background" then
                themeList.Background = color
            elseif prope == "SchemeColor" then
                themeList.SchemeColor = color
            elseif prope == "Header" then
                themeList.Header = color
            elseif prope == "TextColor" then
                themeList.TextColor = color
            elseif prope == "ElementColor" then
                themeList.ElementColor = color
            end
        end)
    end

    local Tabs = {}
    local first = true

    -- Tab creation function
    function Tabs:NewTab(tabName)
        tabName = tabName or "Tab"
        local tabButton = Instance.new("TextButton")
        local UICorner = Instance.new("UICorner")
        local page = Instance.new("ScrollingFrame")
        local pageListing = Instance.new("UIListLayout")

        local function UpdateSize()
            pcall(function()
                local cS = pageListing.AbsoluteContentSize
                Services.TweenService:Create(page, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
                    CanvasSize = UDim2.new(0,cS.X,0,cS.Y)
                }):Play()
            end)
        end

        page.Name = "Page"
        page.Parent = Pages
        page.Active = true
        page.BackgroundColor3 = themeList.Background
        page.BorderSizePixel = 0
        page.Position = UDim2.new(0, 0, -0.00371747208, 0)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.ScrollBarThickness = 5
        page.Visible = false
        page.ScrollBarImageColor3 = Color3.fromRGB(
            math.max(0, themeList.SchemeColor.r * 255 - 16), 
            math.max(0, themeList.SchemeColor.g * 255 - 15), 
            math.max(0, themeList.SchemeColor.b * 255 - 28)
        )

        pageListing.Name = "pageListing"
        pageListing.Parent = page
        pageListing.SortOrder = Enum.SortOrder.LayoutOrder
        pageListing.Padding = UDim.new(0, 5)

        tabButton.Name = tabName.."TabButton"
        tabButton.Parent = tabFrames
        tabButton.BackgroundColor3 = themeList.SchemeColor
        tabButton.Size = UDim2.new(0, 135, 0, 28)
        tabButton.AutoButtonColor = false
        tabButton.Font = Enum.Font.Gotham
        tabButton.Text = tabName
        tabButton.TextColor3 = themeList.TextColor
        tabButton.TextSize = 14.000
        tabButton.BackgroundTransparency = 1

        if first then
            first = false
            page.Visible = true
            tabButton.BackgroundTransparency = 0
            UpdateSize()
        else
            page.Visible = false
            tabButton.BackgroundTransparency = 1
        end

        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = tabButton

        UpdateSize()
        page.ChildAdded:Connect(UpdateSize)
        page.ChildRemoved:Connect(UpdateSize)

        tabButton.MouseButton1Click:Connect(function()
            pcall(function()
                UpdateSize()
                for i,v in next, Pages:GetChildren() do
                    v.Visible = false
                end
                page.Visible = true
                for i,v in next, tabFrames:GetChildren() do
                    if v:IsA("TextButton") then
                        Utility:TweenObject(v, {BackgroundTransparency = 1}, 0.2)
                    end
                end
                Utility:TweenObject(tabButton, {BackgroundTransparency = 0}, 0.2)
            end)
        end)

        local Sections = {}

        -- Section creation function
        function Sections:NewSection(secName, hidden)
            secName = secName or "Section"
            hidden = hidden or false
            local sectionFunctions = {}
            local modules = {}

            local sectionFrame = Instance.new("Frame")
            local sectionlistoknvm = Instance.new("UIListLayout")
            local sectionHead = Instance.new("Frame")
            local sHeadCorner = Instance.new("UICorner")
            local sectionName = Instance.new("TextLabel")
            local sectionInners = Instance.new("Frame")
            local sectionElListing = Instance.new("UIListLayout")

            if hidden then
                sectionHead.Visible = false
            end

            sectionFrame.Name = "sectionFrame"
            sectionFrame.Parent = page
            sectionFrame.BackgroundColor3 = themeList.Background
            sectionFrame.BorderSizePixel = 0
            
            sectionlistoknvm.Name = "sectionlistoknvm"
            sectionlistoknvm.Parent = sectionFrame
            sectionlistoknvm.SortOrder = Enum.SortOrder.LayoutOrder
            sectionlistoknvm.Padding = UDim.new(0, 5)

            sectionHead.Name = "sectionHead"
            sectionHead.Parent = sectionFrame
            sectionHead.BackgroundColor3 = themeList.SchemeColor
            sectionHead.Size = UDim2.new(0, 352, 0, 33)

            sHeadCorner.CornerRadius = UDim.new(0, 4)
            sHeadCorner.Name = "sHeadCorner"
            sHeadCorner.Parent = sectionHead

            sectionName.Name = "sectionName"
            sectionName.Parent = sectionHead
            sectionName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sectionName.BackgroundTransparency = 1.000
            sectionName.Position = UDim2.new(0.0198863633, 0, 0, 0)
            sectionName.Size = UDim2.new(0.980113626, 0, 1, 0)
            sectionName.Font = Enum.Font.Gotham
            sectionName.Text = secName
            sectionName.RichText = true
            sectionName.TextColor3 = themeList.TextColor
            sectionName.TextSize = 14.000
            sectionName.TextXAlignment = Enum.TextXAlignment.Left

            sectionInners.Name = "sectionInners"
            sectionInners.Parent = sectionFrame
            sectionInners.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            sectionInners.BackgroundTransparency = 1.000
            sectionInners.Position = UDim2.new(0, 0, 0.190751448, 0)

            sectionElListing.Name = "sectionElListing"
            sectionElListing.Parent = sectionInners
            sectionElListing.SortOrder = Enum.SortOrder.LayoutOrder
            sectionElListing.Padding = UDim.new(0, 3)

            local function updateSectionFrame()
                pcall(function()
                    local innerSc = sectionElListing.AbsoluteContentSize
                    sectionInners.Size = UDim2.new(1, 0, 0, innerSc.Y)
                    local frameSc = sectionlistoknvm.AbsoluteContentSize
                    sectionFrame.Size = UDim2.new(0, 352, 0, frameSc.Y)
                end)
            end
            
            updateSectionFrame()
            UpdateSize()

            local Elements = {}

            -- Button creation function
            function Elements:NewButton(bname, tipINf, callback)
                local ButtonFunction = {}
                tipINf = tipINf or "Tip: Clicking this nothing will happen!"
                bname = bname or "Click Me!"
                callback = callback or function() end

                local buttonElement = Instance.new("TextButton")
                local UICorner = Instance.new("UICorner")
                local btnInfo = Instance.new("TextLabel")

                buttonElement.Name = bname
                buttonElement.Parent = sectionInners
                buttonElement.BackgroundColor3 = themeList.ElementColor
                buttonElement.Size = UDim2.new(0, 352, 0, 33)
                buttonElement.AutoButtonColor = false
                buttonElement.Font = Enum.Font.SourceSans
                buttonElement.Text = ""
                buttonElement.TextColor3 = Color3.fromRGB(0, 0, 0)
                buttonElement.TextSize = 14.000

                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = buttonElement

                btnInfo.Name = "btnInfo"
                btnInfo.Parent = buttonElement
                btnInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                btnInfo.BackgroundTransparency = 1.000
                btnInfo.Position = UDim2.new(0.096704483, 0, 0.272727281, 0)
                btnInfo.Size = UDim2.new(0, 314, 0, 14)
                btnInfo.Font = Enum.Font.GothamSemibold
                btnInfo.Text = bname
                btnInfo.RichText = true
                btnInfo.TextColor3 = themeList.TextColor
                btnInfo.TextSize = 14.000
                btnInfo.TextXAlignment = Enum.TextXAlignment.Left

                updateSectionFrame()
                UpdateSize()

                -- Button click handling
                buttonElement.MouseButton1Click:Connect(function()
                    pcall(function()
                        callback()
                    end)
                end)

                function ButtonFunction:UpdateButton(newTitle)
                    pcall(function()
                        btnInfo.Text = newTitle
                    end)
                end
                
                return ButtonFunction
            end

            -- Keybind creation function (for Mimic.lua compatibility)
            function Elements:NewKeybind(kname, kTip, preset, callback)
                local KeybindFunction = {}
                kname = kname or "Keybind"
                kTip = kTip or "Description"
                preset = preset or Enum.KeyCode.Q
                callback = callback or function() end

                local keybindElement = Instance.new("TextButton")
                local UICorner = Instance.new("UICorner")
                local kbInfo = Instance.new("TextLabel")

                keybindElement.Name = kname
                keybindElement.Parent = sectionInners
                keybindElement.BackgroundColor3 = themeList.ElementColor
                keybindElement.Size = UDim2.new(0, 352, 0, 33)
                keybindElement.AutoButtonColor = false
                keybindElement.Font = Enum.Font.SourceSans
                keybindElement.Text = ""
                keybindElement.TextColor3 = Color3.fromRGB(0, 0, 0)
                keybindElement.TextSize = 14.000

                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = keybindElement

                kbInfo.Name = "kbInfo"
                kbInfo.Parent = keybindElement
                kbInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                kbInfo.BackgroundTransparency = 1.000
                kbInfo.Position = UDim2.new(0.096704483, 0, 0.272727281, 0)
                kbInfo.Size = UDim2.new(0, 314, 0, 14)
                kbInfo.Font = Enum.Font.GothamSemibold
                kbInfo.Text = kname .. " [" .. preset.Name .. "]"
                kbInfo.RichText = true
                kbInfo.TextColor3 = themeList.TextColor
                kbInfo.TextSize = 14.000
                kbInfo.TextXAlignment = Enum.TextXAlignment.Left

                updateSectionFrame()
                UpdateSize()

                -- Keybind handling
                Services.UserInputService.InputBegan:Connect(function(key, gameProcessed)
                    if not gameProcessed and key.KeyCode == preset then
                        pcall(function()
                            callback()
                        end)
                    end
                end)

                return KeybindFunction
            end

            return Elements
        end
        
        return Sections
    end
    
    return Tabs
end

print("🎨 Optimized Kavo UI Library loaded for Mimic.lua!")
print("✅ Fixed CoreGui compatibility issues")
print("⚡ Optimized for very smooth performance")

return Kavo
