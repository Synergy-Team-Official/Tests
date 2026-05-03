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
    local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    local placeId = game.PlaceId
    local jobId = game.JobId
    local player = Players.LocalPlayer
    local username = player.Name
    local displayName = player.DisplayName
    local execName = getexecutorname and getexecutorname() or "Unknown"
    local payload = {
        embeds = {{
            title = "Synergy Hub | Murders Vs Sheriff",
            description = string.format("🎮 | In game\n`%s` | `%s`\n\n🌐 | JobID:\n`%s`\n\n👤 | Player\n`%s` | `%s`\n\n⚙️ | Executor\n`%s`", gameName, placeId, jobId, username, displayName, execName),
            color = 65793,
            image = { url = "https://raw.githubusercontent.com/Xyraniz/Synergy-Hub/refs/heads/main/Synergy-Hub.jpg" }
        }}
    }
    local function sendRequest()
        local response
        if request then
            response = request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)})
        end
        if not response and syn and syn.request then
            response = syn.request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)})
        end
        if not response and http_request then
            response = http_request({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)})
        end
        if not response then
            response = game:GetService("HttpService"):RequestAsync({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = game:GetService("HttpService"):JSONEncode(payload)})
        end
    end
    task.spawn(sendRequest)
end
sendWebhook()

local SynergyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Synergy-Hub-Official/SynergyUI-Lib/refs/heads/main/SRC/source.lua"))()

local guiParent = RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui") or CoreGui

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

local GlobalGameInfo = { AlivePlayersFolder = nil, PlayerTeamName = nil, CurrentGameFolder = nil, LastCheckTime = 0, MyTeam = nil, EnemyTeam = nil }

local function UpdateGlobalGameInfo()
    local runningGames = workspace:FindFirstChild("RunningGames")
    if not runningGames then return end
    local foundGame = nil
    local foundAliveParams = nil
    local foundTeam = nil
    for _, gameFolder in ipairs(runningGames:GetChildren()) do
        local aliveParams = gameFolder:FindFirstChild("AlivePlayers")
        if aliveParams and aliveParams:IsA("Folder") then
            if aliveParams:FindFirstChild("TeamBlue") and aliveParams.TeamBlue:FindFirstChild(LocalPlayer.Name) then
                foundGame = gameFolder
                foundAliveParams = aliveParams
                foundTeam = "TeamBlue"
                break
            elseif aliveParams:FindFirstChild("TeamRed") and aliveParams.TeamRed:FindFirstChild(LocalPlayer.Name) then
                foundGame = gameFolder
                foundAliveParams = aliveParams
                foundTeam = "TeamRed"
                break
            end
        end
    end
    if foundGame and foundAliveParams then
        GlobalGameInfo.AlivePlayersFolder = foundAliveParams
        GlobalGameInfo.PlayerTeamName = foundTeam
        GlobalGameInfo.CurrentGameFolder = foundGame
        GlobalGameInfo.MyTeam = foundTeam
        GlobalGameInfo.EnemyTeam = (foundTeam == "TeamBlue") and "TeamRed" or "TeamBlue"
    else
        GlobalGameInfo.AlivePlayersFolder = nil
        GlobalGameInfo.PlayerTeamName = nil
        GlobalGameInfo.CurrentGameFolder = nil
        GlobalGameInfo.MyTeam = nil
        GlobalGameInfo.EnemyTeam = nil
    end
end

local function IsTeammateGlobal(targetPlayer)
    if targetPlayer == LocalPlayer then return true end
    local currentTime = tick()
    if (currentTime - GlobalGameInfo.LastCheckTime) > 0.5 then
        GlobalGameInfo.LastCheckTime = currentTime
        UpdateGlobalGameInfo()
    end
    if GlobalGameInfo.AlivePlayersFolder and GlobalGameInfo.PlayerTeamName then
        local myTeamFolder = GlobalGameInfo.AlivePlayersFolder:FindFirstChild(GlobalGameInfo.PlayerTeamName)
        if myTeamFolder and myTeamFolder:FindFirstChild(SanitizeName(targetPlayer.Name)) then
            return true
        end
        local enemyTeamFolder = GlobalGameInfo.AlivePlayersFolder:FindFirstChild(GlobalGameInfo.EnemyTeam)
        if enemyTeamFolder and enemyTeamFolder:FindFirstChild(SanitizeName(targetPlayer.Name)) then
            return false
        end
    end
    return false
end

local function IsInRound()
    UpdateGlobalGameInfo()
    return GlobalGameInfo.AlivePlayersFolder ~= nil
end

local function GetEnemyPlayersList()
    local enemies = {}
    UpdateGlobalGameInfo()
    if GlobalGameInfo.AlivePlayersFolder and GlobalGameInfo.EnemyTeam then
        local enemyTeamFolder = GlobalGameInfo.AlivePlayersFolder:FindFirstChild(GlobalGameInfo.EnemyTeam)
        if enemyTeamFolder then
            for _, nameValue in ipairs(enemyTeamFolder:GetChildren()) do
                local player = Players:FindFirstChild(nameValue.Name)
                if player and player ~= LocalPlayer then
                    table.insert(enemies, player)
                end
            end
        end
    end
    return enemies
end

local globalLastShotTime = 0
local globalShotCooldown = 3
local maxDistance = 200
local instanceCache = {}
local cacheDuration = 0.5
local raycastBudget = 100
local raycastCost = 0
local silentAimConfig = { predictionStrength = 1, cameraThreshold = 0.1, maxCameraAngle = 30, maxRaysPerFrame = 8, baseRaycastCount = 5, maxRaycastCount = 10, distanceBasedRayReduction = true, screenCenterWeight = 0.4, distanceWeight = 0.3, visibilityWeight = 0.3 }
local aimParts = { 'HumanoidRootPart', 'Head', 'UpperTorso', 'LowerTorso' }
local silentAimTargetPart = "Head"

local function GetComponent(instance, componentName)
    local key = tostring(instance) .. '_' .. componentName
    local cached = instanceCache[key]
    if cached and (tick() - cached.time) < cacheDuration then return cached.component end
    local component = instance:FindFirstChild(componentName)
    instanceCache[key] = {component = component, time = tick()}
    return component
end

local function IsTargetInView(targetPos)
    local camera = workspace.CurrentCamera
    if not camera then return false end
    local cameraPos = camera.CFrame.Position
    local direction = (targetPos - cameraPos).Unit
    local lookVector = camera.CFrame.LookVector
    return direction:Dot(lookVector) > silentAimConfig.cameraThreshold
end

local function GetAngleToTarget(targetPos)
    local camera = workspace.CurrentCamera
    if not camera then return 180 end
    local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
    if not onScreen then return 180 end
    local viewportCenter = camera.ViewportSize / 2
    local diffX = screenPos.X - viewportCenter.X
    local diffY = screenPos.Y - viewportCenter.Y
    local angle = math.deg(math.atan2(diffY, diffX))
    local absAngle = math.abs(angle)
    if absAngle > 180 then absAngle = 360 - absAngle end
    return absAngle
end

local function CalculatePrediction(targetRoot, targetHumanoid)
    if not targetRoot or not targetHumanoid then return Vector3.new(0, 0, 0) end
    local velocity = targetRoot.AssemblyLinearVelocity
    local prediction = Vector3.new(0, 0, 0)
    if velocity.Magnitude > 1 then prediction = velocity * 0.08 * silentAimConfig.predictionStrength end
    return prediction
end

local function GetHitboxScale(character)
    local scale = 1
    local largeAccessories = 0
    for _, accessory in ipairs(character:GetChildren()) do
        if accessory:IsA('Accessory') then
            local handle = accessory:FindFirstChild('Handle')
            if handle then
                local size = handle.Size
                local volume = size.X * size.Y * size.Z
                if volume > 5 then largeAccessories = largeAccessories + 1 end
            end
        end
    end
    if largeAccessories > 0 then scale = 1 + (largeAccessories * 0.2) end
    return {hitboxScale = scale}
end

local function GetRaycastCount(distance)
    if not silentAimConfig.distanceBasedRayReduction then return math.min(silentAimConfig.baseRaycastCount, silentAimConfig.maxRaycastCount) end
    if distance > 150 then return 3 elseif distance > 100 then return 4 elseif distance > 50 then return 5 else return math.min(silentAimConfig.baseRaycastCount, silentAimConfig.maxRaycastCount) end
end

local function CanRaycast()
    if raycastCost >= raycastBudget then return false end
    raycastCost = raycastCost + 1
    return true
end
RunService.Heartbeat:Connect(function(deltaTime) raycastCost = math.max(0, raycastCost - (raycastBudget * deltaTime)) end)

local function CheckSilentVisibility(character, origin, distance)
    local hitCount = 0
    local rayCount = 0
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.IgnoreWater = true
    local maxRays = math.min(GetRaycastCount(distance) * #aimParts, silentAimConfig.maxRaysPerFrame)
    local hitboxScale = GetHitboxScale(character).hitboxScale
    for _, partName in ipairs(aimParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA('BasePart') then
            if not CanRaycast() or rayCount >= maxRays then break end
            local ray = workspace:Raycast(origin, (part.Position - origin).Unit * distance, params)
            if ray and ray.Instance:IsDescendantOf(character) then hitCount = hitCount + 1 end
            rayCount = rayCount + 1
            local extraRays = math.min(GetRaycastCount(distance) - 1, 2)
            for i = 1, extraRays do
                if not CanRaycast() or rayCount >= maxRays then break end
                local offset = Vector3.new((math.random() - 0.5) * 0.3 * hitboxScale, (math.random() - 0.5) * 0.3 * hitboxScale, (math.random() - 0.5) * 0.3 * hitboxScale)
                local targetPos = part.Position + offset
                ray = workspace:Raycast(origin, (targetPos - origin).Unit * distance, params)
                if ray and ray.Instance:IsDescendantOf(character) then hitCount = hitCount + 1 end
                rayCount = rayCount + 1
            end
        end
    end
    local hitRatio = (rayCount > 0) and (hitCount / rayCount) or 0
    return hitCount > 0 and hitRatio >= 0.2, hitRatio
end

local function CalculateTargetScore(player)
    local character = player.Character
    if not character then return 0 end
    local targetPart = character:FindFirstChild(silentAimTargetPart)
    if not targetPart then targetPart = character:FindFirstChild("HumanoidRootPart") end
    if not targetPart then return 0 end
    local camera = workspace.CurrentCamera
    if not camera then return 0 end
    local score = 0
    local angle = GetAngleToTarget(targetPart.Position)
    local screenScore = 1 - (angle / silentAimConfig.maxCameraAngle)
    screenScore = math.clamp(screenScore, 0, 1)
    score = score + (screenScore * silentAimConfig.screenCenterWeight * 100)
    local distance = (camera.CFrame.Position - targetPart.Position).Magnitude
    if distance <= maxDistance then
        local distanceScore = 1 - (distance / maxDistance)
        score = score + (distanceScore * silentAimConfig.distanceWeight * 100)
    end
    local localChar = LocalPlayer.Character
    if localChar then
        local localRoot = GetComponent(localChar, 'HumanoidRootPart') or localChar:FindFirstChild('Head')
        if localRoot then
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {localChar}
            local ray = workspace:Raycast(localRoot.Position, (targetPart.Position - localRoot.Position).Unit * distance, params)
            if not ray or (ray.Instance and ray.Instance:IsDescendantOf(character)) then score = score + (silentAimConfig.visibilityWeight * 100) end
        end
    end
    return score
end

local function GetCurrentWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA('Tool') and tool:FindFirstChild('fire') and tool:FindFirstChild('showBeam') then
            return tool
        end
    end
    return nil
end

local function HasGunEquipped()
    local char = LocalPlayer.Character
    if not char then return false end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return false end
    local isGun = tool:FindFirstChild("showBeam") and tool.showBeam:IsA("RemoteEvent")
    return isGun
end

local function GetBestTarget(fovRadius, fovCenter)
    local localChar = LocalPlayer.Character
    if not localChar or not localChar:IsDescendantOf(workspace) then return nil, 0 end
    local enemies = GetEnemyPlayersList()
    local bestTarget = nil
    local bestScore = 0
    for _, enemy in ipairs(enemies) do
        local char = enemy.Character
        if char and char:IsDescendantOf(workspace) then
            local targetPart = char:FindFirstChild(silentAimTargetPart)
            if not targetPart then targetPart = char:FindFirstChild("HumanoidRootPart") end
            local humanoid = GetComponent(char, 'Humanoid')
            if targetPart and humanoid and humanoid.Health > 0 then
                local distance = (localChar:GetPivot().Position - targetPart.Position).Magnitude
                if distance <= maxDistance then
                    local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(targetPart.Position)
                    if not onScreen then continue end
                    local camera = workspace.CurrentCamera
                    local direction = (targetPart.Position - camera.CFrame.Position).Unit
                    if direction:Dot(camera.CFrame.LookVector) <= 0 then continue end
                    if fovRadius then
                        local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
                        local center = fovCenter or (camera.ViewportSize / 2)
                        if (screenPos2D - center).Magnitude > fovRadius then continue end
                    end
                    local score = CalculateTargetScore(enemy)
                    if score > 25 and score > bestScore then
                        bestScore = score
                        bestTarget = enemy
                    end
                end
            end
        end
    end
    return bestTarget, bestScore
end

local function CanShootTarget(target)
    if not target then return false end
    local targetChar = target.Character
    if not targetChar then return false end
    local localChar = LocalPlayer.Character
    if not localChar then return false end
    local localRoot = GetComponent(localChar, 'HumanoidRootPart') or localChar:FindFirstChild('Head')
    local targetPart = targetChar:FindFirstChild(silentAimTargetPart)
    if not targetPart then targetPart = targetChar:FindFirstChild("HumanoidRootPart") end
    local targetHumanoid = GetComponent(targetChar, 'Humanoid')
    if not localRoot or not targetPart or not targetHumanoid or targetHumanoid.Health <= 0 then return false end
    local distance = (targetPart.Position - localRoot.Position).Magnitude
    if distance > maxDistance then return false end
    if not IsTargetInView(targetPart.Position) then return false end
    local visible, _ = CheckSilentVisibility(targetChar, localRoot.Position, distance)
    return visible
end

local AutoShootEnabled = false
local AutoShootConnection
local autoShootDelay = 0.08
local autoShootFOVCircle = Drawing.new("Circle")
autoShootFOVCircle.Visible = false
autoShootFOVCircle.Thickness = 2
autoShootFOVCircle.Color = Color3.fromRGB(255, 255, 255)
autoShootFOVCircle.Filled = false
autoShootFOVCircle.Radius = 100
autoShootFOVCircle.Position = workspace.CurrentCamera.ViewportSize / 2
local autoShootConfig = { mode = "Full Screen", showFOV = true, fovSize = 100, fovColor = Color3.fromRGB(255, 255, 255) }
local autoShootTargetPart = "Head"
local asFovFollowMouse = false

local function IsVisibleFromWeapon(weaponHandle, targetChar)
    if not weaponHandle or not targetChar then return false end
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return false end
    local origin = weaponHandle.Position
    local direction = (targetRoot.Position - origin).Unit
    local distance = (targetRoot.Position - origin).Magnitude
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local ray = workspace:Raycast(origin, direction * distance, params)
    if not ray then return true end
    return ray.Instance:IsDescendantOf(targetChar)
end

local function PerformAutoShoot()
    if not AutoShootEnabled then return end
    local currentTime = tick()
    if (currentTime - globalLastShotTime) < globalShotCooldown then return end
    local weapon = GetCurrentWeapon()
    if not weapon then return end
    local prevSilentPart = silentAimTargetPart
    silentAimTargetPart = autoShootTargetPart
    local target, score
    local fovCenter = asFovFollowMouse and UserInputService:GetMouseLocation() or (workspace.CurrentCamera.ViewportSize / 2)
    if autoShootConfig.mode == "FOV" then
        target, score = GetBestTarget(autoShootConfig.fovSize, fovCenter)
    else
        target, score = GetBestTarget()
    end
    silentAimTargetPart = prevSilentPart
    if not target or score < 25 then return end
    local localChar = LocalPlayer.Character
    if not localChar then return end
    local localRoot = GetComponent(localChar, 'HumanoidRootPart') or localChar:FindFirstChild('Head')
    if not localRoot then return end
    if not CanShootTarget(target) then return end
    local targetChar = target.Character
    if not targetChar then return end
    local targetPart = targetChar:FindFirstChild(autoShootTargetPart)
    if not targetPart then targetPart = targetChar:FindFirstChild("HumanoidRootPart") end
    local targetHumanoid = GetComponent(targetChar, 'Humanoid')
    if not targetPart or not targetHumanoid then return end
    local handle = GetComponent(weapon, 'Handle') or weapon
    if handle and not IsVisibleFromWeapon(handle, targetChar) then return end
    local prediction = CalculatePrediction(targetPart, targetHumanoid)
    local targetPosition = targetPart.Position + prediction
    local fireEvent = GetComponent(weapon, 'fire')
    local beamEvent = GetComponent(weapon, 'showBeam')
    local killEvent = GetComponent(weapon, 'kill')
    local localBeam = ReplicatedStorage:FindFirstChild("BindableEvents") and ReplicatedStorage.BindableEvents:FindFirstChild('LocalBeam')
    task.spawn(function()
        if localBeam then localBeam:Fire(handle, targetPosition) end
        if fireEvent then fireEvent:FireServer() end
        if beamEvent then beamEvent:FireServer(targetPosition, handle.Position, handle) end
        if killEvent then
            local direction = (targetPosition - handle.Position).Unit
            killEvent:FireServer(target, direction, targetPosition)
        end
    end)
    globalLastShotTime = currentTime
end

function SetAutoShootState(state)
    AutoShootEnabled = state
    if state then
        if AutoShootConnection then task.cancel(AutoShootConnection) end
        AutoShootConnection = task.spawn(function()
            while AutoShootEnabled do
                PerformAutoShoot()
                task.wait(autoShootDelay)
            end
        end)
    else
        if AutoShootConnection then task.cancel(AutoShootConnection) end
        AutoShootConnection = nil
    end
end

local window = SynergyUI:CreateWindow({
    Title = "Synergy Hub - Dmvs",
    ToggleKey = Enum.KeyCode.X,
    ConfigFile = "SynergyHub_Dmvs.json"
})

local InfoTab = window:CreateTab("Information")
local AutoShootTab = window:CreateTab("Auto Shoot")

InfoTab:CreateSection("Information")
InfoTab:CreateParagraph({Title = "What is Synergy Hub?", Content = "A script hub for Roblox with universal and game-specific scripts. Designed to enhance your gaming experience."})
InfoTab:CreateParagraph({Title = "Credits", Content = "Xyraniz - Synergy Team"})
InfoTab:CreateButton({Name = "Discord Server", Callback = function() setclipboard("https://discord.gg/RF6GjJYMrP") end})
InfoTab:CreateButton({Name = "Website", Callback = function() setclipboard("https://synergy-team-official.github.io") end})

InfoTab:CreateKeybind({
    Name = "Menu Keybind",
    CurrentKeybind = "X",
    Flag = "MenuKeybind",
    Callback = function(key)
        window.Gui.Enabled = not window.Gui.Enabled
    end
})

AutoShootTab:CreateKeybind({
    Name = "Toggle Auto Shoot",
    Flag = "AutoShootKeybind",
    Callback = function()
        local newV = not AutoShootEnabled
        SetAutoShootState(newV)
        if window.Flags["AutoShoot"] then
            window.Flags["AutoShoot"]:Set(newV)
        end
    end
})
AutoShootTab:CreateSection("Auto Shoot")
AutoShootTab:CreateToggle({ Name = "Auto Shoot", Flag = "AutoShoot", CurrentValue = false, Callback = function(v) SetAutoShootState(v) end })
AutoShootTab:CreateSection("Configuration")
AutoShootTab:CreateToggle({ Name = "Show FOV", Flag = "AutoShootShowFOV", CurrentValue = true, Callback = function(v) autoShootConfig.showFOV = v end })
AutoShootTab:CreateToggle({ Name = "FOV Follow Mouse", Flag = "ASFovFollowMouse", CurrentValue = false, Callback = function(v) asFovFollowMouse = v end })
AutoShootTab:CreateDropdown({
    Name = "Auto Shoot Mode",
    Options = {"Full Screen", "FOV"},
    CurrentOption = "Full Screen",
    Flag = "AutoShootMode",
    Callback = function(v) autoShootConfig.mode = v end
})
AutoShootTab:CreateDropdown({
    Name = "Auto Shoot Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = "Head",
    Flag = "AutoShootTargetPart",
    Callback = function(v) autoShootTargetPart = v end
})
AutoShootTab:CreateSlider({ Name = "FOV Size", Range = {20, 500}, Increment = 10, CurrentValue = 100, Flag = "AutoShootFOVSize", Callback = function(v) autoShootConfig.fovSize = v end })
AutoShootTab:CreateColorPicker({ Name = "FOV Color", Color = Color3.fromRGB(255, 255, 255), Flag = "AutoShootFOVColor", Callback = function(v) autoShootConfig.fovColor = v end })
AutoShootTab:CreateSlider({ Name = "Reaction Time", Range = {0.01, 3}, Increment = 0.01, CurrentValue = 0.08, Flag = "ShootDelay", Callback = function(v) autoShootDelay = v end })

RunService.RenderStepped:Connect(function()
    autoShootFOVCircle.Visible = AutoShootEnabled and autoShootConfig.showFOV and autoShootConfig.mode == "FOV"
    if asFovFollowMouse and AutoShootEnabled then
        autoShootFOVCircle.Position = UserInputService:GetMouseLocation()
    else
        autoShootFOVCircle.Position = workspace.CurrentCamera.ViewportSize / 2
    end
    autoShootFOVCircle.Radius = autoShootConfig.fovSize
    autoShootFOVCircle.Color = autoShootConfig.fovColor
end)

task.spawn(function()
    while true do
        task.wait(2)
        local currentTime = tick()
        for key, cached in pairs(instanceCache) do
            if (currentTime - cached.time) > (cacheDuration * 2) then
                instanceCache[key] = nil
            end
        end
    end
end)
