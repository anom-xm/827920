local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UIS                = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local Lighting           = game:GetService("Lighting")
local HttpService        = game:GetService("HttpService")

local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ==================== WIND UI ====================
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

WindUI:AddTheme({
    Name        = "PurpleGlow",
    Accent      = Color3.fromHex("#a06bff"),
    Background  = Color3.fromHex("#110d1b"),
    Outline     = Color3.fromHex("#d7c2ff"),
    Text        = Color3.fromHex("#f6f1ff"),
    Placeholder = Color3.fromHex("#cdb7ff"),
    Button      = Color3.fromHex("#7d4cff"),
    Icon        = Color3.fromHex("#f0eaff"),
})
WindUI:SetTheme("PurpleGlow")

local Window = WindUI:CreateWindow({
    Title               = "Pro Aim",
    Icon                = "rbxassetid://132168766114173",
    Folder              = "ProAim",
    HidePanelBackground = false,
    Background          = WindUI:Gradient({
        ["0"]   = { Color = Color3.fromHex("#1a1228"), Transparency = 0.10 },
        ["100"] = { Color = Color3.fromHex("#3d2a5f"), Transparency = 0.30 },
    }, { Rotation = 135 }),
    User = {
        Enabled   = true,
        Anonymous = false,
    },
    OpenButton = {
        Enabled    = true,
        Draggable  = true,
        OnlyMobile = false,
    },
})

local function Notify(titulo, conteudo, dur)
    WindUI:Notify({
        Title    = titulo,
        Content  = conteudo,
        Duration = dur or 3,
    })
end

-- ==================== ABAS ====================
local TabHome      = Window:Tab({ Title = "Home",      Icon = "house"     })
local TabVisuals   = Window:Tab({ Title = "Visuals",   Icon = "eye"       })
local TabAimbot    = Window:Tab({ Title = "Aimbot",    Icon = "crosshair" })
local TabFPS       = Window:Tab({ Title = "FPS",       Icon = "zap"       })
local TabCharacter = Window:Tab({ Title = "Character", Icon = "user"      })
local TabConfig    = Window:Tab({ Title = "Config",    Icon = "settings"  })
local TabCredits   = Window:Tab({ Title = "About",     Icon = "heart"     })

-- ==================== SETTINGS INTERNOS ====================
local ESP_Settings = {
    Enabled       = false,
    LimitDistance = 2000,
    TeamCheck     = false,
    TextSize      = 13,
    Font          = 2,
    Box           = { Enabled = false, Color = Color3.fromRGB(177, 143, 255), Outline = true },
    BoxFill       = { Enabled = false, Color = Color3.fromRGB(203, 179, 255), Transparency = 0.7 },
    Name          = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
    Distance      = { Enabled = false, Color = Color3.fromRGB(236, 227, 255) },
    HealthBar     = { Enabled = false },
    Tracer        = { Enabled = false, Origin = "Bottom", Color = Color3.fromRGB(177, 143, 255) },
    Skeleton      = { Enabled = false, Color = Color3.fromRGB(177, 143, 255), Thickness = 1 },
    Chams         = {
        Enabled             = false,
        FillColor           = Color3.fromRGB(158, 118, 255),
        OutlineColor        = Color3.fromRGB(255, 255, 255),
        FillTransparency    = 0.5,
        OutlineTransparency = 0,
    },
}

local Aimbot = {
    Enabled          = false,
    ToggleMode       = false,
    TeamCheck        = false,
    VisibleCheck     = false,
    ForceFieldCheck  = false,
    AimPart          = "Head",
    AimBias          = 0,
    FOV              = 138,
    FOV_Enabled      = false,
    FOV_Color        = Color3.fromRGB(169, 128, 255),
    FOV_LockedColor  = Color3.fromRGB(221, 206, 255),
    Smoothness       = 1,
    Prediction       = false,
    PredictionAmount = 0.14,
    Exceptions      = {},
    ExceptionTarget  = "None",
    Modo             = "Pro",  -- "Legit", "Pro"
}

local AimbotTargetCache = {}

-- Presets de modo
local AimbotModos = {
    Legit = { Smoothness = 20, FOV = 80  },
    Pro   = { Smoothness = 4,  FOV = 300 },
}

local FPS_S = {
    Fullbright     = false,
    NoFog          = false,
    LowGraphics    = false,
    CustomFOV      = false,
    FOVValue       = 70,
    AntiAFK        = false,
    CrosshairOn    = false,
    CrosshairColor = Color3.fromRGB(177, 143, 255),
    CrosshairSize  = 12,
    CrosshairGap   = 4,
    CrosshairThick = 2,
}

-- ==================== ESP ENGINE ====================
local ESP_Cache = {}

local function NewDrawing(Type, Props)
    local o = Drawing.new(Type)
    for k, v in pairs(Props) do o[k] = v end
    return o
end

-- ==================== ESP ENGINE (do message.txt) ====================
local function CreateESP(Player)
    local Objects = {
        Box = NewDrawing("Square", {Thickness = 1, ZIndex = 2, Visible = false}),
        BoxFill = NewDrawing("Square", {Filled = true, ZIndex = 0, Visible = false}),
        Name = NewDrawing("Text", {Text = Player.Name, Center = true, Size = ESP_Settings.TextSize, Font = ESP_Settings.Font, Outline = true, ZIndex = 3, Visible = false}),
        Distance = NewDrawing("Text", {Center = true, Size = ESP_Settings.TextSize - 1, Font = ESP_Settings.Font, Outline = true, ZIndex = 3, Visible = false}),
        HealthBar = NewDrawing("Square", {Filled = true, ZIndex = 2, Visible = false}),
        HealthBarOutline = NewDrawing("Square", {Filled = true, Color = Color3.new(0,0,0), ZIndex = 1, Visible = false}),
        Tracer = NewDrawing("Line", {Thickness = 1, ZIndex = 2, Visible = false}),
        TracerOutline = NewDrawing("Line", {Thickness = 3, Color = Color3.new(0,0,0), ZIndex = 1, Visible = false}),
        SkeletonLines = {},
        Highlight = nil,
        SelectionBox = nil,  -- Box 3D
    }
    for i = 1, 16 do
        table.insert(Objects.SkeletonLines, NewDrawing("Line", {Thickness = 1, ZIndex = 2, Visible = false}))
    end
    ESP_Cache[Player] = Objects
end

local function RemoveESP(Player)
    if ESP_Cache[Player] then
        for k, v in pairs(ESP_Cache[Player]) do
            if k == "Highlight" and v then
                v:Destroy()
            elseif k == "SelectionBox" and v then
                v:Destroy()
            elseif k == "SkeletonLines" then
                for _, line in pairs(v) do line:Remove() end
            elseif v and v.Remove then
                v:Remove()
            end
        end
        ESP_Cache[Player] = nil
    end
end

local SkeletonConnections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}

RunService.RenderStepped:Connect(function()
    for Player, Objects in pairs(ESP_Cache) do
        local Character = Player.Character
        local Humanoid = Character and Character:FindFirstChild("Humanoid")
        local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")

        local IsValid = ESP_Settings.Enabled and Character and Humanoid and RootPart and Humanoid.Health > 0
        local IsTeammate = ESP_Settings.TeamCheck and Player.Team == LocalPlayer.Team

        if IsValid and not IsTeammate then
            local HRP_Pos, OnScreen = Camera:WorldToViewportPoint(RootPart.Position)
            local Dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and (LocalPlayer.Character.HumanoidRootPart.Position - RootPart.Position).Magnitude or 0

            if ESP_Settings.Chams.Enabled then
                if not Objects.Highlight or Objects.Highlight.Parent ~= Character then
                    if Objects.Highlight then Objects.Highlight:Destroy() end
                    local HL = Instance.new("Highlight")
                    HL.Parent = Character; HL.Adornee = Character; HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    Objects.Highlight = HL
                end
                local HL = Objects.Highlight
                HL.FillColor = ESP_Settings.Chams.FillColor; HL.OutlineColor = ESP_Settings.Chams.OutlineColor
                HL.FillTransparency = ESP_Settings.Chams.FillTransparency; HL.OutlineTransparency = ESP_Settings.Chams.OutlineTransparency
                HL.Enabled = true
            else
                if Objects.Highlight then Objects.Highlight:Destroy() Objects.Highlight = nil end
            end

            if OnScreen and Dist <= ESP_Settings.LimitDistance then
                local ScaleFactor = 1 / (HRP_Pos.Z * math.tan(math.rad(Camera.FieldOfView * 0.5)) * 2) * 1000
                local Width, Height = math.floor(4 * ScaleFactor), math.floor(6 * ScaleFactor)
                local BoxPos = Vector2.new(math.floor(HRP_Pos.X - Width * 0.5), math.floor(HRP_Pos.Y - Height * 0.5))

                -- Box 3D (SelectionBox)
                if ESP_Settings.Box.Enabled then
                    if not Objects.SelectionBox or Objects.SelectionBox.Parent == nil then
                        if Objects.SelectionBox then Objects.SelectionBox:Destroy() end
                        local sb = Instance.new("SelectionBox")
                        sb.Color3 = ESP_Settings.Box.Color
                        sb.LineThickness = 0.05
                        sb.SurfaceTransparency = 1
                        sb.SurfaceColor3 = ESP_Settings.Box.Color
                        sb.Adornee = Character
                        sb.Parent = CoreGui
                        Objects.SelectionBox = sb
                    end
                    Objects.SelectionBox.Color3 = ESP_Settings.Box.Color
                    Objects.SelectionBox.Adornee = Character
                    Objects.SelectionBox.Visible = true
                else
                    if Objects.SelectionBox then
                        Objects.SelectionBox.Visible = false
                    end
                end

                if ESP_Settings.BoxFill.Enabled and ESP_Settings.Box.Enabled then
                    Objects.BoxFill.Size = Vector2.new(Width, Height); Objects.BoxFill.Position = BoxPos; Objects.BoxFill.Color = ESP_Settings.BoxFill.Color; Objects.BoxFill.Transparency = ESP_Settings.BoxFill.Transparency; Objects.BoxFill.Visible = true
                else Objects.BoxFill.Visible = false end

                if ESP_Settings.Name.Enabled then
                    Objects.Name.Position = Vector2.new(BoxPos.X + Width / 2, BoxPos.Y - Objects.Name.TextBounds.Y - 2); Objects.Name.Color = ESP_Settings.Name.Color; Objects.Name.Visible = true
                else Objects.Name.Visible = false end

                if ESP_Settings.Distance.Enabled then
                    Objects.Distance.Text = math.floor(Dist) .. "m"; Objects.Distance.Position = Vector2.new(BoxPos.X + Width / 2, BoxPos.Y + Height + 2); Objects.Distance.Color = ESP_Settings.Distance.Color; Objects.Distance.Visible = true
                else Objects.Distance.Visible = false end

                if ESP_Settings.HealthBar.Enabled then
                    local BarWidth = 2; local HealthY = Height * (Humanoid.Health / Humanoid.MaxHealth)
                    Objects.HealthBarOutline.Size = Vector2.new(BarWidth + 2, Height + 2); Objects.HealthBarOutline.Position = Vector2.new(BoxPos.X - BarWidth - 6, BoxPos.Y - 1); Objects.HealthBarOutline.Visible = true
                    Objects.HealthBar.Size = Vector2.new(BarWidth, HealthY); Objects.HealthBar.Position = Vector2.new(BoxPos.X - BarWidth - 5, BoxPos.Y + (Height - HealthY)); Objects.HealthBar.Color = Color3.fromHSV((Humanoid.Health / Humanoid.MaxHealth) * 0.3, 1, 1); Objects.HealthBar.Visible = true
                else Objects.HealthBar.Visible = false; Objects.HealthBarOutline.Visible = false end

                if ESP_Settings.Tracer.Enabled then
                    local Origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    if ESP_Settings.Tracer.Origin == "Center" then Origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    elseif ESP_Settings.Tracer.Origin == "Mouse" then local M = UIS:GetMouseLocation() Origin = Vector2.new(M.X, M.Y) end
                    Objects.Tracer.From = Origin; Objects.Tracer.To = Vector2.new(HRP_Pos.X, HRP_Pos.Y); Objects.Tracer.Color = ESP_Settings.Tracer.Color; Objects.Tracer.Visible = true
                    Objects.TracerOutline.From = Origin; Objects.TracerOutline.To = Vector2.new(HRP_Pos.X, HRP_Pos.Y); Objects.TracerOutline.Visible = true
                else Objects.Tracer.Visible = false; Objects.TracerOutline.Visible = false end

                if ESP_Settings.Skeleton.Enabled then
                    local lineIndex = 1
                    for _, pair in ipairs(SkeletonConnections) do
                        local p1 = Character:FindFirstChild(pair[1])
                        local p2 = Character:FindFirstChild(pair[2])
                        if p1 and p2 then
                            local pos1, onScreen1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, onScreen2 = Camera:WorldToViewportPoint(p2.Position)
                            if onScreen1 or onScreen2 then
                                local line = Objects.SkeletonLines[lineIndex]
                                if line then
                                    line.From = Vector2.new(pos1.X, pos1.Y)
                                    line.To = Vector2.new(pos2.X, pos2.Y)
                                    line.Color = ESP_Settings.Skeleton.Color
                                    line.Thickness = ESP_Settings.Skeleton.Thickness
                                    line.Visible = true
                                    lineIndex = lineIndex + 1
                                end
                            end
                        end
                    end
                    for i = lineIndex, #Objects.SkeletonLines do
                        Objects.SkeletonLines[i].Visible = false
                    end
                else
                    for _, line in pairs(Objects.SkeletonLines) do line.Visible = false end
                end
            else
                -- fora de tela ou longe demais
                for k, v in pairs(Objects) do
                    if k == "SkeletonLines" then for _, l in pairs(v) do l.Visible = false end
                    elseif k == "SelectionBox" and v then v.Visible = false
                    elseif k ~= "Highlight" and k ~= "SelectionBox" and typeof(v) ~= "Instance" then v.Visible = false end
                end
            end
        else
            -- inválido (morto, sem personagem, teammate)
            for k, v in pairs(Objects) do
                if k == "SkeletonLines" then for _, l in pairs(v) do l.Visible = false end
                elseif k == "SelectionBox" and v then v.Visible = false
                elseif k ~= "Highlight" and k ~= "SelectionBox" and typeof(v) ~= "Instance" then v.Visible = false end
            end
            if Objects.Highlight then Objects.Highlight:Destroy() Objects.Highlight = nil end
        end
    end
end)

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, Plr in ipairs(Players:GetPlayers()) do if Plr ~= LocalPlayer then CreateESP(Plr) end end

-- ==================== AIMBOT ENGINE (do message.txt) ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ProAim_FOV"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = CoreGui

local FOV_Frame = Instance.new("Frame")
FOV_Frame.BackgroundTransparency = 1
FOV_Frame.AnchorPoint = Vector2.new(0.5, 0.5)
FOV_Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
FOV_Frame.Size = UDim2.new(0, Aimbot.FOV * 2, 0, Aimbot.FOV * 2)

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2.5
Stroke.Color = Aimbot.FOV_Color
Stroke.Transparency = 0.25
Stroke.Parent = FOV_Frame

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(1, 0)
Corner.Parent = FOV_Frame

FOV_Frame.Parent = ScreenGui

local function UpdateFOV()
    FOV_Frame.Size = UDim2.new(0, Aimbot.FOV * 2, 0, Aimbot.FOV * 2)
    FOV_Frame.Visible = Aimbot.FOV_Enabled  -- aparece independente do aimbot estar ligado
    Stroke.Color = Aimbot.FOV_Color
end

local function AplicarModo(modo)
    local preset = AimbotModos[modo]
    if not preset then return end
    Aimbot.Modo       = modo
    Aimbot.Smoothness = preset.Smoothness
    Aimbot.FOV        = preset.FOV
    UpdateFOV()
end

local function GetAimbotExceptionNames()
    local names = {"None"}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(names, plr.Name)
        end
    end
    return names
end

local function GetRandomBodyPart(char)
    local parts = {
        char:FindFirstChild("HumanoidRootPart"),
        char:FindFirstChild("UpperTorso"),
        char:FindFirstChild("LowerTorso"),
        char:FindFirstChild("Head"),
    }
    local list = {}
    for _, part in ipairs(parts) do
        if part then table.insert(list, part) end
    end
    if #list == 0 then return nil end
    return list[math.random(1, #list)]
end

local function GetAimPartForTarget(plr)
    if not plr or not plr.Character then
        AimbotTargetCache[plr] = nil
        return nil
    end

    local char = plr.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        AimbotTargetCache[plr] = nil
        return nil
    end

    local cache = AimbotTargetCache[plr]
    if cache and cache.Character == char and cache.Part and cache.Part.Parent == char then
        return cache.Part
    end

    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    local upper = char:FindFirstChild("UpperTorso")
    local lower = char:FindFirstChild("LowerTorso")
    local bodyParts = {root, upper, lower}

    local selectedPart

    if Aimbot.AimPart == "Random" then
        selectedPart = GetRandomBodyPart(char)
    elseif Aimbot.AimPart == "Smart" then
        local distance = root and (root.Position - Camera.CFrame.Position).Magnitude or 0
        local minDistance = 7
        local maxDistance = 125
        local minChance = 0.01
        local maxChance = 1

        if distance <= minDistance then
            selectedPart = head or root or bodyParts[1] or upper or lower
        else
            local clampedDistance = math.clamp(distance, minDistance, maxDistance)
            local t = (clampedDistance - minDistance) / (maxDistance - minDistance)
            local headChance = maxChance - (maxChance - minChance) * t

            if head and math.random() < headChance then
                selectedPart = head
            else
                for _, part in ipairs(bodyParts) do
                    if part then
                        selectedPart = part
                        break
                    end
                end
                if not selectedPart then selectedPart = head or root end
            end
        end
    elseif Aimbot.AimPart == "Custom" then
        local bias = Aimbot.AimBias or 0
        local headChance = math.clamp(0.5 - (bias / 200), 0.05, 0.95)
        if head and math.random() < headChance then
            selectedPart = head
        else
            local bodyChoice = bodyParts[math.random(1, #bodyParts)]
            selectedPart = bodyChoice or head or root
        end
    else
        selectedPart = char:FindFirstChild(Aimbot.AimPart) or head or root or upper or lower
    end

    AimbotTargetCache[plr] = {
        Character = char,
        Part = selectedPart,
    }

    return selectedPart
end

local function IsExceptionPlayer(plr)
    if not plr then return false end
    for _, name in ipairs(Aimbot.Exceptions) do
        if name == plr.Name then
            return true
        end
    end
    return false
end

local function IsForceFieldProtected(plr)
    if not plr or not plr.Character then return false end

    if plr.Character:FindFirstChildOfClass("ForceField") or plr.Character:FindFirstChild("ForceField") then
        return true
    end

    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
    if not spawn then return false end

    local distToSpawn = (hrp.Position - spawn.Position).Magnitude
    return distToSpawn <= math.max(spawn.Size.X, 8) + 4
end

local function AddException(name)
    if not name or name == "None" then return false end
    for _, current in ipairs(Aimbot.Exceptions) do
        if current == name then return false end
    end
    table.insert(Aimbot.Exceptions, name)
    return true
end

local function RemoveException(name)
    if not name or name == "None" then return false end
    for i, current in ipairs(Aimbot.Exceptions) do
        if current == name then
            table.remove(Aimbot.Exceptions, i)
            return true
        end
    end
    return false
end

Players.PlayerAdded:Connect(function()
    if AimbotExceptionDropdown then RefreshExceptionDropdown() end
end)

Players.PlayerRemoving:Connect(function(player)
    AimbotTargetCache[player] = nil
    if AimbotExceptionDropdown then RefreshExceptionDropdown() end
end)

local function GetTarget()
    local closest = nil
    local bestDist = Aimbot.FOV

    for _, plr in Players:GetPlayers() do
        local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
        if plr == LocalPlayer or not plr.Character or not hum or hum.Health <= 0 then continue end
        if Aimbot.TeamCheck and plr.Team == LocalPlayer.Team then continue end
        if IsExceptionPlayer(plr) then continue end
        if Aimbot.ForceFieldCheck and IsForceFieldProtected(plr) then continue end

        local part = GetAimPartForTarget(plr)
        if not part then continue end

        local pos = part.Position
        if Aimbot.Prediction then
            pos = pos + (part.Velocity * Aimbot.PredictionAmount)
        end

        local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
        if dist >= bestDist then continue end

        if Aimbot.VisibleCheck then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local result = Workspace:Raycast(Camera.CFrame.Position, pos - Camera.CFrame.Position, rayParams)
            if result and not result.Instance:IsDescendantOf(plr.Character) then continue end
        end

        bestDist = dist
        closest = pos
    end
    return closest
end

RunService.Heartbeat:Connect(function()
    if not Aimbot.Enabled then
        Stroke.Color = Aimbot.FOV_Color
        return
    end

    local shouldAim = Aimbot.ToggleMode or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if not shouldAim then
        Stroke.Color = Aimbot.FOV_Color
        return
    end

    local target = GetTarget()
    if target then
        Stroke.Color = Aimbot.FOV_LockedColor
        local look = CFrame.lookAt(Camera.CFrame.Position, target)
        Camera.CFrame = Camera.CFrame:Lerp(look, 1 / Aimbot.Smoothness)
    else
        Stroke.Color = Aimbot.FOV_Color
    end
end)

-- ==================== CROSSHAIR ENGINE ====================
local CH_SGui = Instance.new("ScreenGui")
CH_SGui.Name = "ProAim_CH"; CH_SGui.ResetOnSpawn = false
CH_SGui.IgnoreGuiInset = true; CH_SGui.DisplayOrder = 9998
CH_SGui.Parent = CoreGui

local chLines = {}

local function BuildCrosshair()
    for _, l in ipairs(chLines) do l:Remove() end
    chLines = {}
    if not FPS_S.CrosshairOn then return end
    local cx = Camera.ViewportSize.X / 2
    local cy = Camera.ViewportSize.Y / 2
    local s  = FPS_S.CrosshairSize
    local g  = FPS_S.CrosshairGap
    local th = FPS_S.CrosshairThick
    local co = FPS_S.CrosshairColor
    local segs = {
        { Vector2.new(cx-s-g,cy), Vector2.new(cx-g,cy) },
        { Vector2.new(cx+g,cy),   Vector2.new(cx+s+g,cy) },
        { Vector2.new(cx,cy-s-g), Vector2.new(cx,cy-g) },
        { Vector2.new(cx,cy+g),   Vector2.new(cx,cy+s+g) },
    }
    for _, seg in ipairs(segs) do
        local line = Drawing.new("Line")
        line.From = seg[1]; line.To = seg[2]
        line.Color = co; line.Thickness = th; line.Visible = true
        table.insert(chLines, line)
    end
end

-- ==================== MISC ENGINE ====================
local origAmb     = Lighting.Ambient
local origOutAmb  = Lighting.OutdoorAmbient
local origFogEnd  = Lighting.FogEnd
local origFogSt   = Lighting.FogStart

local AntiAFK_Conn = nil

local function ApplyFullbright(v)
    if v then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    else
        Lighting.Ambient = origAmb
        Lighting.OutdoorAmbient = origOutAmb
    end
end

local function ApplyNoFog(v)
    if v then Lighting.FogEnd = 1e6; Lighting.FogStart = 1e6
    else Lighting.FogEnd = origFogEnd; Lighting.FogStart = origFogSt end
end

local function ApplyLowGraphics(v)
    pcall(function()
        settings().Rendering.QualityLevel =
            v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
    end)
end

local function ApplyAntiAFK(v)
    if AntiAFK_Conn then AntiAFK_Conn:Disconnect(); AntiAFK_Conn = nil end
    if v then
        AntiAFK_Conn = RunService.Heartbeat:Connect(function()
            local VR = LocalPlayer:FindFirstChild("VirtualUser")
            if not VR then
                VR = Instance.new("VirtualUser"); VR.Parent = LocalPlayer
            end
            VR:CaptureController()
            VR:ClickButton2(Vector2.new())
        end)
    end
end

-- ==================== HOME TAB ====================
local HomeGroup = TabHome:Group({})
HomeGroup:Section({
    Title = "Pro Aim — Universal",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
HomeGroup:Section({
    Title = "Welcome!",
    Desc = "This script works in any Roblox FPS game.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
HomeGroup:Section({
    Title = "Features",
    Desc = "Includes full ESP, Aimbot, crosshair, fullbright, no fog, and more.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
TabHome:Space()
local QuickInfoGroup = TabHome:Group({})
QuickInfoGroup:Section({
    Title = "Quick Info",
    Desc = "Blue and white theme with simple controls.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
TabHome:Space()
local SupportGroup = TabHome:Group({})
SupportGroup:Section({
    Title = "Support",
    Desc = "For updates and feature requests, check the community links in the About tab.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

-- ==================== VISUALS TAB ====================
local VisualsMain = TabVisuals:Group({})
VisualsMain:Section({
    Title = "Master",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
TabVisuals:Toggle({
    Title    = "Enable ESP",
    Default  = false,
    Callback = function(v) ESP_Settings.Enabled = v end,
})
TabVisuals:Toggle({
    Title    = "Team Check",
    Default  = false,
    Callback = function(v) ESP_Settings.TeamCheck = v end,
})
TabVisuals:Space()
local VisualsElements = TabVisuals:Group({})
VisualsElements:Section({
    Title = "Elements",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
TabVisuals:Toggle({ Title="Boxes",      Default=false, Callback=function(v) ESP_Settings.Box.Enabled      = v end })
TabVisuals:Toggle({ Title="Skeleton",   Default=false, Callback=function(v) ESP_Settings.Skeleton.Enabled = v end })
TabVisuals:Toggle({ Title="Names",      Default=false, Callback=function(v) ESP_Settings.Name.Enabled     = v end })
TabVisuals:Toggle({ Title="Health Bar", Default=false, Callback=function(v) ESP_Settings.HealthBar.Enabled= v end })
TabVisuals:Toggle({ Title="Distance",   Default=false, Callback=function(v) ESP_Settings.Distance.Enabled = v end })
TabVisuals:Toggle({ Title="Tracers",    Default=false, Callback=function(v) ESP_Settings.Tracer.Enabled   = v end })
TabVisuals:Toggle({ Title="Box Fill",   Default=false, Callback=function(v) ESP_Settings.BoxFill.Enabled  = v end })
TabVisuals:Space()
local VisualsSettings = TabVisuals:Group({})
VisualsSettings:Section({
    Title = "Settings",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
TabVisuals:Slider({
    Title    = "Max Distance",
    Min      = 100, Max = 5000, Default = 2000,
    Suffix   = " studs",
    Callback = function(v) ESP_Settings.LimitDistance = v end,
})
TabVisuals:Dropdown({
    Title    = "Tracer Origin",
    Values   = {"Bottom","Center","Mouse"},
    Default  = "Bottom",
    Callback = function(v) ESP_Settings.Tracer.Origin = v end,
})
TabVisuals:Space()
local VisualsChams = TabVisuals:Group({})
VisualsChams:Section({
    Title = "Chams",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
TabVisuals:Toggle({
    Title    = "Enable Chams",
    Default  = false,
    Callback = function(v) ESP_Settings.Chams.Enabled = v end,
})
TabVisuals:Slider({
    Title    = "Chams Transparency",
    Min      = 0, Max = 100, Default = 50,
    Suffix   = "%",
    Callback = function(v) ESP_Settings.Chams.FillTransparency = v / 100 end,
})

-- ==================== AIMBOT TAB ====================
local AimbotControl = TabAimbot:Group({})
AimbotControl:Section({
    Title = "Control",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
TabAimbot:Toggle({
    Title    = "Enable Aimbot",
    Default  = false,
    Callback = function(v) Aimbot.Enabled = v end,
})
TabAimbot:Toggle({
    Title    = "Toggle Mode (Mobile Friendly)",
    Default  = false,
    Callback = function(v) Aimbot.ToggleMode = v end,
})
TabAimbot:Toggle({
    Title    = "Team Check",
    Default  = false,
    Callback = function(v) Aimbot.TeamCheck = v end,
})
TabAimbot:Toggle({
    Title    = "Visible Check (Wall Check)",
    Default  = false,
    Callback = function(v) Aimbot.VisibleCheck = v end,
})
TabAimbot:Toggle({
    Title    = "Force Field Check (Spawn Protection Check)",
    Default  = false,
    Callback = function(v) Aimbot.ForceFieldCheck = v end,
})
TabAimbot:Toggle({
    Title    = "Prediction",
    Default  = false,
    Callback = function(v) Aimbot.Prediction = v end,
})
TabAimbot:Space()
local AimbotMode = TabAimbot:Group({})
AimbotMode:Section({
    Title = "Mode",
    Desc = "Legit = subtle | Pro = faster and wider reach",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
TabAimbot:Dropdown({
    Title    = "Aimbot Mode",
    Values   = {"Legit", "Pro"},
    Default  = "Pro",
    Callback = function(v) AplicarModo(v) end,
})
TabAimbot:Space()
local AimbotSettings = TabAimbot:Group({})
AimbotSettings:Section({
    Title = "Settings",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
local AimbotExceptionDropdown = nil
local AimbotBiasSlider = nil

local function RefreshExceptionDropdown()
    if not AimbotExceptionDropdown then return end
    local values = GetAimbotExceptionNames()
    AimbotExceptionDropdown.Values = values
    if AimbotExceptionDropdown.SetValues then
        AimbotExceptionDropdown:SetValues(values)
    end
    if table.find(values, Aimbot.ExceptionTarget) then
        if AimbotExceptionDropdown.SetValue then
            AimbotExceptionDropdown:SetValue(Aimbot.ExceptionTarget)
        else
            AimbotExceptionDropdown.Value = Aimbot.ExceptionTarget
        end
    else
        Aimbot.ExceptionTarget = "None"
        if AimbotExceptionDropdown.SetValue then
            AimbotExceptionDropdown:SetValue("None")
        else
            AimbotExceptionDropdown.Value = "None"
        end
    end
end

local function RefreshAimBiasVisibility()
    if not AimbotBiasSlider then return end
    if AimbotBiasSlider.Visible ~= nil then
        AimbotBiasSlider.Visible = Aimbot.AimPart == "Custom"
    elseif AimbotBiasSlider.Main and AimbotBiasSlider.Main.Visible ~= nil then
        AimbotBiasSlider.Main.Visible = Aimbot.AimPart == "Custom"
    end
end

TabAimbot:Dropdown({
    Title    = "Aim Part",
    Values   = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","Random","Smart","Custom"},
    Default  = "Head",
    Callback = function(v)
        Aimbot.AimPart = v
        RefreshAimBiasVisibility()
    end,
})
AimbotBiasSlider = TabAimbot:Slider({
    Title    = "Aim Bias: Head / Body",
    Value    = { Min = -100, Max = 100, Default = 0 },
    Suffix   = "Head ←→ Body",
    Callback = function(v) Aimbot.AimBias = v end,
})
RefreshAimBiasVisibility()
TabAimbot:Slider({
    Title    = "FOV Size",
    Value    = { Min = 10, Max = 600, Default = 138 },
    Suffix   = " px",
    Callback = function(v) Aimbot.FOV = v; UpdateFOV() end,
})
TabAimbot:Slider({
    Title    = "Smoothness",
    Value    = { Min = 1, Max = 50, Default = 1 },
    Suffix   = " (lower = smoother)",
    Callback = function(v) Aimbot.Smoothness = v end,
})
TabAimbot:Slider({
    Title    = "Prediction Amount",
    Value    = { Min = 1, Max = 50, Default = 14 },
    Suffix   = "%",
    Callback = function(v) Aimbot.PredictionAmount = v / 100 end,
})
TabAimbot:Space()
local AimbotExceptionGroup = TabAimbot:Group({})
AimbotExceptionGroup:Section({
    Title = "Exceptions",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
AimbotExceptionDropdown = TabAimbot:Dropdown({
    Title    = "Select Player",
    Values   = GetAimbotExceptionNames(),
    Default  = "None",
    Callback = function(v) Aimbot.ExceptionTarget = v end,
})
TabAimbot:Button({
    Title    = "Add Exception",
    Icon     = "plus",
    Callback = function()
        if AddException(Aimbot.ExceptionTarget) then
            RefreshExceptionDropdown()
            Notify("Aimbot", Aimbot.ExceptionTarget .. " will be ignored.")
        else
            Notify("Aimbot", Aimbot.ExceptionTarget == "None" and "Select a player first." or "Player already ignored.")
        end
    end,
})
TabAimbot:Button({
    Title    = "Remove Exception",
    Icon     = "minus",
    Callback = function()
        if RemoveException(Aimbot.ExceptionTarget) then
            RefreshExceptionDropdown()
            Notify("Aimbot", Aimbot.ExceptionTarget .. " removed from exceptions.")
        else
            Notify("Aimbot", Aimbot.ExceptionTarget == "None" and "Select a player first." or "Player not in exceptions.")
        end
    end,
})
TabAimbot:Space()
local AimbotFOVGroup = TabAimbot:Group({})
AimbotFOVGroup:Section({
    Title = "FOV Circle",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
TabAimbot:Toggle({
    Title    = "Show FOV Circle",
    Default  = false,
    Callback = function(v) Aimbot.FOV_Enabled = v; UpdateFOV() end,
})

-- ==================== FPS TAB ====================
local FPSRoot = TabFPS:Group({})
FPSRoot:Section({
    Title = "Visuals",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
FPSRoot:Toggle({
    Title    = "Fullbright",
    Default  = false,
    Callback = function(v) FPS_S.Fullbright = v; ApplyFullbright(v) end,
})
FPSRoot:Toggle({
    Title    = "No Fog",
    Default  = false,
    Callback = function(v) FPS_S.NoFog = v; ApplyNoFog(v) end,
})
FPSRoot:Toggle({
    Title    = "Low Graphics (more FPS)",
    Default  = false,
    Callback = function(v) FPS_S.LowGraphics = v; ApplyLowGraphics(v) end,
})
FPSRoot:Space()
FPSRoot:Section({
    Title = "Camera",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
FPSRoot:Toggle({
    Title    = "Custom FOV",
    Default  = false,
    Callback = function(v)
        FPS_S.CustomFOV = v
        if v then Camera.FieldOfView = FPS_S.FOVValue
        else Camera.FieldOfView = 70 end
    end,
})
FPSRoot:Slider({
    Title    = "FOV Value",
    Value    = { Min = 50, Max = 120, Default = 70 },
    Suffix   = "°",
    Callback = function(v)
        FPS_S.FOVValue = v
        if FPS_S.CustomFOV then Camera.FieldOfView = v end
    end,
})
FPSRoot:Button({
    Title    = "Reset Camera FOV",
    Icon     = "rotate-ccw",
    Callback = function()
        Camera.FieldOfView = 70
        Notify("Camera", "FOV reset to 70")
    end,
})
FPSRoot:Space()
FPSRoot:Section({
    Title = "Crosshair",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
FPSRoot:Toggle({
    Title    = "Enable Crosshair",
    Default  = false,
    Callback = function(v) FPS_S.CrosshairOn = v; BuildCrosshair() end,
})
FPSRoot:Slider({
    Title    = "Size",
    Value    = { Min = 4, Max = 30, Default = 12 },
    Suffix   = "px",
    Callback = function(v) FPS_S.CrosshairSize = v; BuildCrosshair() end,
})
FPSRoot:Slider({
    Title    = "Gap",
    Value    = { Min = 0, Max = 20, Default = 4 },
    Suffix   = "px",
    Callback = function(v) FPS_S.CrosshairGap = v; BuildCrosshair() end,
})
FPSRoot:Slider({
    Title    = "Thickness",
    Value    = { Min = 1, Max = 6, Default = 2 },
    Suffix   = "px",
    Callback = function(v) FPS_S.CrosshairThick = v; BuildCrosshair() end,
})
FPSRoot:Space()
FPSRoot:Section({
    Title = "Misc",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
FPSRoot:Toggle({
    Title    = "Anti AFK",
    Default  = false,
    Callback = function(v) FPS_S.AntiAFK = v; ApplyAntiAFK(v) end,
})
FPSRoot:Button({
    Title    = "Rejoin",
    Icon     = "refresh-cw",
    Callback = function()
        local TS = game:GetService("TeleportService")
        pcall(function() TS:Teleport(game.PlaceId, LocalPlayer) end)
    end,
})

-- ==================== ABA CHARACTER — ENGINE ====================
local Char_S = {
    Speed        = false, SpeedValue  = 16,
    Jump         = false, JumpValue   = 50,
    Fly          = false,
    NoClip       = false,
    InfJump      = false,
}

-- Speed / Jump aplicados via Humanoid
local function ApplySpeed(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v and Char_S.SpeedValue or 16 end
end
local function ApplyJump(v)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = v and Char_S.JumpValue or 50 end
end

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if not Char_S.InfJump then return end
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- NoClip
RunService.Stepped:Connect(function()
    if not Char_S.NoClip or not LocalPlayer.Character then return end
    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- Fly engine
local FlyConn = nil
local FlyBody = {}

local function StartFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9,9e9,9e9); bg.P = 9e4; bg.Parent = hrp
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.zero; bv.MaxForce = Vector3.new(9e9,9e9,9e9); bv.P = 9e4; bv.Parent = hrp
    FlyBody = {bg, bv}

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end

    FlyConn = RunService.RenderStepped:Connect(function()
        if not Char_S.Fly then return end
        local speed = 50
        local dir   = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)    then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
        bg.CFrame   = Camera.CFrame
    end)
end

local function StopFly()
    if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
    for _, obj in ipairs(FlyBody) do pcall(function() obj:Destroy() end) end
    FlyBody = {}
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- Reconecta speed/jump ao respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if Char_S.Speed then ApplySpeed(true) end
    if Char_S.Jump  then ApplyJump(true)  end
    if Char_S.Fly   then StartFly()       end
end)

-- ==================== CHARACTER TAB ====================
local CharacterRoot = TabCharacter:Group({})
CharacterRoot:Section({
    Title = "Movement",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
CharacterRoot:Toggle({
    Title    = "Speed Hack",
    Default  = false,
    Callback = function(v) Char_S.Speed = v; ApplySpeed(v) end,
})
CharacterRoot:Slider({
    Title    = "Speed",
    Value    = { Min = 16, Max = 250, Default = 50 },
    Suffix   = " ws",
    Callback = function(v)
        Char_S.SpeedValue = v
        if Char_S.Speed then ApplySpeed(true) end
    end,
})
CharacterRoot:Toggle({
    Title    = "Jump Hack",
    Default  = false,
    Callback = function(v) Char_S.Jump = v; ApplyJump(v) end,
})
CharacterRoot:Slider({
    Title    = "Jump Power",
    Value    = { Min = 50, Max = 500, Default = 100 },
    Suffix   = " jp",
    Callback = function(v)
        Char_S.JumpValue = v
        if Char_S.Jump then ApplyJump(true) end
    end,
})
CharacterRoot:Toggle({
    Title    = "Infinite Jump",
    Default  = false,
    Callback = function(v) Char_S.InfJump = v end,
})
CharacterRoot:Space()
CharacterRoot:Section({
    Title = "Physics",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
CharacterRoot:Toggle({
    Title    = "NoClip",
    Default  = false,
    Callback = function(v) Char_S.NoClip = v end,
})
CharacterRoot:Toggle({
    Title    = "Fly",
    Default  = false,
    Callback = function(v)
        Char_S.Fly = v
        if v then StartFly() else StopFly() end
    end,
})
CharacterRoot:Space()
CharacterRoot:Section({
    Title = "Utility",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
CharacterRoot:Button({
    Title    = "Reset Character",
    Icon     = "refresh-cw",
    Callback = function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end,
})
CharacterRoot:Button({
    Title    = "Teleport to Spawn",
    Icon     = "map-pin",
    Callback = function()
        local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
        local hrp   = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and spawn then
            hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
        end
    end,
})

-- ==================== CONFIG ENGINE ====================
local CONFIG_PATH = "ProAim/config.json"
local AUTOLOAD    = false

local function SerializarConfig()
    return HttpService:JSONEncode({
        ESP = {
            Enabled       = ESP_Settings.Enabled,
            Box           = ESP_Settings.Box.Enabled,
            Name          = ESP_Settings.Name.Enabled,
            Distance      = ESP_Settings.Distance.Enabled,
            HealthBar     = ESP_Settings.HealthBar.Enabled,
            Tracer        = ESP_Settings.Tracer.Enabled,
            Skeleton      = ESP_Settings.Skeleton.Enabled,
            Chams         = ESP_Settings.Chams.Enabled,
            LimitDistance = ESP_Settings.LimitDistance,
            TeamCheck     = ESP_Settings.TeamCheck,
        },
        Aimbot = {
            Enabled          = Aimbot.Enabled,
            ToggleMode       = Aimbot.ToggleMode,
            TeamCheck        = Aimbot.TeamCheck,
            VisibleCheck     = Aimbot.VisibleCheck,
            ForceFieldCheck  = Aimbot.ForceFieldCheck,
            Prediction       = Aimbot.Prediction,
            AimPart          = Aimbot.AimPart,
            AimBias          = Aimbot.AimBias,
            FOV              = Aimbot.FOV,
            Smoothness       = Aimbot.Smoothness,
            FOV_Enabled      = Aimbot.FOV_Enabled,
            Exceptions       = Aimbot.Exceptions,
            Modo             = Aimbot.Modo,
        },
        FPS = {
            Fullbright   = FPS_S.Fullbright,
            NoFog        = FPS_S.NoFog,
            LowGraphics  = FPS_S.LowGraphics,
            CrosshairOn  = FPS_S.CrosshairOn,
            AntiAFK      = FPS_S.AntiAFK,
            FOVValue     = FPS_S.FOVValue,
        },
        Character = {
            Speed       = Char_S.Speed,
            SpeedValue  = Char_S.SpeedValue,
            Jump        = Char_S.Jump,
            JumpValue   = Char_S.JumpValue,
            InfJump     = Char_S.InfJump,
            NoClip      = Char_S.NoClip,
        },
    })
end

local function SalvarConfig()
    local ok, err = pcall(function()
        if not isfolder("ProAim") then makefolder("ProAim") end
        writefile(CONFIG_PATH, SerializarConfig())
    end)
    if ok then Notify("Config", "Configuration saved!") else Notify("Error", "Failed to save: " .. tostring(err)) end
end

local function CarregarConfig()
    local ok, err = pcall(function()
        if not isfile(CONFIG_PATH) then Notify("Config", "No saved config yet."); return end
        local data = HttpService:JSONDecode(readfile(CONFIG_PATH))

        if data.ESP then
            ESP_Settings.Enabled       = data.ESP.Enabled       or false
            ESP_Settings.Box.Enabled   = data.ESP.Box           or false
            ESP_Settings.Name.Enabled  = data.ESP.Name          or false
            ESP_Settings.Distance.Enabled  = data.ESP.Distance  or false
            ESP_Settings.HealthBar.Enabled = data.ESP.HealthBar or false
            ESP_Settings.Tracer.Enabled    = data.ESP.Tracer    or false
            ESP_Settings.Skeleton.Enabled  = data.ESP.Skeleton  or false
            ESP_Settings.Chams.Enabled     = data.ESP.Chams     or false
            ESP_Settings.LimitDistance     = data.ESP.LimitDistance or 2000
            ESP_Settings.TeamCheck         = data.ESP.TeamCheck or false
        end
        if data.Aimbot then
            Aimbot.Enabled         = data.Aimbot.Enabled         or false
            Aimbot.ToggleMode      = data.Aimbot.ToggleMode      or false
            Aimbot.TeamCheck       = data.Aimbot.TeamCheck       or false
            Aimbot.VisibleCheck    = data.Aimbot.VisibleCheck    or false
            Aimbot.ForceFieldCheck = data.Aimbot.ForceFieldCheck or false
            Aimbot.Prediction      = data.Aimbot.Prediction      or false
            Aimbot.AimPart         = data.Aimbot.AimPart         or "Head"
            Aimbot.AimBias         = data.Aimbot.AimBias         or 0
            Aimbot.FOV             = data.Aimbot.FOV             or 160
            Aimbot.Smoothness      = data.Aimbot.Smoothness      or 10
            Aimbot.FOV_Enabled     = data.Aimbot.FOV_Enabled     or false
            Aimbot.Exceptions      = data.Aimbot.Exceptions      or {}
            Aimbot.Modo            = data.Aimbot.Modo            or "Pro"
        end
        if data.FPS then
            if data.FPS.Fullbright  then ApplyFullbright(true)  end
            if data.FPS.NoFog       then ApplyNoFog(true)       end
            if data.FPS.LowGraphics then ApplyLowGraphics(true) end
            if data.FPS.AntiAFK     then ApplyAntiAFK(true)     end
            FPS_S.CrosshairOn = data.FPS.CrosshairOn or false
            FPS_S.FOVValue    = data.FPS.FOVValue    or 70
        end
        if data.Character then
            Char_S.SpeedValue = data.Character.SpeedValue or 16
            Char_S.JumpValue  = data.Character.JumpValue  or 50
            Char_S.InfJump    = data.Character.InfJump    or false
            Char_S.NoClip     = data.Character.NoClip     or false
            if data.Character.Speed then Char_S.Speed = true; ApplySpeed(true) end
            if data.Character.Jump  then Char_S.Jump  = true; ApplyJump(true)  end
        end
        Notify("Config", "Configuration loaded!")
    end)
    if not ok then Notify("Error", "Failed to load: " .. tostring(err)) end
end

-- Auto-load on startup if a saved config exists
task.spawn(function()
    task.wait(1)
    if AUTOLOAD then CarregarConfig() end
end)

-- ==================== CONFIG TAB ====================
local ConfigRoot = TabConfig:Group({})
ConfigRoot:Section({
    Title = "Save / Load",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
ConfigRoot:Button({
    Title    = "Save Config",
    Icon     = "save",
    Callback = SalvarConfig,
})
ConfigRoot:Button({
    Title    = "Load Config",
    Icon     = "folder-open",
    Callback = CarregarConfig,
})
ConfigRoot:Button({
    Title    = "Export (Clipboard)",
    Icon     = "copy",
    Callback = function()
        local json = SerializarConfig()
        pcall(function() setclipboard(json) end)
        Notify("Config", "Config copied to clipboard!")
    end,
})
ConfigRoot:Space()
ConfigRoot:Section({
    Title = "Autoload",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
ConfigRoot:Toggle({
    Title    = "Auto-load config on join",
    Default  = false,
    Callback = function(v)
        AUTOLOAD = v
        pcall(function()
            if not isfolder("ProAim") then makefolder("ProAim") end
            writefile("ProAim/autoload.txt", v and "true" or "false")
        end)
        Notify("Autoload", v and "Enabled! The config will load automatically." or "Disabled.")
    end,
})
ConfigRoot:Space()
ConfigRoot:Section({
    Title = "Reset",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
ConfigRoot:Button({
    Title    = "Delete Saved Config",
    Icon     = "trash-2",
    Callback = function()
        pcall(function() delfile(CONFIG_PATH) end)
        Notify("Config", "Config deleted.")
    end,
})

local CreditsRoot = TabCredits:Group({})
CreditsRoot:Section({
    Title = "About",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
CreditsRoot:Section({
    Title = "Pro Aim Utility",
    Desc = "Custom interface built for a clean blue-white layout.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
CreditsRoot:Space()
CreditsRoot:Section({
    Title = "UI Library",
    Desc = "Optimized for FPS games and utility features.",
    Box = true,
    BoxBorder = true,
    Opened = true,
})

-- ==================== FINAL ====================
Notify("Pro Aim", "Script loaded successfully.", 5)
