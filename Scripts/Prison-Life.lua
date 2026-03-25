local SynergyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Synergy-Hub-Official/Scripts/refs/heads/main/SynergyUI.lua"))()

local playerName = game.Players.LocalPlayer.Name

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local IS_MOBILE = UserInputService.TouchEnabled
local IS_DESKTOP = UserInputService.MouseEnabled

local GunRemotes = ReplicatedStorage:WaitForChild("GunRemotes", 5)
local ShootEvent = GunRemotes and GunRemotes:WaitForChild("ShootEvent", 5)
local FuncReload = GunRemotes and GunRemotes:FindFirstChild("FuncReload")

local SilentAimSettings = {
    Enabled = false,
    TeamCheck = true,
    WallCheck = true,
    DeathCheck = true,
    ForceFieldCheck = true,
    HitChance = 75,
    MissSpread = 5,
    FOV = 80,
    ShowFOV = true,
    ShowTargetLine = false,
    ToggleKey = "RightShift",
    ReloadKey = "R",
    AimPart = "Head",
    RandomAimParts = false,
    AimPartsList = {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"},
    AutoReload = true,
    DynamicFOV = false
}

local WallCheckParams = RaycastParams.new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
WallCheckParams.IgnoreWater = true
WallCheckParams.RespectCanCollide = false

local SilentAimFOV = nil
local TargetLine = nil
local CurrentSilentAimTarget = nil
local IsSilentAimShooting = false
local IsReloading = false
local LastShot = 0

local MobileShootButton = nil
local MobileToggleButton = nil
local MobileReloadButton = nil
local MobileUIScreenGui = nil

local function CreateMobileUI()
    if not IS_MOBILE then return end
    if MobileUIScreenGui then return end
    
    local playerGui = Player:FindFirstChild("PlayerGui") or Player:WaitForChild("PlayerGui")
    MobileUIScreenGui = Instance.new("ScreenGui")
    MobileUIScreenGui.Name = "SilentAimMobileUI"
    MobileUIScreenGui.DisplayOrder = 100
    MobileUIScreenGui.ResetOnSpawn = false
    MobileUIScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    MobileShootButton = Instance.new("TextButton")
    MobileShootButton.Name = "ShootButton"
    MobileShootButton.Size = UDim2.new(0, 100, 0, 100)
    MobileShootButton.Position = UDim2.new(1, -120, 1, -120)
    MobileShootButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    MobileShootButton.BackgroundTransparency = 0.3
    MobileShootButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileShootButton.Text = "FIRE"
    MobileShootButton.Font = Enum.Font.SourceSansBold
    MobileShootButton.TextSize = 20
    MobileShootButton.BorderSizePixel = 0
    MobileShootButton.AutoButtonColor = false
    
    MobileToggleButton = Instance.new("TextButton")
    MobileToggleButton.Name = "ToggleButton"
    MobileToggleButton.Size = UDim2.new(0, 100, 0, 50)
    MobileToggleButton.Position = UDim2.new(1, -120, 1, -240)
    MobileToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 255)
    MobileToggleButton.BackgroundTransparency = 0.3
    MobileToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileToggleButton.Text = "AIM: OFF"
    MobileToggleButton.Font = Enum.Font.SourceSansBold
    MobileToggleButton.TextSize = 16
    MobileToggleButton.BorderSizePixel = 0
    
    MobileReloadButton = Instance.new("TextButton")
    MobileReloadButton.Name = "ReloadButton"
    MobileReloadButton.Size = UDim2.new(0, 100, 0, 50)
    MobileReloadButton.Position = UDim2.new(1, -120, 1, -180)
    MobileReloadButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    MobileReloadButton.BackgroundTransparency = 0.3
    MobileReloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    MobileReloadButton.Text = "RELOAD"
    MobileReloadButton.Font = Enum.Font.SourceSansBold
    MobileReloadButton.TextSize = 16
    MobileReloadButton.BorderSizePixel = 0
    
    local uiCorner1 = Instance.new("UICorner", MobileShootButton)
    uiCorner1.CornerRadius = UDim.new(0.5, 0)
    
    local uiCorner2 = Instance.new("UICorner", MobileToggleButton)
    uiCorner2.CornerRadius = UDim.new(0.25, 0)
    
    local uiCorner3 = Instance.new("UICorner", MobileReloadButton)
    uiCorner3.CornerRadius = UDim.new(0.25, 0)
    
    MobileShootButton.Parent = MobileUIScreenGui
    MobileToggleButton.Parent = MobileUIScreenGui
    MobileReloadButton.Parent = MobileUIScreenGui
    MobileUIScreenGui.Parent = playerGui
    
    MobileToggleButton.Text = "AIM: " .. (SilentAimSettings.Enabled and "ON" or "OFF")
    MobileToggleButton.BackgroundColor3 = SilentAimSettings.Enabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
end

local function DestroyMobileUI()
    if MobileUIScreenGui then
        MobileUIScreenGui:Destroy()
        MobileUIScreenGui = nil
        MobileShootButton = nil
        MobileToggleButton = nil
        MobileReloadButton = nil
    end
end

local function GetBodyPart(character, partName)
    if not character then return nil end
    local directPart = character:FindFirstChild(partName)
    if directPart then return directPart end

    local partMappings = {
        ["Torso"] = {"Torso", "UpperTorso", "LowerTorso"},
        ["LeftArm"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
        ["RightArm"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
        ["LeftLeg"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
        ["RightLeg"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
    }

    local mappings = partMappings[partName]
    if mappings then
        for _, name in ipairs(mappings) do
            local part = character:FindFirstChild(name)
            if part then return part end
        end
    end

    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

local function GetTargetPart(character)
    if not character then return nil end
    local partName
    if SilentAimSettings.RandomAimParts then
        local partsList = SilentAimSettings.AimPartsList
        if partsList and #partsList > 0 then
            partName = partsList[math.random(1, #partsList)]
        else
            partName = "Head"
        end
    else
        partName = SilentAimSettings.AimPart
    end
    return GetBodyPart(character, partName)
end

local function GetMissPosition(targetPos)
    local offset = Vector3.new(
        math.random(-100, 100),
        math.random(-100, 100),
        math.random(-100, 100)
    ).Unit * SilentAimSettings.MissSpread
    return targetPos + offset
end

local function IsPlayerDead(plr)
    if not plr or not plr.Character then return true end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return true end
    return false
end

local function HasForceField(plr)
    if not plr or not plr.Character then return false end
    return plr.Character:FindFirstChildOfClass("ForceField") ~= nil
end

local function IsWallBetween(startPos, endPos, targetCharacter)
    local myChar = Player.Character
    if not myChar then return true end
    WallCheckParams.FilterDescendantsInstances = { myChar }
    local direction = endPos - startPos
    local distance = direction.Magnitude
    local result = workspace:Raycast(startPos, direction.Unit * distance, WallCheckParams)

    if not result then return false end
    local hitPart = result.Instance
    if targetCharacter and hitPart:IsDescendantOf(targetCharacter) then return false end

    if hitPart.Transparency >= 0.8 or not hitPart.CanCollide then
        local newStart = result.Position + direction.Unit * 0.1
        local remainingDist = (endPos - newStart).Magnitude
        if remainingDist > 0.5 then
            local newResult = workspace:Raycast(newStart, direction.Unit * remainingDist, WallCheckParams)
            if not newResult then return false end
            if targetCharacter and newResult.Instance:IsDescendantOf(targetCharacter) then return false end
        else
            return false
        end
    end
    return true
end

local function IsValidTarget(plr)
    if not plr or plr == Player or not plr.Character then return false end
    local targetPart = GetTargetPart(plr.Character)
    if not targetPart then return false end
    if SilentAimSettings.DeathCheck and IsPlayerDead(plr) then return false end
    if SilentAimSettings.ForceFieldCheck and HasForceField(plr) then return false end
    if SilentAimSettings.TeamCheck and plr.Team == Player.Team then return false end
    
    if SilentAimSettings.WallCheck then
        local myChar = Player.Character
        local myHead = myChar and myChar:FindFirstChild("Head")
        if myHead then
            if IsWallBetween(myHead.Position, targetPart.Position, plr.Character) then return false end
        end
    end
    return true
end

local function RollHitChance()
    if SilentAimSettings.HitChance >= 100 then return true end
    if SilentAimSettings.HitChance <= 0 then return false end
    return math.random(1, 100) <= SilentAimSettings.HitChance
end

local function GetClosestTarget(screenCenter)
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    
    local closest = nil
    local shortestDist = SilentAimSettings.FOV

    for _, plr in pairs(Players:GetPlayers()) do
        if IsValidTarget(plr) then
            local targetPart = GetTargetPart(plr.Character)
            if targetPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

local function GetEquippedGun()
    local char = Player.Character
    if not char then return nil end
    
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            if tool:GetAttribute("ToolType") == "Gun" then
                return tool
            end
        end
    end
    return nil
end

local function UpdateAmmoGUI(ammo, maxAmmo)
    pcall(function()
        local playerGui = Player:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        local home = playerGui:FindFirstChild("Home")
        if not home then return end
        
        local hud = home:FindFirstChild("hud")
        if not hud then return end
        
        local gunFrame = hud:FindFirstChild("BottomRightFrame") and hud.BottomRightFrame:FindFirstChild("GunFrame")
        if not gunFrame then return end
        
        local label = gunFrame:FindFirstChild("BulletsLabel")
        if label then
            label.Text = tostring(ammo) .. "/" .. tostring(maxAmmo)
        end
    end)
end

local function ReloadGun()
    if IsReloading then return false end
    if not FuncReload then return false end
    
    local gun = GetEquippedGun()
    if not gun then return false end
    
    local currentAmmo = gun:GetAttribute("Local_CurrentAmmo") or 0
    local maxAmmo = gun:GetAttribute("MaxAmmo") or 0
    
    if currentAmmo >= maxAmmo then return false end
    
    IsReloading = true
    
    if IS_MOBILE and MobileReloadButton then
        MobileReloadButton.Text = "RELOADING..."
        MobileReloadButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    local success = pcall(function()
        FuncReload:InvokeServer()
    end)
    
    if success then
        gun:SetAttribute("Local_CurrentAmmo", maxAmmo)
        UpdateAmmoGUI(maxAmmo, maxAmmo)
        
    end
    
    if IS_MOBILE and MobileReloadButton then
        MobileReloadButton.Text = "RELOAD"
        MobileReloadButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    end
    
    IsReloading = false
    return success
end

local function PlayGunSound(gun)
    if not gun then return end
    local handle = gun:FindFirstChild("Handle", true)
    if not handle then return end

    local shootSound = handle:FindFirstChild("ShootSound")
    if shootSound then
        local sClone = shootSound:Clone()
        sClone.Parent = handle
        sClone:Play()
        Debris:AddItem(sClone, 2)
    end

    local isShotgun = gun:GetAttribute("IsShotgun")
    local secondary = handle:FindFirstChild("SecondarySound")
    
    if isShotgun and secondary then
        task.delay(0.2, function()
            if handle then
                local sClone = secondary:Clone()
                sClone.Parent = handle
                sClone:Play()
                Debris:AddItem(sClone, 2)
            end
        end)
    end
end

local function CreateTaserTracer(startPos, endPos, gun)
    local distance = (endPos - startPos).Magnitude
    
    local bullet = Instance.new("Part")
    bullet.Name = "RayPart"
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.CastShadow = false
    bullet.Material = Enum.Material.Neon
    bullet.BrickColor = BrickColor.new("Cyan")
    bullet.Transparency = 0.5
    bullet.Size = Vector3.new(0.2, 0.2, distance)
    bullet.CFrame = CFrame.new(endPos, startPos) * CFrame.new(0, 0, -distance / 2)
    bullet.CollisionGroup = "Nothing"
    
    local mesh = Instance.new("BlockMesh", bullet)
    mesh.Scale = Vector3.new(0.8, 0.8, 1)
    
    local light = Instance.new("SurfaceLight", bullet)
    light.Color = Color3.fromRGB(0, 234, 255)
    light.Range = 7
    light.Face = Enum.NormalId.Bottom
    light.Brightness = 5
    light.Angle = 180
    
    bullet.Parent = workspace
    
    local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local bulletTween = TweenService:Create(bullet, tweenInfo, { Transparency = 1 })
    local lightTween = TweenService:Create(light, tweenInfo, { Brightness = 0 })
    
    bulletTween:Play()
    lightTween:Play()
    
    Debris:AddItem(bullet, 2)
    
    if gun then
        local handle = gun:FindFirstChild("Handle", true)
        if handle then
            local flare = handle:FindFirstChild("Flare")
            if flare then
                flare.Enabled = true
                task.delay(0.05, function() if flare then flare.Enabled = false end end)
            end
        end
    end
end

local function CreateBulletTracer(startPos, endPos, gun)
    local distance = (endPos - startPos).Magnitude
    
    local bullet = Instance.new("Part")
    bullet.Name = "RayPart"
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.CastShadow = false
    bullet.Material = Enum.Material.Neon
    bullet.BrickColor = BrickColor.Yellow()
    bullet.Transparency = 0.5
    bullet.Size = Vector3.new(0.2, 0.2, distance)
    bullet.CFrame = CFrame.new(endPos, startPos) * CFrame.new(0, 0, -distance / 2)
    
    local mesh = Instance.new("BlockMesh", bullet)
    mesh.Scale = Vector3.new(0.5, 0.5, 1) 
    
    bullet.Parent = workspace
    Debris:AddItem(bullet, 0.05)
    
    if gun then
        local handle = gun:FindFirstChild("Handle", true)
        if handle then
            local flare = handle:FindFirstChild("Flare")
            if flare then
                flare.Enabled = true
                task.delay(0.05, function() if flare then flare.Enabled = false end end)
            end
        end
    end
end

local function CreateProjectileTracer(startPos, endPos, gun)
    if not gun then return end
    local projectileType = gun:GetAttribute("Projectile")
    if projectileType == "Taser" then
        CreateTaserTracer(startPos, endPos, gun)
    else
        CreateBulletTracer(startPos, endPos, gun)
    end
end

local function FireSilentAim()
    local gun = GetEquippedGun()
    if not gun then 
        return false 
    end
    
    local ammo = gun:GetAttribute("Local_CurrentAmmo") or 0
    if ammo <= 0 then 
        if SilentAimSettings.AutoReload then
            ReloadGun()
        end
        return false 
    end

    local fireRate = gun:GetAttribute("FireRate") or 0.12
    local now = tick()
    if now - LastShot < fireRate then return false end

    local char = Player.Character
    local myHead = char and char:FindFirstChild("Head")
    if not myHead then return false end

    local hitPos, hitPart

    if SilentAimSettings.Enabled and CurrentSilentAimTarget and CurrentSilentAimTarget.Character and IsValidTarget(CurrentSilentAimTarget) then
         local targetPart = GetTargetPart(CurrentSilentAimTarget.Character)
         if targetPart then
             if RollHitChance() then
                 hitPos = targetPart.Position
                 hitPart = targetPart
             else
                 hitPos = GetMissPosition(targetPart.Position)
                 hitPart = workspace
             end
         end
    end

    if not hitPos then
         local camera = workspace.CurrentCamera
         local screenCenter = camera.ViewportSize / 2
         if IS_DESKTOP then
             local mouse = UserInputService:GetMouseLocation()
             screenCenter = Vector2.new(mouse.X, mouse.Y)
         elseif SilentAimSettings.DynamicFOV and IS_MOBILE then
             local touches = UserInputService:GetTouches()
             if #touches > 0 then
                 screenCenter = Vector2.new(touches[1].Position.X, touches[1].Position.Y)
             end
         end
         local ray = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
         
         local rayParams = RaycastParams.new()
         rayParams.FilterType = Enum.RaycastFilterType.Exclude
         rayParams.FilterDescendantsInstances = {char}
         
         local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
         if result then
             hitPos = result.Position
             hitPart = result.Instance
         else
             hitPos = ray.Origin + (ray.Direction * 1000)
             hitPart = workspace
         end
    end

    gun:SetAttribute("Local_IsShooting", true)

    local muzzle = gun:FindFirstChild("Muzzle", true)
    local visualStart = muzzle and muzzle.Position or myHead.Position
    local origin = visualStart
    
    local projectileCount = gun:GetAttribute("ProjectileCount") or 1
    local bullets = {}
    for i = 1, projectileCount do
        table.insert(bullets, { origin, hitPos, hitPart })
    end

    LastShot = now

    PlayGunSound(gun)

    for i = 1, projectileCount do
        local offset = Vector3.new(
            math.random(-10, 10) / 100,
            math.random(-10, 10) / 100,
            math.random(-10, 10) / 100
        )
        CreateProjectileTracer(visualStart, hitPos + offset, gun)
    end

    if ShootEvent then
        ShootEvent:FireServer(bullets)
    end

    local newAmmo = ammo - 1
    gun:SetAttribute("Local_CurrentAmmo", newAmmo)
    
    local maxAmmo = gun:GetAttribute("MaxAmmo") or 0
    UpdateAmmoGUI(newAmmo, maxAmmo)

    if newAmmo <= 0 and SilentAimSettings.AutoReload then
        task.wait(0.5)
        ReloadGun()
    end

    return true
end

local function HandleMobileInput(input, gameProcessedEvent)
    if not IS_MOBILE then return end
    if not MobileShootButton or not MobileToggleButton or not MobileReloadButton then return end
    
    local touchPos = input.Position
    
    local shootButtonPos = MobileShootButton.AbsolutePosition
    local shootButtonSize = MobileShootButton.AbsoluteSize
    local toggleButtonPos = MobileToggleButton.AbsolutePosition
    local toggleButtonSize = MobileToggleButton.AbsoluteSize
    local reloadButtonPos = MobileReloadButton.AbsolutePosition
    local reloadButtonSize = MobileReloadButton.AbsoluteSize
    
    if touchPos.X >= shootButtonPos.X and touchPos.X <= shootButtonPos.X + shootButtonSize.X and
       touchPos.Y >= shootButtonPos.Y and touchPos.Y <= shootButtonPos.Y + shootButtonSize.Y then
       
        if input.UserInputState == Enum.UserInputState.Begin then
            IsSilentAimShooting = true
            local gun = GetEquippedGun()
            if gun and not gun:GetAttribute("AutoFire") then
                FireSilentAim()
            end
        elseif input.UserInputState == Enum.UserInputState.End then
            IsSilentAimShooting = false
        end
        
    elseif touchPos.X >= toggleButtonPos.X and touchPos.X <= toggleButtonPos.X + toggleButtonSize.X and
           touchPos.Y >= toggleButtonPos.Y and touchPos.Y <= toggleButtonPos.Y + toggleButtonSize.Y then
           
        if input.UserInputState == Enum.UserInputState.Begin then
            SilentAimSettings.Enabled = not SilentAimSettings.Enabled
            MobileToggleButton.Text = "AIM: " .. (SilentAimSettings.Enabled and "ON" or "OFF")
            MobileToggleButton.BackgroundColor3 = SilentAimSettings.Enabled and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 50, 50)
            
            if not SilentAimSettings.Enabled then
                DestroyMobileUI()
            end
        end
        
    elseif touchPos.X >= reloadButtonPos.X and touchPos.X <= reloadButtonPos.X + reloadButtonSize.X and
           touchPos.Y >= reloadButtonPos.Y and touchPos.Y <= reloadButtonPos.Y + reloadButtonSize.Y then
           
        if input.UserInputState == Enum.UserInputState.Begin then
            ReloadGun()
        end
    else
        return
    end
end

local function SetupPCControls()
    if not IS_DESKTOP then return end
    
    local function HandleAction(actionName, inputState, inputObject)
        if actionName == "SilentAimShoot" then
            if not SilentAimSettings.Enabled then return Enum.ContextActionResult.Pass end
            if inputState == Enum.UserInputState.Begin then
                local gun = GetEquippedGun()
                if not gun then 
                    return Enum.ContextActionResult.Pass 
                end
                
                if not gun:GetAttribute("AutoFire") then
                    IsSilentAimShooting = true
                    FireSilentAim()
                    IsSilentAimShooting = false
                else
                    IsSilentAimShooting = true
                end
                
                return Enum.ContextActionResult.Sink
            elseif inputState == Enum.UserInputState.End then
                IsSilentAimShooting = false
                return Enum.ContextActionResult.Sink
            end
        end
        return Enum.ContextActionResult.Pass
    end
    
    ContextActionService:BindActionAtPriority("SilentAimShoot", HandleAction, false, 3000, Enum.UserInputType.MouseButton1)
end

local function SetupToggleKey()
    if not IS_DESKTOP then return end
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode[SilentAimSettings.ToggleKey] then
            SilentAimSettings.Enabled = not SilentAimSettings.Enabled
            
        elseif input.KeyCode == Enum.KeyCode[SilentAimSettings.ReloadKey] then
            ReloadGun()
        end
    end)
end

if Drawing and Drawing.new then
    pcall(function()
        SilentAimFOV = Drawing.new("Circle")
        SilentAimFOV.Color = Color3.fromRGB(0, 0, 255)
        SilentAimFOV.Thickness = 2
        SilentAimFOV.Filled = false
        SilentAimFOV.Radius = SilentAimSettings.FOV
        SilentAimFOV.Visible = false
        SilentAimFOV.NumSides = 64

        TargetLine = Drawing.new("Line")
        TargetLine.Color = Color3.fromRGB(0, 255, 0)
        TargetLine.Thickness = 2
        TargetLine.Visible = false
    end)
end

local silentAimRenderConnection = RunService.RenderStepped:Connect(function()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local screenCenter = camera.ViewportSize / 2
    if IS_DESKTOP then
        local mouse = UserInputService:GetMouseLocation()
        screenCenter = Vector2.new(mouse.X, mouse.Y)
    elseif SilentAimSettings.DynamicFOV and IS_MOBILE then
        local touches = UserInputService:GetTouches()
        if #touches > 0 then
            screenCenter = Vector2.new(touches[1].Position.X, touches[1].Position.Y)
        end
    end

    if SilentAimFOV then
        SilentAimFOV.Position = screenCenter
        SilentAimFOV.Radius = SilentAimSettings.FOV
        SilentAimFOV.Visible = SilentAimSettings.ShowFOV and SilentAimSettings.Enabled
    end

    if SilentAimSettings.Enabled then
        CurrentSilentAimTarget = GetClosestTarget(screenCenter)
    else
        CurrentSilentAimTarget = nil
    end

    if TargetLine then
        if SilentAimSettings.ShowTargetLine and CurrentSilentAimTarget and CurrentSilentAimTarget.Character then
            local targetPart = GetTargetPart(CurrentSilentAimTarget.Character)
            if targetPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    TargetLine.From = screenCenter
                    TargetLine.To = Vector2.new(screenPos.X, screenPos.Y)
                    TargetLine.Visible = SilentAimSettings.Enabled
                else
                    TargetLine.Visible = false
                end
            else
                TargetLine.Visible = false
            end
        else
            TargetLine.Visible = false
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not IsSilentAimShooting then return end
    local gun = GetEquippedGun()
    if not gun then return end
    
    if gun:GetAttribute("AutoFire") then
        FireSilentAim()
    end
end)

SetupPCControls()
SetupToggleKey()

if IS_MOBILE then
    UserInputService.TouchStarted:Connect(HandleMobileInput)
    UserInputService.TouchEnded:Connect(HandleMobileInput)
end

local Window
local function createMainWindow()
    Window = SynergyUI:CreateWindow({
        Title = "Synergy Hub - Prison Life",
        Author = "Xyraniz",
        ConfigFile = "synergy_hub_config",
        ToggleKey = Enum.KeyCode.X,
        AccentColor = Color3.fromRGB(0, 255, 100),
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        SidebarColor = Color3.fromRGB(20, 20, 20),
        CornerRadius = 6,
    })

    local SilentAimTab = Window:CreateTab("Silent Aim")

    SilentAimTab:CreateKeybind({
        Name = "Silent Aim Toggle Key",
        Flag = "ToggleKey",
        Default = "RightShift",
        Callback = function(v)
            SilentAimSettings.ToggleKey = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Silent Aim Enabled",
        Flag = "SilentAimEnabled",
        Default = false,
        Callback = function(v)
            SilentAimSettings.Enabled = v
            if IS_MOBILE then
                if v then
                    CreateMobileUI()
                else
                    DestroyMobileUI()
                end
            end
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Team Check",
        Flag = "SilentAimTeamCheck",
        Default = true,
        Callback = function(v)
            SilentAimSettings.TeamCheck = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Wall Check",
        Flag = "SilentAimWallCheck",
        Default = true,
        Callback = function(v)
            SilentAimSettings.WallCheck = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Death Check",
        Flag = "SilentAimDeathCheck",
        Default = true,
        Callback = function(v)
            SilentAimSettings.DeathCheck = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "ForceField Check",
        Flag = "SilentAimForceFieldCheck",
        Default = true,
        Callback = function(v)
            SilentAimSettings.ForceFieldCheck = v
        end
    })

    SilentAimTab:CreateSlider({
        Name = "Hit Chance",
        Flag = "SilentAimHitChance",
        Range = {0, 100},
        Default = 75,
        Increment = 1,
        Callback = function(v)
            SilentAimSettings.HitChance = v
        end
    })

    SilentAimTab:CreateSlider({
        Name = "Miss Spread",
        Flag = "SilentAimMissSpread",
        Range = {0, 50},
        Default = 5,
        Increment = 1,
        Callback = function(v)
            SilentAimSettings.MissSpread = v
        end
    })

    SilentAimTab:CreateSlider({
        Name = "Field of View",
        Flag = "SilentAimFOV",
        Range = {50, 500},
        Default = 150,
        Increment = 10,
        Callback = function(v)
            SilentAimSettings.FOV = v
            if SilentAimFOV then
                SilentAimFOV.Radius = v
            end
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Show FOV",
        Flag = "SilentAimShowFOV",
        Default = true,
        Callback = function(v)
            SilentAimSettings.ShowFOV = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Show Target Line",
        Flag = "SilentAimShowTargetLine",
        Default = false,
        Callback = function(v)
            SilentAimSettings.ShowTargetLine = v
        end
    })

    SilentAimTab:CreateDropdown({
        Name = "Target Part",
        Flag = "SilentAimTargetPart",
        Values = {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"},
        Default = "Head",
        Callback = function(v)
            SilentAimSettings.AimPart = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Random Parts",
        Flag = "SilentAimRandomParts",
        Default = false,
        Callback = function(v)
            SilentAimSettings.RandomAimParts = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Auto Reload",
        Flag = "SilentAimAutoReload",
        Default = true,
        Callback = function(v)
            SilentAimSettings.AutoReload = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Dynamic FOV (Follow Mouse/Touch)",
        Flag = "DynamicFOV",
        Default = false,
        Callback = function(v)
            SilentAimSettings.DynamicFOV = v
        end
    })
end

SynergyUI:Notify("Welcome to Synergy Hub! Report bugs on discord.gg/nCNASmNRTE", 5, Color3.fromRGB(0,255,100))
createMainWindow()
