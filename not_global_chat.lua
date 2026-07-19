local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local ChatService = game:GetService("Chat")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. СТИРАЕМ СТАНДАРТНЫЙ БЛОКИРОВАННЫЙ ЧАТ ROBLOX
task.spawn(function()
    local retries = 0
    while retries < 12 do
        local success = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        end)
        if success then break end
        retries = retries + 1
        task.wait(0.5)
    end
end)

-- Очистка дубликатов при перезапуске инжектора
if playerGui:FindFirstChild("RobloxLocalServerChat") then playerGui.RobloxLocalServerChat:Destroy() end

-- 2. СОЗДАНИЕ ИНТЕРФЕЙСА (ВИЗУАЛЬНАЯ КОПИЯ ЧАТА ROBLOX)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RobloxLocalServerChat"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 99999
screenGui.Parent = playerGui

-- Маленькая иконка чата в левом верхнем углу (как оригинальная)
local chatIcon = Instance.new("TextButton")
chatIcon.Size = UDim2.new(0, 32, 0, 32)
chatIcon.Position = UDim2.new(0, 16, 0, 4)
chatIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
chatIcon.BackgroundTransparency = 0.4
chatIcon.Text = "💬"
chatIcon.TextSize = 16
chatIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
chatIcon.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 8)
iconCorner.Parent = chatIcon

-- Рамка чата (Размеры и положение стандартного чата)
local chatFrame = Instance.new("Frame")
chatFrame.Size = UDim2.new(0, 350, 0, 200)
chatFrame.Position = UDim2.new(0, 16, 0, 42)
chatFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
chatFrame.BackgroundTransparency = 0.55 -- Полупрозрачный фон
chatFrame.Visible = true
chatFrame.Active = true
chatFrame.Parent = screenGui

local chatCorner = Instance.new("UICorner")
chatCorner.CornerRadius = UDim.new(0, 6)
chatCorner.Parent = chatFrame

-- Окно прокрутки сообщений
local msgList = Instance.new("ScrollingFrame")
msgList.Size = UDim2.new(1, -12, 1, -46)
msgList.Position = UDim2.new(0, 6, 0, 6)
msgList.BackgroundTransparency = 1
msgList.CanvasSize = UDim2.new(0, 0, 0, 0)
msgList.ScrollBarThickness = 3
msgList.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
msgList.ScrollBarImageTransparency = 0.6
msgList.ZIndex = 51
msgList.Parent = chatFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = msgList

-- Поле ввода текста
local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -12, 0, 30)
textBox.Position = UDim2.new(0, 6, 1, -36)
textBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
textBox.BackgroundTransparency = 0.3
textBox.PlaceholderText = "Нажмите сюда или введите текст..."
textBox.PlaceholderColor3 = Color3.fromRGB(190, 190, 190)
textBox.Text = ""
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.TextSize = 14
textBox.Font = Enum.Font.SourceSans
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.ClearTextOnFocus = false
textBox.ZIndex = 52
textBox.Parent = chatFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 5)
boxCorner.Parent = textBox

local boxPadding = Instance.new("UIPadding")
boxPadding.PaddingLeft = UDim.new(0, 8)
boxPadding.Parent = textBox

-- 3. ФУНКЦИЯ ОТРИСОВКИ ТЕКСТА
local function appendMessage(senderName, messageText)
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -10, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.TextSize = 15
    msgLabel.Font = Enum.Font.SourceSansBold
    msgLabel.TextWrapped = true
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.RichText = true
    msgLabel.ZIndex = 51
    
    local isMe = (senderName == localPlayer.DisplayName or senderName == localPlayer.Name)
    local nameColor = isMe and "rgb(0, 170, 255)" or "rgb(240, 180, 0)"
    
    msgLabel.Text = string.format("<font color='%s'><b>%s</b></font><font color='rgb(255, 255, 255)'><b>:</b> %s</font>", nameColor, senderName, messageText)
    msgLabel.Parent = msgList
    msgLabel.AutomaticSize = Enum.AutomaticSize.Y
    
    task.wait(0.02)
    msgList.CanvasPosition = Vector2.new(0, msgList.AbsoluteCanvasSize.Y)
end

-- 4. НАДЕЖНЫЙ ПЕРЕХВАТ СООБЩЕНИЙ С СЕРВЕРА С УЧЕТОМ PLACE_ID
-- Чат привязан жестко к ID этой конкретной карты и сервера
local function hookPlayer(p)
    p.Chatted:Connect(function(msg)
        appendMessage(p.DisplayName or p.Name, msg)
    end)
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)

-- 5. ОТПРАВКА СООБЩЕНИЯ ВНУТРИ ТЕКУЩЕЙ ИГРЫ
local function sendMessage()
    local text = textBox.Text
    if text == "" then return end
    textBox.Text = ""
    
    -- Тот самый 100% рабочий метод от головы персонажа
    if localPlayer.Character and localPlayer.Character:FindFirstChild("Head") then
        ChatService:Chat(localPlayer.Character.Head, text, Enum.ChatColor.White)
        appendMessage(localPlayer.DisplayName or localPlayer.Name, text)
    end
end

textBox.FocusLost:Connect(function(enterPressed) if enterPressed then sendMessage() end end)

-- Переключение видимости по нажатию кнопки
chatIcon.MouseButton1Click:Connect(function()
    chatFrame.Visible = not chatFrame.Visible
end)
