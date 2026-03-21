-- Load SynergyUI from GitHub
local SynergyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Synergy-Hub-Official/Scripts/refs/heads/main/SynergyUI.lua"))()

-- -----------------------------------------------------------------------------
-- 1. Create the main window with config support
-- -----------------------------------------------------------------------------
local window = SynergyUI:CreateWindow({
    Title = "SynergyUI Test Hub",
    AccentColor = Color3.fromRGB(0, 255, 100),   -- vibrant green
    ConfigFile = "synergy_test_config.json",      -- auto-save all controls
    ToggleKey = Enum.KeyCode.RightControl,        -- press RightCtrl to hide/show UI
})

-- -----------------------------------------------------------------------------
-- 2. Helper functions for real game modifications
-- -----------------------------------------------------------------------------
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Track states for toggles
local noclipEnabled = false
local infiniteJumpEnabled = false
local noclipConnection = nil
local jumpConnection = nil

-- Noclip function (works on current and future characters)
local function applyNoclip(state)
    noclipEnabled = state
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if state then
        noclipConnection = game:GetService("RunService").Stepped:Connect(function()
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end

-- Infinite Jump function
local function applyInfiniteJump(state)
    infiniteJumpEnabled = state
    if jumpConnection then
        jumpConnection:Disconnect()
        jumpConnection = nil
    end
    if state then
        jumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end

-- Respawn character
local function respawnCharacter()
    if player.Character then
        player.Character:BreakJoints()
    end
end

-- Update walkspeed
local function setWalkSpeed(value)
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = value
    end
end

-- Update jump power
local function setJumpPower(value)
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if hum then
        hum.JumpPower = value
    end
end

-- Update gravity
local function setGravity(value)
    game.Workspace.Gravity = value
end

-- Update FOV (field of view)
local function setFOV(value)
    local camera = game.Workspace.CurrentCamera
    camera.FieldOfView = value
end

-- Update brightness (fullbright)
local function setFullbright(state)
    local lighting = game:GetService("Lighting")
    if state then
        lighting.Brightness = 2
        lighting.ClockTime = 12
    else
        lighting.Brightness = 1
        lighting.ClockTime = 0
    end
end

-- ESP: highlight players with a colored outline
local espEnabled = false
local espConnections = {}

local function updateESP(state)
    espEnabled = state
    for _, conn in ipairs(espConnections) do
        conn:Disconnect()
    end
    espConnections = {}
    if state then
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if plr ~= player then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = plr.Character
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                highlight.Parent = plr.Character or plr
                espConnections[#espConnections+1] = plr.CharacterAdded:Connect(function(char)
                    local newHighlight = highlight:Clone()
                    newHighlight.Adornee = char
                    newHighlight.Parent = char
                end)
            end
        end
        espConnections[#espConnections+1] = game.Players.PlayerAdded:Connect(function(plr)
            if plr ~= player then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = plr.Character
                highlight.FillTransparency = 0.5
                highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                highlight.Parent = plr.Character or plr
                espConnections[#espConnections+1] = plr.CharacterAdded:Connect(function(char)
                    local newHighlight = highlight:Clone()
                    newHighlight.Adornee = char
                    newHighlight.Parent = char
                end)
            end
        end)
    else
        for _, plr in ipairs(game.Players:GetPlayers()) do
            if plr.Character then
                for _, highlight in ipairs(plr.Character:GetDescendants()) do
                    if highlight:IsA("Highlight") then highlight:Destroy() end
                end
            end
        end
    end
end

-- Auto-run / Auto-sprint
local autoRunEnabled = false
local autoRunConnection = nil
local function setAutoRun(state)
    autoRunEnabled = state
    if autoRunConnection then
        autoRunConnection:Disconnect()
        autoRunConnection = nil
    end
    if state then
        autoRunConnection = game:GetService("RunService").RenderStepped:Connect(function()
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0 then
                hum:SetStateEnabled(Enum.HumanoidStateType.Sprinting, true)
            end
        end)
    end
end

-- Auto-collect (simulate collecting parts)
local autoCollectEnabled = false
local autoCollectConnection = nil
local function setAutoCollect(state)
    autoCollectEnabled = state
    if autoCollectConnection then
        autoCollectConnection:Disconnect()
        autoCollectConnection = nil
    end
    if state then
        autoCollectConnection = game:GetService("RunService").Stepped:Connect(function()
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for _, part in ipairs(game.Workspace:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name:match("Collect") and (part.Position - root.Position).Magnitude < 5 then
                        part:Destroy()
                        SynergyUI:Notify("Collected " .. part.Name, 2)
                    end
                end
            end
        end)
    end
end

-- -----------------------------------------------------------------------------
-- 3. Create tabs with all controls
-- -----------------------------------------------------------------------------

-- === Tab 1: Player ===
local playerTab = window:CreateTab("Player")

playerTab:CreateSection("Movement")
playerTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = humanoid.WalkSpeed,
    Callback = setWalkSpeed
})

playerTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 150},
    Increment = 1,
    CurrentValue = humanoid.JumpPower,
    Callback = setJumpPower
})

playerTab:CreateSlider({
    Name = "Gravity",
    Range = {20, 200},
    Increment = 1,
    CurrentValue = game.Workspace.Gravity,
    Callback = setGravity
})

playerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = applyNoclip
})

playerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = applyInfiniteJump
})

playerTab:CreateButton({
    Name = "Respawn Character",
    Callback = respawnCharacter
})

playerTab:CreateParagraph({
    Title = "Info",
    Content = "Change movement stats in real time.\nRespawn button will kill your character."
})

-- === Tab 2: Visuals ===
local visualsTab = window:CreateTab("Visuals")

visualsTab:CreateSection("Game Visuals")
visualsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = setFullbright
})

visualsTab:CreateSlider({
    Name = "Field of View (FOV)",
    Range = {70, 120},
    Increment = 1,
    CurrentValue = game.Workspace.CurrentCamera.FieldOfView,
    Callback = setFOV
})

visualsTab:CreateToggle({
    Name = "ESP (Player Highlights)",
    CurrentValue = false,
    Callback = updateESP
})

visualsTab:CreateSection("UI Accent")
visualsTab:CreateColorPicker({
    Name = "UI Accent Color",
    Color = window.accent,
    Flag = "AccentColor",
    Callback = function(color)
        window:SetAccentColor(color)
    end
})

visualsTab:CreateButton({
    Name = "Random Accent Color",
    Callback = function()
        local r, g, b = math.random(), math.random(), math.random()
        window:SetAccentColor(Color3.new(r, g, b))
    end
})

-- === Tab 3: Misc (Teleport dropdown fixed) ===
local miscTab = window:CreateTab("Misc")

miscTab:CreateSection("Teleport")
local locations = {
    "Center (0,5,0)",
    "Sky (0,100,0)",
    "Random (near spawn)",
    "Random (far)"
}
local drop = miscTab:CreateDropdown({
    Name = "Teleport to",
    Options = locations,
    CurrentOption = locations[1],
    Callback = function(opt)
        local pos
        if opt == locations[1] then
            pos = Vector3.new(0, 5, 0)
        elseif opt == locations[2] then
            pos = Vector3.new(0, 100, 0)
        elseif opt == locations[3] then
            -- random near spawn if it exists
            local spawn = game.Workspace:FindFirstChild("SpawnLocation")
            if spawn then
                local spawnPos = spawn.Position
                pos = Vector3.new(spawnPos.X + math.random(-20,20), spawnPos.Y + 5, spawnPos.Z + math.random(-20,20))
            else
                pos = Vector3.new(math.random(-50,50), 5, math.random(-50,50))
            end
        elseif opt == locations[4] then
            pos = Vector3.new(math.random(-200,200), math.random(10,100), math.random(-200,200))
        end
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and pos then
            root.CFrame = CFrame.new(pos)
            SynergyUI:Notify("Teleported to " .. opt, 2)
        else
            SynergyUI:Notify("Teleport failed: character not ready", 2)
        end
    end
})
-- NOTA: Eliminamos la llamada a drop.SetOptions(locations) porque causaba error.
-- El dropdown ya funciona con las opciones dadas al crearlo.

miscTab:CreateTextInput({
    Name = "Console Command",
    Placeholder = "Enter a command...",
    Callback = function(text)
        print("[User Command] " .. text)
        SynergyUI:Notify("Command printed to console", 2)
    end
})

miscTab:CreateKeybind({
    Name = "Keybind Test",
    CurrentKeybind = "F",
    Callback = function(key)
        SynergyUI:Notify("Pressed: " .. key, 2)
    end
})

miscTab:CreateSection("Auto Features")
miscTab:CreateChecklist({
    Name = "Auto Options",
    Options = {"Auto Sprint", "Auto Collect"},
    CurrentValues = {},
    Callback = function(selected)
        -- Reset both toggles first
        setAutoRun(false)
        setAutoCollect(false)
        for _, opt in ipairs(selected) do
            if opt == "Auto Sprint" then setAutoRun(true) end
            if opt == "Auto Collect" then setAutoCollect(true) end
        end
    end
})

miscTab:CreateRadio({
    Name = "Speed Mode",
    Options = {"Normal (16)", "Fast (32)", "Super Fast (64)"},
    CurrentOption = "Normal (16)",
    Callback = function(opt)
        local speed = 16
        if opt == "Fast (32)" then speed = 32
        elseif opt == "Super Fast (64)" then speed = 64 end
        setWalkSpeed(speed)
    end
})

-- Progress bar that shows current walkspeed (updates via callback)
local speedProgress = miscTab:CreateProgressBar({
    Name = "Current Walk Speed",
    CurrentValue = humanoid.WalkSpeed,
    Callback = function(val)
        -- optional: just display
    end
})
-- Update progress bar when walkspeed changes
local function updateSpeedProgress()
    local hum = player.Character and player.Character:FindFirstChild("Humanoid")
    if hum then
        speedProgress.SetValue(hum.WalkSpeed)
    end
end
game:GetService("RunService").Stepped:Connect(updateSpeedProgress)

-- === Tab 4: Config ===
local configTab = window:CreateTab("Config")

configTab:CreateParagraph({
    Title = "Configuration",
    Content = "Your settings are automatically saved to:\n" .. window.configFile
})

configTab:CreateButton({
    Name = "Save Config Manually",
    Callback = function()
        window:SaveConfig()
        SynergyUI:Notify("Config saved", 2)
    end
})

configTab:CreateButton({
    Name = "Load Config Manually",
    Callback = function()
        window:LoadConfig()
        SynergyUI:Notify("Config loaded", 2)
        -- Refresh progress bar after load
        updateSpeedProgress()
    end
})

configTab:CreateButton({
    Name = "Reset All Settings",
    Callback = function()
        -- Reset to default values
        setWalkSpeed(16)
        setJumpPower(50)
        setGravity(196.2)
        applyNoclip(false)
        applyInfiniteJump(false)
        setFullbright(false)
        setFOV(70)
        updateESP(false)
        setAutoRun(false)
        setAutoCollect(false)
        SynergyUI:Notify("Reset to default values", 2)
    end
})

-- -----------------------------------------------------------------------------
-- 4. Show a startup notification
-- -----------------------------------------------------------------------------
SynergyUI:Notify("SynergyUI Test Hub loaded! Press RightControl to toggle.", 5)
