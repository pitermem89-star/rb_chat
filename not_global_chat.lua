local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local MarketPlaceService = game:GetService("MarketplaceService")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. ОТКЛЮЧАЕМ ОРИГИНАЛЬНЫЙ ЧАТ ROBLOX
task.spawn(function()
    local retries = 0
    while retries < 10 do
        local success = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
        end)
        if success then break end
        retries = retries + 1
        task.wait(0.5)
    end
end)

-- Очистка старых копий скрипта
if playerGui:FindFirstChild("RobloxFakeGlobalChat") then playerGui.RobloxFakeGlobalChat:Destroy() end

-- 2. НАСТРОЙКА БАЗЫ ДАННЫХ
local DATABASE_URL = "https://firebaseio.com"

-- Получаем название игры для тега
local gameName = "Game"
pcall(function()
    gameName = MarketPlaceService:GetProductInfo(game.PlaceId).Name
end)

-- 3. СОЗДАНИЕ ИНТЕРФЕЙСА (КОПИЯ СТАНДАРТНОГО ЧАТА)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RobloxFakeGlobalChat"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.Parent = playerGui

-- Кнопка-иконка чата (как стандартная в левом верхнем углу)
local chatIcon = Instance.new("TextButton")
chatIcon.Size = UDim2.new(0, 32, 0, 32)
chatIcon.Position = UDim2.new(0, 16, 0, 4) -- Рядом с кнопкой Roblox меню
chatIcon.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
chatIcon.BackgroundTransparency = 0.5
chatIcon.Text = "💬"
chatIcon.TextSize = 18
chatIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
chatIcon.Parent = screenGui

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 8)
iconCorner.Parent = chatIcon

-- Главный контейнер чата (Размеры и позиция как у оригинала)
local chatFrame = Instance.new("Frame")
chatFrame.Size = UDim2.new(0, 340, 0, 180)
chatFrame.Position = UDim2.new(0, 16, 0, 42)
chatFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
chatFrame.BackgroundTransparency = 0.6 -- Фирменный полупрозрачный фон
chatFrame.Visible = true
chatFrame.Active = true
chatFrame.Parent = screenGui

local chatCorner = Instance.new("UICorner")
chatCorner.CornerRadius = UDim.new(0, 4)
chatCorner.Parent = chatFrame

-- Список сообщений
local msgList = Instance.new("ScrollingFrame")
msgList.Size = UDim2.new(1, -12, 1, -44)
msgList.Position = UDim2.new(0, 6, 0, 6)
msgList.BackgroundTransparency = 1
msgList.CanvasSize = UDim2.new(0, 0, 0, 0)
msgList.ScrollBarThickness = 3
msgList.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
msgList.ScrollBarImageTransparency = 0.7
msgList.ZIndex = 51
msgList.Parent = chatFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = msgList

-- Поле ввода (Появляется внизу контейнера)
local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -12, 0, 28)
textBox.Position = UDim2.new(0, 6, 1, -34)
textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
textBox.BackgroundTransparency = 0.2
textBox.PlaceholderText = "Нажмите сюда, чтобы отправить сообщение миру..."
textBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
textBox.Text = ""
textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
textBox.TextSize = 13
textBox.Font = Enum.Font.SourceSans
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.ClearTextOnFocus = false
textBox.ZIndex = 52
textBox.Parent = chatFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 4)
boxCorner.Parent = textBox

local boxPadding = Instance.new("UIPadding")
boxPadding.PaddingLeft = UDim.new(0, 8)
boxPadding.Parent = textBox

-- 4. ФУНКЦИЯ ПРОРИСОВКИ СТРОК (В стиле Roblox Chat)
local function appendMessage(senderName, currentPlace, messageText)
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -10, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.TextSize = 14
    msgLabel.Font = Enum.Font.SourceSansBold
    msgLabel.TextWrapped = true
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.RichText = true
    msgLabel.ZIndex = 51
    
    -- Текстовые теги и тени как в оригинале
    local isMe = (senderName == localPlayer.DisplayName or senderName == localPlayer.Name)
    local nameColor = isMe and "rgb(0, 170, 255)" or "rgb(255, 200, 0)"
    
    msgLabel.Text = string.format("<font color='rgb(160, 160, 160)'>[%s]</font> <font color='%s'><b>%s</b></font><font color='rgb(255, 255, 255)'><b>:</b> %s</font>", currentPlace, nameColor, senderName, messageText)
    msgLabel.Parent = msgList
    msgLabel.AutomaticSize = Enum.AutomaticSize.Y
    
    -- Листаем вниз
    task.wait(0.05)
    msgList.CanvasPosition = Vector2.new(0, msgList.AbsoluteCanvasSize.Y)
end

-- 5. ЛОГИКА ОТПРАВКИ СООБЩЕНИЯ
local function sendMessage()
    local text = textBox.Text
    if text == "" then return end
    textBox.Text = ""
    
    local data = {
        sender = localPlayer.DisplayName or localPlayer.Name,
        place = gameName,
        text = text,
        time = os.time()
    }
    
    pcall(function()
        request({
            Url = DATABASE_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
end

textBox.FocusLost:Connect(function(enterPressed) if enterPressed then sendMessage() end end)

-- 6. ОБНОВЛЕНИЕ ЧАТА В РЕАЛЬНОМ ВРЕМЕНИ
task.spawn(function()
    while task.wait(1.5) do
        pcall(function()
            local response = request({Url = DATABASE_URL, Method = "GET"})
            if response and response.StatusCode == 200 then
                local allData = HttpService:JSONDecode(response.Body)
                if allData then
                    -- Очищаем старые строки перед рендером
                    for _, child in ipairs(msgList:GetChildren()) do
                        if child:IsA("TextLabel") then child:Destroy() end
                    end
                    
                    local sortedMessages = {}
                    for _, msg in pairs(allData) do table.insert(sortedMessages, msg) end
                    table.sort(sortedMessages, function(a, b) return a.time < b.time end)
                    
                    -- Показываем только последние 30 сообщений мира, чтобы не нагружать телефон
                    local startIdx = #sortedMessages > 30 and (#sortedMessages - 30) or 1
                    for i = startIdx, #sortedMessages do
                        local msg = sortedMessages[i]
                        appendMessage(msg.sender, msg.place, msg.text)
                    end
                end
            end
        end)
    end
end)

-- 7. СВОРАЧИВАНИЕ/РАЗВЕРТЫВАНИЕ ЧАТА ПО НАЖАТИЮ НА ИКОНКУ
chatIcon.MouseButton1Click:Connect(function()
    chatFrame.Visible = not chatFrame.Visible
    chatIcon.BackgroundTransparency = chatFrame.Visible and 0.5 or 0.8
end)
