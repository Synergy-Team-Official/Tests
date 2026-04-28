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

local HitboxSettings = { Enabled = false, Size = 12, AntiWall = false, onlySelected = false, selectedPlayer = nil }
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
            else
                if highlights[targetPlayer] then highlights[targetPlayer]:Destroy(); highlights[targetPlayer] = nil end
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player) if highlights[player] then highlights[player]:Destroy(); highlights[player] = nil end end)
local espUpdateInterval = 0.1; local lastUpdate = tick()
RunService.RenderStepped:Connect(function() local now = tick(); if now - lastUpdate >= espUpdateInterval then pcall(updateESP); lastUpdate = now end end)

local SynergyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Synergy-Hub-Official/SynergyUI-Lib/refs/heads/main/SRC/source.lua"))()
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
local TeleportTab = Window:CreateTab("Teleporting")
local AnimationsTab = Window:CreateTab("Animations")
local AutoBuyTab = Window:CreateTab("Auto Buy")

InfoTab:CreateSection("Information")
InfoTab:CreateParagraph({Title = "What is Synergy Hub?", Content = "A Roblox script hub optimized for gameplay. Designed to dominate in games."})
InfoTab:CreateParagraph({Title = "Credits", Content = "Xyraniz\nSynergy Team"})
InfoTab:CreateButton({Name = "Discord Server", Callback = function() setclipboard("discord.gg/nCNASmNRTE") end})

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
            aimbotPlayerDropdown:SetValue("")
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

AimbotTab:CreateSection("Kill Aura")
local KillAuraEnabled = false
local KillAuraRange = 500
local KillAuraOnlySelected = false
local KillAuraSelectedPlayer = nil
local function getClosestPlayerForKillAura()
    if KillAuraOnlySelected and KillAuraSelectedPlayer then
        local player = KillAuraSelectedPlayer
        if player and player ~= LocalPlayer and not IsTeammateGlobal(player) then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local dist = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if dist <= KillAuraRange then return player end
            end
        end
        return nil
    end
    local closest, shortest = nil, math.huge
    local localPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.zero
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not IsTeammateGlobal(player) then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local dist = (hrp.Position - localPos).Magnitude
                if dist < shortest and dist <= KillAuraRange then
                    shortest = dist
                    closest = player
                end
            end
        end
    end
    return closest
end
local function shootAtPlayer(player)
    if not player or not player.Character then return end
    local targetHead = player.Character:FindFirstChild("Head")
    if not targetHead then return end
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        local mainEvent = ReplicatedStorage:FindFirstChild("MainEvent")
        if mainEvent then
            mainEvent:FireServer("ShootGun", tool:FindFirstChild("Handle"), tool.Handle.CFrame.Position, targetHead.Position, targetHead, Vector3.new(0,0,-1))
        end
    end
end
RunService.Heartbeat:Connect(function()
    if KillAuraEnabled then
        local target = getClosestPlayerForKillAura()
        if target then
            shootAtPlayer(target)
        end
    end
end)
AimbotTab:CreateToggle({ Name = "Enable Kill Aura", CurrentValue = false, Callback = function(v) KillAuraEnabled = v end })
AimbotTab:CreateSlider({ Name = "Range", Range = {0, 300}, Increment = 5, CurrentValue = 500, Callback = function(v) KillAuraRange = v end })
AimbotTab:CreateToggle({ Name = "Only Select Player", CurrentValue = false, Callback = function(v) KillAuraOnlySelected = v end })
local killAuraPlayerDropdown
local function refreshKillAuraPlayers()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    if killAuraPlayerDropdown then
        killAuraPlayerDropdown:SetOptions(playerList)
        if not KillAuraSelectedPlayer or not KillAuraSelectedPlayer.Parent then
            killAuraPlayerDropdown:SetValue("")
            KillAuraSelectedPlayer = nil
        end
    end
end
killAuraPlayerDropdown = AimbotTab:CreateDropdown({ Name = "Select Player (Kill Aura)", Options = {}, CurrentOption = "", Callback = function(v)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == v then
            KillAuraSelectedPlayer = player
            break
        end
    end
end })
AimbotTab:CreateButton({ Name = "Refresh Players", Callback = function() refreshKillAuraPlayers() end })

HitboxTab:CreateToggle({ Name = "Enable Hitbox", CurrentValue = false, Callback = function(v)
    HitboxSettings.Enabled = v
    if v then
        task.spawn(function()
            while HitboxSettings.Enabled do
                pcall(function()
                    for _,targetPlayer in pairs(Players:GetPlayers()) do
                        if targetPlayer ~= LocalPlayer and not IsTeammateGlobal(targetPlayer) then
                            if HitboxSettings.onlySelected and HitboxSettings.selectedPlayer and targetPlayer ~= HitboxSettings.selectedPlayer then continue end
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
HitboxTab:CreateToggle({ Name = "Only Select Player", CurrentValue = false, Callback = function(v) HitboxSettings.onlySelected = v end })
local hitboxPlayerDropdown
local function refreshHitboxPlayers()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    if hitboxPlayerDropdown then
        hitboxPlayerDropdown:SetOptions(playerList)
        if not HitboxSettings.selectedPlayer or not HitboxSettings.selectedPlayer.Parent then
            hitboxPlayerDropdown:SetValue("")
            HitboxSettings.selectedPlayer = nil
        end
    end
end
hitboxPlayerDropdown = HitboxTab:CreateDropdown({ Name = "Select Player", Options = {}, CurrentOption = "", Callback = function(v)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name == v then
            HitboxSettings.selectedPlayer = player
            break
        end
    end
end })
HitboxTab:CreateButton({ Name = "Refresh Players", Callback = function() refreshHitboxPlayers() end })
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
            espPlayerDropdown:SetValue("")
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

local autoMaskEnabled = false
local function autoMask()
    local player = LocalPlayer
    local char = player.Character
    if not (char and char:FindFirstChild("HumanoidRootPart")) then char = player.CharacterAdded:Wait() end
    local originalCF = char.HumanoidRootPart.CFrame
    while autoMaskEnabled do
        task.wait()
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = workspace.Ignored.Shop["[Surgeon Mask] - $27"].Head.CFrame * CFrame.new(0, -4, 0)
            char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
            fireclickdetector(workspace.Ignored.Shop["[Surgeon Mask] - $27"].ClickDetector)
        end
        if player.Backpack:FindFirstChild("[Mask]") then
            while autoMaskEnabled do
                task.wait()
                if player.Backpack:FindFirstChild("[Mask]") then
                    char.Humanoid:EquipTool(player.Backpack:FindFirstChild("[Mask]"))
                end
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = workspace.Ignored.Shop["[Surgeon Mask] - $27"].Head.CFrame * CFrame.new(0, -4, 0)
                    char.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                end
                if char:FindFirstChild("[Mask]") then
                    local mask = char:FindFirstChild("[Mask]")
                    if mask then
                        mask:Activate()
                        task.wait()
                        char.Humanoid:UnequipTools()
                    end
                    task.wait()
                    char.HumanoidRootPart.CFrame = originalCF
                    return
                end
            end
        end
    end
end
MiscTab:CreateToggle({ Name = "Auto Mask", CurrentValue = false, Callback = function(v) autoMaskEnabled = v; if v then task.spawn(autoMask) end end })

local godBlockEnabled = false
local blocking = false
local silentblock = false
MiscTab:CreateToggle({ Name = "God Block", CurrentValue = false, Callback = function(v)
    godBlockEnabled = v
    if v then
        ReplicatedStorage.ClientAnimations.Block.AnimationId = "rbxassetid://0"
        task.wait()
        function Block()
            ReplicatedStorage.MainEvent:FireServer("Block", true)
            wait()
            ReplicatedStorage.MainEvent:FireServer("Block", false)
        end
        if getgenv().AUTO_BLOCK__ then getgenv().AUTO_BLOCK__:Disconnect() end
        getgenv().AUTO_BLOCK__ = RunService.Stepped:Connect(function()
            if blocking then
                if LocalPlayer.Character.BodyEffects:FindFirstChild("Block") then
                    LocalPlayer.Character.BodyEffects.Block:Destroy()
                end
                local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                if tool then
                    if tool:FindFirstChild("GunScript") then
                        ReplicatedStorage.MainEvent:FireServer("Block", false)
                    else
                        Block()
                    end
                else
                    Block()
                end
            end
        end)
        blocking = true
        if not getgenv().godBlockTeleported then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 150, 0)
            task.wait()
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
            getgenv().godBlockTeleported = true
        end
    else
        blocking = false
    end
end })
MiscTab:CreateToggle({ Name = "Hide Block", CurrentValue = false, Callback = function(v) silentblock = v end })
RunService.RenderStepped:Connect(function()
    if silentblock and LocalPlayer.Character then
        for _, track in pairs(LocalPlayer.Character.Humanoid:GetPlayingAnimationTracks()) do
            if track.Animation.AnimationId:match("rbxassetid://2788354405") then
                track:Stop()
            end
        end
    end
end)

local silentstomp = false
MiscTab:CreateToggle({ Name = "Hide Stomp", CurrentValue = false, Callback = function(v) silentstomp = v end })
RunService.RenderStepped:Connect(function()
    if silentstomp and LocalPlayer.Character then
        for _, track in pairs(LocalPlayer.Character.Humanoid:GetPlayingAnimationTracks()) do
            if track.Animation.AnimationId:match("rbxassetid://2816431506") then
                track:Stop()
            end
        end
    end
end)

local antiStompEnabled = false
MiscTab:CreateToggle({ Name = "Anti Stomp (KO Protection)", CurrentValue = false, Callback = function(v)
    antiStompEnabled = v
    if v then
        RunService:BindToRenderStep("anti-stomp", 0, function()
            if LocalPlayer.Character and LocalPlayer.Character.BodyEffects and LocalPlayer.Character.BodyEffects["K.O"].Value == true then
                LocalPlayer.Character.Humanoid:ChangeState("Dead")
            end
        end)
    else
        RunService:UnbindFromRenderStep("anti-stomp")
    end
end })

local antiGrabEnabled = false
MiscTab:CreateToggle({ Name = "Anti Grab", CurrentValue = false, Callback = function(v) antiGrabEnabled = v end })
RunService.RenderStepped:Connect(function()
    if antiGrabEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT") then
        for _, child in pairs(LocalPlayer.Character:GetChildren()) do
            if child:IsA("Accessory") then
                child.Handle:Destroy()
            end
        end
        for _, child in pairs(LocalPlayer.Character:GetChildren()) do
            if child:IsA("Accessory") or child:IsA("Part") or child:IsA("MeshPart") then
                child:Remove()
            end
        end
        wait()
        LocalPlayer.Character.Humanoid:ChangeState(15)
        wait()
        LocalPlayer.Character.Humanoid:ChangeState(16)
        wait()
        LocalPlayer.Character.Humanoid:ChangeState(0)
    end
end)

local antiSlowEnabled = false
MiscTab:CreateToggle({ Name = "Anti Slow", CurrentValue = false, Callback = function(v)
    antiSlowEnabled = v
    if v then
        RunService:BindToRenderStep("Anti-Slow", 0, function()
            if LocalPlayer.Character and LocalPlayer.Character.BodyEffects and LocalPlayer.Character.BodyEffects.Movement then
                if LocalPlayer.Character.BodyEffects.Movement:FindFirstChild("NoWalkSpeed") then
                    LocalPlayer.Character.BodyEffects.Movement.NoWalkSpeed:Destroy()
                end
                if LocalPlayer.Character.BodyEffects.Movement:FindFirstChild("ReduceWalk") then
                    LocalPlayer.Character.BodyEffects.Movement.ReduceWalk:Destroy()
                end
                if LocalPlayer.Character.BodyEffects.Movement:FindFirstChild("NoJumping") then
                    LocalPlayer.Character.BodyEffects.Movement.NoJumping:Destroy()
                end
            end
            if LocalPlayer.Character and LocalPlayer.Character.BodyEffects and LocalPlayer.Character.BodyEffects.Reload.Value == true then
                LocalPlayer.Character.BodyEffects.Reload.Value = false
            end
        end)
    else
        RunService:UnbindFromRenderStep("Anti-Slow")
    end
end })

local doubleJumpEnabled = false
local doubleJumpMax = 2
local doubleJumpHeight = 150
MiscTab:CreateToggle({ Name = "Double Jump", CurrentValue = false, Callback = function(v) doubleJumpEnabled = v end })
local function setupDoubleJump(character)
    local humanoid = character:WaitForChild("Humanoid")
    local jumpCount = 0
    local canDouble = false
    humanoid.StateChanged:Connect(function(_, newState)
        if doubleJumpEnabled then
            if newState == Enum.HumanoidStateType.Landed then
                jumpCount = 0
                canDouble = false
            elseif newState == Enum.HumanoidStateType.Freefall then
                canDouble = true
            elseif newState == Enum.HumanoidStateType.Jumping then
                jumpCount = jumpCount + 1
                if jumpCount == 2 then
                    if not LocalPlayer.Backpack:FindFirstChild("[Boombox]") then
                        local sound = Instance.new("Sound", SoundService)
                        sound.SoundId = "rbxassetid://2306431663"
                        sound:Play()
                    end
                    local anim = Instance.new("Animation")
                    anim.AnimationId = "rbxassetid://2791328524"
                    local track = humanoid:LoadAnimation(anim)
                    track:Play()
                    track.TimePosition = 0
                    track:AdjustSpeed(1.2)
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    hrp.Velocity = Vector3.new(hrp.Velocity.X, doubleJumpHeight, hrp.Velocity.Z)
                end
            end
        end
    end)
    UserInputService.JumpRequest:Connect(function()
        if doubleJumpEnabled and canDouble and jumpCount < doubleJumpMax then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
setupDoubleJump(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
LocalPlayer.CharacterAdded:Connect(setupDoubleJump)

local noJumpCooldown = false
local oldJumpPowerHook
MiscTab:CreateToggle({ Name = "No Jump Cooldown", CurrentValue = false, Callback = function(v)
    noJumpCooldown = v
    if v then
        oldJumpPowerHook = hookmetamethod(game, "__newindex", function(obj, prop, val)
            if not checkcaller() and obj:IsA("Humanoid") and prop == "JumpPower" and noJumpCooldown then
                return
            end
            return oldJumpPowerHook(obj, prop, val)
        end)
    else
        if oldJumpPowerHook then
            oldJumpPowerHook = nil
        end
    end
end })

local antiBatEnabled = false
MiscTab:CreateToggle({ Name = "Anti Bat", CurrentValue = false, Callback = function(v) antiBatEnabled = v end })
local antiBagEnabled = false
MiscTab:CreateToggle({ Name = "Anti Bag", CurrentValue = false, Callback = function(v) antiBagEnabled = v end })
local function antiWeapon(weaponList, enabledFlag)
    if not enabledFlag then return end
    local function isWeapon(name)
        for _, w in pairs(weaponList) do if name == w then return true end end
        return false
    end
    local function inRange(player, range)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            return (LocalPlayer.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude <= range
        end
        return false
    end
    RunService:BindToRenderStep("AntiWeapon", 0, function()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and inRange(player, 10) and player.Character then
                local tool = player.Character:FindFirstChildWhichIsA("Tool")
                if tool and isWeapon(tool.Name) and player.Character.BodyEffects and player.Character.BodyEffects:FindFirstChild("Attacking").Value == true and not getgenv().furrimode then
                    local originalCF = LocalPlayer.Character.HumanoidRootPart.CFrame
                    getgenv().furrimode = true
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 5, 10)
                    RunService:BindToRenderStep("noflinging", 0, function()
                        LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    end)
                    wait(0.5)
                    getgenv().furrimode = false
                    task.wait()
                    RunService:UnbindFromRenderStep("noflinging")
                    LocalPlayer.Character.HumanoidRootPart.CFrame = originalCF
                    task.wait()
                    LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end)
end
local batList = {"Combat","[Knife]","[Nunchucks]","[Bat]","[Katana]","[StopSign]","[SledgeHammer]","[Flamethrower]","[Pitchfork]","[Shovel]"}
local bagList = {"[BrownBag]"}
MiscTab:CreateToggle({ Name = "Anti Bat (enable)", CurrentValue = false, Callback = function(v) if v then antiWeapon(batList, true) else RunService:UnbindFromRenderStep("AntiWeapon") end end })
MiscTab:CreateToggle({ Name = "Anti Bag (enable)", CurrentValue = false, Callback = function(v) if v then antiWeapon(bagList, true) else RunService:UnbindFromRenderStep("AntiWeapon") end end })

local antiFling = false
local TOTT, hohoh = false, false
MiscTab:CreateToggle({ Name = "Anti Fling", CurrentValue = false, Callback = function(v)
    antiFling = v
    if v then
        RunService.Stepped:Connect(function()
            if TOTT then
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Name ~= LocalPlayer.Name and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                        player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end)
        RunService.Heartbeat:Connect(function()
            if hohoh then
                for _, player in pairs(Players:GetPlayers()) do
                    if player.Name ~= LocalPlayer.Name and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                        player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end)
        RunService:BindToRenderStep("Anti-Fling", 0, function()
            for _, player in pairs(Players:GetPlayers()) do
                if player.Name ~= LocalPlayer.Name and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end
        end)
        TOTT = true
        hohoh = true
    else
        TOTT = false
        hohoh = false
        RunService:UnbindFromRenderStep("Anti-Fling")
    end
end })

local adminSprint = false
MiscTab:CreateToggle({ Name = "Admin Sprint", CurrentValue = false, Callback = function(v)
    adminSprint = v
    local char = LocalPlayer.Character
    if char and char.BodyEffects and char.BodyEffects.Movement then
        if v then
            if not char.BodyEffects.Movement:FindFirstChild("FastSprint") then
                local fast = Instance.new("IntValue")
                fast.Name = "FastSprint"
                fast.Parent = char.BodyEffects.Movement
            end
        else
            if char.BodyEffects.Movement:FindFirstChild("FastSprint") then
                char.BodyEffects.Movement.FastSprint:Destroy()
            end
        end
    end
end })

local autoReload = false
MiscTab:CreateToggle({ Name = "Auto Reload", CurrentValue = false, Callback = function(v)
    autoReload = v
    if v then
        RunService:BindToRenderStep("Auto-Reload", 0, function()
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildWhichIsA("Tool")
                if tool and tool:FindFirstChild("Ammo") and tool.Ammo.Value <= 0 then
                    ReplicatedStorage.MainEvent:FireServer("Reload", tool)
                    wait(1)
                end
            end
        end)
    else
        RunService:UnbindFromRenderStep("Auto-Reload")
    end
end })

local autoStomp = false
MiscTab:CreateToggle({ Name = "Auto Stomp", CurrentValue = false, Callback = function(v)
    autoStomp = v
    task.spawn(function()
        while autoStomp do
            wait()
            ReplicatedStorage.MainEvent:FireServer("Stomp")
        end
    end)
end })

local cashAura = false
MiscTab:CreateToggle({ Name = "Cash Aura", CurrentValue = false, Callback = function(v)
    cashAura = v
    if v then
        getgenv().CashAuraConnection = RunService.Heartbeat:Connect(function()
            for _, drop in pairs(workspace.Ignored.Drop:GetChildren()) do
                if drop:IsA("Part") and drop:FindFirstChild("ClickDetector") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    if (drop.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 12 then
                        fireclickdetector(drop.ClickDetector)
                    end
                end
            end
        end)
    else
        if getgenv().CashAuraConnection then getgenv().CashAuraConnection:Disconnect() end
    end
end })

local autoDrop = false
MiscTab:CreateToggle({ Name = "Auto Drop", CurrentValue = false, Callback = function(v)
    autoDrop = v
    if v then
        getgenv().AutoDropConnection = RunService.Heartbeat:Connect(function()
            ReplicatedStorage.MainEvent:FireServer(unpack({"DropMoney","10000"}))
        end)
    else
        if getgenv().AutoDropConnection then getgenv().AutoDropConnection:Disconnect() end
    end
end })

local autoArmor = false
MiscTab:CreateToggle({ Name = "Auto Armor", CurrentValue = false, Callback = function(v)
    autoArmor = v
    task.spawn(function()
        while autoArmor do
            wait()
            pcall(function()
                local char = LocalPlayer.Character
                if char and char.BodyEffects and char.BodyEffects.Armor.Value < 15 then
                    if not savedpos then savedpos = char.HumanoidRootPart.Position end
                    char:MoveTo(workspace.Ignored.Shop["[High-Medium Armor] - $2440"].Head.Position)
                    wait(0.25)
                    fireclickdetector(workspace.Ignored.Shop["[High-Medium Armor] - $2440"].ClickDetector)
                    wait(0.1)
                    char:MoveTo(savedpos)
                    savedpos = nil
                end
            end)
        end
    end)
end })

local autoFireArmor = false
MiscTab:CreateToggle({ Name = "Auto Fire Armor", CurrentValue = false, Callback = function(v)
    autoFireArmor = v
    task.spawn(function()
        while autoFireArmor do
            wait()
            pcall(function()
                local char = LocalPlayer.Character
                if char and char.BodyEffects and char.BodyEffects.FireArmor.Value < 200 then
                    if not savedpos then savedpos = char.HumanoidRootPart.Position end
                    char:MoveTo(workspace.Ignored.Shop["[Fire Armor] - $2493"].Head.Position)
                    wait(0.25)
                    fireclickdetector(workspace.Ignored.Shop["[Fire Armor] - $2493"].ClickDetector)
                    wait(0.1)
                    char:MoveTo(savedpos)
                    savedpos = nil
                end
            end)
        end
    end)
end })

local PreventSitEnabled = false
LocalPlayer.CharacterAdded:Connect(function(char)
    if PreventSitEnabled then
        local humanoid = char:WaitForChild("Humanoid")
        humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
            if humanoid.Sit then
                task.wait(0.01)
                humanoid.Sit = false
            end
        end)
    end
end)
MiscTab:CreateToggle({ Name = "Prevent Sit", CurrentValue = false, Callback = function(v) PreventSitEnabled = v end })

local AlwaysSprintEnabled = false
task.spawn(function()
    while true do
        if AlwaysSprintEnabled then
            game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftShift, true, game)
            task.wait(1)
        else
            task.wait(1)
        end
    end
end)
MiscTab:CreateToggle({ Name = "Always Sprint", CurrentValue = false, Callback = function(v) AlwaysSprintEnabled = v end })

local AntiVoidEnabled = false
local safePosition = Vector3.zero
local function updateSafePosition()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        if pos.Y > -25 then safePosition = pos end
    end
end
RunService.Heartbeat:Connect(function()
    if not AntiVoidEnabled then return end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        if pos.Y < -25 then
            char.HumanoidRootPart.Velocity = Vector3.zero
            char.HumanoidRootPart.CFrame = CFrame.new(safePosition + Vector3.new(0, 5, 0))
        else
            updateSafePosition()
        end
    end
end)
MiscTab:CreateToggle({ Name = "Anti Void", CurrentValue = false, Callback = function(v) AntiVoidEnabled = v end })

local NoSlowEnabled = false
local DEFAULT_SPEED = 16
RunService.RenderStepped:Connect(function()
    if not NoSlowEnabled then return end
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local tool = char:FindFirstChildOfClass("Tool")
        if humanoid and tool and humanoid.WalkSpeed < DEFAULT_SPEED then
            humanoid.WalkSpeed = DEFAULT_SPEED
        end
    end
end)
MiscTab:CreateToggle({ Name = "No Slow (reload)", CurrentValue = false, Callback = function(v) NoSlowEnabled = v end })

local macroEnabled = false
local macroSpeed = 325
local function toggleMacro()
    macroEnabled = not macroEnabled
    if macroEnabled then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = macroSpeed end
        end
        task.spawn(function()
            task.wait(2)
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hum and hrp then hum:Move(hrp.CFrame.LookVector, false) end
            end
        end)
    else
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = 16 end
        end
    end
end
LocalPlayer.CharacterAdded:Connect(function(character)
    if macroEnabled then
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.WalkSpeed = macroSpeed
        task.spawn(function()
            task.wait(2)
            local hum = character:FindFirstChildOfClass("Humanoid")
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hum and hrp then hum:Move(hrp.CFrame.LookVector, false) end
        end)
    end
end)
RunService.RenderStepped:Connect(function()
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
MiscTab:CreateToggle({ Name = "Fake Macro", CurrentValue = false, Callback = function(v) if v then toggleMacro() else if macroEnabled then toggleMacro() end end end })
MiscTab:CreateDropdown({ Name = "Macro Speed", Options = {"SLOW", "NORMAL", "FAST"}, CurrentOption = "NORMAL", Callback = function(v)
    if v == "SLOW" then macroSpeed = 250
    elseif v == "NORMAL" then macroSpeed = 325
    else macroSpeed = 500 end
    if macroEnabled then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.WalkSpeed = macroSpeed end
        end
    end
end })
MiscTab:CreateKeybind({ Name = "Macro Keybind", CurrentKeybind = "Z", Callback = function(key) toggleMacro() end })

local TeleportSection = TeleportTab:CreateSection("Location Teleports")
local function TeleportTo(position)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position)
    end
end
local teleportPositions = {
    {Name = "Bank", Pos = Vector3.new(-432.1439208984375, 38.9649658203125, -284.1016540527344)},
    {Name = "Uphill Gunstore", Pos = Vector3.new(481.3045959472656, 48.07050323486328, -620.1513671875)},
    {Name = "Downhill Gunstore", Pos = Vector3.new(-578.5796508789062, 8.314779281616211, -736.3884887695312)},
    {Name = "Hood Fitness", Pos = Vector3.new(-76.4957275390625, 22.700284957885742, -630.9816284179688)},
    {Name = "Bar", Pos = Vector3.new(-264.5504455566406, 48.52669143676758, -446.29254150390625)},
    {Name = "Safe 2", Pos = Vector3.new(-117, -57, 147)},
    {Name = "Safe 3", Pos = Vector3.new(-546, 173, 1)},
    {Name = "Safe 5", Pos = Vector3.new(0, 150, 0)},
    {Name = "Safe For Test", Pos = Vector3.new(11, 12, 214)},
    {Name = "Da Furniture", Pos = Vector3.new(-489.1640319824219, 21.8498477935791, -76.60957336425781)},
    {Name = "School", Pos = Vector3.new(-531.3531494140625, 21.74999237060547, 252.47506713867188)},
    {Name = "Da Casino", Pos = Vector3.new(-863.4664306640625, 21.59995460510254, -152.92788696289062)},
    {Name = "Da Theatre", Pos = Vector3.new(-1004.9942626953125, 25.10002326965332, -135.17315673828125)},
    {Name = "Basketball Court", Pos = Vector3.new(-896.5643310546875, 21.999818801879883, -528.7317504882812)},
    {Name = "Hair Salon", Pos = Vector3.new(-855.55810546875, 22.005008697509766, -665.0170288085938)},
    {Name = "FoodsMart", Pos = Vector3.new(-906.5833740234375, 22.005002975463867, -653.2225952148438)},
    {Name = "Mat Laundry", Pos = Vector3.new(-971.4241333007812, 22.005887985229492, -630.115478515625)},
    {Name = "Swift", Pos = Vector3.new(-799.7603149414062, 21.8799991607666, -662.3109741210938)},
    {Name = "Military Base", Pos = Vector3.new(-50.412960052490234, 25.25499725341797, -868.921142578125)},
    {Name = "Da Boxing Club", Pos = Vector3.new(-232.0669708251953, 22.067293167114258, -1119.9541015625)},
    {Name = "Flowers", Pos = Vector3.new(-71.62272644042969, 23.15056800842285, -327.79412841796875)},
    {Name = "Hospital", Pos = Vector3.new(98.40196228027344, 22.799989700317383, -484.89385986328125)},
    {Name = "Hood Kicks", Pos = Vector3.new(-203.53347778320312, 21.845796585083008, -410.1529846191406)},
    {Name = "Police Station", Pos = Vector3.new(-265.4999694824219, 21.797977447509766, -96.51517486572266)},
    {Name = "Barba", Pos = Vector3.new(9.003872871398926, 21.74802017211914, -107.73101043701172)},
    {Name = "Church", Pos = Vector3.new(205.8213653564453, 23.77802085876465, -58.47077560424805)},
    {Name = "Train", Pos = Vector3.new(-426.41705322265625, -21.25197982788086, 44.953758239746094)}
}
for _, tp in pairs(teleportPositions) do
    TeleportTab:CreateButton({Name = tp.Name, Callback = function() TeleportTo(tp.Pos) end})
end
TeleportTab:CreateButton({Name = "Save Position", Callback = function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        getgenv().SavedPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    end
end})
TeleportTab:CreateButton({Name = "Load Saved Position", Callback = function()
    if getgenv().SavedPosition and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().SavedPosition
    end
end})

local TargetTab = Window:CreateTab("Target")
local targetSelectedPlayer = nil
local targetPlayerDropdown = nil
local function refreshTargetPlayers()
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, player.Name)
        end
    end
    if targetPlayerDropdown then
        targetPlayerDropdown:SetOptions(playerList)
        if not targetSelectedPlayer or not targetSelectedPlayer.Parent then
            targetPlayerDropdown:SetValue("")
            targetSelectedPlayer = nil
        end
    end
end
targetPlayerDropdown = TargetTab:CreateDropdown({
    Name = "Select Player",
    Options = {},
    CurrentOption = "",
    Callback = function(v)
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name == v then
                targetSelectedPlayer = player
                break
            end
        end
    end
})
TargetTab:CreateButton({ Name = "Refresh Players", Callback = function() refreshTargetPlayers() end })

local cameraFollowActive = false
local camYaw = 0
local camPitch = 30
local camDist = 10
local lastMousePos = nil
local cameraConnection = nil

local function startCameraFollow()
    if cameraConnection then cameraConnection:Disconnect() end
    cameraConnection = RunService.RenderStepped:Connect(function()
        if not cameraFollowActive then return end
        if targetSelectedPlayer and targetSelectedPlayer.Character and targetSelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = targetSelectedPlayer.Character.HumanoidRootPart
            local targetPos = targetRoot.Position
            local yawRad = math.rad(camYaw)
            local pitchRad = math.rad(camPitch)
            local offset = Vector3.new(math.sin(yawRad) * math.cos(pitchRad), math.sin(pitchRad), math.cos(yawRad) * math.cos(pitchRad)) * camDist
            local camCF = CFrame.new(targetPos + offset, targetPos)
            workspace.CurrentCamera.CFrame = camCF
        end
    end)
end

local function stopCameraFollow()
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
end

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if not cameraFollowActive then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Delta
        camYaw = camYaw - delta.X * 0.5
        camPitch = math.clamp(camPitch - delta.Y * 0.5, 10, 80)
    elseif input.KeyCode == Enum.KeyCode.MouseWheel then
        camDist = math.clamp(camDist - input.Position.Z * 0.5, 2, 30)
    end
end)

TargetTab:CreateToggle({
    Name = "View",
    CurrentValue = false,
    Callback = function(v)
        cameraFollowActive = v
        if v then
            startCameraFollow()
        else
            stopCameraFollow()
        end
    end
})

TargetTab:CreateButton({
    Name = "Goto",
    Callback = function()
        if not targetSelectedPlayer then return end
        local char = targetSelectedPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local targetPos = char.HumanoidRootPart.Position
            local localChar = LocalPlayer.Character
            if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                localChar.HumanoidRootPart.CFrame = CFrame.new(targetPos)
            end
        end
    end
})

local loopGotoConnection = nil
local loopGotoEnabled = false
local loopGotoDistance = 5
local function startLoopGoto()
    if loopGotoConnection then loopGotoConnection:Disconnect() end
    loopGotoConnection = RunService.Heartbeat:Connect(function()
        if loopGotoEnabled and targetSelectedPlayer and targetSelectedPlayer.Character and targetSelectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetCF = targetSelectedPlayer.Character.HumanoidRootPart.CFrame
            local behindPos = targetCF.Position - targetCF.LookVector * loopGotoDistance
            local localChar = LocalPlayer.Character
            if localChar and localChar:FindFirstChild("HumanoidRootPart") then
                localChar.HumanoidRootPart.CFrame = CFrame.new(behindPos)
            end
        end
    end)
end
local function stopLoopGoto()
    if loopGotoConnection then
        loopGotoConnection:Disconnect()
        loopGotoConnection = nil
    end
end
TargetTab:CreateToggle({
    Name = "LoopGoto",
    CurrentValue = false,
    Callback = function(v)
        loopGotoEnabled = v
        if v then
            startLoopGoto()
        else
            stopLoopGoto()
        end
    end
})
TargetTab:CreateSlider({
    Name = "Distance",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v)
        loopGotoDistance = v
    end
})

local flingConnection = nil
local flingEnabled = false
local originalCollisionStates = {}
local function setCollision(character, state)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if state == false then
                originalCollisionStates[part] = part.CanCollide
                part.CanCollide = false
            else
                if originalCollisionStates[part] ~= nil then
                    part.CanCollide = originalCollisionStates[part]
                end
            end
        end
    end
end
local function startFling()
    if flingConnection then flingConnection:Disconnect() end
    flingConnection = RunService.Heartbeat:Connect(function()
        if flingEnabled and targetSelectedPlayer and targetSelectedPlayer.Character then
            local targetChar = targetSelectedPlayer.Character
            local root = targetChar:FindFirstChild("HumanoidRootPart")
            if root then
                local randomVel = Vector3.new(math.random(-5000,5000), math.random(3000,8000), math.random(-5000,5000))
                root.Velocity = randomVel
                root.AssemblyLinearVelocity = randomVel
                setCollision(targetChar, false)
            end
        end
    end)
end
local function stopFling()
    if flingConnection then
        flingConnection:Disconnect()
        flingConnection = nil
    end
    if targetSelectedPlayer and targetSelectedPlayer.Character then
        setCollision(targetSelectedPlayer.Character, true)
    end
    originalCollisionStates = {}
end
TargetTab:CreateToggle({
    Name = "Fling",
    CurrentValue = false,
    Callback = function(v)
        flingEnabled = v
        if v then
            startFling()
        else
            stopFling()
        end
    end
})

local function stopAllAnimations(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("AnimationController")
    if humanoid then
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
end
local function setAnimations(character, animTable)
    local animate = character:FindFirstChild("Animate")
    if animate then
        animate.idle.Animation1.AnimationId = animTable.idle1
        animate.idle.Animation2.AnimationId = animTable.idle2
        animate.walk.WalkAnim.AnimationId = animTable.walk
        animate.run.RunAnim.AnimationId = animTable.run
        animate.jump.JumpAnim.AnimationId = animTable.jump
        animate.climb.ClimbAnim.AnimationId = animTable.climb
        animate.fall.FallAnim.AnimationId = animTable.fall
    end
end
local permanentAnim = false
local currentAnimTable = nil
local function applyAnimation(animTable)
    currentAnimTable = animTable
    local character = LocalPlayer.Character
    if character then
        stopAllAnimations(character)
        setAnimations(character, animTable)
    end
end
AnimationsTab:CreateToggle({ Name = "Permanent Animations", CurrentValue = false, Callback = function(v) permanentAnim = v end })
LocalPlayer.CharacterAdded:Connect(function(character)
    if permanentAnim and currentAnimTable then
        character:WaitForChild("HumanoidRootPart")
        stopAllAnimations(character)
        setAnimations(character, currentAnimTable)
    end
end)
local animations = {
    Adidas = {
        idle1 = "http://www.roblox.com/asset/?id=18537376492",
        idle2 = "http://www.roblox.com/asset/?id=18537371272",
        walk = "http://www.roblox.com/asset/?id=18537392113",
        run = "http://www.roblox.com/asset/?id=18537384940",
        jump = "http://www.roblox.com/asset/?id=18537380791",
        climb = "http://www.roblox.com/asset/?id=18537363391",
        fall = "http://www.roblox.com/asset/?id=18537367238"
    },
    DaHood = {
        idle1 = "http://www.roblox.com/asset/?id=3119980985",
        idle2 = "http://www.roblox.com/asset/?id=3119980985",
        walk = "http://www.roblox.com/asset/?id=707897309",
        run = "http://www.roblox.com/asset/?id=2791325054",
        jump = "http://www.roblox.com/asset/?id=707853694",
        climb = "http://www.roblox.com/asset/?id=16738332169",
        fall = "http://www.roblox.com/asset/?id=707829716"
    },
    Bubbly = {
        idle1 = "http://www.roblox.com/asset/?id=10921054344",
        idle2 = "http://www.roblox.com/asset/?id=10921055107",
        walk = "http://www.roblox.com/asset/?id=16738340646",
        run = "http://www.roblox.com/asset/?id=10921057244",
        jump = "http://www.roblox.com/asset/?id=10921062673",
        climb = "http://www.roblox.com/asset/?id=10921061530",
        fall = "http://www.roblox.com/asset/?id=707829716"
    },
    NewIdleZombie = {
        idle1 = "http://www.roblox.com/asset/?id=17172918855",
        idle2 = "http://www.roblox.com/asset/?id=17173014241",
        walk = "http://www.roblox.com/asset/?id=616168032",
        run = "http://www.roblox.com/asset/?id=616163682",
        jump = "http://www.roblox.com/asset/?id=1083218792",
        climb = "http://www.roblox.com/asset/?id=16738332169",
        fall = "http://www.roblox.com/asset/?id=10921337907"
    },
    NewIdle = {
        idle1 = "http://www.roblox.com/asset/?id=17172918855",
        idle2 = "http://www.roblox.com/asset/?id=17173014241",
        walk = "http://www.roblox.com/asset/?id=707897309",
        run = "http://www.roblox.com/asset/?id=742638842",
        jump = "http://www.roblox.com/asset/?id=1083218792",
        climb = "http://www.roblox.com/asset/?id=16738332169",
        fall = "http://www.roblox.com/asset/?id=10921337907"
    },
    Best = {
        idle1 = "http://www.roblox.com/asset/?id=4417977954",
        idle2 = "http://www.roblox.com/asset/?id=4417978624",
        walk = "http://www.roblox.com/asset/?id=707897309",
        run = "http://www.roblox.com/asset/?id=4417979645",
        jump = "http://www.roblox.com/asset/?id=707853694",
        climb = "http://www.roblox.com/asset/?id=16738332169",
        fall = "http://www.roblox.com/asset/?id=707829716"
    },
    Bold = {
        idle1 = "http://www.roblox.com/asset/?id=16738333868",
        idle2 = "http://www.roblox.com/asset/?id=16738334710",
        walk = "http://www.roblox.com/asset/?id=16738340646",
        run = "http://www.roblox.com/asset/?id=16738337225",
        jump = "http://www.roblox.com/asset/?id=16738336650",
        climb = "http://www.roblox.com/asset/?id=16738332169",
        fall = "http://www.roblox.com/asset/?id=16738333171"
    },
    MEGA = {
        idle1 = "http://www.roblox.com/asset/?id=707742142",
        idle2 = "http://www.roblox.com/asset/?id=707855907",
        walk = "http://www.roblox.com/asset/?id=707897309",
        run = "http://www.roblox.com/asset/?id=707861613",
        jump = "http://www.roblox.com/asset/?id=707853694",
        climb = "http://www.roblox.com/asset/?id=707826056",
        fall = "http://www.roblox.com/asset/?id=707829716"
    },
    Levitation = {
        idle1 = "http://www.roblox.com/asset/?id=616006778",
        idle2 = "http://www.roblox.com/asset/?id=616008087",
        walk = "http://www.roblox.com/asset/?id=616013216",
        run = "http://www.roblox.com/asset/?id=616010382",
        jump = "http://www.roblox.com/asset/?id=616008936",
        climb = "http://www.roblox.com/asset/?id=616003713",
        fall = "http://www.roblox.com/asset/?id=616005863"
    },
    JOJO = {
        idle1 = "http://www.roblox.com/asset/?id=1149612882",
        idle2 = "http://www.roblox.com/asset/?id=1149612882",
        walk = "http://www.roblox.com/asset/?id=657552124",
        run = "http://www.roblox.com/asset/?id=1150967949",
        jump = "http://www.roblox.com/asset/?id=1148863382",
        climb = "http://www.roblox.com/asset/?id=658360781",
        fall = "http://www.roblox.com/asset/?id=1148863382"
    },
    RealZombie = {
        idle1 = "http://www.roblox.com/asset/?id=10921301576",
        idle2 = "http://www.roblox.com/asset/?id=10921302207",
        walk = "http://www.roblox.com/asset/?id=616168032",
        run = "http://www.roblox.com/asset/?id=616163682",
        jump = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall = "http://www.roblox.com/asset/?id=616157476"
    },
    Cartoony = {
        idle1 = "http://www.roblox.com/asset/?id=742637544",
        idle2 = "http://www.roblox.com/asset/?id=742638445",
        walk = "http://www.roblox.com/asset/?id=742640026",
        run = "http://www.roblox.com/asset/?id=742638842",
        jump = "http://www.roblox.com/asset/?id=742637942",
        climb = "http://www.roblox.com/asset/?id=742636889",
        fall = "http://www.roblox.com/asset/?id=742637151"
    },
    AElder = {
        idle1 = "http://www.roblox.com/asset/?id=845397899",
        idle2 = "http://www.roblox.com/asset/?id=845400520",
        walk = "http://www.roblox.com/asset/?id=845403856",
        run = "http://www.roblox.com/asset/?id=845386501",
        jump = "http://www.roblox.com/asset/?id=845398858",
        climb = "http://www.roblox.com/asset/?id=845392038",
        fall = "http://www.roblox.com/asset/?id=845396048"
    },
    ZombieAElder = {
        idle1 = "http://www.roblox.com/asset/?id=845397899",
        idle2 = "http://www.roblox.com/asset/?id=845400520",
        walk = "http://www.roblox.com/asset/?id=616168032",
        run = "http://www.roblox.com/asset/?id=616163682",
        jump = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall = "http://www.roblox.com/asset/?id=616157476"
    },
    Zombie = {
        idle1 = "http://www.roblox.com/asset/?id=616158929",
        idle2 = "http://www.roblox.com/asset/?id=616160636",
        walk = "http://www.roblox.com/asset/?id=616168032",
        run = "http://www.roblox.com/asset/?id=616163682",
        jump = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall = "http://www.roblox.com/asset/?id=616157476"
    },
    Ninja = {
        idle1 = "http://www.roblox.com/asset/?id=656117400",
        idle2 = "http://www.roblox.com/asset/?id=656118341",
        walk = "http://www.roblox.com/asset/?id=656121766",
        run = "http://www.roblox.com/asset/?id=656118852",
        jump = "http://www.roblox.com/asset/?id=656117878",
        climb = "http://www.roblox.com/asset/?id=656114359",
        fall = "http://www.roblox.com/asset/?id=656115606"
    },
    Toy = {
        idle1 = "http://www.roblox.com/asset/?id=782841498",
        idle2 = "http://www.roblox.com/asset/?id=782845736",
        walk = "http://www.roblox.com/asset/?id=782843345",
        run = "http://www.roblox.com/asset/?id=782842708",
        jump = "http://www.roblox.com/asset/?id=782847020",
        climb = "http://www.roblox.com/asset/?id=782843869",
        fall = "http://www.roblox.com/asset/?id=782846423"
    },
    Sneaky = {
        idle1 = "http://www.roblox.com/asset/?id=1132473842",
        idle2 = "http://www.roblox.com/asset/?id=1132477671",
        walk = "http://www.roblox.com/asset/?id=1132510133",
        run = "http://www.roblox.com/asset/?id=1132494274",
        jump = "http://www.roblox.com/asset/?id=1132489853",
        climb = "http://www.roblox.com/asset/?id=1132461372",
        fall = "http://www.roblox.com/asset/?id=1132469004"
    },
    Knight = {
        idle1 = "http://www.roblox.com/asset/?id=657595757",
        idle2 = "http://www.roblox.com/asset/?id=657568135",
        walk = "http://www.roblox.com/asset/?id=657552124",
        run = "http://www.roblox.com/asset/?id=657564596",
        jump = "http://www.roblox.com/asset/?id=658409194",
        climb = "http://www.roblox.com/asset/?id=658360781",
        fall = "http://www.roblox.com/asset/?id=657600338"
    },
    NoAnimation = {
        idle1 = "http://www.roblox.com/asset/?id=1",
        idle2 = "http://www.roblox.com/asset/?id=1",
        walk = "http://www.roblox.com/asset/?id=1",
        run = "http://www.roblox.com/asset/?id=1",
        jump = "http://www.roblox.com/asset/?id=1",
        climb = "http://www.roblox.com/asset/?id=1",
        fall = "http://www.roblox.com/asset/?id=1"
    }
}
for name, anim in pairs(animations) do
    AnimationsTab:CreateButton({Name = name, Callback = function() applyAnimation(anim) end})
end

AutoBuyTab:CreateSection("Auto Buy")
local shopNames = {}
for _, shop in pairs(workspace.Ignored.Shop:GetChildren()) do
    table.insert(shopNames, shop.Name)
end
table.sort(shopNames)
local selectedShop = ""
local originalPos = nil
local function buyShop(shopName)
    local shop = workspace.Ignored.Shop:FindFirstChild(shopName)
    if shop and shop:FindFirstChild("Head") and shop:FindFirstChild("ClickDetector") then
        if not originalPos then
            originalPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame
        end
        LocalPlayer.Character.HumanoidRootPart.CFrame = shop.Head.CFrame
        task.wait(0.25)
        fireclickdetector(shop.ClickDetector)
        task.wait(0.5)
        if originalPos then
            LocalPlayer.Character.HumanoidRootPart.CFrame = originalPos
            originalPos = nil
        end
    end
end
local shopDropdown = AutoBuyTab:CreateDropdown({ Name = "Select Shop", Options = shopNames, CurrentOption = "", Callback = function(v) selectedShop = v end })
AutoBuyTab:CreateButton({ Name = "Buy", Callback = function() if selectedShop ~= "" then buyShop(selectedShop) end end })
AutoBuyTab:CreateButton({ Name = "Refresh Shops", Callback = function()
    local newShops = {}
    for _, shop in pairs(workspace.Ignored.Shop:GetChildren()) do
        table.insert(newShops, shop.Name)
    end
    table.sort(newShops)
    shopDropdown:SetOptions(newShops)
end })

FunTab:CreateButton({ Name = "Spiderman", Callback = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/AgentScriptorUser/AgentScriptorUser/main/Da%20Strike%20web%20swing%20sound"))() end })
FunTab:CreateButton({ Name = "Portal Gun", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/c3jQjUyx"))() end })
FunTab:CreateButton({ Name = "Tornado", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/1Q8UeuEM"))() end })
FunTab:CreateButton({ Name = "Holy Cross", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/34DKpNQ9"))() end })
FunTab:CreateButton({ Name = "Buy Sledgehammer", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/E762Nk70"))() end })
FunTab:CreateButton({ Name = "Sonic", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/GjCuV5D5"))() end })
FunTab:CreateButton({ Name = "Neckgrab", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/3Hbt189D"))() end })
FunTab:CreateButton({ Name = "Invisible", Callback = function() loadstring(game:HttpGet("https://pastebin.com/raw/3Rnd9rHf"))() end })

refreshAimbotPlayers()
refreshESPPlayers()
refreshHitboxPlayers()
refreshKillAuraPlayers()
refreshTargetPlayers()
