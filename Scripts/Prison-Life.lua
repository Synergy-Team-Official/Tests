local SynergyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Synergy-Hub-Official/SynergyUI-Lib/main/SRC/source.lua"))()

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
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local IS_MOBILE = UserInputService.TouchEnabled
local IS_DESKTOP = UserInputService.MouseEnabled

local GunRemotes = ReplicatedStorage:FindFirstChild("GunRemotes")
local ShootEvent = GunRemotes and GunRemotes:FindFirstChild("ShootEvent")
local FuncReload = GunRemotes and GunRemotes:FindFirstChild("FuncReload")

getgenv().SilentAimSettings = {
    Enabled = false,
    ClassName = "Universal Silent Aim",
    ToggleKey = "RightAlt",
    TeamCheck = false,
    VisibleCheck = false,
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
    FOVRadius = 130,
    FOVVisible = true,
    ShowSilentAimTarget = false,
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100,
    HeadshotChance = 0,
    FixedFOV = true,
    TargetIndicatorRadius = 20,
    CrosshairLength = 30,
    CrosshairGap = 5,
    IndicatorRotationEnabled = false,
    IndicatorRotationSpeed = 1,
    IndicatorRainbowEnabled = false,
    IndicatorRainbowSpeed = 1,
    MaxDistance = 500,
    PriorityMode = "Closest to Crosshair",
    TargetInfoStyle = "Panel",
    ShowTargetName = true,
    ShowTargetHealth = true,
    ShowTargetDistance = true,
    ShowTargetCategory = false,
    ShowDamageNotifier = false,
    HighlightEnabled = false,
    HighlightRainbowEnabled = false,
    HighlightColor = Color3.fromRGB(255, 255, 0),
    IndependentPanelPosition = "200,200",
    IndependentPanelPinned = false,
    LeakAndHitMode = false,
    Wallbang = false,
    EnableNameTargeting = false,
    WhitelistedNames = {},
    BlacklistedNames = {},
    TargetMode = "Players",
    -- New PC Silent Aim specific settings
    MissSpread = 5,
    DeathCheck = true,
    ForceFieldCheck = true,
    AutoReload = true,
    ShowTargetLine = false,
    RandomAimParts = false,
    DynamicFOV = false
}

local SilentAimSettings = getgenv().SilentAimSettings

local GetPlayers = Players.GetPlayers
local WorldToViewportPoint = Camera.WorldToViewportPoint
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local currentTargetPart = nil
local currentHighlight = nil
local currentRotationAngle = 0
local currentIndicatorHue = 0
local npcList = {}
local targetMap = {}
local avatarCache = {}
local recentShots = {}
local pendingDamage = {}

local lockedTargetObject = nil

local target_indicator_circle = Drawing.new("Circle")
target_indicator_circle.Visible = false; target_indicator_circle.ZIndex = 1000; target_indicator_circle.Thickness = 2; target_indicator_circle.Filled = false

local target_indicator_lines = {}
for i = 1, 5 do 
    local line = Drawing.new("Line")
    line.Visible = false
    line.ZIndex = 1000
    line.Thickness = 2
    table.insert(target_indicator_lines, line) 
end

local overhead_info_texts = {
    Name = Drawing.new("Text"),
    Health = Drawing.new("Text"),
    Distance = Drawing.new("Text"),
    Category = Drawing.new("Text")
}

for _, text in pairs(overhead_info_texts) do
    text.Visible = false
    text.ZIndex = 1001
    text.Font = Drawing.Fonts.Plex
    text.Size = 14
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Center = true
    text.Outline = true
end

local panel_info_bg = Drawing.new("Square")
panel_info_bg.Visible = false
panel_info_bg.ZIndex = 1002
panel_info_bg.Color = Color3.fromRGB(0, 0, 0)
panel_info_bg.Thickness = 0
panel_info_bg.Filled = true
panel_info_bg.Transparency = 0.5

local panel_info_texts = {
    Name = Drawing.new("Text"),
    Health = Drawing.new("Text"),
    Distance = Drawing.new("Text"),
    Category = Drawing.new("Text")
}

for _, text in pairs(panel_info_texts) do
    text.Visible = false
    text.ZIndex = 1003
    text.Font = Drawing.Fonts.Plex
    text.Size = 14
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Center = false
    text.Outline = true
end

local FOVCircleGui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
FOVCircleGui.Name = "FOVCircleGui"
FOVCircleGui.ResetOnSpawn = false
FOVCircleGui.IgnoreGuiInset = true
FOVCircleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local FOVCircleFrame = Instance.new("Frame", FOVCircleGui)
FOVCircleFrame.Name = "FOVCircleFrame"
FOVCircleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircleFrame.Position = UDim2.fromScale(0.5, 0.5)
FOVCircleFrame.BackgroundTransparency = 1

local FOVStroke = Instance.new("UIStroke", FOVCircleFrame)
FOVStroke.Name = "FOVStroke"
FOVStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
FOVStroke.Thickness = 1
FOVStroke.Transparency = 0.5

local FOVCorner = Instance.new("UICorner", FOVCircleFrame)
FOVCorner.Name = "FOVCorner"
FOVCorner.CornerRadius = UDim.new(1, 0)

local IndependentPanelGui = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
IndependentPanelGui.Name = "IndependentPanelGui"
IndependentPanelGui.ResetOnSpawn = false
IndependentPanelGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local IndependentPanelFrame = Instance.new("Frame", IndependentPanelGui)
IndependentPanelFrame.Name = "PanelFrame"
IndependentPanelFrame.Size = UDim2.fromOffset(160, 100)
IndependentPanelFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
IndependentPanelFrame.BackgroundTransparency = 0.3
IndependentPanelFrame.BorderSizePixel = 1
IndependentPanelFrame.BorderColor3 = Color3.new(1,1,1)
IndependentPanelFrame.Visible = false
IndependentPanelFrame.Active = true

local IPCorner = Instance.new("UICorner", IndependentPanelFrame)
IPCorner.CornerRadius = UDim.new(0, 4)

local IPListLayout = Instance.new("UIListLayout", IndependentPanelFrame)
IPListLayout.Padding = UDim.new(0, 5)
IPListLayout.SortOrder = Enum.SortOrder.LayoutOrder
IPListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
IPListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local independent_panel_texts = {}
for i, name in ipairs({"Name", "Health", "Distance", "Category"}) do
    local label = Instance.new("TextLabel", IndependentPanelFrame)
    label.Name = name
    label.Size = UDim2.new(1, -10, 0, 15)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = i
    independent_panel_texts[name] = label
end

IndependentPanelFrame.InputBegan:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 and IndependentPanelFrame.Draggable then 
        IndependentPanelFrame.Position = UDim2.fromOffset(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) 
    end 
end)

IndependentPanelFrame.InputEnded:Connect(function(input) 
    if input.UserInputType == Enum.UserInputType.MouseButton1 and IndependentPanelFrame.Draggable then 
        SilentAimSettings.IndependentPanelPosition = IndependentPanelFrame.Position.X.Offset .. "," .. IndependentPanelFrame.Position.Y.Offset 
    end 
end)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = { ArgCountRequired = 3, Args = {"Instance", "Ray", "table", "boolean", "boolean"} },
    FindPartOnRayWithWhitelist = { ArgCountRequired = 3, Args = {"Instance", "Ray", "table", "boolean"} },
    FindPartOnRay = { ArgCountRequired = 2, Args = {"Instance", "Ray", "Instance", "boolean", "boolean"} },
    Raycast = { ArgCountRequired = 3, Args = {"Instance", "Vector3", "Vector3", "RaycastParams"} }
}

local HitSounds = {
    ["bell"] = "rbxassetid://8679627751",
    ["metal"] = "rbxassetid://3125624765",
    ["click"] = "rbxassetid://17755696142",
    ["exp"] = "rbxassetid://10070796384"
}

local rainbowColor = Color3.fromHSV(0, 1, 1)
task.spawn(function()
    while task.wait() do
        local hue = (tick() % 6) / 6
        rainbowColor = Color3.fromHSV(hue, 1, 1)
    end
end)

local function playHitSound(soundId)
    local sound = Instance.new("Sound")
    sound.Parent = CoreGui
    sound.SoundId = soundId
    sound.Volume = 0.6
    sound:Play()
    Debris:AddItem(sound, sound.TimeLength + 0.2)
end

function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    return math.random() <= Percentage / 100
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToViewportPoint(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then return false end
    for Pos, Argument in next, Args do 
        if typeof(Argument) == RayMethod.Args[Pos] then 
            Matches = Matches + 1 
        end 
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function isNPC(obj)
    return obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and obj:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(obj)
end

function getTargetCategory(character)
    if not character then return "None" end

    if Players:GetPlayerFromCharacter(character) then
        return "Player"
    end

    if SilentAimSettings.EnableNameTargeting then
        local name = character.Name:lower()
        for _, whitelistedName in ipairs(SilentAimSettings.WhitelistedNames) do
            if whitelistedName and whitelistedName ~= "" and string.find(name, whitelistedName:lower(), 1, true) then
                return "Whitelisted"
            end
        end
    end
    
    if character:FindFirstChild("Humanoid") then
         return "NPC"
    end

    return "Unknown"
end

local function updateNPCs()
    local newNpcList = {}
    local addedNpcs = {} 

    if SilentAimSettings.EnableNameTargeting and #SilentAimSettings.WhitelistedNames > 0 then
        for _, model in ipairs(workspace:GetDescendants()) do
            if isNPC(model) then
                for _, substring in ipairs(SilentAimSettings.WhitelistedNames) do
                    if substring and substring ~= "" and string.find(model.Name:lower(), substring:lower(), 1, true) then
                        if not addedNpcs[model] then
                            table.insert(newNpcList, model)
                            addedNpcs[model] = true
                            break 
                        end
                    end
                end
            end
        end
    end

    for _, v in ipairs(workspace:GetChildren()) do
        if isNPC(v) then
            if not addedNpcs[v] then
                table.insert(newNpcList, v)
                addedNpcs[v] = true
            end
        end
    end
    
    npcList = newNpcList
end

local function isBlacklisted(name)
    local lowerName = name:lower()
    for _, blacklistedName in ipairs(SilentAimSettings.BlacklistedNames) do
        if blacklistedName:lower() == lowerName then
            return true
        end
    end
    return false
end

local function isPartVisible(part, customOrigin)
    if not part then return false end
    local localCharacter = Player.Character
    if not localCharacter then return false end
    local origin = customOrigin or Camera.CFrame.Position
    local direction = part.Position - origin
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {localCharacter, part.Parent}
    local raycastResult = workspace:Raycast(origin, direction.Unit * direction.Magnitude, raycastParams)
    return not raycastResult
end

local function GetOnScreenPosition(v3)
    local pos, vis = WorldToViewportPoint(Camera, v3)
    return Vector2.new(pos.X, pos.Y), vis
end

local function GetFovCenter()
    return SilentAimSettings.FixedFOV and (Camera.ViewportSize / 2) or GetMouseLocation(UserInputService)
end

-- NPC target functions (keep for mobile)
local function getClosestPlayer()
    local LocalPlayerCharacter = Player.Character
    if not LocalPlayerCharacter or not LocalPlayerCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local localRoot = LocalPlayerCharacter.HumanoidRootPart
    
    local fovCenter = GetFovCenter()
    local candidates = {}
    
    for _, PlayerObj in ipairs(GetPlayers(Players)) do
        if PlayerObj ~= Player and not (SilentAimSettings.TeamCheck and PlayerObj.Team == Player.Team) and not isBlacklisted(PlayerObj.Name) then
            local Character = PlayerObj.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if Character and Humanoid and Humanoid.Health > 0 then
                local partForChecks = Character:FindFirstChild(SilentAimSettings.TargetPart) or Character:FindFirstChild("HumanoidRootPart")
                if not partForChecks then continue end

                if not (SilentAimSettings.VisibleCheck and not isPartVisible(partForChecks, LocalPlayerCharacter.Head.Position)) then
                    local physicalDist = (localRoot.Position - partForChecks.Position).Magnitude
                    if physicalDist <= SilentAimSettings.MaxDistance then
                        if SilentAimSettings.PriorityMode == "Closest Player (No FOV)" then
                            table.insert(candidates, {character = Character, fov = math.huge, dist = physicalDist, health = Humanoid.Health})
                        else
                            local ScreenPosition, OnScreen = GetOnScreenPosition(partForChecks.Position)
                            if OnScreen then
                                local fovDist = (fovCenter - ScreenPosition).Magnitude
                                if fovDist <= SilentAimSettings.FOVRadius then
                                    table.insert(candidates, {character = Character, fov = fovDist, dist = physicalDist, health = Humanoid.Health})
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b)
        if SilentAimSettings.PriorityMode == "Lowest Health" then
            return a.health < b.health
        elseif SilentAimSettings.PriorityMode == "Closest Distance" or SilentAimSettings.PriorityMode == "Closest Player (No FOV)" then
            return a.dist < b.dist
        else
            return a.fov < b.fov
        end
    end)
    return candidates[1].character
end

local function getNPCTarget()
    local LocalPlayerCharacter = Player.Character
    if not LocalPlayerCharacter or not LocalPlayerCharacter:FindFirstChild("HumanoidRootPart") then return nil end
    local localRoot = LocalPlayerCharacter.HumanoidRootPart

    local fovCenter = GetFovCenter()
    local candidates = {}

    for _, NPCModel in ipairs(npcList) do
        if not (SilentAimSettings.TeamCheck and NPCModel.Team and NPCModel.Team == Player.Team) and not isBlacklisted(NPCModel.Name) then
            local Humanoid = NPCModel and NPCModel:FindFirstChildOfClass("Humanoid")
            if NPCModel and Humanoid and Humanoid.Health > 0 then
                local partForChecks = NPCModel:FindFirstChild(SilentAimSettings.TargetPart) or NPCModel.PrimaryPart or NPCModel:FindFirstChild("HumanoidRootPart")
                if not partForChecks then continue end

                if not (SilentAimSettings.VisibleCheck and not isPartVisible(partForChecks, LocalPlayerCharacter.Head.Position)) then
                    local physicalDist = (localRoot.Position - partForChecks.Position).Magnitude
                    if physicalDist <= SilentAimSettings.MaxDistance then
                         if SilentAimSettings.PriorityMode == "Closest Player (No FOV)" then
                            table.insert(candidates, {character = NPCModel, fov = math.huge, dist = physicalDist, health = Humanoid.Health})
                        else
                            local ScreenPosition, OnScreen = GetOnScreenPosition(partForChecks.Position)
                            if OnScreen then
                                local fovDist = (fovCenter - ScreenPosition).Magnitude
                                if fovDist <= SilentAimSettings.FOVRadius then
                                    table.insert(candidates, {character = NPCModel, fov = fovDist, dist = physicalDist, health = Humanoid.Health})
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end
    table.sort(candidates, function(a, b)
        if SilentAimSettings.PriorityMode == "Lowest Health" then
            return a.health < b.health
        elseif SilentAimSettings.PriorityMode == "Closest Distance" or SilentAimSettings.PriorityMode == "Closest Player (No FOV)" then
            return a.dist < b.dist
        else
            return a.fov < b.fov
        end
    end)
    return candidates[1].character
end

function getPolygonPoints(center, radius, sides)
    local points = {}
    local rotationOffset = SilentAimSettings.IndicatorRotationEnabled and currentRotationAngle or 0
    for i = 1, sides do
        local angle = (i - 1) * (2 * math.pi / sides) - (math.pi / 2) + rotationOffset
        table.insert(points, Vector2.new(center.X + radius * math.cos(angle), center.Y + radius * math.sin(angle)))
    end
    return points
end

function hideAllVisuals()
    target_indicator_circle.Visible = false
    for _, line in ipairs(target_indicator_lines) do 
        line.Visible = false 
    end
    for _, text in pairs(overhead_info_texts) do 
        text.Visible = false 
    end
    panel_info_bg.Visible = false
    for _, text in pairs(panel_info_texts) do 
        text.Visible = false 
    end
    if IndependentPanelFrame then 
        IndependentPanelFrame.Visible = false 
    end
end

local lastHealthValues = {}
local damageIndicators = {}
local DAMAGE_INDICATOR_FADE_TIME = 1

local pos = SilentAimSettings.IndependentPanelPosition:split(",")
IndependentPanelFrame.Position = UDim2.fromOffset(tonumber(pos[1]), tonumber(pos[2]))

local lastTargetCharacter = nil
local lockedRandomPart = nil

-- PC Silent Aim functions (from prison-life.lua)
local WallCheckParams = RaycastParams.new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
WallCheckParams.IgnoreWater = true
WallCheckParams.RespectCanCollide = false

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
        local partsList = {"Head","Torso","HumanoidRootPart","LeftArm","RightArm","LeftLeg","RightLeg"}
        partName = partsList[math.random(1, #partsList)]
    else
        partName = SilentAimSettings.TargetPart
        if partName == "Random" then partName = "Head" end
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
    
    if SilentAimSettings.VisibleCheck then
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
    local shortestDist = SilentAimSettings.FOVRadius

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
    
    local success = pcall(function()
        FuncReload:InvokeServer()
    end)
    
    if success then
        gun:SetAttribute("Local_CurrentAmmo", maxAmmo)
        UpdateAmmoGUI(maxAmmo, maxAmmo)
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

local IsSilentAimShooting = false
local LastShot = 0

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

-- PC Silent Aim Control Setup
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
        elseif input.KeyCode == Enum.KeyCode.R then
            ReloadGun()
        end
    end)
end

-- Mobile hooks (keep original for mobile)
if IS_MOBILE then
    local oldNamecall
    if hookmetamethod then
        oldNamecall = hookmetamethod(game, "__namecall", function(...)
            local method = getnamecallmethod()
            local Arguments = {...}
            
            if SilentAimSettings.Enabled and CalculateChance(SilentAimSettings.HitChance) and currentTargetPart then
                local currentMethod = SilentAimSettings.SilentAimMethod
                
                if method == "Raycast" and currentMethod == "Raycast" then
                    if Arguments[1] == workspace then
                        if typeof(Arguments[#Arguments]) ~= "RaycastParams" then
                            return oldNamecall(...)
                        end
                        
                        Arguments[3] = getDirection(Arguments[2], currentTargetPart.Position)
                        
                        if SilentAimSettings.Wallbang then
                            table.insert(recentShots, {origin = Arguments[2], time = tick()})
                            local wallbangParams = RaycastParams.new()
                            wallbangParams.FilterType = Enum.RaycastFilterType.Include
                            wallbangParams.FilterDescendantsInstances = {currentTargetPart.Parent}
                            local newArgs = {workspace, Arguments[2], Arguments[3], wallbangParams}
                            return oldNamecall(unpack(newArgs))
                        end
                        
                        table.insert(recentShots, {origin = Arguments[2], time = tick()})
                        return oldNamecall(unpack(Arguments))
                    end
                end
                
                if (method == "FindPartOnRayWithIgnoreList" and currentMethod == method) or 
                   (method == "FindPartOnRayWithWhitelist" and currentMethod == method) or 
                   ((method == "FindPartOnRay" or method == "findPartOnRay") and currentMethod:lower() == method:lower()) then
                    
                    if ValidateArguments(Arguments, ExpectedArguments[method] or ExpectedArguments["FindPartOnRay"]) then
                        local shotOrigin = Arguments[2].Origin
                        if SilentAimSettings.Wallbang then
                            table.insert(recentShots, {origin = shotOrigin, time = tick()})
                            return currentTargetPart, currentTargetPart.Position, currentTargetPart.CFrame.LookVector, currentTargetPart.Material
                        end
                        Arguments[2] = Ray.new(Arguments[2].Origin, getDirection(Arguments[2].Origin, currentTargetPart.Position))
                        table.insert(recentShots, {origin = shotOrigin, time = tick()})
                    end
                end
                
                if (method == "ScreenPointToRay" or method == "ViewportPointToRay") and currentMethod == method and Arguments[1] == Camera then
                    local shotOrigin = Camera.CFrame.Position
                    local direction = (currentTargetPart.Position - shotOrigin).Unit
                    table.insert(recentShots, {origin = shotOrigin, time = tick()})
                    return Ray.new(shotOrigin, direction)
                end
            end
            return oldNamecall(...)
        end)
    else
        warn("[SilentAim] hookmetamethod no disponible en este executor. El silent aim no funcionará.")
    end

    local oldIndex
    local Mouse = Player:GetMouse()
    if hookmetamethod then
        oldIndex = hookmetamethod(game, "__index", function(self, Index)
            if self == Mouse and not checkcaller() and SilentAimSettings.Enabled and CalculateChance(SilentAimSettings.HitChance) and 
               SilentAimSettings.SilentAimMethod == "Mouse.Hit/Target" and currentTargetPart then
               
                if Player.Character and Player.Character:FindFirstChild("Head") then
                    table.insert(recentShots, {origin = Player.Character.Head.Position, time = tick()})
                end
                
                if Index == "Target" or Index == "target" then
                    return currentTargetPart
                elseif Index == "Hit" or Index == "hit" then
                    return (SilentAimSettings.MouseHitPrediction and (currentTargetPart.CFrame + (currentTargetPart.Velocity * currentTargetPart.Velocity.magnitude * SilentAimSettings.MouseHitPredictionAmount))) or currentTargetPart.CFrame
                elseif Index == "X" or Index == "x" then
                    return self.X
                elseif Index == "Y" or Index == "y" then
                    return self.Y
                elseif Index == "UnitRay" then
                    return Ray.new(self.Origin, (self.Hit.p - self.Origin.p).Unit)
                end
            end
            return oldIndex(self, Index)
        end)
    end

    local oldRayNew
    if hookfunction then
        oldRayNew = hookfunction(Ray.new, function(origin, direction)
            if SilentAimSettings.Enabled and CalculateChance(SilentAimSettings.HitChance) and 
               SilentAimSettings.SilentAimMethod == "Ray" and currentTargetPart and not checkcaller() then
                table.insert(recentShots, {origin = origin, time = tick()})
                local newDirectionVector = getDirection(origin, currentTargetPart.Position)
                return oldRayNew(origin, newDirectionVector)
            end
            return oldRayNew(origin, direction)
        end)
    end
end

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
    aimbotTeam = "All"
}

local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = aimbotState.aimbotFOVColor
FOVring.Filled = false
FOVring.Radius = aimbotState.aimbotFOVSize
FOVring.Position = Camera.ViewportSize / 2

local aimbotConnection
local aimbotToggleKey = "T"
local hitboxToggleKey = "G"

local function updateDrawings()
    local camViewportSize = Camera.ViewportSize
    FOVring.Position = camViewportSize / 2
end

local function lookAt(target, smoothness)
    local lookVector = (target - Camera.CFrame.Position).unit
    local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + lookVector)
    Camera.CFrame = Camera.CFrame:Lerp(newCFrame, smoothness)
end

local function getPlayerTeam(player)
    if not player.Team then return "Unknown" end
    local teamName = player.Team.Name
    if teamName:find("Inmate") then return "Inmates" end
    if teamName:find("Guard") then return "Guards" end
    if teamName:find("Criminal") then return "Criminals" end
    return "Unknown"
end

local function getTargetPlayer(trg_part, fov, teamCheck, visibilityCheck)
    local candidates = {}
    local playerMousePos = Camera.ViewportSize / 2
    local localPlayer = Player
    local localTeam = localPlayer.Team
    local localChar = localPlayer.Character
    local localPos = localChar and localChar.PrimaryPart and localChar.PrimaryPart.Position or Vector3.zero

    for _, player in ipairs(Players:GetPlayers()) do
        if player == localPlayer then continue end

        if aimbotState.aimbotTeam ~= "All" then
            local playerTeam = getPlayerTeam(player)
            if playerTeam ~= aimbotState.aimbotTeam then
                continue
            end
        end

        if teamCheck and player.Team and player.Team == localTeam then
            continue
        end

        local character = player.Character
        if character then
            local part = character:FindFirstChild(trg_part)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if part and humanoid and humanoid.Health > 0 then
                local visible = true
                if visibilityCheck then
                    local direction = part.Position - Camera.CFrame.Position
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                    rayParams.FilterDescendantsInstances = {localPlayer.Character}
                    local result = workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
                    visible = not result or result.Instance:IsDescendantOf(character)
                end
                if visible then
                    local ePos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    local screenDist = (Vector2.new(ePos.X, ePos.Y) - playerMousePos).Magnitude
                    local threeDDist = (part.Position - localPos).Magnitude
                    local health = humanoid.Health
                    local threat = 0
                    pcall(function()
                        local scoreFolder = player:FindFirstChild("ScoreFolder")
                        if scoreFolder then
                            local kills = scoreFolder:FindFirstChild("Kills")
                            local assists = scoreFolder:FindFirstChild("Assists")
                            if kills and assists then
                                threat = kills.Value + (assists.Value / 2)
                            end
                        end
                    end)
                    local score = 1 / (screenDist + 1) + 1 / (threeDDist + 1) + health / 100 + threat / 10
                    table.insert(candidates, {Player = player, Part = part, Score = score, ScreenDist = screenDist})
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.Score > b.Score end)

    if aimbotState.fovType == "LIMITED_FOV" then
        for _, candidate in ipairs(candidates) do
            if candidate.ScreenDist <= fov then
                return candidate.Player
            end
        end
        return nil
    elseif aimbotState.fovType == "FULL_SCREEN" or aimbotState.fovType == "360_DEGREES" then
        return #candidates > 0 and candidates[1].Player or nil
    end
    return nil
end

-- Render loop
resume(create(function()
    RenderStepped:Connect(function()
        if SilentAimSettings.IndicatorRotationEnabled then 
            currentRotationAngle = (currentRotationAngle + (SilentAimSettings.IndicatorRotationSpeed / 50)) % (math.pi * 2) 
        end
        if SilentAimSettings.IndicatorRainbowEnabled or SilentAimSettings.HighlightRainbowEnabled then 
            currentIndicatorHue = (currentIndicatorHue + (SilentAimSettings.IndicatorRainbowSpeed / 200)) % 1 
        end
        
        local currentTime = tick()
        for i = #recentShots, 1, -1 do
            if currentTime - recentShots[i].time > 1 then
                table.remove(recentShots, i)
            end
        end

        -- Target selection for mobile (old method) and for PC visual display
        if IS_MOBILE then
            currentTargetPart = nil
            local currentTargetCharacter = nil

            if SilentAimSettings.Enabled then
                if lockedTargetObject then
                     if lockedTargetObject.Parent and not isBlacklisted(lockedTargetObject.Name) then
                        if lockedTargetObject:IsA("Player") then
                            currentTargetCharacter = lockedTargetObject.Character
                        elseif lockedTargetObject:IsA("Model") then
                            currentTargetCharacter = lockedTargetObject
                        end
                    else
                        lockedTargetObject = nil 
                    end
                else
                    local targetMode = SilentAimSettings.TargetMode
                    local playerTarget, npcTarget
                    if targetMode == "Players" or targetMode == "All" then 
                        playerTarget = getClosestPlayer() 
                    end
                    if targetMode == "NPCs" or targetMode == "All" then 
                        npcTarget = getNPCTarget() 
                    end

                    if playerTarget and npcTarget then
                        local priority = SilentAimSettings.PriorityMode
                        if priority == "Lowest Health" then
                            local pHumanoid = playerTarget:FindFirstChildOfClass("Humanoid")
                            local nHumanoid = npcTarget:FindFirstChildOfClass("Humanoid")
                            currentTargetCharacter = (pHumanoid and nHumanoid and pHumanoid.Health <= nHumanoid.Health) and playerTarget or npcTarget
                        else
                            local pDist = (Player.Character.HumanoidRootPart.Position - playerTarget.HumanoidRootPart.Position).Magnitude
                            local nDist = (Player.Character.HumanoidRootPart.Position - npcTarget.HumanoidRootPart.Position).Magnitude
                            currentTargetCharacter = pDist < nDist and playerTarget or npcTarget
                        end
                    else
                        currentTargetCharacter = playerTarget or npcTarget
                    end
                end
            end

            if currentTargetCharacter ~= lastTargetCharacter then
                lockedRandomPart = nil 
            end
            lastTargetCharacter = currentTargetCharacter

            if currentTargetCharacter then
                local humanoid = currentTargetCharacter:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then
                    if lockedTargetObject and lockedTargetObject:IsA("Model") and lockedTargetObject == currentTargetCharacter then
                        lockedTargetObject = nil
                    end
                    currentTargetCharacter = nil
                    currentTargetPart = nil
                else
                    local baseTargetPart = nil
                    if SilentAimSettings.LeakAndHitMode then
                        for _, part in ipairs(currentTargetCharacter:GetDescendants()) do
                            if part:IsA("BasePart") and part.Parent == currentTargetCharacter then
                                if isPartVisible(part) then
                                    baseTargetPart = part
                                    break
                                end
                            end
                        end
                    else
                        local targetPartName = SilentAimSettings.TargetPart
                        if targetPartName == "Random" then
                            if not lockedRandomPart or not lockedRandomPart.Parent or lockedRandomPart.Parent ~= currentTargetCharacter then
                                lockedRandomPart = currentTargetCharacter[ValidTargetParts[math.random(1, #ValidTargetParts)]]
                            end
                            baseTargetPart = lockedRandomPart
                        else
                            baseTargetPart = currentTargetCharacter:FindFirstChild(targetPartName) or currentTargetCharacter:FindFirstChild("HumanoidRootPart")
                        end
                    end

                    if baseTargetPart then
                        if CalculateChance(SilentAimSettings.HeadshotChance) then
                            local headPart = currentTargetCharacter:FindFirstChild("Head")
                            if headPart then
                                currentTargetPart = headPart
                            else
                                currentTargetPart = baseTargetPart
                            end
                        else
                            currentTargetPart = baseTargetPart
                        end
                    else
                        currentTargetPart = nil
                    end
                end
            end
        else -- PC: use new target selection for visual display
            if SilentAimSettings.Enabled then
                local camera = workspace.CurrentCamera
                if camera then
                    local screenCenter = camera.ViewportSize / 2
                    if IS_DESKTOP then
                        local mouse = UserInputService:GetMouseLocation()
                        screenCenter = Vector2.new(mouse.X, mouse.Y)
                    end
                    CurrentSilentAimTarget = GetClosestTarget(screenCenter)
                else
                    CurrentSilentAimTarget = nil
                end
            else
                CurrentSilentAimTarget = nil
            end

            -- Update currentTargetPart for visual indicators
            if CurrentSilentAimTarget and CurrentSilentAimTarget.Character then
                currentTargetPart = GetTargetPart(CurrentSilentAimTarget.Character)
            else
                currentTargetPart = nil
            end
        end

        -- Damage indicators (common)
        if SilentAimSettings.Enabled and currentTargetPart then
            local humanoid = currentTargetPart.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local currentHealth = humanoid.Health
                local lastHealth = lastHealthValues[humanoid]
                if lastHealth and currentHealth < lastHealth then
                    local damage = math.floor(lastHealth - currentHealth)
                    if damage > 0 then
                        if not pendingDamage[humanoid] then
                            pendingDamage[humanoid] = { damage = 0, lastUpdate = tick(), position = currentTargetPart.Position }
                        end
                        pendingDamage[humanoid].damage = pendingDamage[humanoid].damage + damage
                        pendingDamage[humanoid].lastUpdate = tick()
                        pendingDamage[humanoid].position = currentTargetPart.Position
                    end
                end
                lastHealthValues[humanoid] = currentHealth
            end
        end
        
        local DAMAGE_ACCUMULATION_WINDOW = 0.15
        for humanoid, data in pairs(pendingDamage) do
            if currentTime - data.lastUpdate > DAMAGE_ACCUMULATION_WINDOW then
                if SilentAimSettings.ShowDamageNotifier and data.damage > 0 then
                    local screenPos, onScreen = getPositionOnScreen(data.position)
                    if onScreen then
                        local indicator = {} 
                        indicator.Created = tick() 
                        indicator.Position = screenPos
                        indicator.TextObject = Drawing.new("Text")
                        indicator.TextObject.Font = Drawing.Fonts.Monospace 
                        indicator.TextObject.Text = string.format("-%d", data.damage)
                        indicator.TextObject.Color = Color3.fromRGB(255, 50, 50) 
                        indicator.TextObject.Size = 20
                        indicator.TextObject.Center = true 
                        indicator.TextObject.Outline = true
                        table.insert(damageIndicators, indicator)
                    end
                end
                pendingDamage[humanoid] = nil
            end
        end

        for i = #damageIndicators, 1, -1 do
            local indicator = damageIndicators[i]; local age = tick() - indicator.Created
            if age > DAMAGE_INDICATOR_FADE_TIME then
                indicator.TextObject:Remove(); table.remove(damageIndicators, i)
            else
                local progress = age / DAMAGE_INDICATOR_FADE_TIME
                indicator.TextObject.Position = indicator.Position - Vector2.new(0, progress * 40)
                indicator.TextObject.Transparency = progress; indicator.TextObject.Visible = true
            end
        end

        hideAllVisuals()
        
        if currentHighlight and (not currentTargetPart or not SilentAimSettings.HighlightEnabled) then
            currentHighlight:Destroy()
            currentHighlight = nil
        end

        if SilentAimSettings.Enabled and currentTargetPart and SilentAimSettings.HighlightEnabled then
             if not currentHighlight then
                currentHighlight = Instance.new("Highlight")
                currentHighlight.Parent = currentTargetPart.Parent
            end
            currentHighlight.Adornee = currentTargetPart.Parent
            currentHighlight.Enabled = true
            currentHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            if SilentAimSettings.HighlightRainbowEnabled then
                local rainbowColor = Color3.fromHSV(currentIndicatorHue, 1, 1)
                currentHighlight.FillColor = rainbowColor
                currentHighlight.OutlineColor = rainbowColor
                currentHighlight.FillTransparency = 0.5
                currentHighlight.OutlineTransparency = 0
            else
                currentHighlight.FillColor = SilentAimSettings.HighlightColor
                currentHighlight.OutlineColor = SilentAimSettings.HighlightColor
                currentHighlight.FillTransparency = 0.5
                currentHighlight.OutlineTransparency = 0
            end
        end

        if SilentAimSettings.Enabled and currentTargetPart then
            local RootToViewportPoint, IsOnScreen = getPositionOnScreen(currentTargetPart.Position)

            if IsOnScreen and SilentAimSettings.ShowSilentAimTarget then
                local indicatorRadius = SilentAimSettings.TargetIndicatorRadius
                local indicatorStyle = "Circle"
                local finalIndicatorColor
                local isTargetVisible = isPartVisible(currentTargetPart)
                if isTargetVisible then 
                    finalIndicatorColor = Color3.fromRGB(0, 255, 0)
                    indicatorRadius = indicatorRadius * 0.6
                elseif SilentAimSettings.IndicatorRainbowEnabled then 
                    finalIndicatorColor = Color3.fromHSV(currentIndicatorHue, 1, 1)
                else 
                    finalIndicatorColor = Color3.fromRGB(255, 0, 0)
                end
                
                if indicatorStyle == "Circle" then
                    target_indicator_circle.Visible = true
                    target_indicator_circle.Color = finalIndicatorColor
                    target_indicator_circle.Radius = indicatorRadius
                    target_indicator_circle.Position = RootToViewportPoint
                end
            end
        end
        
        if FOVCircleGui and FOVCircleGui.Enabled then
            if SilentAimSettings.FixedFOV then 
                FOVCircleFrame.Position = UDim2.fromScale(0.5, 0.5) 
            else 
                local mousePos = GetMouseLocation(UserInputService)
                FOVCircleFrame.Position = UDim2.fromOffset(mousePos.X, mousePos.Y) 
            end
        end
        
        updateDrawings()
        FOVring.Visible = aimbotState.showFOV and aimbotState.aimbotEnabled and aimbotState.fovType == "LIMITED_FOV" or false
        
        if aimbotState.aimbotEnabled then
            local closest = getTargetPlayer(aimbotState.aimbotTargetPart or "Head", aimbotState.aimbotFOVSize, aimbotState.aimbotTeamCheck, aimbotState.aimbotVisibilityCheck)
            if closest and closest.Character and closest.Character:FindFirstChild(aimbotState.aimbotTargetPart or "Head") then
                lookAt(closest.Character[aimbotState.aimbotTargetPart or "Head"].Position, aimbotState.aimbotSmoothness)
            end
        end
    end)
end))

function createMainWindow()
    Window = SynergyUI:CreateWindow({
        Title = "Synergy Hub - Prison Life",
        Author = "Xyraniz",
        AccentColor = Color3.fromRGB(0, 255, 100),
        BackgroundColor = Color3.fromRGB(20, 20, 20),
        SidebarColor = Color3.fromRGB(30, 30, 30),
        Font = Enum.Font.Gotham,
        CornerRadius = 6,
        ToggleKey = Enum.KeyCode.X,
        CloseOnEscape = false
    })

    local InfoTab = Window:CreateTab("Information", nil)
    local AimbotTab = Window:CreateTab("Aimbot", nil)
    local SilentAimTab = Window:CreateTab("Silent Aim", nil)
    local HitboxTab = Window:CreateTab("Hitbox Expansion", nil)
    local VisualTab = Window:CreateTab("Highlights", nil)
    local TPTab = Window:CreateTab("TP", nil)
    local MiscTab = Window:CreateTab("Misc", nil)
    local PlayerTab = Window:CreateTab("Player", nil)

    -- Simplified Info Tab
    InfoTab:CreateSection("Information")
    InfoTab:CreateParagraph({Title = "What is Synergy Hub?", Content = "A Roblox script hub optimized for gameplay. Designed to dominate in games."})
    InfoTab:CreateParagraph({Title = "Credits", Content = "Xyraniz\nSynergy Team"})
    InfoTab:CreateButton({Name = "Discord Server", Callback = function() setclipboard("discord.gg/nCNASmNRTE") end})
    InfoTab:CreateKeybind({Name = "Menu Keybind", CurrentKeybind = "X", Flag = "MenuKeybind", Callback = function(key) Window:Toggle() end})

    AimbotTab:CreateKeybind({
        Name = "Aimbot Toggle Key",
        CurrentKeybind = "T",
        Callback = function(v)
            aimbotToggleKey = v
        end
    })

    AimbotTab:CreateToggle({
        Name = "Aimbot Enabled",
        CurrentValue = aimbotState.aimbotEnabled,
        Callback = function(v)
            aimbotState.aimbotEnabled = v
        end
    })

    AimbotTab:CreateToggle({
        Name = "Show FOV",
        CurrentValue = aimbotState.showFOV,
        Callback = function(v)
            aimbotState.showFOV = v
        end
    })

    AimbotTab:CreateDropdown({
        Name = "FOV Type",
        Options = {"LIMITED_FOV", "FULL_SCREEN", "360_DEGREES"},
        CurrentOption = aimbotState.fovType,
        Callback = function(v)
            aimbotState.fovType = v
        end
    })

    AimbotTab:CreateDropdown({
        Name = "Select Team",
        Options = {"All", "Guards", "Inmates", "Criminals"},
        CurrentOption = aimbotState.aimbotTeam,
        Callback = function(v)
            aimbotState.aimbotTeam = v
        end
    })

    AimbotTab:CreateSlider({
        Name = "Smoothness",
        Range = {0.1, 1},
        Increment = 0.05,
        CurrentValue = aimbotState.aimbotSmoothness,
        Callback = function(v)
            aimbotState.aimbotSmoothness = v
        end
    })

    AimbotTab:CreateColorPicker({
        Name = "FOV Color",
        Color = aimbotState.aimbotFOVColor,
        Callback = function(c)
            aimbotState.aimbotFOVColor = c
            if FOVring then
                FOVring.Color = c
            end
        end
    })

    AimbotTab:CreateSlider({
        Name = "FOV Size",
        Range = {50, 500},
        Increment = 10,
        CurrentValue = aimbotState.aimbotFOVSize,
        Callback = function(v)
            aimbotState.aimbotFOVSize = v
            if FOVring then
                FOVring.Radius = v
            end
        end
    })

    AimbotTab:CreateDropdown({
        Name = "Target Part",
        Options = {"Head", "HumanoidRootPart", "UpperTorso"},
        CurrentOption = aimbotState.aimbotTargetPart,
        Callback = function(v)
            aimbotState.aimbotTargetPart = v
        end
    })

    AimbotTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = aimbotState.aimbotTeamCheck,
        Callback = function(v)
            aimbotState.aimbotTeamCheck = v
        end
    })

    AimbotTab:CreateToggle({
        Name = "Visibility Check",
        CurrentValue = aimbotState.aimbotVisibilityCheck,
        Callback = function(v)
            aimbotState.aimbotVisibilityCheck = v
        end
    })

    SilentAimTab:CreateKeybind({
        Name = "Silent Aim Toggle Key",
        CurrentKeybind = SilentAimSettings.ToggleKey,
        Callback = function(v)
            SilentAimSettings.ToggleKey = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Silent Aim Enabled",
        CurrentValue = SilentAimSettings.Enabled,
        Callback = function(v)
            SilentAimSettings.Enabled = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = SilentAimSettings.TeamCheck,
        Callback = function(v)
            SilentAimSettings.TeamCheck = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Wall Check",
        CurrentValue = SilentAimSettings.VisibleCheck,
        Callback = function(v)
            SilentAimSettings.VisibleCheck = v
        end
    })

    SilentAimTab:CreateSlider({
        Name = "Hit Chance",
        Range = {0, 100},
        Increment = 1,
        CurrentValue = SilentAimSettings.HitChance,
        Callback = function(v)
            SilentAimSettings.HitChance = v
        end
    })

    SilentAimTab:CreateSlider({
        Name = "Miss Spread",
        Range = {0, 50},
        Increment = 1,
        CurrentValue = SilentAimSettings.MissSpread,
        Callback = function(v)
            SilentAimSettings.MissSpread = v
        end
    })

    SilentAimTab:CreateSlider({
        Name = "Field of View",
        Range = {50, 500},
        Increment = 10,
        CurrentValue = SilentAimSettings.FOVRadius,
        Callback = function(v)
            SilentAimSettings.FOVRadius = v
            FOVCircleFrame.Size = UDim2.fromOffset(v * 2, v * 2)
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Show FOV Circle",
        CurrentValue = SilentAimSettings.FOVVisible,
        Callback = function(v)
            SilentAimSettings.FOVVisible = v
            FOVCircleGui.Enabled = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Show Target",
        CurrentValue = SilentAimSettings.ShowSilentAimTarget,
        Callback = function(v)
            SilentAimSettings.ShowSilentAimTarget = v
        end
    })

    SilentAimTab:CreateDropdown({
        Name = "Target Part",
        Options = {"Head", "HumanoidRootPart", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Random"},
        CurrentOption = SilentAimSettings.TargetPart,
        Callback = function(v)
            SilentAimSettings.TargetPart = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Random Parts",
        CurrentValue = SilentAimSettings.RandomAimParts,
        Callback = function(v)
            SilentAimSettings.RandomAimParts = v
        end
    })

    SilentAimTab:CreateSlider({
        Name = "Max Distance",
        Range = {50, 2000},
        Increment = 10,
        CurrentValue = SilentAimSettings.MaxDistance,
        Callback = function(v)
            SilentAimSettings.MaxDistance = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Death Check",
        CurrentValue = SilentAimSettings.DeathCheck,
        Callback = function(v)
            SilentAimSettings.DeathCheck = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "ForceField Check",
        CurrentValue = SilentAimSettings.ForceFieldCheck,
        Callback = function(v)
            SilentAimSettings.ForceFieldCheck = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Auto Reload",
        CurrentValue = SilentAimSettings.AutoReload,
        Callback = function(v)
            SilentAimSettings.AutoReload = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Show Target Line",
        CurrentValue = SilentAimSettings.ShowTargetLine,
        Callback = function(v)
            SilentAimSettings.ShowTargetLine = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Dynamic FOV",
        CurrentValue = SilentAimSettings.DynamicFOV,
        Callback = function(v)
            SilentAimSettings.DynamicFOV = v
        end
    })

    SilentAimTab:CreateToggle({
        Name = "Highlight Target",
        CurrentValue = SilentAimSettings.HighlightEnabled,
        Callback = function(v)
            SilentAimSettings.HighlightEnabled = v
        end
    })

    -- Hitbox tab (unchanged from deepseek.lua)
    local HitboxSettings = {
        Enabled = false,
        TeamCheck = true,
        Size = 4,
        Transparency = 0.5,
        Color = Color3.fromRGB(255, 0, 0),
        Shape = "Square"
    }

    local hitboxOriginalSizes = {}
    local hitboxOriginalTransparencies = {}
    local hitboxOriginalColors = {}
    local hitboxOriginalMaterials = {}
    local hitboxOriginalShapes = {}

    local function restoreHitbox(part)
        if hitboxOriginalSizes[part] then
            part.Size = hitboxOriginalSizes[part]
            part.Transparency = hitboxOriginalTransparencies[part]
            part.Color = hitboxOriginalColors[part]
            part.Material = hitboxOriginalMaterials[part]
            part.Shape = hitboxOriginalShapes[part]
            hitboxOriginalSizes[part] = nil
            hitboxOriginalTransparencies[part] = nil
            hitboxOriginalColors[part] = nil
            hitboxOriginalMaterials[part] = nil
            hitboxOriginalShapes[part] = nil
        end
    end

    local function updateHitboxes()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local isTeammate = player.Team == Player.Team
                    local targetParts = {}
                    for _, part in pairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") and (part.Name:match("Head") or part.Name:match("Torso") or part.Name == "HumanoidRootPart") then
                            table.insert(targetParts, part)
                        end
                    end
                    if #targetParts == 0 then
                        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                        if rootPart then
                            table.insert(targetParts, rootPart)
                        end
                    end
                    
                    for _, part in pairs(targetParts) do
                        if HitboxSettings.Enabled and (not HitboxSettings.TeamCheck or not isTeammate) then
                            if not hitboxOriginalSizes[part] then
                                hitboxOriginalSizes[part] = part.Size
                                hitboxOriginalTransparencies[part] = part.Transparency
                                hitboxOriginalColors[part] = part.Color
                                hitboxOriginalMaterials[part] = part.Material
                                hitboxOriginalShapes[part] = part.Shape
                            end
                            part.Size = Vector3.new(HitboxSettings.Size, HitboxSettings.Size, HitboxSettings.Size)
                            part.Transparency = HitboxSettings.Transparency
                            part.Color = HitboxSettings.Color
                            part.Material = Enum.Material.Neon
                            if HitboxSettings.Shape == "Circle" then
                                part.Shape = Enum.PartType.Ball
                            else
                                part.Shape = Enum.PartType.Block
                            end
                        else
                            restoreHitbox(part)
                        end
                    end
                end
            end
        end
    end

    local hitboxLastUpdate = 0
    local hitboxUpdateInterval = 0.5
    
    local hitboxUpdateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        hitboxLastUpdate = hitboxLastUpdate + deltaTime
        if hitboxLastUpdate < hitboxUpdateInterval then return end
        hitboxLastUpdate = 0
        updateHitboxes()
    end)

    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            task.wait(0.5)
            updateHitboxes()
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if player.Character then
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") and hitboxOriginalSizes[part] then
                    restoreHitbox(part)
                end
            end
        end
    end)

    HitboxTab:CreateToggle({
        Name = "Expanded Hitbox",
        CurrentValue = HitboxSettings.Enabled,
        Callback = function(v)
            HitboxSettings.Enabled = v
            updateHitboxes()
        end
    })

    HitboxTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = HitboxSettings.TeamCheck,
        Callback = function(v)
            HitboxSettings.TeamCheck = v
            updateHitboxes()
        end
    })

    HitboxTab:CreateSlider({
        Name = "Hitbox Size",
        Range = {1, 20},
        Increment = 1,
        CurrentValue = HitboxSettings.Size,
        Callback = function(v)
            HitboxSettings.Size = v
            updateHitboxes()
        end
    })

    HitboxTab:CreateSlider({
        Name = "Hitbox Transparency",
        Range = {0, 1},
        Increment = 0.1,
        CurrentValue = HitboxSettings.Transparency,
        Callback = function(v)
            HitboxSettings.Transparency = v
            updateHitboxes()
        end
    })

    HitboxTab:CreateColorPicker({
        Name = "Hitbox Color",
        Color = HitboxSettings.Color,
        Callback = function(c)
            HitboxSettings.Color = c
            updateHitboxes()
        end
    })

    HitboxTab:CreateDropdown({
        Name = "Hitbox Shape",
        Options = {"Square", "Circle"},
        CurrentOption = HitboxSettings.Shape,
        Callback = function(v)
            HitboxSettings.Shape = v
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Player and player.Character then
                    for _, part in pairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") and hitboxOriginalSizes[part] then
                            restoreHitbox(part)
                        end
                    end
                end
            end
            updateHitboxes()
        end
    })

    HitboxTab:CreateKeybind({
        Name = "Hitbox Toggle Key",
        CurrentKeybind = "G",
        Callback = function(v)
            hitboxToggleKey = v
        end
    })

    -- ESP/Highlights tab (unchanged from deepseek.lua)
    local ESPSettings = {
        Inmates = false,
        Guards = false,
        Criminals = false,
        InmatesTransparency = 0.5,
        GuardsTransparency = 0.5,
        CriminalsTransparency = 0.5
    }

    local highlights = {}
    local teamColors = {
        Inmates = Color3.fromRGB(255, 165, 0),
        Guards = Color3.fromRGB(0, 0, 255),
        Criminals = Color3.fromRGB(255, 0, 0)
    }

    local function createHighlightForPlayer(player)
        pcall(function()
            local character = player.Character
            if character and not highlights[player] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "ESP_Highlight"
                highlight.Adornee = character
                highlight.Parent = character
                highlights[player] = highlight

                player.CharacterAdded:Connect(function(newChar)
                    task.wait(0.5)
                    if highlights[player] then
                        highlights[player].Adornee = newChar
                        highlights[player].Parent = newChar
                        updateHighlightForPlayer(player)
                    end
                end)

                player.CharacterRemoving:Connect(function()
                    if highlights[player] then
                        highlights[player]:Destroy()
                        highlights[player] = nil
                    end
                end)
            end
        end)
    end

    local function updateHighlightForPlayer(player)
        pcall(function()
            if highlights[player] then
                local team = getPlayerTeam(player)
                local shouldShow = (team == "Inmates" and ESPSettings.Inmates) or
                                   (team == "Guards" and ESPSettings.Guards) or
                                   (team == "Criminals" and ESPSettings.Criminals)
                highlights[player].Enabled = shouldShow and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0
                if shouldShow then
                    highlights[player].FillColor = teamColors[team]
                    highlights[player].FillTransparency = ESPSettings[team .. "Transparency"]
                    highlights[player].OutlineColor = teamColors[team]
                    highlights[player].OutlineTransparency = 0
                end
            end
        end)
    end

    local function updateAllESP()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player then
                createHighlightForPlayer(player)
                updateHighlightForPlayer(player)
            end
        end
    end

    Players.PlayerAdded:Connect(function(player)
        if player ~= Player then
            createHighlightForPlayer(player)
            player:GetPropertyChangedSignal("Team"):Connect(function()
                updateHighlightForPlayer(player)
            end)
            updateHighlightForPlayer(player)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        if highlights[player] then
            highlights[player]:Destroy()
            highlights[player] = nil
        end
    end)

    local espLastUpdate = 0
    local espUpdateInterval = 0.5
    
    local espUpdateConnection = RunService.Heartbeat:Connect(function(deltaTime)
        espLastUpdate = espLastUpdate + deltaTime
        if espLastUpdate < espUpdateInterval then return end
        espLastUpdate = 0
        updateAllESP()
    end)

    VisualTab:CreateToggle({
        Name = "Inmates ESP",
        CurrentValue = ESPSettings.Inmates,
        Callback = function(v)
            ESPSettings.Inmates = v
            updateAllESP()
        end
    })

    VisualTab:CreateToggle({
        Name = "Guards ESP",
        CurrentValue = ESPSettings.Guards,
        Callback = function(v)
            ESPSettings.Guards = v
            updateAllESP()
        end
    })

    VisualTab:CreateToggle({
        Name = "Criminals ESP",
        CurrentValue = ESPSettings.Criminals,
        Callback = function(v)
            ESPSettings.Criminals = v
            updateAllESP()
        end
    })

    VisualTab:CreateSlider({
        Name = "Inmates ESP Transparency",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = ESPSettings.InmatesTransparency,
        Callback = function(v)
            ESPSettings.InmatesTransparency = v
            updateAllESP()
        end
    })

    VisualTab:CreateSlider({
        Name = "Guards ESP Transparency",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = ESPSettings.GuardsTransparency,
        Callback = function(v)
            ESPSettings.GuardsTransparency = v
            updateAllESP()
        end
    })

    VisualTab:CreateSlider({
        Name = "Criminals ESP Transparency",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = ESPSettings.CriminalsTransparency,
        Callback = function(v)
            ESPSettings.CriminalsTransparency = v
            updateAllESP()
        end
    })

    -- TP Tab (unchanged)
    local function teleportAndPickupWeapon(targetPos)
        local Character = Player.Character or Player.CharacterAdded:Wait()
        local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        local Humanoid = Character:WaitForChild("Humanoid")

        local originalPosition = HumanoidRootPart.CFrame

        HumanoidRootPart.CFrame = CFrame.new(targetPos)
        wait(0.1)

        Humanoid.Jump = true
        wait(0.1)

        wait(0.60)

        local weapons = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and (obj.Position - targetPos).Magnitude < 20 then
                table.insert(weapons, obj)
            end
        end
        
        for _, weapon in ipairs(weapons) do
            pcall(function()
                weapon.Parent = Character
            end)
            task.wait(0.05)
        end

        HumanoidRootPart.CFrame = originalPosition
        
        return #weapons > 0
    end

    local function teleportTo(position)
        local Character = Player.Character or Player.CharacterAdded:Wait()
        local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        local Humanoid = Character:WaitForChild("Humanoid")

        HumanoidRootPart.CFrame = CFrame.new(position)
        wait(0.1)

        Humanoid.Jump = true
        wait(0.1)

        wait(0.60)
    end

    TPTab:CreateButton({
        Name = "MP5",
        Callback = function()
            local success = teleportAndPickupWeapon(
                Vector3.new(814, 101, 2229)
            )
            if success then
                SynergyUI:Notify("MP5 obtained successfully", 2, Color3.fromRGB(0, 255, 100))
            end
        end,
    })

    TPTab:CreateButton({
        Name = "REMINGTON-870",
        Callback = function()
            local success = teleportAndPickupWeapon(
                Vector3.new(820, 101, 2229)
            )
            if success then
                SynergyUI:Notify("REMINGTON-870 obtained successfully", 2, Color3.fromRGB(0, 255, 100))
            end
        end,
    })

    TPTab:CreateButton({
        Name = "AK-47",
        Callback = function()
            local success = teleportAndPickupWeapon(
                Vector3.new(-932, 94, 2039)
            )
            if success then
                SynergyUI:Notify("AK-47 obtained successfully", 2, Color3.fromRGB(0, 255, 100))
            end
        end,
    })

    TPTab:CreateButton({
        Name = "M4A1",
        Callback = function()
            local success = teleportAndPickupWeapon(
                Vector3.new(847, 101, 2229)
            )
            if success then
                SynergyUI:Notify("M4A1 obtained successfully", 2, Color3.fromRGB(0, 255, 100))
            end
        end,
    })

    TPTab:CreateButton({
        Name = "FAL",
        Callback = function()
            local success = teleportAndPickupWeapon(
                Vector3.new(-916, 94, 2048)
            )
            if success then
                SynergyUI:Notify("FAL obtained successfully", 2, Color3.fromRGB(0, 255, 100))
            end
        end,
    })

    TPTab:CreateButton({
        Name = "Police Base",
        Callback = function()
            teleportTo(Vector3.new(853, 100, 2274))
            SynergyUI:Notify("Teleported to Police Base", 2, Color3.fromRGB(0, 255, 100))
        end,
    })

    TPTab:CreateButton({
        Name = "Park",
        Callback = function()
            teleportTo(Vector3.new(811, 99, 2520))
            SynergyUI:Notify("Teleported to Park", 2, Color3.fromRGB(0, 255, 100))
        end,
    })

    TPTab:CreateButton({
        Name = "Kitchen",
        Callback = function()
            teleportTo(Vector3.new(902, 100, 2249))
            SynergyUI:Notify("Teleported to Kitchen", 2, Color3.fromRGB(0, 255, 100))
        end,
    })

    TPTab:CreateButton({
        Name = "Prison",
        Callback = function()
            teleportTo(Vector3.new(945, 115, 2448))
            SynergyUI:Notify("Teleported to Prison", 2, Color3.fromRGB(0, 255, 100))
        end,
    })

    TPTab:CreateButton({
        Name = "Criminal Base",
        Callback = function()
            teleportTo(Vector3.new(-936, 94, 2050))
            SynergyUI:Notify("Teleported to Criminal Base", 2, Color3.fromRGB(0, 255, 100))
        end,
    })

    -- Misc Tab (unchanged)
    local NoTaseMode = false

    local function setInputState(active)
        if not Player.Character then return end
        local inputHandler = Player.Character:FindFirstChild("ClientInputHandler")
        if inputHandler then
            inputHandler.Disabled = active
        end
    end

    Player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if NoTaseMode then
            local inputHandler = char:FindFirstChild("ClientInputHandler")
            if inputHandler then
                inputHandler.Disabled = true
            end
        end
    end)

    MiscTab:CreateToggle({
        Name = "Anti-Tase",
        CurrentValue = false,
        Callback = function(v)
            NoTaseMode = v
            if NoTaseMode then
                setInputState(true)
            else
                setInputState(false)
            end
        end,
    })

    local gunHacks = {
        infiniteAmmo = false,
        noRecoil = false,
        rapidFire = false
    }

    local function updateGunAttributes(tool)
        if not tool or not tool:IsA("Tool") then return end
        
        if gunHacks.infiniteAmmo then
            pcall(function()
                local ammoValue = tool:FindFirstChild("Ammo")
                if ammoValue and ammoValue:IsA("NumberValue") then
                    ammoValue.Value = 99999
                end
            end)
        end
        
        if gunHacks.noRecoil then
            pcall(function()
                tool:SetAttribute("SpreadRadius", 0)
            end)
        end
        
        if gunHacks.rapidFire then
            pcall(function()
                tool:SetAttribute("FireRate", 0.02)
                tool:SetAttribute("AutoFire", true)
            end)
        end
    end

    MiscTab:CreateToggle({
        Name = "Infinite Ammo",
        CurrentValue = false,
        Callback = function(v)
            gunHacks.infiniteAmmo = v
            if v then
                for _, tool in pairs(Player.Backpack:GetChildren()) do
                    updateGunAttributes(tool)
                end
            end
        end
    })

    MiscTab:CreateToggle({
        Name = "No Recoil",
        CurrentValue = false,
        Callback = function(v)
            gunHacks.noRecoil = v
            if v then
                for _, tool in pairs(Player.Backpack:GetChildren()) do
                    updateGunAttributes(tool)
                end
            end
        end
    })

    MiscTab:CreateToggle({
        Name = "Rapid Fire",
        CurrentValue = false,
        Callback = function(v)
            gunHacks.rapidFire = v
            if v then
                for _, tool in pairs(Player.Backpack:GetChildren()) do
                    updateGunAttributes(tool)
                end
            end
        end
    })

    local autoPickupSettings = {
        Enabled = false,
        Range = 30
    }

    local function autoPickupAura()
        if not autoPickupSettings.Enabled then return end
        local character = Player.Character
        if not character or not character.PrimaryPart then return end
        local pos = character.PrimaryPart.Position
        for _, item in ipairs(workspace:GetDescendants()) do
            if (item:IsA("Tool") or item:IsA("Model")) and not item:IsDescendantOf(character) and (item.Position - pos).Magnitude <= autoPickupSettings.Range then
                pcall(function()
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        item.Parent = character
                    end
                end)
            end
        end
    end

    local autoPickupConnection

    MiscTab:CreateToggle({
        Name = "Auto Pickup Aura",
        CurrentValue = false,
        Callback = function(v)
            autoPickupSettings.Enabled = v
            if v then
                autoPickupConnection = task.spawn(function()
                    while autoPickupSettings.Enabled do
                        autoPickupAura()
                        task.wait(0.2)
                    end
                end)
                SynergyUI:Notify("Auto Pickup Aura enabled - Items will be collected automatically", 3, Color3.fromRGB(0, 255, 100))
            else
                if autoPickupConnection then
                    task.cancel(autoPickupConnection)
                    autoPickupConnection = nil
                end
                SynergyUI:Notify("Auto Pickup Aura disabled", 2, Color3.fromRGB(255, 100, 100))
            end
        end
    })

    MiscTab:CreateSlider({
        Name = "Aura Range",
        Range = {10, 100},
        Increment = 5,
        CurrentValue = autoPickupSettings.Range,
        Callback = function(v)
            autoPickupSettings.Range = v
        end
    })

    Player.Backpack.ChildAdded:Connect(function(tool)
        wait(0.1)
        updateGunAttributes(tool)
    end)

    spawn(function()
        while true do
            wait(0.5)
            if gunHacks.infiniteAmmo or gunHacks.noRecoil or gunHacks.rapidFire then
                for _, tool in pairs(Player.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        updateGunAttributes(tool)
                    end
                end
            end
        end
    end)

    MiscTab:CreateButton({
        Name = "Give Key Card",
        Callback = function()
            local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
            if toolsFolder then
                local keyCard = toolsFolder:FindFirstChild("Key card")
                if keyCard then
                    local clonedCard = keyCard:Clone()
                    local backpack = Player:FindFirstChild("Backpack")
                    if backpack then
                        clonedCard.Parent = backpack
                        SynergyUI:Notify("Key Card added to backpack", 2, Color3.fromRGB(0, 255, 100))
                    else
                        clonedCard.Parent = Player.Character
                        SynergyUI:Notify("Key Card added to character", 2, Color3.fromRGB(0, 255, 100))
                    end
                else
                    SynergyUI:Notify("Key Card not found in Tools folder", 2, Color3.fromRGB(255, 100, 100))
                end
            else
                SynergyUI:Notify("Tools folder not found", 2, Color3.fromRGB(255, 100, 100))
            end
        end
    })

    -- Player Tab (unchanged)
    local PlayerFeatures = {
        WalkSpeed = 16,
        JumpPower = 50,
        InfiniteJump = false,
        NoClip = false,
        SpeedHack = false
    }

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
            end
        end)
    end

    characterAddedConnection = Player.CharacterAdded:Connect(function(character)
        applyPlayerMods(character)
    end)

    if Player.Character then
        applyPlayerMods(Player.Character)
    end

    PlayerTab:CreateSlider({
        Name = "WalkSpeed",
        Range = {16, 500},
        Increment = 1,
        CurrentValue = PlayerFeatures.WalkSpeed,
        Callback = function(v)
            PlayerFeatures.WalkSpeed = v
            pcall(function()
                local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid and not PlayerFeatures.SpeedHack then
                    humanoid.WalkSpeed = v
                end
            end)
        end
    })

    PlayerTab:CreateSlider({
        Name = "JumpPower",
        Range = {30, 500},
        Increment = 1,
        CurrentValue = PlayerFeatures.JumpPower,
        Callback = function(v)
            PlayerFeatures.JumpPower = v
            pcall(function()
                local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.JumpPower = v
                end
            end)
        end
    })

    PlayerTab:CreateToggle({
        Name = "Speed Hack",
        CurrentValue = PlayerFeatures.SpeedHack,
        Callback = function(v)
            PlayerFeatures.SpeedHack = v
            
            pcall(function()
                local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
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
        CurrentValue = PlayerFeatures.InfiniteJump,
        Callback = function(v)
            PlayerFeatures.InfiniteJump = v
            
            if v then
                if infiniteJumpConnection then infiniteJumpConnection:Disconnect() end
                infiniteJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
                    pcall(function()
                        local humanoid = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
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
        CurrentValue = PlayerFeatures.NoClip,
        Callback = function(v)
            PlayerFeatures.NoClip = v
            
            if v then
                if noclipConnection then noclipConnection:Disconnect() end
                noclipConnection = RunService.Stepped:Connect(function()
                    pcall(function()
                        for _, part in pairs(Player.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end)
                end)
            else
                if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
                pcall(function()
                    for _, part in pairs(Player.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end)
            end
        end
    })

    PlayerTab:CreateTextInput({
        Name = "TimeScale",
        CurrentText = "1",
        Callback = function(v)
            local ts = tonumber(v)
            if ts then
                game:GetService("ReplicatedStorage").wkspc.TimeScale.Value = ts
            end
        end
    })

    PlayerTab:CreateSlider({
        Name = "FOV Value",
        Range = {0, 120},
        Increment = 1,
        CurrentValue = 70,
        Callback = function(v)
            game:GetService("Players").LocalPlayer.Settings.FOV.Value = v
        end
    })

    updateAllESP()
    updateHitboxes()
    FOVCircleGui.Enabled = SilentAimSettings.FOVVisible
    FOVCircleFrame.Size = UDim2.fromOffset(SilentAimSettings.FOVRadius * 2, SilentAimSettings.FOVRadius * 2)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode.Name == aimbotToggleKey then
            aimbotState.aimbotEnabled = not aimbotState.aimbotEnabled
            SynergyUI:Notify(aimbotState.aimbotEnabled and "Aimbot enabled" or "Aimbot disabled", 1, Color3.fromRGB(0, 255, 100))
        end
        
        if input.KeyCode.Name == hitboxToggleKey then
            HitboxSettings.Enabled = not HitboxSettings.Enabled
            updateHitboxes()
            SynergyUI:Notify(HitboxSettings.Enabled and "Hitbox enabled" or "Hitbox disabled", 1, Color3.fromRGB(0, 255, 100))
        end
        
        if input.KeyCode.Name == SilentAimSettings.ToggleKey then
            SilentAimSettings.Enabled = not SilentAimSettings.Enabled
            SynergyUI:Notify(SilentAimSettings.Enabled and "Silent Aim enabled" or "Silent Aim disabled", 1, Color3.fromRGB(0, 255, 100))
        end
        
        if input.KeyCode == Enum.KeyCode.R then
            ReloadGun()
        end
    end)
end

createMainWindow()

aimbotToggleKey = "T"
hitboxToggleKey = "G"

task.spawn(function()
    while task.wait(2) do
        if SilentAimSettings.TargetMode == "NPCs" or SilentAimSettings.TargetMode == "All" then
            updateNPCs()
        end
    end
end)

-- PC Silent Aim initialization
if IS_DESKTOP then
    SetupPCControls()
    SetupToggleKey()
    -- Auto-fire support
    RunService.Heartbeat:Connect(function()
        if IsSilentAimShooting then
            local gun = GetEquippedGun()
            if gun and gun:GetAttribute("AutoFire") then
                FireSilentAim()
            end
        end
    end)
end

game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "SynergyUI" then
        if IS_MOBILE then
            if oldNamecall then oldNamecall:UnHook() end
            if oldIndex then oldIndex:UnHook() end
            if oldRayNew then oldRayNew:UnHook() end
        end
        if FOVCircleGui then FOVCircleGui:Destroy() end
        if IndependentPanelGui then IndependentPanelGui:Destroy() end
        if currentHighlight then currentHighlight:Destroy() end
        hideAllVisuals()
    end
end)
