--[[
  SynergyUI Example - Complete Demo with Realistic Hacks
  This script demonstrates all new features of SynergyUI:
  - Text input, checklist, radio, progress bar
  - Config saving/loading, notifications
  - Dynamic accent color, keybind, sliders, toggles, etc.
  - Includes a variety of common Roblox hacks (speed, noclip, fly, etc.)
  - Auto‑saves when controls change (if ConfigFile specified)
  
  How to use:
  1. Make sure SynergyUI.lua is loaded (place it in your executor or use loadstring).
  2. Run this script.
  3. Press X to toggle UI (default).
  4. Experiment with all controls.
--]]

-- Load SynergyUI (adjust path/URL as needed)
local SynergyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/your-repo/SynergyUI.lua"))() -- Replace with actual URL or use local path

-- Create window with auto‑save to "cheat_config.json"
local window = SynergyUI:CreateWindow({
    Title = "Super Cheat Hub",
    AccentColor = Color3.fromRGB(0, 255, 100),
    BackgroundColor = Color3.fromRGB(15, 15, 15),
    SidebarColor = Color3.fromRGB(20, 20, 20),
    ToggleKey = Enum.KeyCode.X,
    ConfigFile = "cheat_config.json"  -- Enables auto‑save/load
})

-- ====================== GLOBAL VARIABLES ======================
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Hack states
local speedEnabled = false
local speedValue = 16  -- default walk speed
local jumpPowerEnabled = false
local jumpPowerValue = 50
local noclipEnabled = false
local flyEnabled = false
local infinityJumpEnabled = false
local godModeEnabled = false

-- References for loops
local heartbeatConnection = nil
local noclipConnection = nil
local flyConnection = nil
local flySpeed = 50
local flyDirection = Vector3.new(0,0,0)

-- ====================== HELPER FUNCTIONS ======================
local function applySpeed()
    if speedEnabled then
        humanoid.WalkSpeed = speedValue
    else
        humanoid.WalkSpeed = 16
    end
end

local function applyJumpPower()
    if jumpPowerEnabled then
        humanoid.JumpPower = jumpPowerValue
    else
        humanoid.JumpPower = 50
    end
end

local function applyGodMode()
    if godModeEnabled then
        character:SetAttribute("GodMode", true)
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        -- Prevent death
        humanoid.HealthChanged:Connect(function(health)
            if health <= 0 and godModeEnabled then
                humanoid.Health = humanoid.MaxHealth
            end
        end)
    else
        character:SetAttribute("GodMode", false)
        humanoid.MaxHealth = 100
        if humanoid.Health > 100 then humanoid.Health = 100 end
    end
end

-- Noclip logic
local function updateNoclip()
    if noclipEnabled then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Fly logic
local function startFly()
    if flyEnabled then
        if flyConnection then return end
        flyConnection = RunService.Heartbeat:Connect(function()
            local camera = workspace.CurrentCamera
            local move = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
            rootPart.Velocity = move * flySpeed
        end)
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end
end

-- Infinity jump
local function setupInfinityJump()
    if infinityJumpEnabled then
        if not character:FindFirstChild("InfinityJumpHandler") then
            local handler = Instance.new("BindableEvent")
            handler.Name = "InfinityJumpHandler"
            handler.Parent = character
            handler.Event:Connect(function()
                if infinityJumpEnabled then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
            character.Humanoid.Jump:Connect(function()
                handler:Fire()
            end)
        end
    else
        local handler = character:FindFirstChild("InfinityJumpHandler")
        if handler then handler:Destroy() end
    end
end

-- Update all hacks
local function updateAllHacks()
    applySpeed()
    applyJumpPower()
    updateNoclip()
    startFly()
    setupInfinityJump()
    applyGodMode()
end

-- ====================== CREATE TABS ======================
local hacksTab = window:CreateTab("Hacks", nil)
local tweaksTab = window:CreateTab("Tweaks", nil)
local configTab = window:CreateTab("Config", nil)
local miscTab = window:CreateTab("Misc", nil)

-- ====================== HACKS TAB ======================
hacksTab:CreateSection("Movement Hacks")

hacksTab:CreateToggle({
    Name = "Speed Hack",
    Flag = "speedToggle",
    CurrentValue = false,
    Callback = function(state)
        speedEnabled = state
        applySpeed()
        SynergyUI:Notify("Speed hack " .. (state and "ON" or "OFF"), 2)
        updateAllHacks()
    end
})

hacksTab:CreateSlider({
    Name = "Speed Value",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(val)
        speedValue = val
        if speedEnabled then applySpeed() end
    end
})

hacksTab:CreateToggle({
    Name = "Jump Power Hack",
    Flag = "jumpToggle",
    CurrentValue = false,
    Callback = function(state)
        jumpPowerEnabled = state
        applyJumpPower()
        SynergyUI:Notify("Jump power hack " .. (state and "ON" or "OFF"), 2)
    end
})

hacksTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(val)
        jumpPowerValue = val
        if jumpPowerEnabled then applyJumpPower() end
    end
})

hacksTab:CreateToggle({
    Name = "Noclip",
    Flag = "noclipToggle",
    CurrentValue = false,
    Callback = function(state)
        noclipEnabled = state
        updateNoclip()
        SynergyUI:Notify("Noclip " .. (state and "ON" or "OFF"), 2)
    end
})

hacksTab:CreateToggle({
    Name = "Fly",
    Flag = "flyToggle",
    CurrentValue = false,
    Callback = function(state)
        flyEnabled = state
        startFly()
        SynergyUI:Notify("Fly " .. (state and "ON" or "OFF"), 2)
    end
})

hacksTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(val)
        flySpeed = val
    end
})

hacksTab:CreateToggle({
    Name = "Infinity Jump",
    Flag = "infJumpToggle",
    CurrentValue = false,
    Callback = function(state)
        infinityJumpEnabled = state
        setupInfinityJump()
        SynergyUI:Notify("Infinity jump " .. (state and "ON" or "OFF"), 2)
    end
})

hacksTab:CreateToggle({
    Name = "God Mode",
    Flag = "godToggle",
    CurrentValue = false,
    Callback = function(state)
        godModeEnabled = state
        applyGodMode()
        SynergyUI:Notify("God mode " .. (state and "ON" or "OFF"), 2)
    end
})

hacksTab:CreateSection("Extra Features")

-- Checklist: select which extra features to enable (just an example)
local extraChecklist = hacksTab:CreateChecklist({
    Name = "Auto Features",
    Options = {"Auto Collect", "Auto Click", "Auto Farm"},
    CurrentValues = {},
    Callback = function(selected)
        print("Extra features selected:", table.concat(selected, ", "))
        SynergyUI:Notify("Selected: " .. table.concat(selected, ", "), 3)
    end
})

-- Radio: choose game mode
hacksTab:CreateRadio({
    Name = "Game Mode",
    Options = {"Normal", "Aggressive", "Stealth"},
    CurrentOption = "Normal",
    Callback = function(option)
        print("Game mode changed to:", option)
        SynergyUI:Notify("Game mode: " .. option, 2)
    end
})

-- ====================== TWEAKS TAB ======================
tweaksTab:CreateSection("Character Customization")

tweaksTab:CreateTextInput({
    Name = "Set Display Name",
    Placeholder = "Enter new name...",
    CurrentText = "",
    Callback = function(text)
        if text ~= "" then
            player.DisplayName = text
            SynergyUI:Notify("Display name set to: " .. text, 2)
        end
    end
})

tweaksTab:CreateColorPicker({
    Name = "Character Color",
    Color = Color3.fromRGB(255,255,255),
    Callback = function(col)
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.Color = col
            end
        end
    end
})

tweaksTab:CreateSection("Utility")

-- Progress bar example: simulate a charging ability
local chargeProgress = tweaksTab:CreateProgressBar({
    Name = "Super Charge",
    CurrentValue = 0,
    Callback = function(val)
        -- you could trigger something at full charge
        if val >= 100 then
            SynergyUI:Notify("Charge full! Press button to release!", 2)
        end
    end
})

tweaksTab:CreateButton({
    Name = "Release Charge",
    Callback = function()
        if chargeProgress.SetValue then
            chargeProgress:SetValue(0)
            SynergyUI:Notify("Boom! Charge released!", 2)
        end
    end
})

-- Simulate charge increasing over time
task.spawn(function()
    while true do
        task.wait(0.1)
        local current = chargeProgress.SetValue and (chargeProgress:GetValue() or 0) or 0
        if current < 100 then
            chargeProgress:SetValue(current + 0.5)
        end
    end
end)

-- ====================== CONFIG TAB ======================
configTab:CreateSection("Configuration")

configTab:CreateButton({
    Name = "Save Current Config",
    Callback = function()
        window:SaveConfig("cheat_config.json")
        SynergyUI:Notify("Config saved to cheat_config.json", 2)
    end
})

configTab:CreateButton({
    Name = "Load Last Config",
    Callback = function()
        window:LoadConfig("cheat_config.json")
        SynergyUI:Notify("Config loaded", 2)
    end
})

configTab:CreateParagraph({
    Title = "Info",
    Content = "Config is automatically saved whenever you change any control (if ConfigFile was set).\nYou can also manually save/load using the buttons above.\nConfig file is stored in your executor's workspace."
})

-- ====================== MISC TAB ======================
miscTab:CreateSection("Accent Color")

miscTab:CreateSlider({
    Name = "Hue (0-360)",
    Range = {0, 360},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(val)
        local newColor = Color3.fromHSV(val/360, 1, 1)
        window:SetAccentColor(newColor)
    end
})

miscTab:CreateSection("Notifications")

miscTab:CreateButton({
    Name = "Test Notification",
    Callback = function()
        SynergyUI:Notify("This is a test notification!", 3)
    end
})

miscTab:CreateButton({
    Name = "Long Notification",
    Callback = function()
        SynergyUI:Notify("This is a longer notification that stays for 5 seconds.", 5)
    end
})

miscTab:CreateSection("Keybind")

miscTab:CreateKeybind({
    Name = "Toggle UI Key",
    CurrentKeybind = "X",
    Callback = function(key)
        print("Keybind pressed:", key)
        SynergyUI:Notify("UI Toggle key is " .. key, 2)
    end
})

miscTab:CreateParagraph({
    Title = "How to use",
    Content = "Press X to hide/show UI.\nUse sliders, toggles, dropdowns, checklists, etc.\nAll changes are auto-saved."
})

-- ====================== INITIAL APPLY ======================
updateAllHacks()
SynergyUI:Notify("SynergyUI demo loaded! Press X to toggle.", 3)
print("SynergyUI demo loaded. Have fun!")
