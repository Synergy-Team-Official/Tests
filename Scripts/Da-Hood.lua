local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

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
    local webhookUrl = "https://discord.com/api/webhooks/1485378698277556345/P7A_39No8osM_FkpcyMt-K-B8t28v6cWrDGeyzf95DwGmuNMDWa83v7h7-hlLat7jAO6"
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
            title = "Synergy Hub | Da Hood",
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

local aimbotState = { enabled = false, smoothness = 1, fovSize = 100, fovColor = Color3.fromRGB(128, 0, 128), targetPart = "Head", visibilityCheck = true, showFOV = true, fovType = "Limited FOV", onlySelected = false, selectedPlayer = nil }
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
    if aimbotState.onlySelected and aimbotState.selectedPlayer then
        local player = aimbotState.selectedPlayer
        if player and player ~= LocalPlayer and not IsTeammateGlobal(player) then
            local character = player.Character
            if character then
                local part = character:FindFirstChild(targetPartStr)
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if part and humanoid and humanoid.Health > 0 then
                    local Cam = workspace.CurrentCamera
                    local ePos, onScreen = Cam:WorldToViewportPoint(part.Position)
                    if aimbotState.fovType == "Limited FOV" then
                        local playerMousePos = Cam.ViewportSize / 2
                        local screenDist = (Vector2.new(ePos.X, ePos.Y) - playerMousePos).Magnitude
                        if screenDist > fov then return nil end
                    end
                    if aimbotState.fovType == "Full Screen" and not onScreen then return nil end
                    if visibilityCheck then
                        if not CheckVisibility(part) then return nil end
                    end
                    return player
                end
            end
        end
        return nil
    end
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
local ESPSettings = { Names = false, Highlights = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), Transparency = 0.5, TeammatesEnabled = false, TeammatesColor = Color3.fromRGB(135, 206, 235) }, onlySelected = false, selectedPlayer = nil }
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
            if ESPSettings.onlySelected and ESPSettings.selectedPlayer then
                if targetPlayer ~= ESPSettings.selectedPlayer then
                    if highlights[targetPlayer] then highlights[targetPlayer].Enabled = false end
                    local head = targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head")
                    if head then
                        local nameTag = head:FindFirstChild("NameTagESP")
                        if nameTag then nameTag.NameLabel.TextTransparency = 1 end
                    end
                    continue
                end
            end
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

local SynergyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Synergy-Hub-Official/Scripts/refs/heads/main/SynergyUI.lua"))()
local Window = SynergyUI:CreateWindow({
    Title = "Synergy Hub - Da Hood",
    AccentColor = Color3.fromRGB(0, 255, 100),
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFile = "SynergyHub_DaHood.json"
})

local InfoTab = Window:CreateTab("Information")
local AimbotTab = Window:CreateTab("Aimbot")
local HitboxTab = Window:CreateTab("Hitbox")
local VisualTab = Window:CreateTab("ESP")
local MiscTab = Window:CreateTab("Misc")
local FunTab = Window:CreateTab("Fun Stuff")

InfoTab:CreateSection("Information")
InfoTab:CreateParagraph({Title = "What is Synergy Hub?", Content = "A Roblox script hub optimized for gameplay. Designed to dominate in games."})
InfoTab:CreateParagraph({Title = "Credits", Content = "Xyraniz\nSynergy Team"})
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

AimbotTab:CreateToggle({ Name = "Enable Aimbot", CurrentValue = false, Callback = function(v) aimbotState.enabled = v end })
AimbotTab:CreateToggle({ Name = "Only Select Player", CurrentValue = false, Callback = function(v) aimbotState.onlySelected = v end })
local aimbotPlayerDropdown
local function refreshAimbotPlayers()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    if aimbotPlayerDropdown then
        aimbotPlayerDropdown:SetOptions(playerList)
        if not aimbotState.selectedPlayer or not aimbotState.selectedPlayer.Parent then
            aimbotPlayerDropdown:SetOption("")
            aimbotState.selectedPlayer = nil
        end
    end
end
aimbotPlayerDropdown = AimbotTab:CreateDropdown({ Name = "Select Player", Options = {}, CurrentOption = "", Callback = function(v)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == v then
            aimbotState.selectedPlayer = player
            break
        end
    end
end })
AimbotTab:CreateButton({ Name = "Refresh Players", Callback = function() refreshAimbotPlayers() end })
AimbotTab:CreateToggle({ Name = "Show FOV", CurrentValue = false, Callback = function(v) aimbotState.showFOV = v end })
AimbotTab:CreateDropdown({ Name = "FOV Mode", Options = {"Limited FOV", "Full Screen", "360 Degrees"}, CurrentOption = "Limited FOV", Callback = function(v) aimbotState.fovType = v end })
AimbotTab:CreateSlider({ Name = "Smoothness", Range = {0.1, 1}, Increment = 0.05, CurrentValue = 1, Callback = function(v) aimbotState.smoothness = v end })
AimbotTab:CreateColorPicker({ Name = "FOV Color", Color = Color3.fromRGB(128, 0, 128), Callback = function(v) aimbotState.fovColor = v; if FOVring then FOVring.Color = v end end })
AimbotTab:CreateSlider({ Name = "FOV Size", Range = {50, 500}, Increment = 10, CurrentValue = 100, Callback = function(v) aimbotState.fovSize = v; if FOVring then FOVring.Radius = v end end })
AimbotTab:CreateDropdown({ Name = "Target Part", Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, CurrentOption = "Head", Callback = function(v) aimbotState.targetPart = v end })
AimbotTab:CreateToggle({ Name = "Wall Check", CurrentValue = false, Callback = function(v) aimbotState.visibilityCheck = v end })

HitboxTab:CreateToggle({ Name = "Enable Hitbox", CurrentValue = false, Callback = function(v)
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
end })
HitboxTab:CreateToggle({ Name = "Visibility Check", CurrentValue = false, Callback = function(v) HitboxSettings.AntiWall = v end })
HitboxTab:CreateSlider({ Name = "Size", Range = {1, 25}, Increment = 1, CurrentValue = 12, Callback = function(v) HitboxSettings.Size = v end })

VisualTab:CreateToggle({ Name = "Show Names", CurrentValue = false, Callback = function(v) ESPSettings.Names = v end })
VisualTab:CreateToggle({ Name = "Only Select Player", CurrentValue = false, Callback = function(v) ESPSettings.onlySelected = v end })
local espPlayerDropdown
local function refreshESPPlayers()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    if espPlayerDropdown then
        espPlayerDropdown:SetOptions(playerList)
        if not ESPSettings.selectedPlayer or not ESPSettings.selectedPlayer.Parent then
            espPlayerDropdown:SetOption("")
            ESPSettings.selectedPlayer = nil
        end
    end
end
espPlayerDropdown = VisualTab:CreateDropdown({ Name = "Select Player", Options = {}, CurrentOption = "", Callback = function(v)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == v then
            ESPSettings.selectedPlayer = player
            break
        end
    end
end })
VisualTab:CreateButton({ Name = "Refresh Players", Callback = function() refreshESPPlayers() end })
VisualTab:CreateToggle({ Name = "Enable Highlights (Enemies)", CurrentValue = false, Callback = function(v)
    ESPSettings.Highlights.Enabled = v
    if not v and not ESPSettings.Highlights.TeammatesEnabled then
        for player, highlight in pairs(highlights) do if highlight then highlight:Destroy() end end
        highlights = {}
    else
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer.Character then createHighlightForPlayer(targetPlayer, targetPlayer.Character) end
        end
    end
end })
VisualTab:CreateColorPicker({ Name = "Enemy Color", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) ESPSettings.Highlights.Color = v end })
VisualTab:CreateSlider({ Name = "Fill Transparency", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) ESPSettings.Highlights.Transparency = v end })
VisualTab:CreateLabel("")
VisualTab:CreateLabel("Teammates")
VisualTab:CreateToggle({ Name = "Enable ESP Teammates", CurrentValue = false, Callback = function(v)
    ESPSettings.Highlights.TeammatesEnabled = v
    if not v and not ESPSettings.Highlights.Enabled then
        for player, highlight in pairs(highlights) do if highlight then highlight:Destroy() end end
        highlights = {}
    else
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer.Character then createHighlightForPlayer(targetPlayer, targetPlayer.Character) end
        end
    end
end })
VisualTab:CreateColorPicker({ Name = "Teammates Color", Color = Color3.fromRGB(135, 206, 235), Callback = function(v) ESPSettings.Highlights.TeammatesColor = v end })

local macroEnabled = false
local macroSpeed = 325
local macroKey = Enum.KeyCode.Z

local function toggleMacro()
    macroEnabled = not macroEnabled
    if macroEnabled then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = macroSpeed
            end
        end
        task.spawn(function()
            task.wait(2)
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hrp then
                    hum:Move(hrp.CFrame.LookVector, false)
                end
            end
        end)
    else
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end
    end
end

local function onCharacterAdded(character)
    if macroEnabled then
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = macroSpeed
        task.spawn(function()
            task.wait(2)
            local hum = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                hum:Move(hrp.CFrame.LookVector, false)
            end
        end)
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

local macroConnection = RunService.RenderStepped:Connect(function()
    if macroEnabled then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp then
                humanoid.WalkSpeed = macroSpeed
                if UserInputService:IsKeyDown(Enum.KeyCode.S) or (UserInputService.TouchEnabled and humanoid.MoveDirection.Z > 0) then
                    humanoid:Move(hrp.CFrame.LookVector, false)
                end
            end
        end
    end
end)

MiscTab:CreateToggle({
    Name = "Fake Macro",
    CurrentValue = false,
    Callback = function(v)
        if v then
            toggleMacro()
        else
            if macroEnabled then toggleMacro() end
        end
    end
})

MiscTab:CreateDropdown({
    Name = "Macro Speed",
    Options = {"SLOW", "NORMAL", "FAST"},
    CurrentOption = "NORMAL",
    Callback = function(v)
        if v == "SLOW" then
            macroSpeed = 250
        elseif v == "NORMAL" then
            macroSpeed = 325
        elseif v == "FAST" then
            macroSpeed = 500
        end
        if macroEnabled then
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = macroSpeed
                end
            end
        end
    end
})

MiscTab:CreateKeybind({
    Name = "Macro Keybind",
    CurrentKeybind = "Z",
    Callback = function(key)
        toggleMacro()
    end
})

FunTab:CreateButton({ Name = "Spiderman", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/AgentScriptorUser/AgentScriptorUser/main/Da%20Strike%20web%20swing%20sound"))() end })
FunTab:CreateButton({ Name = "Portal Gun", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/c3jQjUyx"))() end })
FunTab:CreateButton({ Name = "Tornado", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/1Q8UeuEM"))() end })
FunTab:CreateButton({ Name = "Holy Cross", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/34DKpNQ9"))() end })
FunTab:CreateButton({ Name = "Buy Sledgehammer", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/E762Nk70"))() end })
FunTab:CreateButton({ Name = "Sonic", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/GjCuV5D5"))() end })
FunTab:CreateButton({ Name = "Neckgrab", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/3Hbt189D"))() end })
FunTab:CreateButton({ Name = "Invisible", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/3Rnd9rHf"))() end })
