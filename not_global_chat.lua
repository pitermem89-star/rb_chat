
local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UIS                = game:GetService("UserInputService")
local MPS                = game:GetService("MarketplaceService")
local HS                 = game:GetService("HttpService")
local Lighting           = game:GetService("Lighting")
local RunService         = game:GetService("RunService")
local tost               = tostring

local SETTINGS_FILE_V    = "seluwia_settings.json"
local KEY_FILE           = "seluwia_key.txt"
local PINNED_FILE        = "seluwia_pinned.json"

local player             = Players.LocalPlayer
local playerGui          = player:WaitForChild("PlayerGui")
local CoreGui            = game:GetService("CoreGui")

if CoreGui:FindFirstChild("SeluwiaUI") then
    CoreGui.SeluwiaUI:Destroy()
end

local Themes = {
    Dark = {
        bg        = Color3.fromRGB(12,  12,  15),
        surface   = Color3.fromRGB(18,  18,  22),
        surfaceHi = Color3.fromRGB(25,  25,  30),
        border    = Color3.fromRGB(45,  45,  55),
        borderHi  = Color3.fromRGB(80,  80,  95),
        accent    = Color3.fromRGB(220, 220, 220),
        accentDim = Color3.fromRGB(120, 120, 120),
        green     = Color3.fromRGB(0,   255, 127),
        greenDim  = Color3.fromRGB(20,  70,  45),
        red       = Color3.fromRGB(255, 90,  90),
        redDim    = Color3.fromRGB(60,  18,  18),
        amber     = Color3.fromRGB(255, 200, 60),
        text      = Color3.fromRGB(240, 240, 240),
        textMuted = Color3.fromRGB(150, 150, 150),
        textDim   = Color3.fromRGB(90,  90,  90),
    },
    Light = {
        bg        = Color3.fromRGB(244, 246, 250),
        surface   = Color3.fromRGB(250, 252, 255),
        surfaceHi = Color3.fromRGB(255, 255, 255),
        border    = Color3.fromRGB(211, 216, 228),
        borderHi  = Color3.fromRGB(176, 186, 207),
        accent    = Color3.fromRGB(41,  49,  65),
        accentDim = Color3.fromRGB(102, 112, 134),
        green     = Color3.fromRGB(0,   170, 90),
        greenDim  = Color3.fromRGB(211, 241, 224),
        red       = Color3.fromRGB(210, 65, 65),
        redDim    = Color3.fromRGB(247, 225, 225),
        amber     = Color3.fromRGB(222, 152, 35),
        text      = Color3.fromRGB(46,  53,  69),
        textMuted = Color3.fromRGB(100, 110, 130),
        textDim   = Color3.fromRGB(148, 156, 173),
    },
}
local currentTheme = "Dark"
local C = {}
for k, v in pairs(Themes[currentTheme]) do
    C[k] = v
end

local UI = {
    Main = nil,
    Loading = nil,
    GameInfo = nil,
    CountLabel = nil,
    RateLabel = nil,
    TabBar = nil,
    LogArea = nil,
    PinnedScroll = nil,
    Tabs = {},
    Entries = {},
    PinnedEntries = {},
    ActiveAutoButtons = {},
    ActiveSpamButtons = {},
    Conns = {},
    Labels = {
        SignalTypes = {},
        PinnedTypes = {},
    }
}

local State = {
    isMobile        = UIS.TouchEnabled,
    vp              = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080),
    autoSpeed       = 100,
    latestEvent     = nil,
    showProductNames= false,
    showSignalText  = true,
    quickFireKey    = nil,
    toggleKey       = Enum.KeyCode.RightShift,
    fxEnabled       = false,
    autoRunEnabled  = false,
    showCurrentGame = true,
    showRateMonitor = true,
    eventCount      = 0,
    pinCount        = 0,
    suppressCounter = 0,
    rateSmooth      = 0,
    uiVisible       = true,
    isCollapsed     = false,
    activeTab       = nil,
    globalPinned    = {},
    pinnedDataList  = {},
    signalTimestamps= {},
}

local PW  = State.isMobile and math.floor(State.vp.X * 0.92) or 780
local PH  = State.isMobile and math.floor(State.vp.Y * 0.75) or 480
local TH  = State.isMobile and 46 or 52
local FH  = State.isMobile and 46 or 50
local TABH= State.isMobile and 36 or 34
local BH  = State.isMobile and 36 or 28
local FS, FM, FL = 13, (State.isMobile and 15 or 14), (State.isMobile and 17 or 16)

-- save/load extra settings
local function saveSeluwiaSettings()
    pcall(function()
        if writefile then
            local data = {
                showNames     = State.showProductNames,
                showSignalText= State.showSignalText,
                quickFireKey  = State.quickFireKey and State.quickFireKey.Name or nil,
                toggleKey     = State.toggleKey and State.toggleKey.Name or nil,
                theme         = currentTheme,
                fxEnabled     = State.fxEnabled,
                autoRunEnabled= State.autoRunEnabled,
                showCurrentGame= State.showCurrentGame,
                showRateMonitor= State.showRateMonitor,
            }
            writefile(SETTINGS_FILE_V, HS:JSONEncode(data))
        end
    end)
end

local function loadSeluwiaSettings()
    pcall(function()
        if isfile and isfile(SETTINGS_FILE_V) then
            local d = HS:JSONDecode(readfile(SETTINGS_FILE_V))
            if d then
                State.showProductNames = d.showNames == true
                State.showSignalText   = d.showSignalText ~= false
                State.fxEnabled        = d.fxEnabled == true
                State.autoRunEnabled   = d.autoRunEnabled == true
                State.showCurrentGame  = d.showCurrentGame ~= false
                State.showRateMonitor  = d.showRateMonitor ~= false
                if d.theme == "Dark" or d.theme == "Light" then
                    currentTheme = d.theme
                    for k, v in pairs(Themes[currentTheme]) do
                        C[k] = v
                    end
                end
                if d.quickFireKey then
                    pcall(function() State.quickFireKey = Enum.KeyCode[d.quickFireKey] end)
                end
                if d.toggleKey then
                    pcall(function() State.toggleKey = Enum.KeyCode[d.toggleKey] end)
                end
            end
        end
    end)
end
loadSeluwiaSettings()

-- resolve product name from id
local nameCache = {}
local function getProductName(id, sigType)
    if nameCache[id] then return nameCache[id] end
    local name = nil
    pcall(function()
        if sigType == "Product" then
            local info = MPS:GetProductInfo(id, Enum.InfoType.Product)
            if info and info.Name then name = info.Name end
        elseif sigType == "Gamepass" then
            local info = MPS:GetProductInfo(id, Enum.InfoType.GamePass)
            if info and info.Name then name = info.Name end
        else
            local info = MPS:GetProductInfo(id, Enum.InfoType.Asset)
            if info and info.Name then name = info.Name end
        end
    end)
    if not name then
        pcall(function()
            local url
            if sigType == "Gamepass" then
                url = "https://economy.roblox.com/v1/game-pass/"..tostring(id).."/game-pass-product-info"
            elseif sigType == "Product" then
                url = "https://economy.roblox.com/v2/developer-products/"..tostring(id).."/info"
            end
            if url then
                local res = game:HttpGet(url)
                local data = HS:JSONDecode(res)
                if data and data.Name then
                    name = data.Name
                elseif data and data.name then
                    name = data.name
                end
            end
        end)
    end
    if not name then
        for _, infoType in ipairs({Enum.InfoType.GamePass, Enum.InfoType.Product, Enum.InfoType.Asset}) do
            pcall(function()
                local info = MPS:GetProductInfo(id, infoType)
                if info and info.Name and info.Name ~= "" then name = info.Name end
            end)
            if name then break end
        end
    end
    if name then nameCache[id] = name end
    return name
end

local TIF = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TIM = TweenInfo.new(0.30, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TIS = TweenInfo.new(0.50, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local resizing = false

-- HELPERS
local function corner(inst, r)
    local c = Instance.new("UICorner", inst)
    c.CornerRadius = UDim.new(0, r or 10)
    return c
end

local function stroke(inst, col, t)
    local s = Instance.new("UIStroke", inst)
    s.Color     = col or C.border
    s.Thickness = t or 1
    return s
end

local function tw(inst, info, props)
    TweenService:Create(inst, info, props):Play()
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(inp)
        if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) and not resizing then
            dragging = true
            dragStart = inp.Position
            startPos = frame.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
            if UI.GameInfo then
                UI.GameInfo.Position = UDim2.new(0, frame.Position.X.Offset + frame.Size.X.Offset + 10, 0, frame.Position.Y.Offset)
            end
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- VISUAL FX (merged script)
do
    local FX = {
        BLUR_SIZE = 24, BRIGHTNESS_TARGET = 1, TWEEN_TIME = 0.8,
        STAR_SIZE_MIN = 2, STAR_SIZE_MAX = 7, STAR_SPEED_MIN = 1.5, STAR_SPEED_MAX = 3.5, SPAWN_INTERVAL = 0.03,
        STAR_COLOR = Color3.fromRGB(255, 255, 255), PARALLAX_STRENGTH = 0.02, PARALLAX_SMOOTH = 0.08, FOG_DENSITY = 0.3,
        AMBIENT_SOUND_ID = "rbxassetid://9120386430", AMBIENT_VOLUME = 0.4,
        DUST_SIZE = UDim2.new(0, 3, 0, 3), DUST_LIFETIME = 0.8, DUST_SPAWN_RATE = 0.02, DUST_COLOR = Color3.fromRGB(255, 255, 255), DUST_Y_OFFSET = -55,
    }
    local S = {
        originalBrightness = Lighting.Brightness,
        blurEffect = nil, blurTween = nil,
        screenGui = nil, starContainer = nil, timeGui = nil, ambientSound = nil, dustGui = nil, dustContainer = nil, fpsPingGui = nil,
        starLoopRunning = false, dustLoopRunning = false,
        currentFps = 0, currentPing = 0, mouseX = 0, mouseY = 0, offsetX = 0, offsetY = 0, parallaxConnection = nil,
    }

    do
        local frames, lastTime = 0, tick()
        RunService.Heartbeat:Connect(function()
            frames = frames + 1
            if tick() - lastTime >= 1 then
                S.currentFps = math.floor(frames / (tick() - lastTime))
                S.currentPing = math.floor(player:GetNetworkPing() * 1000)
                frames = 0
                lastTime = tick()
            end
        end)
    end

    local function fxSetBlurAndBrightness(blurSize, brightness)
        if S.blurTween then S.blurTween:Cancel(); S.blurTween = nil end
        if blurSize > 0 then
            if not S.blurEffect then S.blurEffect = Instance.new("BlurEffect"); S.blurEffect.Size = 0; S.blurEffect.Parent = Lighting end
            S.blurTween = TweenService:Create(S.blurEffect, TweenInfo.new(FX.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = blurSize})
            S.blurTween:Play()
        else
            if S.blurEffect then
                S.blurTween = TweenService:Create(S.blurEffect, TweenInfo.new(FX.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0})
                S.blurTween:Play()
                S.blurTween.Completed:Connect(function() if S.blurEffect then S.blurEffect:Destroy(); S.blurEffect = nil end end)
            end
        end
        TweenService:Create(Lighting, TweenInfo.new(FX.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Brightness = brightness}):Play()
    end

    local function fxCreateStar()
        local s = Instance.new("Frame")
        s.BorderSizePixel = 0
        s.BackgroundColor3 = FX.STAR_COLOR
        s.AnchorPoint = Vector2.new(0.5, 0)
        local sz = math.random(FX.STAR_SIZE_MIN, FX.STAR_SIZE_MAX)
        s.Size = UDim2.new(0, sz, 0, sz)
        Instance.new("UICorner", s).CornerRadius = UDim.new(0, 1)
        return s
    end
    local function fxSpawnStar()
        if not S.starContainer then return end
        local s = fxCreateStar()
        s.Parent = S.starContainer
        s.ZIndex = 2
        local sz = math.random(FX.STAR_SIZE_MIN, FX.STAR_SIZE_MAX)
        s.Size = UDim2.new(0, sz, 0, sz)
        s.Position = UDim2.new(math.random(), 0, -0.05, 0)
        s.BackgroundTransparency = 0.1 + math.random() * 0.5
        local dur = math.random(FX.STAR_SPEED_MIN * 100, FX.STAR_SPEED_MAX * 100) / 100
        local tws = TweenService:Create(s, TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Position = UDim2.new(s.Position.X.Scale, 0, 1.1, 0), BackgroundTransparency = 1})
        tws:Play()
        tws.Completed:Connect(function()
            if s and s.Parent then
                s:Destroy()
            end
        end)
    end
    local function fxStartStars()
        if S.starLoopRunning then return end
        S.starLoopRunning = true
        for _ = 1, 18 do
            fxSpawnStar()
        end
        task.spawn(function() while S.starLoopRunning and S.screenGui and S.screenGui.Enabled do fxSpawnStar(); task.wait(FX.SPAWN_INTERVAL) end end)
    end
    local function fxStopStars() S.starLoopRunning = false end

    local function fxStartParallax()
        local pos = UIS:GetMouseLocation(); S.mouseX, S.mouseY = pos.X, pos.Y
        S.parallaxConnection = RunService.Heartbeat:Connect(function()
            if not S.starContainer then return end
            local p = UIS:GetMouseLocation(); S.mouseX, S.mouseY = p.X, p.Y
            local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
            local tx = (S.mouseX / vp.X - 0.5) * FX.PARALLAX_STRENGTH * vp.X
            local ty = (S.mouseY / vp.Y - 0.5) * FX.PARALLAX_STRENGTH * vp.Y
            S.offsetX = S.offsetX + (tx - S.offsetX) * FX.PARALLAX_SMOOTH
            S.offsetY = S.offsetY + (ty - S.offsetY) * FX.PARALLAX_SMOOTH
            S.starContainer.Position = UDim2.new(0.5, S.offsetX, 0.5, S.offsetY)
        end)
    end
    local function fxStopParallax()
        if S.parallaxConnection then S.parallaxConnection:Disconnect(); S.parallaxConnection = nil end
        S.offsetX, S.offsetY = 0, 0
    end

    local function fxStartSound()
        local assetId = tonumber(string.match(FX.AMBIENT_SOUND_ID or "", "%d+"))
        if not assetId then return end
        local isSoundAsset = false
        pcall(function()
            local info = MPS:GetProductInfo(assetId, Enum.InfoType.Asset)
            if info and info.AssetTypeId == 3 then
                isSoundAsset = true
            end
        end)
        if not isSoundAsset then
            return
        end
        if S.ambientSound then S.ambientSound:Stop(); S.ambientSound:Destroy() end
        S.ambientSound = Instance.new("Sound")
        S.ambientSound.SoundId = FX.AMBIENT_SOUND_ID
        S.ambientSound.Looped = true
        S.ambientSound.Volume = 0
        S.ambientSound.Parent = playerGui
        S.ambientSound:Play()
        TweenService:Create(S.ambientSound, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Volume = FX.AMBIENT_VOLUME}):Play()
    end
    local function fxStopSound()
        if S.ambientSound then
            local t = TweenService:Create(S.ambientSound, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Volume = 0})
            t:Play()
            t.Completed:Connect(function() if S.ambientSound then S.ambientSound:Stop(); S.ambientSound:Destroy(); S.ambientSound = nil end end)
        end
    end

    local function fxCreateTimeGui()
        if S.timeGui then S.timeGui:Destroy() end
        S.timeGui = Instance.new("ScreenGui"); S.timeGui.Name = "SeluwiaFxTime"; S.timeGui.ResetOnSpawn = false; S.timeGui.DisplayOrder = 10; S.timeGui.Parent = playerGui
        local c = Instance.new("Frame"); c.Size = UDim2.new(0, 200, 0, 70); c.Position = UDim2.new(0, 20, 1, -90); c.BackgroundTransparency = 1; c.Parent = S.timeGui
        local d = Instance.new("TextLabel"); d.Name = "DateLabel"; d.Size = UDim2.new(1, 0, 0, 20); d.BackgroundTransparency = 1; d.TextColor3 = Color3.fromRGB(220,220,255); d.TextSize = 16; d.Font = Enum.Font.GothamMedium; d.TextXAlignment = Enum.TextXAlignment.Left; d.Parent = c
        local t = Instance.new("TextLabel"); t.Name = "TimeLabel"; t.Size = UDim2.new(1, 0, 0, 40); t.Position = UDim2.new(0,0,0,22); t.BackgroundTransparency = 1; t.TextColor3 = Color3.fromRGB(255,255,255); t.TextSize = 40; t.Font = Enum.Font.GothamBold; t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = c
        task.spawn(function()
            while S.timeGui and S.timeGui.Parent do
                local now = os.time() + 3 * 3600
                d.Text = os.date("!%A %d.%m", now)
                t.Text = os.date("!%H:%M:%S", now)
                task.wait(1)
            end
        end)
    end
    local function fxRemoveTimeGui() if S.timeGui then S.timeGui:Destroy(); S.timeGui = nil end end

    local function fxCreateFpsPingGui()
        if S.fpsPingGui then S.fpsPingGui:Destroy() end
        S.fpsPingGui = Instance.new("ScreenGui"); S.fpsPingGui.Name = "SeluwiaFxNet"; S.fpsPingGui.ResetOnSpawn = false; S.fpsPingGui.DisplayOrder = 10; S.fpsPingGui.Parent = playerGui
        local c = Instance.new("Frame"); c.Size = UDim2.new(0, 170, 0, 50); c.Position = UDim2.new(1, -20, 1, -30); c.AnchorPoint = Vector2.new(1,1); c.BackgroundTransparency = 1; c.Parent = S.fpsPingGui
        local f = Instance.new("TextLabel"); f.Name = "F"; f.Size = UDim2.new(1,0,0,24); f.BackgroundTransparency = 1; f.TextColor3 = Color3.fromRGB(255,255,255); f.TextSize = 18; f.Font = Enum.Font.GothamBold; f.TextXAlignment = Enum.TextXAlignment.Right; f.Parent = c
        local p = Instance.new("TextLabel"); p.Name = "P"; p.Size = UDim2.new(1,0,0,24); p.Position = UDim2.new(0,0,0,26); p.BackgroundTransparency = 1; p.TextColor3 = Color3.fromRGB(255,255,255); p.TextSize = 18; p.Font = Enum.Font.GothamBold; p.TextXAlignment = Enum.TextXAlignment.Right; p.Parent = c
        task.spawn(function()
            while S.fpsPingGui and S.fpsPingGui.Parent do
                f.Text = "FPS: " .. tostring(S.currentFps)
                p.Text = "Ping: " .. tostring(S.currentPing) .. " ms"
                task.wait(0.5)
            end
        end)
    end
    local function fxRemoveFpsPingGui() if S.fpsPingGui then S.fpsPingGui:Destroy(); S.fpsPingGui = nil end end

    local function fxCreateDust()
        if S.dustGui then S.dustGui:Destroy() end
        S.dustGui = Instance.new("ScreenGui"); S.dustGui.Name = "SeluwiaFxDust"; S.dustGui.ResetOnSpawn = false; S.dustGui.DisplayOrder = 5; S.dustGui.Parent = playerGui
        S.dustContainer = Instance.new("Frame"); S.dustContainer.Size = UDim2.new(1,0,1,0); S.dustContainer.BackgroundTransparency = 1; S.dustContainer.Parent = S.dustGui
        S.dustLoopRunning = true
        task.spawn(function()
            while S.dustLoopRunning and S.dustGui and S.dustGui.Parent do
                local p = UIS:GetMouseLocation()
                local d = Instance.new("Frame")
                d.Size = FX.DUST_SIZE; d.AnchorPoint = Vector2.new(0.5,0.5); d.Position = UDim2.new(0,p.X,0,p.Y + FX.DUST_Y_OFFSET)
                d.BackgroundColor3 = FX.DUST_COLOR; d.BackgroundTransparency = 0.4; d.BorderSizePixel = 0
                Instance.n
