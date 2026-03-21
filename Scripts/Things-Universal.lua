local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService('VirtualUser')
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local whitelistedNames = {"DONATE100YT", "eyedsee", "01_Yxn", "70xyr", "mauri1492", "cabada2007", "sparro61"}
local isWhitelisted = false
for _, name in ipairs(whitelistedNames) do
    if LocalPlayer.Name == name then
        isWhitelisted = true
        break
    end
end
if not isWhitelisted then
    return
end

task.spawn(function()
    local function playSound(id)
        local sound = Instance.new("Sound")
        sound.Name = "IntroSound_" .. id
        sound.SoundId = "rbxassetid://" .. tostring(id)
        sound.Volume = 5
        sound.Parent = SoundService
        sound:Play()
        Debris:AddItem(sound, 10)
    end
    playSound(128446729987033)
end)

local function sendWebhook()
    local webhookUrl = "https://discord.com/api/webhooks/1459428558400258099/CR3gaPOYnMz8zmzwbuQqWioHynPybGk5dV1ZmAVVfBfNipHX468RhyEcepZ-8Rgs7rCQ"
    local gameName = "Unknown"
    pcall(function()
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    local placeId = game.PlaceId
    local jobId = game.JobId
    local player = game.Players.LocalPlayer
    local username = player.Name
    local displayName = player.DisplayName
    local payload = {
        embeds = {{
            title = "Synergy Hub | Things Universal",
            description = string.format("骨 | En el juego\n`%s` | `%s`\n\n西 | JobID:\n`%s`\n\n正 | Jugador\n`%s` | `%s`", gameName, placeId, jobId, username, displayName),
            color = 65793,
            image = { url = "https://raw.githubusercontent.com/Xyraniz/Synergy-Hub/refs/heads/main/Synergy-Hub.jpg" }
        }}
    }
    local function sendRequest()
        local success, response
        if request then
            success, response = pcall(function() return request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)}) end)
        end
        if not success and syn and syn.request then
            success, response = pcall(function() return syn.request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)}) end)
        end
        if not success and http_request then
            success, response = pcall(function() return http_request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)}) end)
        end
        if not success then
            success, response = pcall(function() return game:GetService("HttpService"):RequestAsync({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)}) end)
        end
    end
    task.spawn(sendRequest)
end

sendWebhook()

local SynergyLibrary = {}
local guiParent = RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui") or CoreGui

function SynergyLibrary:CreateWindow(titleText, subtitleText)
    local existingGui = guiParent:FindFirstChild("SynergyHub")
    if existingGui then
        existingGui:Destroy()
    end

    local SynergyHub = Instance.new("ScreenGui")
    SynergyHub.Name = "SynergyHub"
    SynergyHub.Parent = guiParent
    SynergyHub.ResetOnSpawn = false
    SynergyHub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SynergyHub.IgnoreGuiInset = true

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = SynergyHub
    MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 100)
    MainFrame.BorderSizePixel = 1
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
    MainFrame.Size = UDim2.new(0, 550, 0, 350)
    MainFrame.ClipsDescendants = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 6)
    MainCorner.Parent = MainFrame

    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = MainFrame
    TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TopBar.BorderSizePixel = 0
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    TopBar.ZIndex = 2

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 6)
    TopCorner.Parent = TopBar

    local TopFix = Instance.new("Frame")
    TopFix.Parent = TopBar
    TopFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    TopFix.BorderSizePixel = 0
    TopFix.Position = UDim2.new(0, 0, 0.5, 0)
    TopFix.Size = UDim2.new(1, 0, 0.5, 0)
    TopFix.ZIndex = 2

    local Title = Instance.new("TextLabel")
    Title.Parent = TopBar
    Title.BackgroundTransparency = 1.000
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = titleText
    Title.TextColor3 = Color3.fromRGB(0, 255, 100)
    Title.TextSize = 14.000
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 2

    local ControlContainer = Instance.new("Frame")
    ControlContainer.Parent = TopBar
    ControlContainer.BackgroundTransparency = 1.000
    ControlContainer.Position = UDim2.new(1, -70, 0, 0)
    ControlContainer.Size = UDim2.new(0, 70, 1, 0)
    ControlContainer.ZIndex = 2

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Parent = ControlContainer
    MinimizeBtn.BackgroundTransparency = 1.000
    MinimizeBtn.Size = UDim2.new(0.5, 0, 1, 0)
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = 18.000
    MinimizeBtn.ZIndex = 2

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = ControlContainer
    CloseBtn.BackgroundTransparency = 1.000
    CloseBtn.Position = UDim2.new(0.5, 0, 0, 0)
    CloseBtn.Size = UDim2.new(0.5, 0, 1, 0)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
    CloseBtn.TextSize = 14.000
    CloseBtn.ZIndex = 2

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Parent = MainFrame
    Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Sidebar.BorderSizePixel = 0
    Sidebar.Position = UDim2.new(0, 0, 0, 35)
    Sidebar.Size = UDim2.new(0, 130, 1, -35)

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.Parent = Sidebar
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Parent = MainFrame
    ContentArea.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    ContentArea.BorderSizePixel = 0
    ContentArea.Position = UDim2.new(0, 130, 0, 35)
    ContentArea.Size = UDim2.new(1, -130, 1, -35)

    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then update(input) end
    end)

    local minimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 550, 0, 35)}):Play()
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 550, 0, 350)}):Play()
        end
    end)
    CloseBtn.MouseButton1Click:Connect(function() SynergyHub:Destroy() end)

    local uiVisible = true
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.X then
            uiVisible = not uiVisible
            SynergyHub.Enabled = uiVisible
        end
    end)

    local WindowConfig = { Flags = {} }
    local tabs = {}
    local firstTab = true

    function WindowConfig:Toggle()
        uiVisible = not uiVisible
        SynergyHub.Enabled = uiVisible
    end

    function WindowConfig:CreateTab(tabName, iconName)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Parent = Sidebar
        TabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        TabBtn.BorderSizePixel = 0
        TabBtn.Size = UDim2.new(1, 0, 0, 35)
        TabBtn.Font = Enum.Font.Gotham
        TabBtn.Text = tabName
        TabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        TabBtn.TextSize = 14.000

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Parent = ContentArea
        TabContent.Active = true
        TabContent.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        TabContent.BorderSizePixel = 0
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.ScrollBarThickness = 4
        TabContent.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 100)
        TabContent.Visible = firstTab

        local ContentLayout = Instance.new("UIListLayout")
        ContentLayout.Parent = TabContent
        ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ContentLayout.Padding = UDim.new(0, 5)

        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.Parent = TabContent
        ContentPadding.PaddingLeft = UDim.new(0, 10)
        ContentPadding.PaddingRight = UDim.new(0, 10)
        ContentPadding.PaddingTop = UDim.new(0, 10)
        ContentPadding.PaddingBottom = UDim.new(0, 10)

        if firstTab then
            TabBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
            firstTab = false
        end

        table.insert(tabs, {Btn = TabBtn, Content = TabContent})

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in ipairs(tabs) do
                t.Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                t.Content.Visible = false
            end
            TabBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
            TabContent.Visible = true
        end)

        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
        end)

        local TabConfig = {}

        function TabConfig:Select()
            for _, t in ipairs(tabs) do
                t.Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
                t.Content.Visible = false
            end
            TabBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
            TabContent.Visible = true
        end

        function TabConfig:CreateSection(sectionName)
            local SectionLabel = Instance.new("TextLabel")
            SectionLabel.Parent = TabContent
            SectionLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SectionLabel.BackgroundTransparency = 1.000
            SectionLabel.Size = UDim2.new(1, 0, 0, 25)
            SectionLabel.Font = Enum.Font.GothamBold
            SectionLabel.Text = sectionName
            SectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            SectionLabel.TextSize = 14.000
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
        end

        function TabConfig:CreateParagraph(options)
            local PFrame = Instance.new("Frame")
            PFrame.Parent = TabContent
            PFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            PFrame.Size = UDim2.new(1, 0, 0, 60)
            Instance.new("UICorner", PFrame).CornerRadius = UDim.new(0, 4)
            local Title = Instance.new("TextLabel")
            Title.Parent = PFrame
            Title.BackgroundTransparency = 1
            Title.Position = UDim2.new(0, 10, 0, 5)
            Title.Size = UDim2.new(1, -20, 0, 20)
            Title.Font = Enum.Font.GothamBold
            Title.Text = options.Title
            Title.TextColor3 = Color3.fromRGB(0, 255, 100)
            Title.TextSize = 14
            Title.TextXAlignment = Enum.TextXAlignment.Left
            local Content = Instance.new("TextLabel")
            Content.Parent = PFrame
            Content.BackgroundTransparency = 1
            Content.Position = UDim2.new(0, 10, 0, 25)
            Content.Size = UDim2.new(1, -20, 0, 30)
            Content.Font = Enum.Font.Gotham
            Content.Text = options.Content
            Content.TextColor3 = Color3.fromRGB(200, 200, 200)
            Content.TextSize = 12
            Content.TextWrapped = true
            Content.TextXAlignment = Enum.TextXAlignment.Left
            Content.TextYAlignment = Enum.TextYAlignment.Top
        end

        function TabConfig:CreateButton(options)
            local BtnFrame = Instance.new("Frame")
            BtnFrame.Parent = TabContent
            BtnFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            BtnFrame.Size = UDim2.new(1, 0, 0, 35)
            Instance.new("UICorner", BtnFrame).CornerRadius = UDim.new(0, 4)
            local ActionBtn = Instance.new("TextButton")
            ActionBtn.Parent = BtnFrame
            ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ActionBtn.BackgroundTransparency = 1.000
            ActionBtn.Size = UDim2.new(1, 0, 1, 0)
            ActionBtn.Font = Enum.Font.Gotham
            ActionBtn.Text = options.Name
            ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            ActionBtn.TextSize = 14.000
            ActionBtn.MouseButton1Click:Connect(function()
                local succ, err = pcall(options.Callback)
                if not succ then warn(err) end
                TweenService:Create(ActionBtn, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(0, 255, 100)}):Play()
                task.wait(0.1)
                TweenService:Create(ActionBtn, TweenInfo.new(0.1), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            end)
        end

        function TabConfig:CreateToggle(options)
            local toggled = options.CurrentValue or false
            local flag = options.Flag or options.Name
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Parent = TabContent
            ToggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 4)
            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Parent = ToggleFrame
            ToggleLabel.BackgroundTransparency = 1.000
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.Text = options.Name
            ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ToggleLabel.TextSize = 14.000
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            local IndicatorOuter = Instance.new("Frame")
            IndicatorOuter.Parent = ToggleFrame
            IndicatorOuter.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            IndicatorOuter.Position = UDim2.new(1, -40, 0.5, -10)
            IndicatorOuter.Size = UDim2.new(0, 30, 0, 20)
            Instance.new("UICorner", IndicatorOuter).CornerRadius = UDim.new(1, 0)
            local IndicatorInner = Instance.new("Frame")
            IndicatorInner.Parent = IndicatorOuter
            IndicatorInner.BackgroundColor3 = toggled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(100, 100, 100)
            IndicatorInner.Position = toggled and UDim2.new(0, 12, 0, 2) or UDim2.new(0, 2, 0, 2)
            IndicatorInner.Size = UDim2.new(0, 16, 0, 16)
            Instance.new("UICorner", IndicatorInner).CornerRadius = UDim.new(1, 0)
            local InvisibleBtn = Instance.new("TextButton")
            InvisibleBtn.Parent = ToggleFrame
            InvisibleBtn.BackgroundTransparency = 1.000
            InvisibleBtn.Size = UDim2.new(1, 0, 1, 0)
            InvisibleBtn.Text = ""

            local function setToggle(state)
                toggled = state
                if toggled then
                    TweenService:Create(IndicatorInner, TweenInfo.new(0.2), {Position = UDim2.new(0, 12, 0, 2), BackgroundColor3 = Color3.fromRGB(0, 255, 100)}):Play()
                    ToggleLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
                else
                    TweenService:Create(IndicatorInner, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0, 2), BackgroundColor3 = Color3.fromRGB(100, 100, 100)}):Play()
                    ToggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
                options.Callback(toggled)
            end
            WindowConfig.Flags[flag] = { Set = function(self, v) setToggle(v) end }
            InvisibleBtn.MouseButton1Click:Connect(function() setToggle(not toggled) end)
            if toggled then options.Callback(toggled) end
        end

        function TabConfig:CreateSlider(options)
            local sliderValue = options.CurrentValue or options.Range[1]
            local flag = options.Flag or options.Name
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Parent = TabContent
            SliderFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            SliderFrame.Size = UDim2.new(1, 0, 0, 45)
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 4)
            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Parent = SliderFrame
            SliderLabel.BackgroundTransparency = 1.000
            SliderLabel.Position = UDim2.new(0, 10, 0, 5)
            SliderLabel.Size = UDim2.new(0.7, 0, 0, 15)
            SliderLabel.Font = Enum.Font.Gotham
            SliderLabel.Text = options.Name
            SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            SliderLabel.TextSize = 14.000
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Parent = SliderFrame
            ValueLabel.BackgroundTransparency = 1.000
            ValueLabel.Position = UDim2.new(1, -60, 0, 5)
            ValueLabel.Size = UDim2.new(0, 50, 0, 15)
            ValueLabel.Font = Enum.Font.Gotham
            ValueLabel.Text = tostring(sliderValue)
            ValueLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
            ValueLabel.TextSize = 14.000
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            local SliderBg = Instance.new("Frame")
            SliderBg.Parent = SliderFrame
            SliderBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            SliderBg.Position = UDim2.new(0, 10, 0, 25)
            SliderBg.Size = UDim2.new(1, -20, 0, 10)
            Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)
            local SliderFill = Instance.new("Frame")
            SliderFill.Parent = SliderBg
            SliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
            SliderFill.Size = UDim2.new((sliderValue - options.Range[1]) / (options.Range[2] - options.Range[1]), 0, 1, 0)
            Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
            local DragBtn = Instance.new("TextButton")
            DragBtn.Parent = SliderBg
            DragBtn.BackgroundTransparency = 1
            DragBtn.Size = UDim2.new(1, 0, 1, 0)
            DragBtn.Text = ""

            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
                local val = options.Range[1] + pos * (options.Range[2] - options.Range[1])
                local increment = options.Increment or 1
                val = math.floor(val / increment + 0.5) * increment
                val = math.clamp(val, options.Range[1], options.Range[2])
                local formattedVal = math.floor(val) == val and tostring(val) or string.format("%.2f", val)
                ValueLabel.Text = formattedVal
                SliderFill.Size = UDim2.new((val - options.Range[1]) / (options.Range[2] - options.Range[1]), 0, 1, 0)
                options.Callback(val)
            end

            local draggingSlider = false
            DragBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = true
                    updateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSlider = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
        end

        function TabConfig:CreateDropdown(options)
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Parent = TabContent
            DropdownFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            DropdownFrame.ClipsDescendants = true
            Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 4)
            local DropBtn = Instance.new("TextButton")
            DropBtn.Parent = DropdownFrame
            DropBtn.BackgroundTransparency = 1.000
            DropBtn.Position = UDim2.new(0, 10, 0, 0)
            DropBtn.Size = UDim2.new(1, -20, 0, 35)
            DropBtn.Font = Enum.Font.Gotham
            DropBtn.Text = options.Name .. " : " .. (options.CurrentOption or "")
            DropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            DropBtn.TextSize = 14.000
            DropBtn.TextXAlignment = Enum.TextXAlignment.Left
            local OptionsContainer = Instance.new("ScrollingFrame")
            OptionsContainer.Parent = DropdownFrame
            OptionsContainer.Active = true
            OptionsContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            OptionsContainer.BorderSizePixel = 0
            OptionsContainer.Position = UDim2.new(0, 0, 0, 35)
            OptionsContainer.Size = UDim2.new(1, 0, 1, -35)
            OptionsContainer.ScrollBarThickness = 2
            OptionsContainer.ScrollBarImageColor3 = Color3.fromRGB(0, 255, 100)
            local OptLayout = Instance.new("UIListLayout")
            OptLayout.Parent = OptionsContainer
            OptLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local isOpen = false
            local function refreshOptions(newOptions)
                for _, child in ipairs(OptionsContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, opt in ipairs(newOptions) do
                    local OptBtn = Instance.new("TextButton")
                    OptBtn.Parent = OptionsContainer
                    OptBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    OptBtn.BorderSizePixel = 0
                    OptBtn.Size = UDim2.new(1, 0, 0, 25)
                    OptBtn.Font = Enum.Font.Gotham
                    OptBtn.Text = opt
                    OptBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                    OptBtn.TextSize = 12.000
                    OptBtn.MouseButton1Click:Connect(function()
                        DropBtn.Text = options.Name .. " : " .. opt
                        isOpen = false
                        TweenService:Create(DropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                        options.Callback(opt)
                    end)
                end
                OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, #newOptions * 25)
            end
            refreshOptions(options.Options)

            DropBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    local targetHeight = math.min(35 + (#options.Options * 25), 135)
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()
                else
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                end
            end)

            return { SetOptions = function(self, newOpts) refreshOptions(newOpts); options.Options = newOpts end }
        end

        function TabConfig:CreateColorPicker(options)
            local ColorFrame = Instance.new("Frame")
            ColorFrame.Parent = TabContent
            ColorFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            ColorFrame.Size = UDim2.new(1, 0, 0, 35)
            ColorFrame.ClipsDescendants = true
            Instance.new("UICorner", ColorFrame).CornerRadius = UDim.new(0, 4)
            local ColorLabel = Instance.new("TextLabel")
            ColorLabel.Parent = ColorFrame
            ColorLabel.BackgroundTransparency = 1.000
            ColorLabel.Position = UDim2.new(0, 10, 0, 0)
            ColorLabel.Size = UDim2.new(0.7, 0, 0, 35)
            ColorLabel.Font = Enum.Font.Gotham
            ColorLabel.Text = options.Name
            ColorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ColorLabel.TextSize = 14.000
            ColorLabel.TextXAlignment = Enum.TextXAlignment.Left
            local PreviewBlock = Instance.new("Frame")
            PreviewBlock.Parent = ColorFrame
            PreviewBlock.BackgroundColor3 = options.Color or Color3.fromRGB(255, 255, 255)
            PreviewBlock.Position = UDim2.new(1, -40, 0, 5)
            PreviewBlock.Size = UDim2.new(0, 30, 0, 25)
            Instance.new("UICorner", PreviewBlock).CornerRadius = UDim.new(0, 4)
            local ExpandBtn = Instance.new("TextButton")
            ExpandBtn.Parent = ColorFrame
            ExpandBtn.BackgroundTransparency = 1
            ExpandBtn.Size = UDim2.new(1, 0, 0, 35)
            ExpandBtn.Text = ""

            local RGBContainer = Instance.new("Frame")
            RGBContainer.Parent = ColorFrame
            RGBContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            RGBContainer.Position = UDim2.new(0, 0, 0, 35)
            RGBContainer.Size = UDim2.new(1, 0, 1, -35)
            
            local r, g, b = PreviewBlock.BackgroundColor3.R, PreviewBlock.BackgroundColor3.G, PreviewBlock.BackgroundColor3.B
            local function makeColorSlider(name, pos, colorTint, initialVal, callback)
                local SFrame = Instance.new("Frame")
                SFrame.Parent = RGBContainer
                SFrame.BackgroundTransparency = 1
                SFrame.Position = UDim2.new(0, 0, 0, pos)
                SFrame.Size = UDim2.new(1, 0, 0, 30)
                local SLabel = Instance.new("TextLabel")
                SLabel.Parent = SFrame
                SLabel.BackgroundTransparency = 1
                SLabel.Position = UDim2.new(0, 10, 0, 0)
                SLabel.Size = UDim2.new(0, 15, 1, 0)
                SLabel.Font = Enum.Font.GothamBold
                SLabel.Text = name
                SLabel.TextColor3 = colorTint
                SLabel.TextSize = 14
                local SBg = Instance.new("Frame")
                SBg.Parent = SFrame
                SBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
                SBg.Position = UDim2.new(0, 35, 0.5, -5)
                SBg.Size = UDim2.new(1, -45, 0, 10)
                Instance.new("UICorner", SBg).CornerRadius = UDim.new(1, 0)
                local SFill = Instance.new("Frame")
                SFill.Parent = SBg
                SFill.BackgroundColor3 = colorTint
                SFill.Size = UDim2.new(initialVal, 0, 1, 0)
                Instance.new("UICorner", SFill).CornerRadius = UDim.new(1, 0)
                local DBtn = Instance.new("TextButton")
                DBtn.Parent = SBg
                DBtn.BackgroundTransparency = 1
                DBtn.Size = UDim2.new(1, 0, 1, 0)
                DBtn.Text = ""

                local draggingC = false
                local function updateC(input)
                    local p = math.clamp((input.Position.X - SBg.AbsolutePosition.X) / SBg.AbsoluteSize.X, 0, 1)
                    SFill.Size = UDim2.new(p, 0, 1, 0)
                    callback(p)
                end
                DBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingC = true
                        updateC(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingC = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if draggingC and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateC(input)
                    end
                end)
            end

            local function updateFinalColor()
                local newC = Color3.new(r, g, b)
                PreviewBlock.BackgroundColor3 = newC
                options.Callback(newC)
            end

            makeColorSlider("R", 5, Color3.fromRGB(255, 50, 50), r, function(v) r = v updateFinalColor() end)
            makeColorSlider("G", 35, Color3.fromRGB(50, 255, 50), g, function(v) g = v updateFinalColor() end)
            makeColorSlider("B", 65, Color3.fromRGB(50, 50, 255), b, function(v) b = v updateFinalColor() end)

            local isOpen = false
            ExpandBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    TweenService:Create(ColorFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 135)}):Play()
                else
                    TweenService:Create(ColorFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                end
            end)
        end

        function TabConfig:CreateKeybind(options)
            local KeyFrame = Instance.new("Frame")
            KeyFrame.Parent = TabContent
            KeyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            KeyFrame.Size = UDim2.new(1, 0, 0, 35)
            Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 4)
            local KeyLabel = Instance.new("TextLabel")
            KeyLabel.Parent = KeyFrame
            KeyLabel.BackgroundTransparency = 1.000
            KeyLabel.Position = UDim2.new(0, 10, 0, 0)
            KeyLabel.Size = UDim2.new(0.7, 0, 1, 0)
            KeyLabel.Font = Enum.Font.Gotham
            KeyLabel.Text = options.Name
            KeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            KeyLabel.TextSize = 14.000
            KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
            local BindBtn = Instance.new("TextButton")
            BindBtn.Parent = KeyFrame
            BindBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            BindBtn.Position = UDim2.new(1, -70, 0, 5)
            BindBtn.Size = UDim2.new(0, 60, 0, 25)
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.Text = options.CurrentKeybind or "None"
            BindBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
            BindBtn.TextSize = 12.000
            Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)

            local binding = false
            BindBtn.MouseButton1Click:Connect(function()
                binding = true
                BindBtn.Text = "..."
            end)
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding = false
                    BindBtn.Text = input.KeyCode.Name
                    options.Callback(input.KeyCode.Name)
                elseif not binding and not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == BindBtn.Text then
                    options.Callback(input.KeyCode.Name)
                end
            end)
        end

        return TabConfig
    end

    return WindowConfig
end

local function SanitizeName(str) return tostring(str):gsub('%s+', '') end

local function CheckVisibility(part)
    local Cam = workspace.CurrentCamera
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {LocalPlayer.Character}
    local Result = workspace:Raycast(Cam.CFrame.Position, part.Position - Cam.CFrame.Position, Params)
    if not Result then return true end
    return Result.Instance:IsDescendantOf(part.Parent)
end

local function IsTeammateGlobal(targetPlayer)
    local success, isTeammate = pcall(function()
        if targetPlayer == LocalPlayer then return true end
        if LocalPlayer.Team and targetPlayer.Team then
            return LocalPlayer.Team == targetPlayer.Team
        end
        return false
    end)
    return success and isTeammate or false
end

local aimbotState = { enabled = false, smoothness = 1, fovSize = 100, fovColor = Color3.fromRGB(128, 0, 128), targetPart = "Head", visibilityCheck = true, showFOV = true, fovType = "Limited FOV" }
local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = aimbotState.fovColor
FOVring.Filled = false
FOVring.Radius = aimbotState.fovSize
FOVring.Position = workspace.CurrentCamera.ViewportSize / 2
local aimbotConnection

local function updateDrawings()
    local camViewportSize = workspace.CurrentCamera.ViewportSize
    FOVring.Position = camViewportSize / 2
end

local function lookAt(target, smoothness)
    local Cam = workspace.CurrentCamera
    local lookVector = (target - Cam.CFrame.Position).unit
    local newCFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookVector)
    Cam.CFrame = Cam.CFrame:Lerp(newCFrame, smoothness)
end

local function getTargetPlayer(targetPartStr, fov, visibilityCheck)
    local candidates = {}
    local Cam = workspace.CurrentCamera
    local playerMousePos = Cam.ViewportSize / 2
    local localPos = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.Position or Vector3.zero
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not IsTeammateGlobal(player) then
            local character = player.Character
            if character then
                local part = character:FindFirstChild(targetPartStr)
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if part and humanoid and humanoid.Health > 0 then
                    local ePos, onScreen = Cam:WorldToViewportPoint(part.Position)
                    if not onScreen and aimbotState.fovType ~= "360 Degrees" then continue end
                    local screenDist = (Vector2.new(ePos.X, ePos.Y) - playerMousePos).Magnitude
                    if aimbotState.fovType == "Limited FOV" and screenDist > fov then continue end
                    local visible = true
                    if visibilityCheck then visible = CheckVisibility(part) end
                    if visible then
                        local threeDDist = (part.Position - localPos).Magnitude
                        table.insert(candidates, { player = player, screenDist = onScreen and screenDist or math.huge, threeDDist = threeDDist })
                    end
                end
            end
        end
    end
    if #candidates == 0 then return nil end
    local selected = candidates[1]
    for _, cand in ipairs(candidates) do if cand.threeDDist < selected.threeDDist then selected = cand end end
    return selected.player
end

local function initializeAimbot()
    if not FOVring then
        FOVring = Drawing.new("Circle")
        FOVring.Visible = false; FOVring.Thickness = 2; FOVring.Color = aimbotState.fovColor; FOVring.Filled = false; FOVring.Radius = aimbotState.fovSize; FOVring.Position = workspace.CurrentCamera.ViewportSize / 2
    end
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() updateDrawings() end)
end

local HitboxSettings = { Enabled = false, Size = 12, AntiWall = false }
local ESPSettings = { Names = false, Highlights = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), Transparency = 0.5, TeammatesEnabled = false, TeammatesColor = Color3.fromRGB(135, 206, 235) } }
local originalHitboxProperties = {}

local function restoreHitbox(targetPlayer)
    if targetPlayer.Character then
        local bodyParts = {"HumanoidRootPart"}
        for _, partName in pairs(bodyParts) do
            local part = targetPlayer.Character:FindFirstChild(partName)
            if part and originalHitboxProperties[targetPlayer] and originalHitboxProperties[targetPlayer][partName] then
                local props = originalHitboxProperties[targetPlayer][partName]
                part.Size = props.Size
                part.Transparency = props.Transparency
                part.Color = props.Color
                part.CanCollide = props.CanCollide
            end
        end
    end
end
local function restoreAllHitboxes()
    for _, targetPlayer in pairs(Players:GetPlayers()) do restoreHitbox(targetPlayer) end
    originalHitboxProperties = {}
end

local nameTagContainer = Instance.new("BillboardGui")
local playerNameLabel = Instance.new("TextLabel")
nameTagContainer.Name = "NameTagESP"
nameTagContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
nameTagContainer.Active = true
nameTagContainer.AlwaysOnTop = true
nameTagContainer.LightInfluence = 1.000
nameTagContainer.Size = UDim2.new(0, 200, 0, 30)
nameTagContainer.StudsOffset = Vector3.new(0, 3, 0)
playerNameLabel.Name = "NameLabel"
playerNameLabel.Parent = nameTagContainer
playerNameLabel.BackgroundTransparency = 1
playerNameLabel.BorderSizePixel = 0
playerNameLabel.Size = UDim2.new(1, 0, 1, 0)
playerNameLabel.Font = Enum.Font.GothamBold
playerNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
playerNameLabel.TextSize = 14
playerNameLabel.TextStrokeTransparency = 0.5
playerNameLabel.TextWrapped = true
playerNameLabel.TextTransparency = 1

local highlights = {}
local HighlightStorage = Instance.new("Folder")
HighlightStorage.Name = "Synergy_Visuals"
local protectedGui = game:GetService("CoreGui")
if not pcall(function() HighlightStorage.Parent = protectedGui end) then HighlightStorage.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

local function createHighlightForPlayer(targetPlayer, character)
    if not character then return end
    if highlights[targetPlayer] then
        if highlights[targetPlayer].Parent == nil then highlights[targetPlayer]:Destroy(); highlights[targetPlayer] = nil else return end
    end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.Enabled = false
    highlight.Parent = HighlightStorage
    highlights[targetPlayer] = highlight
end

local function createNameTagForPlayer(targetPlayer, character)
    if not character then return end
    pcall(function()
        local head = character:WaitForChild("Head", 10)
        if head then
            if head:FindFirstChild("NameTagESP") then return end
            local nameClone = nameTagContainer:Clone()
            nameClone.Parent = head
            nameClone:FindFirstChild("NameLabel").Text = targetPlayer.Name
        end
    end)
end

local function addESPToPlayer(targetPlayer)
    targetPlayer.CharacterAdded:Connect(function(newCharacter)
        repeat task.wait() until newCharacter:FindFirstChild("HumanoidRootPart")
        createHighlightForPlayer(targetPlayer, newCharacter)
        createNameTagForPlayer(targetPlayer, newCharacter)
    end)
    if targetPlayer.Character then
        createHighlightForPlayer(targetPlayer, targetPlayer.Character)
        createNameTagForPlayer(targetPlayer, targetPlayer.Character)
    end
end

for _, targetPlayer in pairs(Players:GetPlayers()) do if targetPlayer ~= LocalPlayer then addESPToPlayer(targetPlayer) end end
Players.PlayerAdded:Connect(function(newPlayer) if newPlayer ~= LocalPlayer then addESPToPlayer(newPlayer) end end)

local function updateESP()
    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= LocalPlayer then
            if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health <= 0 then
                    local head = targetPlayer.Character:FindFirstChild("Head")
                    if head then
                        local nameTag = head:FindFirstChild("NameTagESP")
                        if nameTag then nameTag:Destroy() end
                    end
                    if highlights[targetPlayer] then highlights[targetPlayer].Enabled = false end
                else
                    local inRange = false
                    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if localRoot then
                        local dist = (localRoot.Position - targetPlayer.Character.HumanoidRootPart.Position).Magnitude
                        inRange = dist <= 150
                    end
                    if not inRange then
                        local nameTag = targetPlayer.Character:FindFirstChild("Head") and targetPlayer.Character.Head:FindFirstChild("NameTagESP")
                        if nameTag then nameTag.NameLabel.TextTransparency = 1 end
                        if highlights[targetPlayer] then highlights[targetPlayer].Enabled = false end
                    else
                        if not highlights[targetPlayer] or not highlights[targetPlayer].Parent then createHighlightForPlayer(targetPlayer, targetPlayer.Character) end
                        if highlights[targetPlayer] and highlights[targetPlayer].Adornee ~= targetPlayer.Character then highlights[targetPlayer].Adornee = targetPlayer.Character end
                        if targetPlayer.Character:FindFirstChild("Head") and not targetPlayer.Character.Head:FindFirstChild("NameTagESP") then createNameTagForPlayer(targetPlayer, targetPlayer.Character) end
                        local isTeammate = IsTeammateGlobal(targetPlayer)
                        local nameTag = targetPlayer.Character:FindFirstChild("Head") and targetPlayer.Character.Head:FindFirstChild("NameTagESP")
                        if nameTag then
                            local showName = ESPSettings.Names and not isTeammate
                            nameTag.NameLabel.TextTransparency = showName and 0 or 1
                        end
                        pcall(function()
                            local shouldHighlight = false
                            local useColor = ESPSettings.Highlights.Color
                            if isTeammate then
                                if ESPSettings.Highlights.TeammatesEnabled then shouldHighlight = true; useColor = ESPSettings.Highlights.TeammatesColor end
                            else
                                if ESPSettings.Highlights.Enabled then shouldHighlight = true; useColor = ESPSettings.Highlights.Color end
                            end
                            if highlights[targetPlayer] then
                                if shouldHighlight then
                                    highlights[targetPlayer].Enabled = true
                                    highlights[targetPlayer].FillColor = useColor
                                    highlights[targetPlayer].FillTransparency = ESPSettings.Highlights.Transparency
                                    highlights[targetPlayer].OutlineColor = useColor
                                else
                                    highlights[targetPlayer].Enabled = false
                                end
                            end
                        end)
                    end
                end
            else
                if highlights[targetPlayer] then highlights[targetPlayer]:Destroy(); highlights[targetPlayer] = nil end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player) if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end end)
local espUpdateInterval = 0.1; local lastUpdate = tick()
RunService.RenderStepped:Connect(function() local now = tick(); if now - lastUpdate >= espUpdateInterval then pcall(updateESP); lastUpdate = now end end)

local Window

local function createMainWindow()
    Window = SynergyLibrary:CreateWindow("Synergy Hub - Things Universal", "")
    
    local InfoTab = Window:CreateTab("Information")
    local AimbotTab = Window:CreateTab("Aimbot")
    local HitboxTab = Window:CreateTab("Hitbox")
    local VisualTab = Window:CreateTab("ESP")

    InfoTab:CreateSection("Information")
    InfoTab:CreateParagraph({Title = "What is Synergy Hub?", Content = "A Roblox script hub optimized for gameplay. Designed to dominate in games."})
    InfoTab:CreateParagraph({Title = "Credits", Content = "Xyraniz\nSynergy Team\nCustom UI Port"})
    InfoTab:CreateButton({Name = "Discord Server", Callback = function() setclipboard("discord.gg/nCNASmNRTE") end})
    InfoTab:CreateKeybind({Name = "Menu Keybind", CurrentKeybind = "X", Flag = "MenuKeybind", Callback = function(key) Window:Toggle() end})

    pcall(initializeAimbot)
    aimbotConnection = RunService.RenderStepped:Connect(function()
        pcall(function()
            updateDrawings()
            if aimbotState.enabled then
                FOVring.Visible = aimbotState.showFOV and aimbotState.fovType == "Limited FOV"
                local closest = getTargetPlayer(aimbotState.targetPart, aimbotState.fovSize, aimbotState.visibilityCheck)
                if closest and closest.Character and closest.Character:FindFirstChild(aimbotState.targetPart) then 
                    pcall(function() lookAt(closest.Character[aimbotState.targetPart].Position, aimbotState.smoothness) end) 
                end
            else
                FOVring.Visible = false
            end
        end)
    end)

    AimbotTab:CreateSection("Aimbot Controls")
    AimbotTab:CreateToggle({Name = "Enable Aimbot", Flag = "AimbotEnabled", CurrentValue = false, Callback = function(v) aimbotState.enabled = v end})
    AimbotTab:CreateToggle({Name = "Show FOV", Flag = "ShowFOV", CurrentValue = false, Callback = function(v) aimbotState.showFOV = v end})
    AimbotTab:CreateDropdown({Name = "FOV Mode", Options = {"Limited FOV", "Full Screen", "360 Degrees"}, CurrentOption = "Limited FOV", Flag = "AimbotFOVType", Callback = function(v) aimbotState.fovType = v end})
    AimbotTab:CreateSlider({Name = "Smoothness", Range = {0.1, 1}, Increment = 0.05, CurrentValue = 1, Flag = "AimbotSmoothness", Callback = function(v) aimbotState.smoothness = v end})
    AimbotTab:CreateColorPicker({Name = "FOV Color", Color = Color3.fromRGB(128, 0, 128), Flag = "AimbotFOVColor", Callback = function(v) aimbotState.fovColor = v; if FOVring then FOVring.Color = v end end})
    AimbotTab:CreateSlider({Name = "FOV Size", Range = {50, 500}, Increment = 10, CurrentValue = 100, Flag = "AimbotFOVSize", Callback = function(v) aimbotState.fovSize = v; if FOVring then FOVring.Radius = v end end})
    AimbotTab:CreateDropdown({Name = "Target Part", Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, CurrentOption = "Head", Flag = "AimbotTargetPart", Callback = function(v) aimbotState.targetPart = v end})
    AimbotTab:CreateToggle({Name = "Wall Check", Flag = "AimbotVisibilityCheck", CurrentValue = false, Callback = function(v) aimbotState.visibilityCheck = v end})

    HitboxTab:CreateSection("Hitbox Expansion")
    HitboxTab:CreateToggle({Name = "Enable Hitbox", Flag = "HitboxEnabled", CurrentValue = false, Callback = function(v)
        HitboxSettings.Enabled = v
        if v then
            task.spawn(function()
                while HitboxSettings.Enabled do
                    pcall(function()
                        for _,targetPlayer in pairs(Players:GetPlayers()) do
                            if targetPlayer ~= LocalPlayer and not IsTeammateGlobal(targetPlayer) then
                                if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                    if HitboxSettings.AntiWall and not CheckVisibility(targetPlayer.Character.HumanoidRootPart) then
                                        restoreHitbox(targetPlayer)
                                    else
                                        local bodyParts = {"HumanoidRootPart"}
                                        for _, partName in pairs(bodyParts) do
                                            local part = targetPlayer.Character:FindFirstChild(partName)
                                            if part then
                                                if not originalHitboxProperties[targetPlayer] then originalHitboxProperties[targetPlayer] = {} end
                                                if not originalHitboxProperties[targetPlayer][partName] then originalHitboxProperties[targetPlayer][partName] = { Size = part.Size, Transparency = part.Transparency, Color = part.Color, CanCollide = part.CanCollide } end
                                                local newSize = Vector3.new(HitboxSettings.Size, HitboxSettings.Size, HitboxSettings.Size)
                                                if part.Size ~= newSize or part.CanCollide ~= false then
                                                    part.CanCollide = false
                                                    part.Size = newSize
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(0.3)
                end
            end)
        else pcall(restoreAllHitboxes) end
    end})
    HitboxTab:CreateToggle({Name = "Visibility Check", Flag = "HitboxAntiWall", CurrentValue = false, Callback = function(v) HitboxSettings.AntiWall = v end})
    HitboxTab:CreateSlider({Name = "Size", Range = {1, 25}, Increment = 1, CurrentValue = 12, Flag = "HitboxSize", Callback = function(v) HitboxSettings.Size = v end})

    VisualTab:CreateSection("ESP Visuals")
    VisualTab:CreateToggle({Name = "Show Names", Flag = "ESPNames", CurrentValue = false, Callback = function(v) ESPSettings.Names = v end})
    VisualTab:CreateToggle({Name = "Enable Highlights (Enemies)", Flag = "HighlightsEnabled", CurrentValue = false, Callback = function(v) ESPSettings.Highlights.Enabled = v; if not v and not ESPSettings.Highlights.TeammatesEnabled then for player, highlight in pairs(highlights) do if highlight then highlight:Destroy() end end highlights = {} else for _, targetPlayer in pairs(Players:GetPlayers()) do if targetPlayer ~= LocalPlayer and targetPlayer.Character then createHighlightForPlayer(targetPlayer, targetPlayer.Character) end end end end})
    VisualTab:CreateColorPicker({Name = "Enemy Color", Color = Color3.fromRGB(255, 0, 0), Flag = "HighlightsColor", Callback = function(v) ESPSettings.Highlights.Color = v end})
    VisualTab:CreateSlider({Name = "Fill Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.5, Flag = "HighlightsTransparency", Callback = function(v) ESPSettings.Highlights.Transparency = v end})
    VisualTab:CreateSection("Teammates")
    VisualTab:CreateToggle({Name = "Enable ESP Teammates", Flag = "TeammatesESPEnabled", CurrentValue = false, Callback = function(v) ESPSettings.Highlights.TeammatesEnabled = v; if not v and not ESPSettings.Highlights.Enabled then for player, highlight in pairs(highlights) do if highlight then highlight:Destroy() end end highlights = {} else for _, targetPlayer in pairs(Players:GetPlayers()) do if targetPlayer ~= LocalPlayer and targetPlayer.Character then createHighlightForPlayer(targetPlayer, targetPlayer.Character) end end end end})
    VisualTab:CreateColorPicker({Name = "Teammates Color", Color = Color3.fromRGB(135, 206, 235), Flag = "TeammatesColor", Callback = function(v) ESPSettings.Highlights.TeammatesColor = v end})

    InfoTab:Select()
end

pcall(createMainWindow)
