-- НАСТРОЙКИ СОБСТВЕННОГО ИНТЕРФЕЙСА
local MAIN_COLOR = Color3.fromRGB(30, 30, 35)      -- Темный футуристичный фон чата
local ACCENT_COLOR = Color3.fromRGB(138, 43, 226)   -- Фиолетовый неоновый акцент (кнопки)
local TEXT_COLOR = Color3.fromRGB(240, 240, 240)   -- Цвет основного текста
local BG_TRANSPARENCY = 0.2                        -- Прозрачность окна
local FONT_SIZE = 15                               -- Размер текста
local FONT_STYLE = Enum.Font.GothamMedium          -- Шрифт

-- Сервисы
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

-- Создание автономного GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StandalonePrivateChat"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

--- ==========================================
--- 1. ПЛАВАЮЩАЯ КНОПКА ВЫЗОВА (TOGGLE)
--- ==========================================
local ToggleButton = Instance.new("TextButton")
local ToggleCorner = Instance.new("UICorner")

ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0.02, 0, 0.2, 0)
ToggleButton.BackgroundColor3 = ACCENT_COLOR
ToggleButton.Text = "🔒" -- Иконка приватного/своего чата
ToggleButton.TextSize = 26
ToggleButton.TextColor3 = TEXT_COLOR
ToggleButton.Font = FONT_STYLE
ToggleButton.Active = true
ToggleButton.ZIndex = 5
ToggleButton.Parent = ScreenGui

ToggleCorner.CornerRadius = UDim.new(0.5, 0)
ToggleCorner.Parent = ToggleButton

-- Логика перетаскивания (Draggable) для мобильных телефонов
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

--- ==========================================
--- 2. АВТОНОМНОЕ ОКНО ЧАТА
--- ==========================================
local MainFrame = Instance.new("Frame")
local MainCorner = Instance.new("UICorner")

MainFrame.Size = UDim2.new(0.45, 0, 0.5, 0) -- Адаптивно под экраны смартфонов
MainFrame.Position = UDim2.new(0.02, 0, 0.3, 0)
MainFrame.BackgroundColor3 = MAIN_COLOR
MainFrame.BackgroundTransparency = BG_TRANSPARENCY
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local ScrollingFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local UIPadding = Instance.new("UIPadding")

ScrollingFrame.Size = UDim2.new(0.96, 0, 0.8, 0)
ScrollingFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.ScrollBarThickness = 3
ScrollingFrame.ScrollBarImageColor3 = ACCENT_COLOR
ScrollingFrame.Parent = MainFrame

UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

UIPadding.Parent = ScrollingFrame
UIPadding.PaddingLeft = UDim.new(0, 8)
UIPadding.PaddingRight = UDim.new(0, 8)

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
    ScrollingFrame.CanvasPosition = Vector2.new(0, UIListLayout.AbsoluteContentSize.Y)
end)

--- ==========================================
--- 3. СВОЯ СИСТЕМА ДЛЯ ВВОДА СООБЩЕНИЙ
--- ==========================================
local InputFrame = Instance.new("Frame")
local TextBox = Instance.new("TextBox")
local SendButton = Instance.new("TextButton")
local InputCorner = Instance.new("UICorner")
local SendCorner = Instance.new("UICorner")

InputFrame.Size = UDim2.new(0.96, 0, 0.14, 0)
InputFrame.Position = UDim2.new(0.02, 0, 0.84, 0)
InputFrame.BackgroundTransparency = 1
InputFrame.Parent = MainFrame

-- Поле ввода
TextBox.Size = UDim2.new(0.75, 0, 1, 0)
TextBox.Position = UDim2.new(0, 0, 0, 0)
TextBox.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
TextBox.TextColor3 = TEXT_COLOR
TextBox.TextSize = FONT_SIZE
TextBox.Font = FONT_STYLE
TextBox.PlaceholderText = "Напишите что-то в свой чат..."
TextBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
TextBox.Text = ""
TextBox.ClearTextOnFocus = false
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.Parent = InputFrame

InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = TextBox

local TextPadding = Instance.new("UIPadding")
TextPadding.PaddingLeft = UDim.new(0, 12)
TextPadding.Parent = TextBox

-- Кнопка отправки
SendButton.Size = UDim2.new(0.23, 0, 1, 0)
SendButton.Position = UDim2.new(0.77, 0, 0, 0)
SendButton.BackgroundColor3 = ACCENT_COLOR
SendButton.Text = "SEND"
SendButton.TextColor3 = TEXT_COLOR
SendButton.TextSize = FONT_SIZE
SendButton.Font = Enum.Font.GothamBold
SendButton.Parent = InputFrame

SendCorner.CornerRadius = UDim.new(0, 8)
SendCorner.Parent = SendButton

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

--- ==========================================
--- 4. ПОЛНОСТЬЮ АЛЬТЕРНАТИВНАЯ СЕТЕВАЯ ЛОГИКА
--- ==========================================

-- Функция локального вывода сообщения в НАШЕ окно
local function displayCustomMessage(senderName, messageText, color)
    local MessageLabel = Instance.new("TextLabel")
    MessageLabel.Size = UDim2.new(1, 0, 0, 0)
    MessageLabel.AutomaticSize = Enum.AutomaticSize.Y
    MessageLabel.BackgroundTransparency = 1
    MessageLabel.Text = "• [" .. senderName .. "]: " .. messageText
    MessageLabel.TextColor3 = color or TEXT_COLOR
    MessageLabel.TextSize = FONT_SIZE
    MessageLabel.Font = FONT_STYLE
    MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
    MessageLabel.TextWrapped = true
    MessageLabel.Parent = ScrollingFrame
end

-- Ищем скрытые каналы репликации в текущей игре
local networkEvent = nil
local possibleNames = {"SayMessageRequest", "Chat", "Message", "Send", "Tell", "Mute", "Report"}

-- Авто-поиск любого подходящего сетевого события для симуляции отправки данных
for _, desc in pairs(game:GetDescendants()) do
    if desc:IsA("RemoteEvent") then
        for _, name in pairs(possibleNames) do
            if desc.Name:find(name) then
                networkEvent = desc
                break
            end
        end
    end
    if networkEvent then break end
end

-- Если ничего не найдено, используем стандартную скрытую уязвимость дефолтного DefaultChatSystemChatEvents
if not networkEvent then
    local folder = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    networkEvent = folder and folder:FindFirstChild("SayMessageRequest")
end

-- СВЯЗЬ МЕЖДУ КЛИЕНТАМИ ЧЕРЕЗ АЛЬТЕРНАТИВНЫЙ ТРАФИК
local function sendStandaloneMessage()
    local text = TextBox.Text
    if text == "" then return end
    TextBox.Text = ""

    -- Отображаем у себя в кастомном окне мгновенно
    displayCustomMessage(localPlayer.Name, text, ACCENT_COLOR)

    -- Отправляем в обход системного GUI через найденный туннель
    if networkEvent and networkEvent:IsA("RemoteEvent") then
        -- Отправляем сырые данные. Сервер отреплицирует это другим игрокам
        networkEvent:FireServer(text, "All")
    elseif networkEvent and networkEvent:IsA("RemoteFunction") then
        task.spawn(function() networkEvent:InvokeServer(text, "All") end)
    end
end

SendButton.MouseButton1Click:Connect(sendStandaloneMessage)
TextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then sendStandaloneMessage() end
end)

-- ГЛОБАЛЬНЫЙ ПЕРЕХВАТЧИК: Ловит сообщения от других игроков ИЗ СЕТИ, минуя GUI чата Roblox
local chattedConnection
chattedConnection = Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(msg)
        if player ~= localPlayer then
            displayCustomMessage(player.Name, msg, TEXT_COLOR)
        end
    end)
end)

-- Подключаем тех игроков, кто уже находится на сервере
for _, player in pairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        player.Chatted:Connect(function(msg)
            displayCustomMessage(player.Name, msg, TEXT_COLOR)
        end)
    end
end

displayCustomMessage("СИСТЕМА", "Альтернативный изолированный чат запущен. Интерфейс Roblox проигнорирован.", Color3.fromRGB(0, 255, 150))
