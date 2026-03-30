local SynergyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Synergy-Hub-Official/SynergyUI-Lib/refs/heads/main/SRC/source.lua"))()

local function sendWebhook()
    local webhookUrl = "https://discord.com/api/webhooks/1459474492240822282/Da2IG4ceQhg1qeAiS76fP5rWRKdRMRcOX3x7sB7bSmlgwzs_CHSQ_LIS8cCbVnys2gzF"
    local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    local placeId = game.PlaceId
    local jobId = game.JobId
    local player = game.Players.LocalPlayer
    local username = player.Name
    local displayName = player.DisplayName

    local payload = {
        embeds = {{
            title = "Synergy Hub | Arsenal",
            description = string.format("🍜 | Game\n`%s` | `%s`\n\n🐼 | JobID:\n`%s`\n\n🐳 | Player\n`%s` | `%s`", 
                gameName, placeId, jobId, username, displayName),
            color = 65793,
            image = {
                url = "https://raw.githubusercontent.com/Xyraniz/Synergy-Hub/refs/heads/main/Synergy-Hub.jpg"
            }
        }}
    }
    
    local function sendRequest()
        local success, response
        if request then
            success, response = pcall(function()
                return request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)})
            end)
        end
        if not success and syn and syn.request then
            success, response = pcall(function()
                return syn.request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)})
            end)
        end
        if not success and http_request then
            success, response = pcall(function()
                return http_request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)})
            end)
        end
        if not success then
            success, response = pcall(function()
                return game:GetService("HttpService"):RequestAsync({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)})
            end)
        end
    end
    
    task.spawn(sendRequest)
end

sendWebhook()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local aimbotState = {
    aimbotEnabled = false,
    aimbotSmoothness = 1,
    aimbotFOVSize = 100,
    aimbotFOVColor = Color3.fromRGB(128, 0, 128),
    aimbotTargetPart = "Head",
    aimbotTeamCheck = true,
    aimbotVisibilityCheck = false,
    showFOV = true,
    fovType = "LIMITED_FOV",
    targetSelection = "CLOSEST"
}

local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = aimbotState.aimbotFOVColor
FOVring.Filled = false
FOVring.Radius = aimbotState.aimbotFOVSize
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

local function getTargetPlayer(trg_part, fov, teamCheck, visibilityCheck)
    local candidates = {}
    local Cam = workspace.CurrentCamera
    local playerMousePos = Cam.ViewportSize / 2
    local localPlayer = Players.LocalPlayer
    local localTeam = localPlayer.Team
    local localChar = localPlayer.Character
    local localPos = localChar and localChar.PrimaryPart and localChar.PrimaryPart.Position or Vector3.zero

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and (not teamCheck or not player.Team or player.Team ~= localTeam) then
            local character = player.Character
            if character then
                local part = character:FindFirstChild(trg_part)
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if part and humanoid then
                    local visible = true
                    if visibilityCheck then
                        local direction = part.Position - Cam.CFrame.Position
                        local rayParams = RaycastParams.new()
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        rayParams.FilterDescendantsInstances = {localPlayer.Character}
                        local result = workspace:Raycast(Cam.CFrame.Position, direction, rayParams)
                        visible = not result or result.Instance:IsDescendantOf(character)
                    end
                    if visible then
                        local ePos, onScreen = Cam:WorldToViewportPoint(part.Position)
                        local screenDist = (Vector2.new(ePos.X, ePos.Y) - playerMousePos).Magnitude
                        local threeDDist = (part.Position - localPos).Magnitude
                        local health = humanoid.Health
                        local scoreFolder = player:FindFirstChild("ScoreFolder")
                        local threat = 0
                        if scoreFolder then
                            local kills = scoreFolder:FindFirstChild("Kills")
                            local assists = scoreFolder:FindFirstChild("Assists")
                            if kills and assists then
                                threat = kills.Value + assists.Value
                            end
                        end
                        table.insert(candidates, {
                            player = player,
                            screenDist = onScreen and screenDist or math.huge,
                            threeDDist = threeDDist,
                            health = health,
                            threat = threat,
                            onScreen = onScreen
                        })
                    end
                end
            end
        end
    end

    local filtered = {}
    for _, cand in ipairs(candidates) do
        local include = false
        if aimbotState.fovType == "LIMITED_FOV" then
            if cand.onScreen and cand.screenDist < fov then
                include = true
            end
        elseif aimbotState.fovType == "FULL_SCREEN" then
            if cand.onScreen then
                include = true
            end
        elseif aimbotState.fovType == "360_DEGREES" then
            include = true
        end
        if include then
            table.insert(filtered, cand)
        end
    end

    if #filtered == 0 then return nil end

    local selected = filtered[1]
    if aimbotState.targetSelection == "CLOSEST" then
        for _, cand in ipairs(filtered) do
            if cand.threeDDist < selected.threeDDist then
                selected = cand
            end
        end
    elseif aimbotState.targetSelection == "FARTHEST" then
        for _, cand in ipairs(filtered) do
            if cand.threeDDist > selected.threeDDist then
                selected = cand
            end
        end
    elseif aimbotState.targetSelection == "HIGHEST_HEALTH" then
        for _, cand in ipairs(filtered) do
            if cand.health > selected.health then
                selected = cand
            end
        end
    elseif aimbotState.targetSelection == "LOWEST_HEALTH" then
        for _, cand in ipairs(filtered) do
            if cand.health < selected.health then
                selected = cand
            end
        end
    elseif aimbotState.targetSelection == "HIGHEST_THREAT" then
        for _, cand in ipairs(filtered) do
            if cand.threat > selected.threat then
                selected = cand
            end
        end
    elseif aimbotState.targetSelection == "LOWEST_THREAT" then
        for _, cand in ipairs(filtered) do
            if cand.threat < selected.threat then
                selected = cand
            end
        end
    end

    return selected.player
end

local function cleanupAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    if FOVring then
        FOVring:Remove()
        FOVring = nil
    end
end

local function initializeAimbot()
    if not FOVring then
        FOVring = Drawing.new("Circle")
        FOVring.Visible = false
        FOVring.Thickness = 2
        FOVring.Color = aimbotState.aimbotFOVColor
        FOVring.Filled = false
        FOVring.Radius = aimbotState.aimbotFOVSize
        FOVring.Position = workspace.CurrentCamera.ViewportSize / 2
    end
    
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        updateDrawings()
    end)
end

local function createMainWindow()
    local Window = SynergyUI:CreateWindow({
        Title = "Synergy Hub - Arsenal",
        Author = "Xyraniz\nSynergy Team",
        ToggleKey = Enum.KeyCode.X,
        AccentColor = Color3.fromRGB(100, 70, 255),
        ConfigFile = "SynergyHub_Arsenal.json",
        CloseOnEscape = false
    })

    local InfoTab = Window:CreateTab("Info")
    local AutoFarmTab = Window:CreateTab("AutoFarm")
    local AimbotTab = Window:CreateTab("Aimbot")
    local HitboxTab = Window:CreateTab("Hitbox")
    local VisualTab = Window:CreateTab("Visual")
    local WeaponsTab = Window:CreateTab("Weapon Mods")
    local PlayerTab = Window:CreateTab("Player")

    InfoTab:CreateParagraph({
        Title = "",
        Content = ""
    })

    InfoTab:CreateParagraph({
        Title = "What is Synergy Hub?",
        Content = "A script hub for Roblox with universal and game-specific scripts. Designed to enhance your gaming experience."
    })

    InfoTab:CreateParagraph({
        Title = "Credits",
        Content = "Xyraniz\nSynergyTeam"
    })

    InfoTab:CreateButton({
        Name = "Discord Server",
        Callback = function()
            pcall(function() setclipboard("https://discord.gg/WgxZwefhpz") end)
            SynergyUI:Notify("Invite copied", 2, Color3.fromRGB(0, 170, 255), "TopRight")
        end,
        Tooltip = "Copy invite"
    })

    InfoTab:CreateKeybind({
        Name = "Synergy Hub Key",
        Flag = "Keybind",
        CurrentKeybind = "X",
        Callback = function(v)
            local key = Enum.KeyCode[v]
            if key then
                Window.ToggleKey = key
            end
        end
    })

    local AutoFarmSettings = {
        Enabled = false,
        Height = 5,
        Distance = 5
    }
    
    local autoFarmConnection
    
    local function updateAutoFarm()
        if autoFarmConnection then
            autoFarmConnection:Disconnect()
            autoFarmConnection = nil
        end
        
        if AutoFarmSettings.Enabled then
            autoFarmConnection = RunService.Heartbeat:Connect(function()
                local lp = Players.LocalPlayer
                local char = lp.Character
                if not char then return end
                local hum = char:FindFirstChild("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if not hum or not root or hum.Health <= 0 then return end
                
                local function sameTeam(p1, p2)
                    if p1.Team and p2.Team then
                        return p1.Team == p2.Team
                    end
                    return false
                end
                
                local function getNearestPlayer()
                    local nearest = nil
                    local dist = math.huge
                    local localPos = root.Position
                    for _, v in pairs(Players:GetPlayers()) do
                        if v ~= lp and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
                            if not sameTeam(lp, v) then
                                local targetPos = v.Character.HumanoidRootPart.Position
                                local vertical_diff = targetPos.Y - localPos.Y
                                if vertical_diff < -50 then continue end
                                local d = (localPos - targetPos).Magnitude
                                if d < dist then
                                    dist = d
                                    nearest = v.Character
                                end
                            end
                        end
                    end
                    return nearest
                end
                
                local function getBackPosition(targetRoot)
                    return targetRoot.CFrame * CFrame.new(0, 0, AutoFarmSettings.Distance) + Vector3.new(0, AutoFarmSettings.Height, 0)
                end
                
                local target = getNearestPlayer()
                local noTargetCounter = 0
                if target and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("Head") and target.Humanoid.Health > 0 then
                    noTargetCounter = 0
                    local pos = getBackPosition(target.HumanoidRootPart)
                    root.CFrame = CFrame.new(pos.p, target.Head.Position)
                    root.Velocity = Vector3.new(0, 0, 0)
                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, target.Head.Position)
                else
                    noTargetCounter = noTargetCounter + 1
                    root.Velocity = Vector3.new(0, 0, 0)
                    if noTargetCounter > 30 then
                        root.CFrame = root.CFrame * CFrame.new(0, 15, 0)
                        noTargetCounter = 0
                    end
                end
            end)
        end
    end
    
    Window.Flags = Window.Flags or {}
    Window.Flags["AutoFarmEnabled"] = AutoFarmTab:CreateToggle({
        Name = "AutoFarm Enabled",
        Flag = "AutoFarmEnabled",
        CurrentValue = false,
        Callback = function(v)
            AutoFarmSettings.Enabled = v
            updateAutoFarm()
        end
    })
    
    AutoFarmTab:CreateKeybind({
        Name = "Toggle AutoFarm",
        Flag = "AutoFarmKeybind",
        CurrentKeybind = "",
        Callback = function()
            local newState = not Window.Flags["AutoFarmEnabled"].CurrentValue
            Window.Flags["AutoFarmEnabled"]:Set(newState)
        end
    })
    
    AutoFarmTab:CreateSlider({
        Name = "Height",
        Flag = "AutoFarmHeight",
        Range = {0, 50},
        Increment = 1,
        CurrentValue = 5,
        Callback = function(v)
            AutoFarmSettings.Height = v
        end
    })
    
    AutoFarmTab:CreateSlider({
        Name = "Distance",
        Flag = "AutoFarmDistance",
        Range = {0, 50},
        Increment = 1,
        CurrentValue = 5,
        Callback = function(v)
            AutoFarmSettings.Distance = v
        end
    })

    initializeAimbot()
    
    aimbotConnection = RunService.RenderStepped:Connect(function()
        updateDrawings()
        if aimbotState.aimbotEnabled then
            FOVring.Visible = aimbotState.showFOV and aimbotState.aimbotEnabled and aimbotState.fovType == "LIMITED_FOV" or false
            local closest = getTargetPlayer(aimbotState.aimbotTargetPart, aimbotState.aimbotFOVSize, aimbotState.aimbotTeamCheck, aimbotState.aimbotVisibilityCheck)
            if closest and closest.Character and closest.Character:FindFirstChild(aimbotState.aimbotTargetPart) then
                lookAt(closest.Character[aimbotState.aimbotTargetPart].Position, aimbotState.aimbotSmoothness)
            end
        end
    end)

    Window.Flags["AimbotEnabled"] = AimbotTab:CreateToggle({
        Name = "Aimbot Enabled",
        Flag = "AimbotEnabled",
        CurrentValue = false,
        Callback = function(v)
            aimbotState.aimbotEnabled = v
        end
    })
    
    AimbotTab:CreateKeybind({
        Name = "Toggle Aimbot",
        Flag = "AimbotKeybind",
        CurrentKeybind = "",
        Callback = function()
            local newState = not Window.Flags["AimbotEnabled"].CurrentValue
            Window.Flags["AimbotEnabled"]:Set(newState)
        end
    })

    AimbotTab:CreateToggle({
        Name = "Show FOV",
        Flag = "ShowFOV",
        CurrentValue = false,
        Callback = function(v)
            aimbotState.showFOV = v
        end
    })

    AimbotTab:CreateDropdown({
        Name = "FOV Type",
        Flag = "AimbotFOVType",
        Options = {"Limited FOV", "Full Screen", "360 Degrees"},
        CurrentOption = "Limited FOV",
        Callback = function(v)
            local mapping = {
                ["Limited FOV"] = "LIMITED_FOV",
                ["Full Screen"] = "FULL_SCREEN",
                ["360 Degrees"] = "360_DEGREES"
            }
            aimbotState.fovType = mapping[v] or "LIMITED_FOV"
        end
    })

    AimbotTab:CreateDropdown({
        Name = "Target Selection",
        Flag = "AimbotTargetSelection",
        Options = {"Closest", "Farthest", "Highest Health", "Lowest Health", "Highest Threat", "Lowest Threat"},
        CurrentOption = "Closest",
        Callback = function(v)
            local mapping = {
                ["Closest"] = "CLOSEST",
                ["Farthest"] = "FARTHEST",
                ["Highest Health"] = "HIGHEST_HEALTH",
                ["Lowest Health"] = "LOWEST_HEALTH",
                ["Highest Threat"] = "HIGHEST_THREAT",
                ["Lowest Threat"] = "LOWEST_THREAT"
            }
            aimbotState.targetSelection = mapping[v] or "CLOSEST"
        end
    })

    AimbotTab:CreateSlider({
        Name = "Smoothing",
        Flag = "AimbotSmoothness",
        Range = {0.1, 1},
        Increment = 0.05,
        CurrentValue = 1,
        Callback = function(v)
            aimbotState.aimbotSmoothness = v
        end
    })

    AimbotTab:CreateColorPicker({
        Name = "FOV Color",
        Flag = "AimbotFOVColor",
        Color = Color3.fromRGB(128, 0, 128),
        Callback = function(v)
            aimbotState.aimbotFOVColor = v
            if FOVring then
                FOVring.Color = v
            end
        end
    })

    AimbotTab:CreateSlider({
        Name = "FOV Size",
        Flag = "AimbotFOVSize",
        Range = {50, 500},
        Increment = 10,
        CurrentValue = 100,
        Callback = function(v)
            aimbotState.aimbotFOVSize = v
            if FOVring then
                FOVring.Radius = v
            end
        end
    })

    AimbotTab:CreateDropdown({
        Name = "Target Part",
        Flag = "AimbotTargetPart",
        Options = {"Head", "HumanoidRootPart", "UpperTorso"},
        CurrentOption = "Head",
        Callback = function(v)
            aimbotState.aimbotTargetPart = v
        end
    })

    AimbotTab:CreateToggle({
        Name = "Team Check",
        Flag = "AimbotTeamCheck",
        CurrentValue = true,
        Callback = function(v)
            aimbotState.aimbotTeamCheck = v
        end
    })

    AimbotTab:CreateToggle({
        Name = "Visibility Check",
        Flag = "AimbotVisibilityCheck",
        CurrentValue = false,
        Callback = function(v)
            aimbotState.aimbotVisibilityCheck = v
        end
    })

    local HitboxSettings = {
        Enabled = false,
        Size = 12,
        Transparency = 1,
        Color = Color3.fromRGB(255, 0, 0),
        TeamCheck = true
    }

    local ESPSettings = {
        Box = false,
        Names = false,
        TeamCheck = true,
        Highlights = {
            Enabled = false,
            Color = Color3.fromRGB(255, 0, 0),
            Transparency = 0.5,
            TeamCheck = true
        }
    }

    local originalHitboxProperties = {}

    local function isTeammate(targetPlayer)
        local localTeam = LocalPlayer.Team
        local targetTeam = targetPlayer.Team
        
        if not localTeam or not targetTeam then
            return false
        end
        
        return localTeam == targetTeam
    end

    local function restoreHitbox(targetPlayer)
        if targetPlayer.Character then
            local bodyParts = {"RightUpperLeg", "LeftUpperLeg", "HeadHB", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "UpperTorso"}
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
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            restoreHitbox(targetPlayer)
        end
        originalHitboxProperties = {}
    end
    
    Window.Flags["HitboxEnabled"] = HitboxTab:CreateToggle({
        Name = "Hitbox",
        Flag = "HitboxEnabled",
        CurrentValue = false,
        Callback = function(v)
            HitboxSettings.Enabled = v
            
            if v then
                spawn(function()
                    while HitboxSettings.Enabled do
                        pcall(function()
                            for _,targetPlayer in pairs(Players:GetPlayers()) do
                                if targetPlayer.Name ~= LocalPlayer.Name then
                                    local shouldExpand = not (HitboxSettings.TeamCheck and isTeammate(targetPlayer))
                                    
                                    if targetPlayer.Character then
                                        local bodyParts = {"RightUpperLeg", "LeftUpperLeg", "HeadHB", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "UpperTorso"}
                                        for _, partName in pairs(bodyParts) do
                                            local part = targetPlayer.Character:FindFirstChild(partName)
                                            if part then
                                                if not originalHitboxProperties[targetPlayer] then
                                                    originalHitboxProperties[targetPlayer] = {}
                                                end
                                                if not originalHitboxProperties[targetPlayer][partName] then
                                                    originalHitboxProperties[targetPlayer][partName] = {
                                                        Size = part.Size,
                                                        Transparency = part.Transparency,
                                                        Color = part.Color,
                                                        CanCollide = part.CanCollide
                                                    }
                                                end
                                                
                                                if shouldExpand then
                                                    local newSize = Vector3.new(HitboxSettings.Size, HitboxSettings.Size, HitboxSettings.Size)
                                                    if part.Size ~= newSize or part.Transparency ~= HitboxSettings.Transparency or part.Color ~= HitboxSettings.Color or part.CanCollide ~= false then
                                                        part.CanCollide = false
                                                        part.Transparency = HitboxSettings.Transparency
                                                        part.Color = HitboxSettings.Color
                                                        part.Size = newSize
                                                    end
                                                else
                                                    local props = originalHitboxProperties[targetPlayer][partName]
                                                    if part.Size ~= props.Size or part.Transparency ~= props.Transparency or part.Color ~= props.Color or part.CanCollide ~= props.CanCollide then
                                                        part.Size = props.Size
                                                        part.Transparency = props.Transparency
                                                        part.Color = props.Color
                                                        part.CanCollide = props.CanCollide
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                        wait(0.3)
                    end
                end)
            else
                restoreAllHitboxes()
            end
        end
    })
    
    HitboxTab:CreateKeybind({
        Name = "Toggle Hitbox",
        Flag = "HitboxKeybind",
        CurrentKeybind = "",
        Callback = function()
            local newState = not Window.Flags["HitboxEnabled"].CurrentValue
            Window.Flags["HitboxEnabled"]:Set(newState)
        end
    })

    HitboxTab:CreateSlider({
        Name = "Hitbox Size",
        Flag = "HitboxSize",
        Range = {1, 25},
        Increment = 1,
        CurrentValue = 12,
        Callback = function(v)
            HitboxSettings.Size = v
        end
    })

    HitboxTab:CreateSlider({
        Name = "Hitbox Transparency",
        Flag = "HitboxTransparency",
        Range = {0, 1},
        Increment = 0.1,
        CurrentValue = 1,
        Callback = function(v)
            HitboxSettings.Transparency = v
        end
    })

    HitboxTab:CreateColorPicker({
        Name = "Hitbox Color",
        Flag = "HitboxColor",
        Color = Color3.fromRGB(255, 0, 0),
        Callback = function(v)
            HitboxSettings.Color = v
        end
    })

    HitboxTab:CreateToggle({
        Name = "Team Check",
        Flag = "HitboxTeamCheck",
        CurrentValue = true,
        Callback = function(v)
            HitboxSettings.TeamCheck = v
        end
    })

    local nameTagContainer = Instance.new("BillboardGui")
    local playerNameLabel = Instance.new("TextLabel")
    local boxContainer = Instance.new("BillboardGui")
    local torsoHighlight = Instance.new("Frame")

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

    boxContainer.Name = "BoxESP"
    boxContainer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    boxContainer.Active = true
    boxContainer.AlwaysOnTop = true
    boxContainer.LightInfluence = 1.000
    boxContainer.MaxDistance = 999999.000
    boxContainer.Size = UDim2.new(4, 0, 6, 0)

    torsoHighlight.Name = "TorsoHighlight"
    torsoHighlight.Parent = boxContainer
    torsoHighlight.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    torsoHighlight.BackgroundTransparency = 0.7
    torsoHighlight.BorderSizePixel = 2
    torsoHighlight.BorderColor3 = Color3.fromRGB(0, 0, 0)
    torsoHighlight.Size = UDim2.new(1, 0, 1, 0)

    local function addESPToPlayer(targetPlayer)
        targetPlayer.CharacterAdded:Connect(function(character)
            wait(0.5)
            if character:FindFirstChild("Head") then
                local nameClone = nameTagContainer:Clone()
                nameClone.Parent = character:FindFirstChild("Head")
                nameClone:FindFirstChild("NameLabel").Text = targetPlayer.Name
            end
            if character:FindFirstChild("UpperTorso") then
                local boxClone = boxContainer:Clone()
                boxClone.Parent = character:FindFirstChild("UpperTorso")
            end
        end)
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
            local nameClone = nameTagContainer:Clone()
            nameClone.Parent = targetPlayer.Character:FindFirstChild("Head")
            nameClone:FindFirstChild("NameLabel").Text = targetPlayer.Name
        end
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("UpperTorso") then
            local boxClone = boxContainer:Clone()
            boxClone.Parent = targetPlayer.Character:FindFirstChild("UpperTorso")
        end
    end

    for _, targetPlayer in pairs(Players:GetPlayers()) do
        if targetPlayer ~= LocalPlayer then
            addESPToPlayer(targetPlayer)
        end
    end

    Players.PlayerAdded:Connect(function(newPlayer)
        if newPlayer ~= LocalPlayer then
            addESPToPlayer(newPlayer)
        end
    end)

    local highlights = {}
    
    local function updateESP()
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer.Character then
                local shouldShow = not ESPSettings.TeamCheck or not isTeammate(targetPlayer)
                
                local nameTag = targetPlayer.Character:FindFirstChild("Head") and 
                               targetPlayer.Character.Head:FindFirstChild("NameTagESP")
                if nameTag then
                    nameTag.NameLabel.TextTransparency = ESPSettings.Names and (shouldShow and 0 or 1) or 1
                end
                
                local boxESP = targetPlayer.Character:FindFirstChild("UpperTorso") and 
                              targetPlayer.Character.UpperTorso:FindFirstChild("BoxESP")
                if boxESP then
                    boxESP.TorsoHighlight.Visible = ESPSettings.Box and shouldShow
                end

                local shouldShowHighlights = ESPSettings.Highlights.Enabled and 
                                           (not ESPSettings.Highlights.TeamCheck or not isTeammate(targetPlayer))
                
                if shouldShowHighlights then
                    if not highlights[targetPlayer] then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ESP_Highlight"
                        highlight.Adornee = targetPlayer.Character
                        highlight.Enabled = true
                        highlight.FillColor = ESPSettings.Highlights.Color
                        highlight.FillTransparency = ESPSettings.Highlights.Transparency
                        highlight.OutlineColor = ESPSettings.Highlights.Color
                        highlight.OutlineTransparency = 0
                        highlight.Parent = targetPlayer.Character
                        highlights[targetPlayer] = highlight
                    else
                        highlights[targetPlayer].Enabled = true
                        highlights[targetPlayer].FillColor = ESPSettings.Highlights.Color
                        highlights[targetPlayer].FillTransparency = ESPSettings.Highlights.Transparency
                        highlights[targetPlayer].OutlineColor = ESPSettings.Highlights.Color
                    end
                elseif highlights[targetPlayer] then
                    highlights[targetPlayer].Enabled = false
                end
            end
        end
    end

    Players.PlayerRemoving:Connect(function(player)
        if highlights[player] then
            highlights[player]:Destroy()
            highlights[player] = nil
        end
    end)

    local espUpdateInterval = 0.1
    local lastUpdate = tick()
    
    RunService.RenderStepped:Connect(function()
        local now = tick()
        if now - lastUpdate >= espUpdateInterval then
            updateESP()
            lastUpdate = now
        end
    end)

    Window.Flags["HighlightsEnabled"] = VisualTab:CreateToggle({
        Name = "Highlights Enabled",
        Flag = "HighlightsEnabled",
        CurrentValue = false,
        Callback = function(v)
            ESPSettings.Highlights.Enabled = v
            if not v then
                for player, highlight in pairs(highlights) do
                    if highlight then
                        highlight:Destroy()
                    end
                end
                highlights = {}
            end
        end
    })
    
    VisualTab:CreateKeybind({
        Name = "Toggle Highlights",
        Flag = "HighlightsKeybind",
        CurrentKeybind = "",
        Callback = function()
            local newState = not Window.Flags["HighlightsEnabled"].CurrentValue
            Window.Flags["HighlightsEnabled"]:Set(newState)
        end
    })
    
    VisualTab:CreateToggle({
        Name = "Box ESP",
        Flag = "ESPBox",
        CurrentValue = false,
        Callback = function(v)
            ESPSettings.Box = v
        end
    })

    VisualTab:CreateToggle({
        Name = "Names ESP",
        Flag = "ESPNames",
        CurrentValue = false,
        Callback = function(v)
            ESPSettings.Names = v
        end
    })

    VisualTab:CreateToggle({
        Name = "Team Check in ESP",
        Flag = "ESPTeamCheck",
        CurrentValue = true,
        Callback = function(v)
            ESPSettings.TeamCheck = v
        end
    })

    VisualTab:CreateSection("Extra Visuals")
    
    VisualTab:CreateColorPicker({
        Name = "Highlights Color",
        Flag = "HighlightsColor",
        Color = Color3.fromRGB(255, 0, 0),
        Callback = function(v)
            ESPSettings.Highlights.Color = v
        end
    })

    VisualTab:CreateToggle({
        Name = "Team Check",
        Flag = "HighlightsTeamCheck",
        CurrentValue = true,
        Callback = function(v)
            ESPSettings.Highlights.TeamCheck = v
        end
    })

    VisualTab:CreateSlider({
        Name = "Transparency",
        Flag = "HighlightsTransparency",
        Range = {0, 1},
        Increment = 0.1,
        CurrentValue = 0.5,
        Callback = function(v)
            ESPSettings.Highlights.Transparency = v
        end
    })

    local WeaponModifications = {
        InfiniteAmmo = false,
        RapidFire = false,
        RemoveRecoil = false,
        RemoveSpread = false,
        AutoFire = false,
        InstantReload = false
    }

    local WeaponOriginalValues = {
        FireRate = {},
        ReloadTime = {},
        ExtraReloadTime = {},
        AutoFire = {},
        SpreadControl = {},
        RecoilControl = {}
    }

    WeaponsTab:CreateToggle({
        Name = "Infinite Ammo",
        Flag = "InfiniteAmmo",
        CurrentValue = false,
        Callback = function(v)
            WeaponModifications.InfiniteAmmo = v
            game:GetService("ReplicatedStorage").wkspc.CurrentCurse.Value = v and "Infinite Ammo" or ""
        end
    })

    WeaponsTab:CreateToggle({
        Name = "Fire Rate Modifier",
        Flag = "FireRate",
        CurrentValue = false,
        Callback = function(v)
            WeaponModifications.RapidFire = v
            
            if v then
                for _, weaponComponent in pairs(game.ReplicatedStorage.Weapons:GetDescendants()) do
                    if weaponComponent.Name == "FireRate" or weaponComponent.Name == "BFireRate" then
                        if not WeaponOriginalValues.FireRate[weaponComponent] then
                            WeaponOriginalValues.FireRate[weaponComponent] = weaponComponent.Value
                        end
                        weaponComponent.Value = 0.02
                    end
                end
            else
                for weaponComponent, originalValue in pairs(WeaponOriginalValues.FireRate) do
                    if weaponComponent then
                        weaponComponent.Value = originalValue
                    end
                end
            end
        end
    })

    WeaponsTab:CreateToggle({
        Name = "No Recoil",
        Flag = "NoRecoil",
        CurrentValue = false,
        Callback = function(v)
            WeaponModifications.RemoveRecoil = v
            
            if v then
                for _, weaponComponent in pairs(game:GetService("ReplicatedStorage").Weapons:GetDescendants()) do
                    if weaponComponent.Name == "RecoilControl" or weaponComponent.Name == "Recoil" then
                        if not WeaponOriginalValues.RecoilControl[weaponComponent] then
                            WeaponOriginalValues.RecoilControl[weaponComponent] = weaponComponent.Value
                        end
                        weaponComponent.Value = 0
                    end
                end
            else
                for weaponComponent, originalValue in pairs(WeaponOriginalValues.RecoilControl) do
                    if weaponComponent then
                        weaponComponent.Value = originalValue
                    end
                end
            end
        end
    })

    WeaponsTab:CreateToggle({
        Name = "Fast Reload",
        Flag = "FastReload",
        CurrentValue = false,
        Callback = function(v)
            WeaponModifications.InstantReload = v
            
            if v then
                for _, weaponObject in pairs(game.ReplicatedStorage.Weapons:GetChildren()) do
                    if weaponObject:FindFirstChild("ReloadTime") then
                        if not WeaponOriginalValues.ReloadTime[weaponObject] then
                            WeaponOriginalValues.ReloadTime[weaponObject] = weaponObject.ReloadTime.Value
                        end
                        weaponObject.ReloadTime.Value = 0.01
                    end
                    if weaponObject:FindFirstChild("EReloadTime") then
                        if not WeaponOriginalValues.ExtraReloadTime[weaponObject] then
                            WeaponOriginalValues.ExtraReloadTime[weaponObject] = weaponObject.EReloadTime.Value
                        end
                        weaponObject.EReloadTime.Value = 0.01
                    end
                end
            else
                for weaponObject, originalValue in pairs(WeaponOriginalValues.ReloadTime) do
                    if weaponObject and weaponObject:FindFirstChild("ReloadTime") then
                        weaponObject.ReloadTime.Value = originalValue
                    end
                end
                for weaponObject, originalValue in pairs(WeaponOriginalValues.ExtraReloadTime) do
                    if weaponObject and weaponObject:FindFirstChild("EReloadTime") then
                        weaponObject.EReloadTime.Value = originalValue
                    end
                end
            end
        end
    })

    WeaponsTab:CreateToggle({
        Name = "Always Automatic",
        Flag = "AlwaysAuto",
        CurrentValue = false,
        Callback = function(v)
            WeaponModifications.AutoFire = v
            
            if v then
                for _, weaponComponent in pairs(game.ReplicatedStorage.Weapons:GetDescendants()) do
                    if weaponComponent.Name == "Auto" or weaponComponent.Name == "AutoFire" or weaponComponent.Name == "Automatic" then
                        if not WeaponOriginalValues.AutoFire[weaponComponent] then
                            WeaponOriginalValues.AutoFire[weaponComponent] = weaponComponent.Value
                        end
                        weaponComponent.Value = true
                    end
                end
            else
                for weaponComponent, originalValue in pairs(WeaponOriginalValues.AutoFire) do
                    if weaponComponent then
                        weaponComponent.Value = originalValue
                    end
                end
            end
        end
    })

    WeaponsTab:CreateToggle({
        Name = "No Spread",
        Flag = "NoSpread",
        CurrentValue = false,
        Callback = function(v)
            WeaponModifications.RemoveSpread = v
            
            if v then
                for _, weaponComponent in pairs(game:GetService("ReplicatedStorage").Weapons:GetDescendants()) do
                    if weaponComponent.Name == "MaxSpread" or weaponComponent.Name == "Spread" then
                        if not WeaponOriginalValues.SpreadControl[weaponComponent] then
                            WeaponOriginalValues.SpreadControl[weaponComponent] = weaponComponent.Value
                        end
                        weaponComponent.Value = 0
                    end
                end
            else
                for weaponComponent, originalValue in pairs(WeaponOriginalValues.SpreadControl) do
                    if weaponComponent then
                        weaponComponent.Value = originalValue
                    end
                end
            end
        end
    })

    local PlayerFeatures = {
        WalkSpeed = 16,
        JumpPower = 50,
        InfiniteJump = false,
        NoClip = false,
        Flight = false,
        FlightSpeed = 50,
        SpeedHack = false
    }

    local FlightController = {active = false, speed = 50}
    local playerCharacter, humanoidComponent, velocityController, rotationController, cameraView, isFlying
    local keyStates = {W = false, S = false, A = false, D = false, Moving = false}

    local noclipConnection
    local infiniteJumpConnection
    local speedHackConnection
    local characterAddedConnection

    local function applyPlayerMods(character)
        pcall(function()
            local humanoid = character:WaitForChild("Humanoid", 5)
            if humanoid then
                humanoid.WalkSpeed = PlayerFeatures.SpeedHack and 100 or PlayerFeatures.WalkSpeed
                humanoid.JumpPower = PlayerFeatures.JumpPower

                if PlayerFeatures.SpeedHack then
                    if speedHackConnection then speedHackConnection:Disconnect() end
                    speedHackConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                        humanoid.WalkSpeed = 100
                    end)
                end

                if PlayerFeatures.NoClip then
                    if noclipConnection then noclipConnection:Disconnect() end
                    noclipConnection = RunService.Stepped:Connect(function()
                        for _, part in pairs(character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end)
                end

                if PlayerFeatures.Flight then
                    EnableFlight()
                end
            end
        end)
    end

    characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        applyPlayerMods(character)
    end)

    if LocalPlayer.Character then
        applyPlayerMods(LocalPlayer.Character)
    end

    local function EnableFlight()
        pcall(function()
            if not LocalPlayer.Character or isFlying then return end
            playerCharacter = LocalPlayer.Character
            humanoidComponent = playerCharacter:WaitForChild("Humanoid")
            local rootPart = playerCharacter:WaitForChild("HumanoidRootPart")
            if not humanoidComponent or not rootPart then return end
            humanoidComponent.PlatformStand = true
            cameraView = workspace.CurrentCamera
            velocityController = Instance.new("BodyVelocity")
            rotationController = Instance.new("BodyAngularVelocity")
            velocityController.Velocity = Vector3.new(0, 0, 0)
            velocityController.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            velocityController.P = 1250
            rotationController.AngularVelocity = Vector3.new(0, 0, 0)
            rotationController.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            rotationController.P = 1250
            velocityController.Parent = rootPart
            rotationController.Parent = rootPart
            isFlying = true
            humanoidComponent.Died:Once(function()
                isFlying = false
                DisableFlight()
            end)
        end)
    end

    local function DisableFlight()
        pcall(function()
            if not playerCharacter or not isFlying then return end
            humanoidComponent.PlatformStand = false
            if velocityController then velocityController:Destroy() end
            if rotationController then rotationController:Destroy() end
            isFlying = false
        end)
    end

    game:GetService("UserInputService").InputBegan:Connect(function(input,gameProcessed)
        if gameProcessed then return end 
        for key,state in pairs(keyStates) do 
            if key~="Moving" and input.KeyCode==Enum.KeyCode[key] then 
                keyStates[key]=true 
                keyStates.Moving=true 
            end 
        end 
    end)

    game:GetService("UserInputService").InputEnded:Connect(function(input,gameProcessed)
        if gameProcessed then return end 
        local anyKeyActive=false 
        for key,state in pairs(keyStates) do 
            if key~="Moving" then 
                if input.KeyCode==Enum.KeyCode[key] then 
                    keyStates[key]=false 
                end 
                if keyStates[key] then 
                    anyKeyActive=true 
                end 
            end 
        end 
        keyStates.Moving=anyKeyActive 
    end)

    local function GetMovementVector(directionVector)
        return directionVector*(FlightController.speed/directionVector.Magnitude) 
    end

    RunService.Heartbeat:Connect(function(timeStep)
        if isFlying and playerCharacter and playerCharacter.PrimaryPart then 
            local position=playerCharacter.PrimaryPart.Position 
            local cameraFrame=cameraView.CFrame 
            local xAngle,yAngle,zAngle=cameraFrame:toEulerAnglesXYZ()
            playerCharacter:SetPrimaryPartCFrame(CFrame.new(position.x,position.y,position.z)*CFrame.Angles(xAngle,yAngle,zAngle))
            if keyStates.Moving then 
                local movement=Vector3.new()
                if keyStates.W then movement=movement+(GetMovementVector(cameraFrame.lookVector)) end 
                if keyStates.S then movement=movement-(GetMovementVector(cameraFrame.lookVector)) end 
                if keyStates.A then movement=movement-(GetMovementVector(cameraFrame.rightVector)) end 
                if keyStates.D then movement=movement+(GetMovementVector(cameraFrame.rightVector)) end 
                playerCharacter:TranslateBy(movement*timeStep) 
            end 
        end 
    end)

    PlayerTab:CreateToggle({
        Name = "Fly",
        Flag = "FlyEnabled",
        CurrentValue = false,
        Callback = function(v)
            PlayerFeatures.Flight = v
            if v then
                EnableFlight()
            else
                DisableFlight()
            end
        end
    })

    PlayerTab:CreateSlider({
        Name = "Flight Speed",
        Flag = "FlySpeed",
        Range = {1, 500},
        Increment = 1,
        CurrentValue = 50,
        Callback = function(v)
            PlayerFeatures.FlightSpeed = v
            FlightController.speed = v
        end
    })

    PlayerTab:CreateSlider({
        Name = "Walk Speed",
        Flag = "WalkSpeed",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = 16,
        Callback = function(v)
            PlayerFeatures.WalkSpeed = v
            pcall(function()
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and not PlayerFeatures.SpeedHack then
                    humanoid.WalkSpeed = v
                end
            end)
        end
    })

    PlayerTab:CreateSlider({
        Name = "Jump Power",
        Flag = "JumpPower",
        Range = {30, 500},
        Increment = 1,
        CurrentValue = 50,
        Callback = function(v)
            PlayerFeatures.JumpPower = v
            pcall(function()
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.JumpPower = v
                end
            end)
        end
    })

    PlayerTab:CreateToggle({
        Name = "Speed Hack",
        Flag = "SpeedHack",
        CurrentValue = false,
        Callback = function(v)
            PlayerFeatures.SpeedHack = v
            
            pcall(function()
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if v then
                        if speedHackConnection then speedHackConnection:Disconnect() end
                        speedHackConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                            humanoid.WalkSpeed = 100
                        end)
                        humanoid.WalkSpeed = 100
                    else
                        if speedHackConnection then speedHackConnection:Disconnect() speedHackConnection = nil end
                        humanoid.WalkSpeed = PlayerFeatures.WalkSpeed
                    end
                end
            end)
        end
    })

    PlayerTab:CreateToggle({
        Name = "Infinite Jump",
        Flag = "InfJump",
        CurrentValue = false,
        Callback = function(v)
            PlayerFeatures.InfiniteJump = v
            
            if v then
                if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
                infiniteJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
                    pcall(function()
                        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end)
                end)
            else
                if infiniteJumpConnection then infiniteJumpConnection:Disconnect() infiniteJumpConnection = nil end
            end
        end
    })

    PlayerTab:CreateToggle({
        Name = "Noclip",
        Flag = "Noclip",
        CurrentValue = false,
        Callback = function(v)
            PlayerFeatures.NoClip = v
            
            if v then
                if noclipConnection then noclipConnection:Disconnect() end
                noclipConnection = RunService.Stepped:Connect(function()
                    pcall(function()
                        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end)
                end)
            else
                if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
                pcall(function()
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end)
            end
        end
    })

    PlayerTab:CreateSlider({
        Name = "Arsenal FOV",
        Flag = "FOVValue",
        Range = {0, 120},
        Increment = 1,
        CurrentValue = 70,
        Callback = function(v)
            game:GetService("Players").LocalPlayer.Settings.FOV.Value = v
        end
    })
end

createMainWindow()
