-- ============================================================================
-- CHILLI HUB V8 - MÀN HÌNH BẢO TRÌ & NÂNG CẤP HIỆN ĐẠI (MAINTENANCE SCREEN)
-- Thiết kế: Glassmorphism Siêu Thực, Hiệu ứng Neon Cyberpunk & Responsive
-- ============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- Xác định ScreenGui an toàn trên mọi Executor (Delta, Fluxus, Codex, Solara, Wave, v.v.)
local parentGui
if typeof(gethui) == "function" then
    parentGui = gethui()
else
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui then
        parentGui = coreGui
    else
        parentGui = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Xóa UI cũ nếu đang tồn tại
local OLD_GUI_NAME = "ChilliMaintenanceOverlay"
local existingGui = parentGui:FindFirstChild(OLD_GUI_NAME)
if existingGui then
    pcall(function() existingGui:Destroy() end)
end

-- Âm thanh thông báo nhẹ nhàng chuẩn Roblox
local function playNotificationSound()
    pcall(function()
        local snd = Instance.new("Sound")
        snd.SoundId = "rbxassetid://6026984224"
        snd.Volume = 0.85
        snd.PlaybackSpeed = 1.05
        snd.Parent = SoundService
        if SoundService.PlayLocalSound then
            SoundService:PlayLocalSound(snd)
        else
            snd:Play()
        end
        game:GetService("Debris"):AddItem(snd, 3)
    end)
end

-- Hiệu ứng làm mờ hậu cảnh (Blur)
local blurEffect = nil
pcall(function()
    blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "ChilliMaintenanceBlur"
    blurEffect.Size = 0
    blurEffect.Parent = Lighting
    TweenService:Create(blurEffect, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = 18
    }):Play()
end)

-- Tạo ScreenGui chính
local screenGui = Instance.new("ScreenGui")
screenGui.Name = OLD_GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

-- Khung nền đen mờ bao phủ toàn màn hình
local backdrop = Instance.new("Frame")
backdrop.Name = "DarkBackdrop"
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.Position = UDim2.fromScale(0, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(5, 7, 12)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel = 0
backdrop.Active = true
backdrop.ZIndex = 1
backdrop.Parent = screenGui

TweenService:Create(backdrop, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    BackgroundTransparency = 0.35
}):Play()

-- Khung tâm modal thông báo bảo trì (Main Card)
local modal = Instance.new("Frame")
modal.Name = "MaintenanceModal"
modal.AnchorPoint = Vector2.new(0.5, 0.5)
modal.Position = UDim2.new(0.5, 0, 0.5, 30) -- Bắt đầu thấp hơn để chạy hiệu ứng trượt lên
modal.Size = UDim2.new(0, 520, 0, 420)
modal.BackgroundColor3 = Color3.fromRGB(13, 16, 26)
modal.BackgroundTransparency = 1
modal.BorderSizePixel = 0
modal.ClipsDescendants = true
modal.ZIndex = 10
modal.Parent = backdrop

-- Hỗ trợ co giãn chuẩn xác trên màn hình điện thoại (Mobile Responsive)
local uiScale = Instance.new("UIScale")
uiScale.Parent = modal

local function adjustScale()
    local cam = workspace.CurrentCamera
    if cam then
        local vp = cam.ViewportSize
        if vp.X < 560 or vp.Y < 460 then
            local scaleX = vp.X / 560
            local scaleY = vp.Y / 460
            uiScale.Scale = math.clamp(math.min(scaleX, scaleY) * 0.92, 0.55, 1)
        else
            uiScale.Scale = 1
        end
    end
end
adjustScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adjustScale)

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 16)
modalCorner.Parent = modal

-- Viền phát sáng rực rỡ (Cyber Glow Stroke)
local modalStroke = Instance.new("UIStroke")
modalStroke.Name = "ModalGlowStroke"
modalStroke.Thickness = 1.6
modalStroke.Color = Color3.fromRGB(255, 95, 60)
modalStroke.Transparency = 1
modalStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
modalStroke.Parent = modal

local strokeGrad = Instance.new("UIGradient")
strokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 90, 50)),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 175, 45)),
    ColorSequenceKeypoint.new(0.70, Color3.fromRGB(150, 90, 255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 90, 50)),
})
strokeGrad.Parent = modalStroke

-- Hiệu ứng xoay góc gradient viền liên tục
local rotAngle = 0
local rotConn = RunService.RenderStepped:Connect(function(dt)
    rotAngle = (rotAngle + dt * 48) % 360
    strokeGrad.Rotation = rotAngle
end)

-- Lớp nền ảnh tinh vân mờ bên trong card
local bgCosmic = Instance.new("ImageLabel")
bgCosmic.Name = "CosmicBg"
bgCosmic.Size = UDim2.fromScale(1, 1)
bgCosmic.Position = UDim2.fromScale(0, 0)
bgCosmic.BackgroundTransparency = 1
bgCosmic.Image = "rbxassetid://83726521558450"
bgCosmic.ImageRectOffset = Vector2.new(100, 100)
bgCosmic.ImageRectSize = Vector2.new(400, 300)
bgCosmic.ScaleType = Enum.ScaleType.Stretch
bgCosmic.ImageTransparency = 0.88
bgCosmic.ZIndex = 11
bgCosmic.Parent = modal

-- Vầng sáng phát quang ở đỉnh card
local topGlow = Instance.new("ImageLabel")
topGlow.Name = "TopGlow"
topGlow.AnchorPoint = Vector2.new(0.5, 0)
topGlow.Position = UDim2.new(0.5, 0, 0, -50)
topGlow.Size = UDim2.new(1, 100, 0, 130)
topGlow.BackgroundTransparency = 1
topGlow.Image = "rbxassetid://4965945816"
topGlow.ImageColor3 = Color3.fromRGB(255, 120, 60)
topGlow.ImageTransparency = 0.72
topGlow.ZIndex = 12
topGlow.Parent = modal

-- 1. THANH HUY HIỆU STATUS (PULSING STATUS BADGE)
local statusBadge = Instance.new("Frame")
statusBadge.Name = "StatusBadge"
statusBadge.AnchorPoint = Vector2.new(0.5, 0)
statusBadge.Position = UDim2.new(0.5, 0, 0, 18)
statusBadge.Size = UDim2.new(0, 250, 0, 26)
statusBadge.BackgroundColor3 = Color3.fromRGB(24, 20, 28)
statusBadge.BackgroundTransparency = 0.2
statusBadge.BorderSizePixel = 0
statusBadge.ZIndex = 15
statusBadge.Parent = modal

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(1, 0)
badgeCorner.Parent = statusBadge

local badgeStroke = Instance.new("UIStroke")
badgeStroke.Thickness = 1.1
badgeStroke.Color = Color3.fromRGB(255, 180, 50)
badgeStroke.Transparency = 0.3
badgeStroke.Parent = statusBadge

-- Đèn tròn màu vàng cam nhấp nháy (Pulsing Dot)
local pulseDot = Instance.new("Frame")
pulseDot.Name = "PulseDot"
pulseDot.AnchorPoint = Vector2.new(0, 0.5)
pulseDot.Position = UDim2.new(0, 10, 0.5, 0)
pulseDot.Size = UDim2.new(0, 8, 0, 8)
pulseDot.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
pulseDot.BorderSizePixel = 0
pulseDot.ZIndex = 16
pulseDot.Parent = statusBadge

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = pulseDot

-- Tween nhấp nháy đèn báo hiệu
task.spawn(function()
    while statusBadge and statusBadge.Parent do
        TweenService:Create(pulseDot, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.65
        }):Play()
        task.wait(0.7)
        TweenService:Create(pulseDot, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0
        }):Play()
        task.wait(0.7)
    end
end)

local badgeText = Instance.new("TextLabel")
badgeText.Name = "BadgeText"
badgeText.Position = UDim2.new(0, 24, 0, 0)
badgeText.Size = UDim2.new(1, -28, 1, 0)
badgeText.BackgroundTransparency = 1
badgeText.Font = Enum.Font.GothamBold
badgeText.TextSize = 11
badgeText.TextColor3 = Color3.fromRGB(255, 200, 80)
badgeText.Text = "ĐANG BẢO TRÌ • UNDER MAINTENANCE"
badgeText.TextXAlignment = Enum.TextXAlignment.Center
badgeText.ZIndex = 16
badgeText.Parent = statusBadge

-- 2. KHU VỰC LOGO & TIÊU ĐỀ CHÍNH
local logoHolder = Instance.new("Frame")
logoHolder.Name = "LogoHolder"
logoHolder.AnchorPoint = Vector2.new(0.5, 0)
logoHolder.Position = UDim2.new(0.5, 0, 0, 54)
logoHolder.Size = UDim2.new(0, 62, 0, 62)
logoHolder.BackgroundColor3 = Color3.fromRGB(15, 12, 22)
logoHolder.BorderSizePixel = 0
logoHolder.ZIndex = 15
logoHolder.Parent = modal

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(1, 0)
logoCorner.Parent = logoHolder

local logoStroke = Instance.new("UIStroke")
logoStroke.Thickness = 1.8
logoStroke.Color = Color3.fromRGB(255, 90, 50)
logoStroke.Parent = logoHolder

local logoGrad = Instance.new("UIGradient")
logoGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 90, 50)),
    ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 210, 80)),
})
logoGrad.Parent = logoStroke

-- Logo Quả Ớt chính thức của Chilli Hub
local chilliLogo = Instance.new("ImageLabel")
chilliLogo.Name = "ChilliLogo"
chilliLogo.AnchorPoint = Vector2.new(0.5, 0.5)
chilliLogo.Position = UDim2.fromScale(0.5, 0.5)
chilliLogo.Size = UDim2.fromScale(0.82, 0.82)
chilliLogo.BackgroundTransparency = 1
chilliLogo.Image = "rbxassetid://74441610995894"
chilliLogo.ScaleType = Enum.ScaleType.Fit
chilliLogo.ZIndex = 16
chilliLogo.Parent = logoHolder

-- Tên Hub
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "HubTitle"
titleLabel.AnchorPoint = Vector2.new(0.5, 0)
titleLabel.Position = UDim2.new(0.5, 0, 0, 122)
titleLabel.Size = UDim2.new(1, -40, 0, 24)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 19
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "CHILLI HUB V8"
titleLabel.ZIndex = 15
titleLabel.Parent = modal

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 220, 160)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 110, 70)),
})
titleGrad.Parent = titleLabel

-- Đường phân cách ánh sáng neon mảnh
local divider = Instance.new("Frame")
divider.Name = "NeonDivider"
divider.AnchorPoint = Vector2.new(0.5, 0)
divider.Position = UDim2.new(0.5, 0, 0, 152)
divider.Size = UDim2.new(0, 140, 0, 1.5)
divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider.BorderSizePixel = 0
divider.ZIndex = 15
divider.Parent = modal

local divGrad = Instance.new("UIGradient")
divGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 90, 50)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 210, 80)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 90, 50)),
})
divGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0.00, 0.8),
    NumberSequenceKeypoint.new(0.50, 0.0),
    NumberSequenceKeypoint.new(1.00, 0.8),
})
divGrad.Parent = divider

-- 3. HỘP NỘI DUNG THÔNG BÁO (VIỆT & ANH)
local contentBox = Instance.new("Frame")
contentBox.Name = "ContentBox"
contentBox.AnchorPoint = Vector2.new(0.5, 0)
contentBox.Position = UDim2.new(0.5, 0, 0, 164)
contentBox.Size = UDim2.new(1, -44, 0, 138)
contentBox.BackgroundColor3 = Color3.fromRGB(9, 11, 18)
contentBox.BackgroundTransparency = 0.35
contentBox.BorderSizePixel = 0
contentBox.ZIndex = 15
contentBox.Parent = modal

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 12)
contentCorner.Parent = contentBox

local contentStroke = Instance.new("UIStroke")
contentStroke.Thickness = 1
contentStroke.Color = Color3.fromRGB(45, 55, 80)
contentStroke.Transparency = 0.5
contentStroke.Parent = contentBox

-- TIẾNG VIỆT CHÍNH (ĐẬM VÀ RÕ NÉT)
local vnTitle = Instance.new("TextLabel")
vnTitle.Name = "VietnameseMainNotice"
vnTitle.Position = UDim2.new(0, 14, 0, 12)
vnTitle.Size = UDim2.new(1, -28, 0, 46)
vnTitle.BackgroundTransparency = 1
vnTitle.Font = Enum.Font.GothamBold
vnTitle.TextSize = 14
vnTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
vnTitle.TextWrapped = true
vnTitle.RichText = true
vnTitle.Text = "Chúng tôi đang tích cực <font color=\"#FFA733\">sửa lỗi</font> và <font color=\"#FF5733\">update</font>, rất xin lỗi vì sự cố này.\nScript sẽ sớm trở lại!"
vnTitle.TextXAlignment = Enum.TextXAlignment.Center
vnTitle.TextYAlignment = Enum.TextYAlignment.Center
vnTitle.ZIndex = 16
vnTitle.Parent = contentBox

-- Đường gạch mảnh chia 2 ngôn ngữ
local langDivider = Instance.new("Frame")
langDivider.Name = "LangDivider"
langDivider.AnchorPoint = Vector2.new(0.5, 0)
langDivider.Position = UDim2.new(0.5, 0, 0, 68)
langDivider.Size = UDim2.new(0.7, 0, 0, 1)
langDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
langDivider.BackgroundTransparency = 0.88
langDivider.BorderSizePixel = 0
langDivider.ZIndex = 16
langDivider.Parent = contentBox

-- TIẾNG ANH PHỤ (BẢN DỊCH NHỎ GỌN BÊN DƯỚI)
local enSubtitle = Instance.new("TextLabel")
enSubtitle.Name = "EnglishSubNotice"
enSubtitle.Position = UDim2.new(0, 14, 0, 74)
enSubtitle.Size = UDim2.new(1, -28, 0, 52)
enSubtitle.BackgroundTransparency = 1
enSubtitle.Font = Enum.Font.GothamMedium
enSubtitle.TextSize = 11.5
enSubtitle.TextColor3 = Color3.fromRGB(155, 168, 192)
enSubtitle.TextWrapped = true
enSubtitle.RichText = true
enSubtitle.Text = "We are actively fixing bugs and pushing new updates. We sincerely apologize for this inconvenience.\nThe script will return soon!"
enSubtitle.TextXAlignment = Enum.TextXAlignment.Center
enSubtitle.TextYAlignment = Enum.TextYAlignment.Center
enSubtitle.ZIndex = 16
enSubtitle.Parent = contentBox

-- 4. THANH TIẾN ĐỘ CHUYỂN ĐỘNG (PROGRESS PULSE BAR)
local progressTrack = Instance.new("Frame")
progressTrack.Name = "ProgressTrack"
progressTrack.AnchorPoint = Vector2.new(0.5, 0)
progressTrack.Position = UDim2.new(0.5, 0, 0, 312)
progressTrack.Size = UDim2.new(1, -44, 0, 5)
progressTrack.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
progressTrack.BorderSizePixel = 0
progressTrack.ClipsDescendants = true
progressTrack.ZIndex = 15
progressTrack.Parent = modal

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = progressTrack

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0.45, 0, 1, 0)
progressBar.Position = UDim2.new(-0.45, 0, 0, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(255, 95, 50)
progressBar.BorderSizePixel = 0
progressBar.ZIndex = 16
progressBar.Parent = progressTrack

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = progressBar

local barGrad = Instance.new("UIGradient")
barGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 75, 45)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 205, 75)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 75, 45)),
})
barGrad.Parent = progressBar

-- Chạy dải tiến độ lặp vô tận mượt mà
task.spawn(function()
    while progressTrack and progressTrack.Parent do
        progressBar.Position = UDim2.new(-0.45, 0, 0, 0)
        local tweenIn = TweenService:Create(progressBar, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Position = UDim2.new(1.0, 0, 0, 0)
        })
        tweenIn:Play()
        tweenIn.Completed:Wait()
        task.wait(0.2)
    end
end)

-- 5. CỤM NÚT TƯƠNG TÁC CUỐI TRANG
local btnRow = Instance.new("Frame")
btnRow.Name = "ButtonRow"
btnRow.AnchorPoint = Vector2.new(0.5, 0)
btnRow.Position = UDim2.new(0.5, 0, 0, 332)
btnRow.Size = UDim2.new(1, -44, 0, 42)
btnRow.BackgroundTransparency = 1
btnRow.ZIndex = 15
btnRow.Parent = modal

local btnLayout = Instance.new("UIListLayout")
btnLayout.FillDirection = Enum.FillDirection.Horizontal
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
btnLayout.Padding = UDim.new(0, 12)
btnLayout.Parent = btnRow

-- Nút 1: Sao chép link Discord
local discordBtn = Instance.new("TextButton")
discordBtn.Name = "DiscordBtn"
discordBtn.Size = UDim2.new(0.62, 0, 1, 0)
discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBtn.BorderSizePixel = 0
discordBtn.Font = Enum.Font.GothamBold
discordBtn.TextSize = 13
discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
discordBtn.Text = "💬 Tham gia Discord Nhận Tin"
discordBtn.AutoButtonColor = false
discordBtn.ZIndex = 16
discordBtn.Parent = btnRow

local discCorner = Instance.new("UICorner")
discCorner.CornerRadius = UDim.new(0, 10)
discCorner.Parent = discordBtn

local discStroke = Instance.new("UIStroke")
discStroke.Thickness = 1.2
discStroke.Color = Color3.fromRGB(140, 155, 255)
discStroke.Transparency = 0.4
discStroke.Parent = discordBtn

-- Nút 2: Đóng bảng thông báo
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0.34, 0, 1, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 48)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.TextColor3 = Color3.fromRGB(200, 208, 225)
closeBtn.Text = "✕ Đóng lại"
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 16
closeBtn.Parent = btnRow

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Thickness = 1
closeStroke.Color = Color3.fromRGB(55, 65, 90)
closeStroke.Transparency = 0.5
closeStroke.Parent = closeBtn

-- Hàm đóng thông báo có hiệu ứng thu nhỏ mượt mà
local isClosing = false
local function dismissMaintenanceScreen()
    if isClosing then return end
    isClosing = true
    if rotConn then rotConn:Disconnect() end

    if blurEffect then
        TweenService:Create(blurEffect, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = 0
        }):Play()
    end

    TweenService:Create(backdrop, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    }):Play()

    local closeTween = TweenService:Create(modal, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 0.5, 40),
        BackgroundTransparency = 1
    })
    closeTween.Completed:Connect(function()
        if blurEffect then pcall(function() blurEffect:Destroy() end) end
        screenGui:Destroy()
    end)
    closeTween:Play()
end

closeBtn.MouseButton1Click:Connect(dismissMaintenanceScreen)

-- Logic sao chép Link Discord
local DISCORD_INVITE_LINK = "https://discord.gg/chillihub" -- Thay link discord của bạn ở đây
discordBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if typeof(setclipboard) == "function" then
            setclipboard(DISCORD_INVITE_LINK)
        elseif typeof(toclipboard) == "function" then
            toclipboard(DISCORD_INVITE_LINK)
        end
    end)
    
    playNotificationSound()

    discordBtn.Text = "✅ Đã sao chép Link Discord!"
    discordBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    task.delay(2.2, function()
        if discordBtn and discordBtn.Parent then
            discordBtn.Text = "💬 Tham gia Discord Nhận Tin"
            discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        end
    end)
end)

-- Hiệu ứng Hover nút bấm
local function applyHover(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = hoverColor
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = normalColor
        }):Play()
    end)
end

applyHover(discordBtn, Color3.fromRGB(88, 101, 242), Color3.fromRGB(105, 118, 255))
applyHover(closeBtn, Color3.fromRGB(28, 32, 48), Color3.fromRGB(38, 44, 65))

-- 6. HIỆU ỨNG XUẤT HIỆN MỞ MÀN (SPRING OPEN ANIMATION)
modal.BackgroundTransparency = 1
modalStroke.Transparency = 1
modal.Position = UDim2.new(0.5, 0, 0.5, 45)

playNotificationSound()

TweenService:Create(modal, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, 0, 0.5, 0),
    BackgroundTransparency = 0.08
}):Play()

TweenService:Create(modalStroke, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
    Transparency = 0.2
}):Play()

print("[Chilli Hub V8] Đã kích hoạt màn hình thông báo bảo trì thành công!")
