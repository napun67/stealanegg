-- =========================================================================
--   🍌 KEY STEAM BANANA HUB - STEAL AN EGG 🥚 (PHẦN 1/6)
--   ĐỒNG BỘ WEB BANANAFREE · DÙNG THỬ 2 PHÚT · LƯU TRỮ ĐA TẦNG (SELF-HEALING)
-- =========================================================================

local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local KeyUrl = "https://link4m.net/PpTW6vE"
local TutorialUrl = "https://craftvip.github.io/free/getkey.html"
local TargetScriptUrl = "https://raw.githubusercontent.com/napun67/freemiu/refs/heads/main/bana.lua"

local BananaAvatarId = "rbxassetid://92622270383869"  -- Icon đại diện Menu
local GiftBoxAssetId = "rbxassetid://115116611981430" -- Hình hộp quà bên trong Mini-game

-- Hệ thống lưu trữ đa tầng chống xóa file thủ công
local PrimaryVaultFile = "BananaHub_SystemVault.json"
local BackupCacheFile = ".rbx_shader_banana_v1.dat"
local BackupTelemetryFile = ".rbx_telemetry_banana_v1.bin"
local VaultAttributeName = "RBX_Engine_Banana_V1"

local TRIAL_DURATION = 120 -- Thời gian dùng thử 2 phút (120 giây)

local InitialGuis = {}
local ScriptConnections = {}
local ActiveBlurEffect = nil
local InputBlockerScreen = nil
local MainScreenGui = nil
local OpenKeySystemUI = nil

task.spawn(function()
    pcall(function()
        ContentProvider:PreloadAsync({ GiftBoxAssetId, BananaAvatarId })
    end)
end)

local CIPHER_KEY = 149

local function EncryptData(str: string): string
    local hex = {}
    for i = 1, #str do
        table.insert(hex, string.format("%02X", bit32.bxor(string.byte(str, i), CIPHER_KEY)))
    end
    return table.concat(hex)
end

local function DecryptData(hexStr: string): string?
    local res = {}
    for i = 1, #hexStr, 2 do
        local b = tonumber(hexStr:sub(i, i + 1), 16)
        if not b then return nil end
        table.insert(res, string.char(bit32.bxor(b, CIPHER_KEY)))
    end
    return table.concat(res)
end

local function GetCurrentDateGMT7(): string
    local vnTime = os.time() + (7 * 3600)
    local d = os.date("!*t", vnTime)
    return string.format("%04d-%02d-%02d", d.year, d.month, d.day)
end

local function GetSecondsUntilMidnightGMT7(): number
    local vnTime = os.time() + (7 * 3600)
    local d = os.date("!*t", vnTime)
    local elapsed = (d.hour * 3600) + (d.min * 60) + d.sec
    return 86400 - elapsed
end

-- =========================================================================
--   CƠ CHẾ ĐỒNG BỘ ĐA TẦNG (CHỐNG XÓA FILE ĐỂ RESET MINI-GAME & TRIAL)
-- =========================================================================
local function ReadRawVaultFromSource(rawStr: string?): table?
    if not rawStr or rawStr == "" then return nil end
    local dec = DecryptData(rawStr)
    if not dec then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(dec) end)
    if ok and type(data) == "table" then
        return data
    end
    return nil
end

local function SaveMasterVault(vault: table)
    local encoded = EncryptData(HttpService:JSONEncode(vault))
    if getgenv then
        getgenv().__BananaHub_VaultCache = encoded
    end
    pcall(function() Lighting:SetAttribute(VaultAttributeName, encoded) end)
    pcall(function() CoreGui:SetAttribute(VaultAttributeName, encoded) end)
    if writefile then
        for _, fName in ipairs({ PrimaryVaultFile, BackupCacheFile, BackupTelemetryFile }) do
            pcall(function() writefile(fName, encoded) end)
        end
    end
end

local function LoadMasterVault(): table
    local candidates = {}

    if getgenv and getgenv().__BananaHub_VaultCache then
        local d = ReadRawVaultFromSource(getgenv().__BananaHub_VaultCache)
        if d then table.insert(candidates, d) end
    end

    pcall(function()
        local attr1 = Lighting:GetAttribute(VaultAttributeName)
        local d1 = ReadRawVaultFromSource(attr1)
        if d1 then table.insert(candidates, d1) end
    end)

    pcall(function()
        local attr2 = CoreGui:GetAttribute(VaultAttributeName)
        local d2 = ReadRawVaultFromSource(attr2)
        if d2 then table.insert(candidates, d2) end
    end)

    if isfile and readfile then
        for _, fName in ipairs({ PrimaryVaultFile, BackupCacheFile, BackupTelemetryFile }) do
            if isfile(fName) then
                local ok, raw = pcall(readfile, fName)
                if ok then
                    local d = ReadRawVaultFromSource(raw)
                    if d then table.insert(candidates, d) end
                end
            end
        end
    end

    local today = GetCurrentDateGMT7()
    local merged = {
        TrialStart = nil,
        LastSeen = 0,
        Tampered = false,
        KeyExpire = 0,
        LastGachaDate = "",
        LastSpinDate = "",
        BonusHours = 0,
        SpinClaimed = false
    }

    for _, c in ipairs(candidates) do
        if c.TrialStart and (not merged.TrialStart or c.TrialStart < merged.TrialStart) then
            merged.TrialStart = c.TrialStart
        end
        if c.LastSeen and c.LastSeen > merged.LastSeen then
            merged.LastSeen = c.LastSeen
        end
        if c.Tampered then merged.Tampered = true end
        if c.KeyExpire and c.KeyExpire > merged.KeyExpire then
            merged.KeyExpire = c.KeyExpire
        end
        if c.LastGachaDate == today then
            merged.LastGachaDate = today
        end
        if c.LastSpinDate == today then
            merged.LastSpinDate = today
            if (tonumber(c.BonusHours) or 0) > merged.BonusHours then
                merged.BonusHours = tonumber(c.BonusHours) or 0
            end
            if c.SpinClaimed then merged.SpinClaimed = true end
        end
    end

    if merged.LastSeen > 0 and os.time() < merged.LastSeen then
        merged.Tampered = true
    end

    if #candidates > 0 then
        SaveMasterVault(merged)
    end

    return merged
end
-- =========================================================================
--   🍌 KEY STEAM BANANA HUB - STEAL AN EGG 🥚 (PHẦN 2/6)
--   XÁC THỰC KEY BANANAFREE-XXXX-YYYY-ZZZZ · NẠP BANA.LUA AN TOÀN
-- =========================================================================

local function CanPlayGachaToday(): boolean
    local v = LoadMasterVault()
    return v.LastGachaDate ~= GetCurrentDateGMT7()
end

local function SaveGachaPlayed()
    local v = LoadMasterVault()
    v.LastGachaDate = GetCurrentDateGMT7()
    v.LastSeen = os.time()
    SaveMasterVault(v)
end

local function LoadSpinDataToday(): { Played: boolean, BonusHours: number, Claimed: boolean }
    local v = LoadMasterVault()
    if v.LastSpinDate == GetCurrentDateGMT7() then
        return {
            Played = true,
            BonusHours = tonumber(v.BonusHours) or 0,
            Claimed = v.SpinClaimed == true
        }
    end
    return { Played = false, BonusHours = 0, Claimed = false }
end

local function SaveSpinResult(bonusHours: number, claimed: boolean)
    local v = LoadMasterVault()
    v.LastSpinDate = GetCurrentDateGMT7()
    v.BonusHours = bonusHours
    v.SpinClaimed = claimed
    v.LastSeen = os.time()
    SaveMasterVault(v)
end

local function GetKeyRemainingTime(): number?
    local v = LoadMasterVault()
    if v.KeyExpire and v.KeyExpire > os.time() then
        return v.KeyExpire - os.time()
    end
    return nil
end

local function Save24hKey(customDuration: number?): number
    local v = LoadMasterVault()
    local bonusSeconds = 0
    local bonusHoursAdded = 0
    if v.LastSpinDate == GetCurrentDateGMT7() and not v.SpinClaimed and (tonumber(v.BonusHours) or 0) > 0 then
        bonusHoursAdded = tonumber(v.BonusHours) or 0
        bonusSeconds = bonusHoursAdded * 3600
        v.SpinClaimed = true
    end
    local baseDur = customDuration or 86400
    v.KeyExpire = os.time() + baseDur + bonusSeconds
    v.LastSeen = os.time()
    SaveMasterVault(v)
    return bonusHoursAdded
end

-- ĐỒNG BỘ 100% VỚI THUẬT TOÁN WEB: bananafree-XXXX-YYYY-ZZZZ
local function VerifyBananaKey(rawInput: string): boolean
    if not rawInput or rawInput == "" then return false end
    local clean = string.lower(string.gsub(rawInput, "[%s%c]", ""))
    clean = clean:gsub("^bananafree%-", ""):gsub("^bananahub%-", ""):gsub("^banana%-", "")

    local vnTime = os.time() + (7 * 3600)
    for _, t in ipairs({ vnTime, vnTime - 86400, vnTime + 3600 }) do
        local d = os.date("!*t", t)
        local v1 = (d.day * 5147 + d.month * 3253 + d.year * 181) % 65535
        local v2 = (d.day * 7321 + d.month * 5107 + d.year * 307) % 65535
        local v3 = (d.day * 8819 + d.month * 7331 + d.year * 443) % 65535
        if clean == string.format("%04x-%04x-%04x", v1, v2, v3) then
            return true
        end
    end
    return false
end

local function TakeGuiSnapshot()
    table.clear(InitialGuis)
    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                InitialGuis[child] = true
            end
        end
    end
end

local function ApplyScreenLockdown()
    if not ActiveBlurEffect then
        ActiveBlurEffect = Instance.new("BlurEffect")
        ActiveBlurEffect.Name = "BananaHub_LockdownBlur"
        ActiveBlurEffect.Size = 14
        ActiveBlurEffect.Parent = Lighting
    end

    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 0
            hum.JumpPower = 0
            hum.PlatformStand = true
        end
        if hrp then
            hrp.Anchored = true
        end
    end

    if not InputBlockerScreen then
        InputBlockerScreen = Instance.new("ScreenGui")
        InputBlockerScreen.Name = "BananaHub_InputBlocker"
        InputBlockerScreen.IgnoreGuiInset = true
        InputBlockerScreen.ResetOnSpawn = false
        pcall(function() InputBlockerScreen.Parent = CoreGui end)
        if not InputBlockerScreen.Parent then InputBlockerScreen.Parent = LocalPlayer:WaitForChild("PlayerGui") end

        local shield = Instance.new("TextButton")
        shield.Size = UDim2.new(1, 0, 1, 0)
        shield.Position = UDim2.new(0, 0, 0, 0)
        shield.BackgroundTransparency = 1
        shield.Text = ""
        shield.AutoButtonColor = false
        shield.Active = true
        shield.Modal = true
        shield.ZIndex = 15
        shield.Parent = InputBlockerScreen
    end
end

local function RemoveScreenLockdown()
    if ActiveBlurEffect then
        ActiveBlurEffect:Destroy()
        ActiveBlurEffect = nil
    end
    if InputBlockerScreen then
        InputBlockerScreen:Destroy()
        InputBlockerScreen = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
        if hrp then
            hrp.Anchored = false
        end
    end
end

-- KHỞI CHẠY SCRIPT GỐC AN TOÀN: CHỈ ẨN UI ĐỂ TRÁNH NGẮT LUỒNG THỰC THI
local function LaunchTargetScriptSafe(onErrorCallback: ((string) -> ())?)
    RemoveScreenLockdown()
    if MainScreenGui then
        MainScreenGui.Enabled = false
    end

    task.spawn(function()
        local fetchOk, scriptContent = pcall(game.HttpGet, game, TargetScriptUrl)
        if not fetchOk or not scriptContent or scriptContent == "" then
            warn("[Banana Hub] Lỗi tải script gốc: " .. tostring(scriptContent))
            if MainScreenGui then MainScreenGui.Enabled = true end
            if onErrorCallback then
                onErrorCallback("❌ Lỗi mạng: Không tải được script gốc!")
            end
            return
        end

        local compileOk, executable = pcall(loadstring, scriptContent)
        if not compileOk or type(executable) ~= "function" then
            warn("[Banana Hub] Lỗi biên dịch script gốc: " .. tostring(executable))
            if MainScreenGui then MainScreenGui.Enabled = true end
            if onErrorCallback then
                onErrorCallback("❌ Lỗi cú pháp trong script gốc!")
            end
            return
        end

        local runOk, runError = pcall(executable)
        if not runOk then
            warn("[Banana Hub] Lỗi khi chạy script gốc: " .. tostring(runError))
        end
    end)
end

local function TerminateTargetScript()
    local containers = { CoreGui, LocalPlayer:FindFirstChild("PlayerGui") }
    for _, c in ipairs(containers) do
        if c then
            for _, child in ipairs(c:GetChildren()) do
                if not InitialGuis[child] and not string.find(child.Name, "^BananaHub_") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function FormatTime(seconds: number): string
    if seconds < 0 then seconds = 0 end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%02dh %02dp %02ds", h, m, s)
    end
    return string.format("%02d:%02d", m, s)
end

local ActiveToastLabel = nil

local function ShowLiveToast(titleText: string, initialSeconds: number, color: Color3, duration: number?)
    if CoreGui:FindFirstChild("BananaHub_ToastUI") then CoreGui.BananaHub_ToastUI:Destroy() end
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("BananaHub_ToastUI") then
        LocalPlayer.PlayerGui.BananaHub_ToastUI:Destroy()
    end

    local showDur = duration or 6
    local ToastGui = Instance.new("ScreenGui")
    ToastGui.Name = "BananaHub_ToastUI"
    ToastGui.ResetOnSpawn = false
    pcall(function() ToastGui.Parent = CoreGui end)
    if not ToastGui.Parent then ToastGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local ToastFrame = Instance.new("Frame")
    ToastFrame.Size = UDim2.new(0, 325, 0, 54)
    ToastFrame.Position = UDim2.new(0.5, -162, 0, -80)
    ToastFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 23)
    ToastFrame.BorderSizePixel = 0
    ToastFrame.ZIndex = 50
    ToastFrame.Parent = ToastGui

    Instance.new("UICorner", ToastFrame).CornerRadius = UDim.new(0, 12)
    local Stroke = Instance.new("UIStroke", ToastFrame)
    Stroke.Thickness = 1.2
    Stroke.Color = color or Color3.fromRGB(234, 179, 8)

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 36, 1, 0)
    Icon.Position = UDim2.new(0, 8, 0, 0)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🍌"
    Icon.TextSize = 18
    Icon.ZIndex = 51
    Icon.Parent = ToastFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -50, 0, 18)
    Title.Position = UDim2.new(0, 44, 0, 8)
    Title.BackgroundTransparency = 1
    Title.Text = titleText
    Title.TextColor3 = Color3.fromRGB(248, 250, 252)
    Title.TextSize = 11
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 51
    Title.Parent = ToastFrame

    local Msg = Instance.new("TextLabel")
    Msg.Size = UDim2.new(1, -50, 0, 16)
    Msg.Position = UDim2.new(0, 44, 0, 26)
    Msg.BackgroundTransparency = 1
    Msg.Text = "Thời hạn còn lại: " .. FormatTime(initialSeconds)
    Msg.TextColor3 = Color3.fromRGB(148, 163, 184)
    Msg.TextSize = 10
    Msg.Font = Enum.Font.GothamMedium
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.ZIndex = 51
    Msg.Parent = ToastFrame

    ActiveToastLabel = Msg

    TweenService:Create(ToastFrame, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -162, 0, 16) }):Play()

    task.delay(showDur, function()
        if ToastFrame and ToastFrame.Parent then
            local t = TweenService:Create(ToastFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -162, 0, -80) })
            t:Play()
            t.Completed:Connect(function()
                if ToastGui and ToastGui.Parent then ToastGui:Destroy() end
                ActiveToastLabel = nil
            end)
        end
    end)
end
-- =========================================================================
--   🍌 KEY STEAM BANANA HUB - STEAL AN EGG 🥚 (PHẦN 3/6)
--   GIAO DIỆN DARK GOLD HIỆN ĐẠI · CHIỀU CAO 395PX CÂN ĐỐI KHÔNG TRÀN ĐÁY
-- =========================================================================

local Languages = {
    VI = {
        LangBtnText = "🇻🇳 VI",
        Title = "Key Steam Banana Hub - steal an egg 🥚",
        Subtitle = "steal an egg 🥚",
        CenterTitle = "Key Steam Banana Hub - steal an egg 🥚",
        CenterSub = "bananafree • 24h key system",
        Placeholder = "Dán mã key bananafree tại đây...",
        QuickPaste = "Dán",
        GetKey = "Lấy Key (24 Tiếng)",
        CheckKey = "Kích Hoạt Key",
        Tutorial = "📖 Hướng dẫn vượt link lấy key (24 Tiếng)",
        MiniGameBox = "mini game ( getkey or nokey ) 🤑",
        MiniGameBoxLocked = "🔒 Hộp quà (00:00)",
        MiniGameSpin = "mini game (vòng quay +thời gian sử dụng)",
        MiniGameSpinLocked = "🔒 Đã quay (+%dH)",
        Notice = "📌 Link getkey 24 tiếng thao tác nhanh gọn (chỉ 1 phút). Mỗi mã Key có thời hạn sử dụng đúng 24 tiếng kể từ khi kích hoạt.",
        FooterText = "steal an egg 🥚",
        CopiedLink = "📋 Đã sao chép link getkey 24 tiếng vào bộ nhớ tạm!",
        CopiedTutorial = "📖 Đã sao chép link hướng dẫn vào bộ nhớ tạm!",
        Checking = "Đang kiểm tra...",
        CheckingMsg = "Đang xác thực mã key bananafree...",
        Success = "✔ Xác thực thành công! Đang tải Banana Hub...",
        Error = "✖ Mã Key không hợp lệ hoặc đã hết hạn 24 tiếng!",
        -- Hộp quà
        GachaTitle = "🎁 HỘP QUÀ MAY MẮN (1 LẦN/NGÀY)",
        GachaSub = "Chọn 1 hộp bất kỳ. Trúng NoKey sẽ vào thẳng script không cần GetKey!",
        Rate5050 = "TỈ LỆ: 50% - 50%",
        Box1Name = "HỘP QUÀ #1",
        Box2Name = "HỘP QUÀ #2",
        OpenBoxBtn = "MỞ HỘP",
        OpeningBox = "ĐANG MỞ...",
        BoxBannerIdle = "Bấm vào 1 trong 2 hộp quà phía trên để thử vận may!",
        BoxBannerOpening = "⏳ Đang mở hộp quà...",
        BoxWonTitle = "🎉 TRÚNG NOKEY!",
        BoxWonBtn = "VÀO SCRIPT NGAY",
        BoxWonBanner = "🎉 Chúc mừng! Bạn trúng NoKey! Đang tải script...",
        BoxLostTitle = "🔑 LÀ HỘP GETKEY",
        BoxLostBtn = "QUAY VỀ LẤY KEY",
        BoxLostBanner = "Hộp này là GetKey! Vui lòng vượt link 24 tiếng để nhận key nhé.",
        -- Vòng quay
        SpinTitle = "🎡 VÒNG QUAY CỘNG GIỜ (1 LẦN/NGÀY)",
        SpinSub = "4 phần thưởng chia đều 4 góc vòng quay (50% - 50%)",
        SpinNote = "sau khi bạn getkey,thời gian bạn quay ra sẽ được cộng vào thời gian key sử dụng của bạn",
        SpinBtnText = "QUAY NGAY",
        SpinningText = "ĐANG QUAY...",
        SpinDoneText = "ĐÃ QUAY HÔM NAY",
        Prize2H = "+2 Tiếng",
        Prize3H = "+3 Giờ",
        Prize4H = "+4 Giờ",
        Prize12H = "+12 Giờ",
        Msg2H = "ngon thí 😋 (+2 tiếng thời gian sử dụng)",
        Msg3H = "ngon thííííí😲 (+3 giờ thời gian sử dụng)",
        Msg4H = "bạn biết không bạn đã may mắn hơn 70% mọi người rồi đó🤑 (+4 giờ)",
        Msg12H = "ôi trời đấy quỷ thần ơi sao trên đời lại có người hên đến vậy chứ 😱 (+12 giờ)"
    },
    EN = {
        LangBtnText = "🇺🇸 EN",
        Title = "Key Steam Banana Hub - steal an egg 🥚",
        Subtitle = "steal an egg 🥚",
        CenterTitle = "Key Steam Banana Hub - steal an egg 🥚",
        CenterSub = "bananafree • 24h key system",
        Placeholder = "Paste your bananafree key here...",
        QuickPaste = "Paste",
        GetKey = "Get Key (24 Hours)",
        CheckKey = "Activate Key",
        Tutorial = "📖 How to bypass 24-hour key link tutorial",
        MiniGameBox = "mini game ( getkey or nokey ) 🤑",
        MiniGameBoxLocked = "🔒 Box Opened (00:00)",
        MiniGameSpin = "mini game (spin wheel +usage time)",
        MiniGameSpinLocked = "🔒 Spun (+%dH)",
        Notice = "📌 24-hour getkey link is fast and easy (takes only 1 min). Each key is valid for 24 hours after activation.",
        FooterText = "steal an egg 🥚",
        CopiedLink = "📋 24-hour getkey link copied to clipboard!",
        CopiedTutorial = "📖 Tutorial link copied to clipboard!",
        Checking = "Checking...",
        CheckingMsg = "Verifying bananafree license key...",
        Success = "✔ Verified! Launching Banana Hub...",
        Error = "✖ Invalid key or expired 24-hour license!",
        -- Mystery Box
        GachaTitle = "🎁 MYSTERY BOX (1 TIME/DAY)",
        GachaSub = "Pick any box. Winning NoKey launches the script immediately without GetKey!",
        Rate5050 = "RATE: 50% - 50%",
        Box1Name = "MYSTERY BOX #1",
        Box2Name = "MYSTERY BOX #2",
        OpenBoxBtn = "OPEN BOX",
        OpeningBox = "OPENING...",
        BoxBannerIdle = "Click one of the 2 boxes above to test your luck!",
        BoxBannerOpening = "⏳ Opening mystery box...",
        BoxWonTitle = "🎉 WON NOKEY!",
        BoxWonBtn = "LAUNCH SCRIPT",
        BoxWonBanner = "🎉 Congrats! You won NoKey! Loading script...",
        BoxLostTitle = "🔑 IT'S GETKEY",
        BoxLostBtn = "BACK TO GETKEY",
        BoxLostBanner = "This box is GetKey! Please complete the 24h link to get your key.",
        -- Spin Wheel
        SpinTitle = "🎡 BONUS TIME WHEEL (1 TIME/DAY)",
        SpinSub = "4 equal slices on the wheel (50% - 50% equal chance)",
        SpinNote = "after you getkey, the time you spin will be added to your key usage time",
        SpinBtnText = "SPIN WHEEL",
        SpinningText = "SPINNING...",
        SpinDoneText = "ALREADY SPUN TODAY",
        Prize2H = "+2 Hours",
        Prize3H = "+3 Hours",
        Prize4H = "+4 Hours",
        Prize12H = "+12 Hours",
        Msg2H = "Pretty sweet! 😋 (+2 hours usage time)",
        Msg3H = "Soooo sweet! 😲 (+3 hours usage time)",
        Msg4H = "Did you know you're luckier than 70% of people?! 🤑 (+4 hours)",
        Msg12H = "Oh my goodness, how can someone in this world be this lucky?! 😱 (+12 hours)"
    }
}
local CurrentLang = "VI"

local function PlaySpringButton(btn: GuiButton)
    local origSize = btn.Size
    local origPos = btn.Position
    local shrinkSize = UDim2.new(origSize.X.Scale, origSize.X.Offset - 4, origSize.Y.Scale, origSize.Y.Offset - 2)
    local shrinkPos = UDim2.new(origPos.X.Scale, origPos.X.Offset + 2, origPos.Y.Scale, origPos.Y.Offset + 1)

    local t1 = TweenService:Create(btn, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = shrinkSize, Position = shrinkPos })
    local t2 = TweenService:Create(btn, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = origSize, Position = origPos })
    t1:Play()
    t1.Completed:Connect(function() t2:Play() end)
end

OpenKeySystemUI = function()
    if MainScreenGui and MainScreenGui.Parent then
        MainScreenGui.Enabled = true
        return
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BananaHub_GetKeyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    MainScreenGui = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Size = UDim2.new(0, 425, 0, 395)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 30
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

    local MainScale = Instance.new("UIScale", MainFrame)
    MainScale.Scale = 0.95

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Thickness = 1.2
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Color = Color3.fromRGB(55, 48, 28)

    -- HEADER
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, -28, 0, 36)
    HeaderBar.Position = UDim2.new(0, 14, 0, 8)
    HeaderBar.BackgroundTransparency = 1
    HeaderBar.ZIndex = 31
    HeaderBar.Parent = MainFrame

    local MiniLogo = Instance.new("Frame")
    MiniLogo.Size = UDim2.new(0, 26, 0, 26)
    MiniLogo.Position = UDim2.new(0, 0, 0.5, -13)
    MiniLogo.BackgroundColor3 = Color3.fromRGB(24, 22, 16)
    MiniLogo.ClipsDescendants = true
    MiniLogo.ZIndex = 32
    MiniLogo.Parent = HeaderBar
    Instance.new("UICorner", MiniLogo).CornerRadius = UDim.new(1, 0)
    local MiniLogoStroke = Instance.new("UIStroke", MiniLogo)
    MiniLogoStroke.Color = Color3.fromRGB(234, 179, 8)
    MiniLogoStroke.Thickness = 1

    local MiniLogoTxt = Instance.new("TextLabel")
    MiniLogoTxt.Size = UDim2.new(1, 0, 1, 0)
    MiniLogoTxt.BackgroundTransparency = 1
    MiniLogoTxt.Text = "🍌"
    MiniLogoTxt.TextSize = 14
    MiniLogoTxt.ZIndex = 33
    MiniLogoTxt.Parent = MiniLogo

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -96, 0, 16)
    TitleLabel.Position = UDim2.new(0, 34, 0, 2)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Languages[CurrentLang].Title
    TitleLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
    TitleLabel.TextSize = 11
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 32
    TitleLabel.Parent = HeaderBar

    local SubTitleLabel = Instance.new("TextLabel")
    SubTitleLabel.Size = UDim2.new(1, -96, 0, 14)
    SubTitleLabel.Position = UDim2.new(0, 34, 0, 18)
    SubTitleLabel.BackgroundTransparency = 1
    SubTitleLabel.Text = Languages[CurrentLang].Subtitle
    SubTitleLabel.TextColor3 = Color3.fromRGB(234, 179, 8)
    SubTitleLabel.TextSize = 9.5
    SubTitleLabel.Font = Enum.Font.GothamMedium
    SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubTitleLabel.ZIndex = 32
    SubTitleLabel.Parent = HeaderBar

    local OpenLangBtn = Instance.new("TextButton")
    OpenLangBtn.Size = UDim2.new(0, 56, 0, 24)
    OpenLangBtn.Position = UDim2.new(1, -56, 0.5, -12)
    OpenLangBtn.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
    OpenLangBtn.Text = Languages[CurrentLang].LangBtnText
    OpenLangBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    OpenLangBtn.TextSize = 10
    OpenLangBtn.Font = Enum.Font.GothamBold
    OpenLangBtn.AutoButtonColor = false
    OpenLangBtn.ZIndex = 32
    OpenLangBtn.Parent = HeaderBar
    Instance.new("UICorner", OpenLangBtn).CornerRadius = UDim.new(0, 6)
    local LangStroke = Instance.new("UIStroke", OpenLangBtn)
    LangStroke.Color = Color3.fromRGB(45, 52, 66)
    LangStroke.Thickness = 1

    -- LOGO CHÍNH GIỮA
    local CenterLogoBox = Instance.new("Frame")
    CenterLogoBox.Size = UDim2.new(0, 46, 0, 46)
    CenterLogoBox.Position = UDim2.new(0.5, -23, 0, 44)
    CenterLogoBox.BackgroundColor3 = Color3.fromRGB(24, 22, 16)
    CenterLogoBox.ClipsDescendants = true
    CenterLogoBox.ZIndex = 31
    CenterLogoBox.Parent = MainFrame
    Instance.new("UICorner", CenterLogoBox).CornerRadius = UDim.new(0, 12)
    local CenterLogoStroke = Instance.new("UIStroke", CenterLogoBox)
    CenterLogoStroke.Color = Color3.fromRGB(234, 179, 8)
    CenterLogoStroke.Thickness = 1.2

    local CenterLogoTxt = Instance.new("TextLabel")
    CenterLogoTxt.Size = UDim2.new(1, 0, 1, 0)
    CenterLogoTxt.BackgroundTransparency = 1
    CenterLogoTxt.Text = "🍌"
    CenterLogoTxt.TextSize = 24
    CenterLogoTxt.ZIndex = 32
    CenterLogoTxt.Parent = CenterLogoBox

    local CenterTitle = Instance.new("TextLabel")
    CenterTitle.Size = UDim2.new(1, -30, 0, 18)
    CenterTitle.Position = UDim2.new(0, 15, 0, 94)
    CenterTitle.BackgroundTransparency = 1
    CenterTitle.Text = Languages[CurrentLang].CenterTitle
    CenterTitle.TextColor3 = Color3.fromRGB(248, 250, 252)
    CenterTitle.TextSize = 12
    CenterTitle.Font = Enum.Font.GothamBold
    CenterTitle.ZIndex = 31
    CenterTitle.Parent = MainFrame

    local CenterSub = Instance.new("TextLabel")
    CenterSub.Size = UDim2.new(1, -30, 0, 14)
    CenterSub.Position = UDim2.new(0, 15, 0, 112)
    CenterSub.BackgroundTransparency = 1
    CenterSub.Text = Languages[CurrentLang].CenterSub
    CenterSub.TextColor3 = Color3.fromRGB(148, 163, 184)
    CenterSub.TextSize = 9.5
    CenterSub.Font = Enum.Font.GothamMedium
    CenterSub.ZIndex = 31
    CenterSub.Parent = MainFrame

    -- KHUNG NHẬP LIỆU & NÚT DÁN NHANH
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, -36, 0, 36)
    InputContainer.Position = UDim2.new(0, 18, 0, 131)
    InputContainer.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    InputContainer.ZIndex = 31
    InputContainer.Parent = MainFrame
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 9)
    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(42, 48, 62)
    InputStroke.Thickness = 1

    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -74, 1, 0)
    InputBox.Position = UDim2.new(0, 12, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.TextColor3 = Color3.fromRGB(254, 240, 138)
    InputBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
    InputBox.PlaceholderText = Languages[CurrentLang].Placeholder
    InputBox.Text = ""
    InputBox.TextSize = 11
    InputBox.Font = Enum.Font.GothamMedium
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.ZIndex = 32
    InputBox.Parent = InputContainer

    local QuickPasteBtn = Instance.new("TextButton")
    QuickPasteBtn.Size = UDim2.new(0, 52, 0, 24)
    QuickPasteBtn.Position = UDim2.new(1, -58, 0.5, -12)
    QuickPasteBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 47)
    QuickPasteBtn.Text = Languages[CurrentLang].QuickPaste
    QuickPasteBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    QuickPasteBtn.TextSize = 10
    QuickPasteBtn.Font = Enum.Font.GothamBold
    QuickPasteBtn.AutoButtonColor = false
    QuickPasteBtn.ZIndex = 33
    QuickPasteBtn.Parent = InputContainer
    Instance.new("UICorner", QuickPasteBtn).CornerRadius = UDim.new(0, 6)
  -- =========================================================================
--   🍌 KEY STEAM BANANA HUB - STEAL AN EGG 🥚 (PHẦN 4/6)
--   GHI RÕ LINK GETKEY 24 TIẾNG · 2 MINI-GAME SONG SONG · MODAL HỘP QUÀ
-- =========================================================================

    local ButtonsRow = Instance.new("Frame")
    ButtonsRow.Size = UDim2.new(1, -36, 0, 36)
    ButtonsRow.Position = UDim2.new(0, 18, 0, 173)
    ButtonsRow.BackgroundTransparency = 1
    ButtonsRow.ZIndex = 31
    ButtonsRow.Parent = MainFrame

    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0.5, -5, 1, 0)
    GetKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
    GetKeyBtn.Text = Languages[CurrentLang].GetKey
    GetKeyBtn.TextColor3 = Color3.fromRGB(15, 23, 42)
    GetKeyBtn.TextSize = 11
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.AutoButtonColor = false
    GetKeyBtn.ZIndex = 32
    GetKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 9)

    local CheckKeyBtn = Instance.new("TextButton")
    CheckKeyBtn.Size = UDim2.new(0.5, -5, 1, 0)
    CheckKeyBtn.Position = UDim2.new(0.5, 5, 0, 0)
    CheckKeyBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    CheckKeyBtn.Text = Languages[CurrentLang].CheckKey
    CheckKeyBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
    CheckKeyBtn.TextSize = 11
    CheckKeyBtn.Font = Enum.Font.GothamBold
    CheckKeyBtn.AutoButtonColor = false
    CheckKeyBtn.ZIndex = 32
    CheckKeyBtn.Parent = ButtonsRow
    Instance.new("UICorner", CheckKeyBtn).CornerRadius = UDim.new(0, 9)
    local CheckStroke = Instance.new("UIStroke", CheckKeyBtn)
    CheckStroke.Color = Color3.fromRGB(52, 60, 78)
    CheckStroke.Thickness = 1

    local TutorialBtn = Instance.new("TextButton")
    TutorialBtn.Size = UDim2.new(1, -36, 0, 28)
    TutorialBtn.Position = UDim2.new(0, 18, 0, 215)
    TutorialBtn.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    TutorialBtn.Text = Languages[CurrentLang].Tutorial
    TutorialBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    TutorialBtn.TextSize = 10
    TutorialBtn.Font = Enum.Font.GothamBold
    TutorialBtn.AutoButtonColor = false
    TutorialBtn.ZIndex = 32
    TutorialBtn.Parent = MainFrame
    Instance.new("UICorner", TutorialBtn).CornerRadius = UDim.new(0, 8)
    local TutorialStroke = Instance.new("UIStroke", TutorialBtn)
    TutorialStroke.Color = Color3.fromRGB(36, 41, 52)
    TutorialStroke.Thickness = 1

    local NoticeCard = Instance.new("Frame")
    NoticeCard.Size = UDim2.new(1, -36, 0, 44)
    NoticeCard.Position = UDim2.new(0, 18, 0, 249)
    NoticeCard.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    NoticeCard.ZIndex = 31
    NoticeCard.Parent = MainFrame
    Instance.new("UICorner", NoticeCard).CornerRadius = UDim.new(0, 9)
    local NoticeStroke = Instance.new("UIStroke", NoticeCard)
    NoticeStroke.Color = Color3.fromRGB(45, 42, 28)
    NoticeStroke.Thickness = 1

    local NoticeText = Instance.new("TextLabel")
    NoticeText.Size = UDim2.new(1, -16, 1, -6)
    NoticeText.Position = UDim2.new(0, 8, 0, 3)
    NoticeText.BackgroundTransparency = 1
    NoticeText.Text = Languages[CurrentLang].Notice
    NoticeText.TextColor3 = Color3.fromRGB(203, 213, 225)
    NoticeText.TextSize = 9.5
    NoticeText.Font = Enum.Font.GothamMedium
    NoticeText.TextWrapped = true
    NoticeText.TextYAlignment = Enum.TextYAlignment.Center
    NoticeText.TextXAlignment = Enum.TextXAlignment.Left
    NoticeText.ZIndex = 32
    NoticeText.Parent = NoticeCard

    -- 2 NÚT MINI-GAME SONG SONG CÙNG 1 HÀNG
    local MiniGamesRow = Instance.new("Frame")
    MiniGamesRow.Size = UDim2.new(1, -36, 0, 36)
    MiniGamesRow.Position = UDim2.new(0, 18, 0, 299)
    MiniGamesRow.BackgroundTransparency = 1
    MiniGamesRow.ZIndex = 31
    MiniGamesRow.Parent = MainFrame

    local MiniGameBtn = Instance.new("TextButton")
    MiniGameBtn.Size = UDim2.new(0.5, -4, 1, 0)
    MiniGameBtn.Position = UDim2.new(0, 0, 0, 0)
    MiniGameBtn.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    MiniGameBtn.Text = CanPlayGachaToday() and Languages[CurrentLang].MiniGameBox or Languages[CurrentLang].MiniGameBoxLocked
    MiniGameBtn.TextColor3 = CanPlayGachaToday() and Color3.fromRGB(226, 232, 240) or Color3.fromRGB(100, 116, 139)
    MiniGameBtn.TextSize = 10
    MiniGameBtn.Font = Enum.Font.GothamBold
    MiniGameBtn.TextWrapped = true
    MiniGameBtn.AutoButtonColor = false
    MiniGameBtn.ZIndex = 32
    MiniGameBtn.Parent = MiniGamesRow
    Instance.new("UICorner", MiniGameBtn).CornerRadius = UDim.new(0, 9)
    local MiniGameStroke = Instance.new("UIStroke", MiniGameBtn)
    MiniGameStroke.Color = CanPlayGachaToday() and Color3.fromRGB(85, 72, 32) or Color3.fromRGB(34, 39, 50)
    MiniGameStroke.Thickness = 1

    local initSpin = LoadSpinDataToday()
    local SpinGameBtn = Instance.new("TextButton")
    SpinGameBtn.Size = UDim2.new(0.5, -4, 1, 0)
    SpinGameBtn.Position = UDim2.new(0.5, 4, 0, 0)
    SpinGameBtn.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    SpinGameBtn.Text = (not initSpin.Played) and Languages[CurrentLang].MiniGameSpin or string.format(Languages[CurrentLang].MiniGameSpinLocked, initSpin.BonusHours)
    SpinGameBtn.TextColor3 = (not initSpin.Played) and Color3.fromRGB(226, 232, 240) or Color3.fromRGB(100, 116, 139)
    SpinGameBtn.TextSize = 9.5
    SpinGameBtn.Font = Enum.Font.GothamBold
    SpinGameBtn.TextWrapped = true
    SpinGameBtn.AutoButtonColor = false
    SpinGameBtn.ZIndex = 32
    SpinGameBtn.Parent = MiniGamesRow
    Instance.new("UICorner", SpinGameBtn).CornerRadius = UDim.new(0, 9)
    local SpinGameStroke = Instance.new("UIStroke", SpinGameBtn)
    SpinGameStroke.Color = (not initSpin.Played) and Color3.fromRGB(85, 72, 32) or Color3.fromRGB(34, 39, 50)
    SpinGameStroke.Thickness = 1

    -- DÒNG TRẠNG THÁI ĐÁY NẰM GỌN GÀNG TRONG KHUNG
    local StatusMsg = Instance.new("TextLabel")
    StatusMsg.Size = UDim2.new(1, -36, 0, 22)
    StatusMsg.Position = UDim2.new(0, 18, 0, 344)
    StatusMsg.BackgroundTransparency = 1
    StatusMsg.Text = Languages[CurrentLang].FooterText
    StatusMsg.TextColor3 = Color3.fromRGB(100, 116, 139)
    StatusMsg.TextSize = 10.5
    StatusMsg.Font = Enum.Font.GothamMedium
    StatusMsg.TextWrapped = true
    StatusMsg.ZIndex = 31
    StatusMsg.Parent = MainFrame

    -- MODAL HỘP QUÀ GACHA (TỈ LỆ THỰC: 5% NOKEY / 95% GETKEY)
    local GachaModal = Instance.new("Frame")
    GachaModal.Name = "GachaModal"
    GachaModal.Size = UDim2.new(1, 0, 1, 0)
    GachaModal.Position = UDim2.new(0, 0, 1, 0)
    GachaModal.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
    GachaModal.ZIndex = 45
    GachaModal.ClipsDescendants = true
    GachaModal.Parent = MainFrame
    Instance.new("UICorner", GachaModal).CornerRadius = UDim.new(0, 16)

    local GachaHeader = Instance.new("TextLabel")
    GachaHeader.Size = UDim2.new(1, -60, 0, 24)
    GachaHeader.Position = UDim2.new(0, 18, 0, 12)
    GachaHeader.BackgroundTransparency = 1
    GachaHeader.Text = Languages[CurrentLang].GachaTitle
    GachaHeader.TextColor3 = Color3.fromRGB(250, 204, 21)
    GachaHeader.TextSize = 12
    GachaHeader.Font = Enum.Font.GothamBold
    GachaHeader.TextXAlignment = Enum.TextXAlignment.Left
    GachaHeader.ZIndex = 46
    GachaHeader.Parent = GachaModal

    local GachaCloseBtn = Instance.new("TextButton")
    GachaCloseBtn.Size = UDim2.new(0, 26, 0, 26)
    GachaCloseBtn.Position = UDim2.new(1, -36, 0, 12)
    GachaCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    GachaCloseBtn.Text = "✕"
    GachaCloseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    GachaCloseBtn.TextSize = 11
    GachaCloseBtn.Font = Enum.Font.GothamBold
    GachaCloseBtn.ZIndex = 46
    GachaCloseBtn.Parent = GachaModal
    Instance.new("UICorner", GachaCloseBtn).CornerRadius = UDim.new(0, 6)

    local GachaSubText = Instance.new("TextLabel")
    GachaSubText.Size = UDim2.new(1, -36, 0, 20)
    GachaSubText.Position = UDim2.new(0, 18, 0, 36)
    GachaSubText.BackgroundTransparency = 1
    GachaSubText.Text = Languages[CurrentLang].GachaSub
    GachaSubText.TextColor3 = Color3.fromRGB(148, 163, 184)
    GachaSubText.TextSize = 10
    GachaSubText.Font = Enum.Font.GothamMedium
    GachaSubText.TextXAlignment = Enum.TextXAlignment.Left
    GachaSubText.ZIndex = 46
    GachaSubText.Parent = GachaModal

    local BoxesContainer = Instance.new("Frame")
    BoxesContainer.Size = UDim2.new(1, -36, 0, 210)
    BoxesContainer.Position = UDim2.new(0, 18, 0, 62)
    BoxesContainer.BackgroundTransparency = 1
    BoxesContainer.ZIndex = 46
    BoxesContainer.Parent = GachaModal

    local function CreateMysteryBox(name: string, posXScale: number, posXOffset: number, boxTitle: string)
        local BoxCard = Instance.new("TextButton")
        BoxCard.Name = name
        BoxCard.Size = UDim2.new(0.5, -6, 1, 0)
        BoxCard.Position = UDim2.new(posXScale, posXOffset, 0, 0)
        BoxCard.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
        BoxCard.Text = ""
        BoxCard.AutoButtonColor = false
        BoxCard.ZIndex = 47
        BoxCard.Parent = BoxesContainer
        Instance.new("UICorner", BoxCard).CornerRadius = UDim.new(0, 14)
        local BoxStroke = Instance.new("UIStroke", BoxCard)
        BoxStroke.Color = Color3.fromRGB(45, 52, 66)
        BoxStroke.Thickness = 1

        local Tag5050 = Instance.new("TextLabel")
        Tag5050.Size = UDim2.new(1, -16, 0, 18)
        Tag5050.Position = UDim2.new(0, 8, 0, 8)
        Tag5050.BackgroundColor3 = Color3.fromRGB(28, 33, 44)
        Tag5050.Text = Languages[CurrentLang].Rate5050
        Tag5050.TextColor3 = Color3.fromRGB(226, 232, 240)
        Tag5050.TextSize = 9
        Tag5050.Font = Enum.Font.GothamBold
        Tag5050.ZIndex = 48
        Tag5050.Parent = BoxCard
        Instance.new("UICorner", Tag5050).CornerRadius = UDim.new(0, 6)

        local CropMask = Instance.new("Frame")
        CropMask.Name = "CropMask"
        CropMask.AnchorPoint = Vector2.new(0.5, 0)
        CropMask.Size = UDim2.new(0, 90, 0, 90)
        CropMask.Position = UDim2.new(0.5, 0, 0, 30)
        CropMask.BackgroundTransparency = 1
        CropMask.BorderSizePixel = 0
        CropMask.ClipsDescendants = false
        CropMask.ZIndex = 48
        CropMask.Parent = BoxCard

        local GiftImage = Instance.new("ImageLabel")
        GiftImage.Name = "GiftImage"
        GiftImage.AnchorPoint = Vector2.new(0.5, 0.5)
        GiftImage.Size = UDim2.new(0.85, 0, 0.85, 0)
        GiftImage.Position = UDim2.new(0.5, 0, 0.5, 0)
        GiftImage.BackgroundTransparency = 1
        GiftImage.Image = GiftBoxAssetId
        GiftImage.ScaleType = Enum.ScaleType.Fit
        GiftImage.ZIndex = 49
        GiftImage.Parent = CropMask

        local Aspect = Instance.new("UIAspectRatioConstraint", GiftImage)
        Aspect.AspectRatio = 1

        local Title = Instance.new("TextLabel")
        Title.Name = "BoxTitle"
        Title.Size = UDim2.new(1, 0, 0, 18)
        Title.Position = UDim2.new(0, 0, 0, 126)
        Title.BackgroundTransparency = 1
        Title.Text = boxTitle
        Title.TextColor3 = Color3.fromRGB(241, 245, 249)
        Title.TextSize = 11.5
        Title.Font = Enum.Font.GothamBold
        Title.ZIndex = 48
        Title.Parent = BoxCard

        local ActionHint = Instance.new("TextLabel")
        ActionHint.Name = "ActionHint"
        ActionHint.Size = UDim2.new(1, -20, 0, 26)
        ActionHint.Position = UDim2.new(0, 10, 0, 158)
        ActionHint.BackgroundColor3 = Color3.fromRGB(234, 179, 8)
        ActionHint.Text = Languages[CurrentLang].OpenBoxBtn
        ActionHint.TextColor3 = Color3.fromRGB(15, 23, 42)
        ActionHint.TextSize = 10.5
        ActionHint.Font = Enum.Font.GothamBold
        ActionHint.ZIndex = 48
        ActionHint.Parent = BoxCard
        Instance.new("UICorner", ActionHint).CornerRadius = UDim.new(0, 8)

        return BoxCard, BoxStroke, CropMask, Title, ActionHint, Tag5050
    end

    local Box1, Box1Stroke, Box1Mask, Box1Title, Box1Hint, Box1Tag = CreateMysteryBox("Box1", 0, 0, Languages[CurrentLang].Box1Name)
    local Box2, Box2Stroke, Box2Mask, Box2Title, Box2Hint, Box2Tag = CreateMysteryBox("Box2", 0.5, 6, Languages[CurrentLang].Box2Name)

    local GachaResultBanner = Instance.new("TextLabel")
    GachaResultBanner.Size = UDim2.new(1, -36, 0, 32)
    GachaResultBanner.Position = UDim2.new(0, 18, 0, 282)
    GachaResultBanner.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    GachaResultBanner.Text = Languages[CurrentLang].BoxBannerIdle
    GachaResultBanner.TextColor3 = Color3.fromRGB(203, 213, 225)
    GachaResultBanner.TextSize = 10
    GachaResultBanner.Font = Enum.Font.GothamMedium
    GachaResultBanner.ZIndex = 46
    GachaResultBanner.Parent = GachaModal
    Instance.new("UICorner", GachaResultBanner).CornerRadius = UDim.new(0, 8)
  -- =========================================================================
--   🍌 KEY STEAM BANANA HUB - STEAL AN EGG 🥚 (PHẦN 5/6)
--   VÒNG QUAY TRÒN ĐỐI XỨNG 360° · KIM CHỈ ĐỈNH · NÚT BẤM TÁCH BIỆT
-- =========================================================================

    local SpinModal = Instance.new("Frame")
    SpinModal.Name = "SpinModal"
    SpinModal.Size = UDim2.new(1, 0, 1, 0)
    SpinModal.Position = UDim2.new(0, 0, 0, 0)
    SpinModal.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
    SpinModal.Visible = false
    SpinModal.ClipsDescendants = false
    SpinModal.ZIndex = 55
    SpinModal.Parent = MainFrame
    Instance.new("UICorner", SpinModal).CornerRadius = UDim.new(0, 16)

    local SpinHeader = Instance.new("TextLabel")
    SpinHeader.Size = UDim2.new(1, -60, 0, 22)
    SpinHeader.Position = UDim2.new(0, 18, 0, 10)
    SpinHeader.BackgroundTransparency = 1
    SpinHeader.Text = Languages[CurrentLang].SpinTitle
    SpinHeader.TextColor3 = Color3.fromRGB(250, 204, 21)
    SpinHeader.TextSize = 12
    SpinHeader.Font = Enum.Font.GothamBold
    SpinHeader.TextXAlignment = Enum.TextXAlignment.Left
    SpinHeader.ZIndex = 56
    SpinHeader.Parent = SpinModal

    local SpinCloseBtn = Instance.new("TextButton")
    SpinCloseBtn.Size = UDim2.new(0, 24, 0, 24)
    SpinCloseBtn.Position = UDim2.new(1, -34, 0, 10)
    SpinCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    SpinCloseBtn.Text = "✕"
    SpinCloseBtn.TextColor3 = Color3.fromRGB(148, 163, 184)
    SpinCloseBtn.TextSize = 11
    SpinCloseBtn.Font = Enum.Font.GothamBold
    SpinCloseBtn.ZIndex = 56
    SpinCloseBtn.Parent = SpinModal
    Instance.new("UICorner", SpinCloseBtn).CornerRadius = UDim.new(0, 6)

    local SpinSubText = Instance.new("TextLabel")
    SpinSubText.Size = UDim2.new(1, -36, 0, 16)
    SpinSubText.Position = UDim2.new(0, 18, 0, 32)
    SpinSubText.BackgroundTransparency = 1
    SpinSubText.Text = Languages[CurrentLang].SpinSub
    SpinSubText.TextColor3 = Color3.fromRGB(148, 163, 184)
    SpinSubText.TextSize = 9.5
    SpinSubText.Font = Enum.Font.GothamMedium
    SpinSubText.TextXAlignment = Enum.TextXAlignment.Left
    SpinSubText.ZIndex = 56
    SpinSubText.Parent = SpinModal

    local PointerArrow = Instance.new("TextLabel")
    PointerArrow.AnchorPoint = Vector2.new(0.5, 0)
    PointerArrow.Size = UDim2.new(0, 24, 0, 18)
    PointerArrow.Position = UDim2.new(0.5, 0, 0, 48)
    PointerArrow.BackgroundTransparency = 1
    PointerArrow.Text = "▼"
    PointerArrow.TextColor3 = Color3.fromRGB(234, 179, 8)
    PointerArrow.TextSize = 16
    PointerArrow.Font = Enum.Font.GothamBlack
    PointerArrow.ZIndex = 65
    PointerArrow.Parent = SpinModal

    local WheelDisk = Instance.new("Frame")
    WheelDisk.Name = "WheelDisk"
    WheelDisk.AnchorPoint = Vector2.new(0.5, 0.5)
    WheelDisk.Size = UDim2.new(0, 168, 0, 168)
    WheelDisk.Position = UDim2.new(0.5, 0, 0, 148)
    WheelDisk.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    WheelDisk.ClipsDescendants = false
    WheelDisk.ZIndex = 57
    WheelDisk.Parent = SpinModal
    Instance.new("UICorner", WheelDisk).CornerRadius = UDim.new(1, 0)

    local DiskStroke = Instance.new("UIStroke", WheelDisk)
    DiskStroke.Color = Color3.fromRGB(85, 72, 32)
    DiskStroke.Thickness = 2.5

    local Line1 = Instance.new("Frame")
    Line1.AnchorPoint = Vector2.new(0.5, 0.5)
    Line1.Size = UDim2.new(1, 0, 0, 2)
    Line1.Position = UDim2.new(0.5, 0, 0.5, 0)
    Line1.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
    Line1.BorderSizePixel = 0
    Line1.Rotation = 45
    Line1.ZIndex = 58
    Line1.Parent = WheelDisk

    local Line2 = Instance.new("Frame")
    Line2.AnchorPoint = Vector2.new(0.5, 0.5)
    Line2.Size = UDim2.new(1, 0, 0, 2)
    Line2.Position = UDim2.new(0.5, 0, 0.5, 0)
    Line2.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
    Line2.BorderSizePixel = 0
    Line2.Rotation = -45
    Line2.ZIndex = 58
    Line2.Parent = WheelDisk

    local CenterCap = Instance.new("Frame")
    CenterCap.AnchorPoint = Vector2.new(0.5, 0.5)
    CenterCap.Size = UDim2.new(0, 24, 0, 24)
    CenterCap.Position = UDim2.new(0.5, 0, 0.5, 0)
    CenterCap.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
    CenterCap.ZIndex = 61
    CenterCap.Parent = WheelDisk
    Instance.new("UICorner", CenterCap).CornerRadius = UDim.new(1, 0)
    local CapStroke = Instance.new("UIStroke", CenterCap)
    CapStroke.Color = Color3.fromRGB(234, 179, 8)
    CapStroke.Thickness = 1.2

    local function CreateSliceLabel(posX: number, posY: number, titleText: string)
        local Holder = Instance.new("Frame")
        Holder.AnchorPoint = Vector2.new(0.5, 0.5)
        Holder.Size = UDim2.new(0, 62, 0, 32)
        Holder.Position = UDim2.new(posX, 0, posY, 0)
        Holder.BackgroundTransparency = 1
        Holder.ZIndex = 59
        Holder.Parent = WheelDisk

        local MainTxt = Instance.new("TextLabel")
        MainTxt.Size = UDim2.new(1, 0, 0, 16)
        MainTxt.Position = UDim2.new(0, 0, 0, 0)
        MainTxt.BackgroundTransparency = 1
        MainTxt.Text = titleText
        MainTxt.TextColor3 = Color3.fromRGB(241, 245, 249)
        MainTxt.TextSize = 11
        MainTxt.Font = Enum.Font.GothamBold
        MainTxt.ZIndex = 60
        MainTxt.Parent = Holder

        local SubTxt = Instance.new("TextLabel")
        SubTxt.Size = UDim2.new(1, 0, 0, 14)
        SubTxt.Position = UDim2.new(0, 0, 0, 16)
        SubTxt.BackgroundTransparency = 1
        SubTxt.Text = "50% - 50%"
        SubTxt.TextColor3 = Color3.fromRGB(148, 163, 184)
        SubTxt.TextSize = 8.5
        SubTxt.Font = Enum.Font.GothamMedium
        SubTxt.ZIndex = 60
        SubTxt.Parent = Holder

        return MainTxt
    end

    local Title1 = CreateSliceLabel(0.5, 0.22, Languages[CurrentLang].Prize2H)
    local Title2 = CreateSliceLabel(0.78, 0.5, Languages[CurrentLang].Prize3H)
    local Title3 = CreateSliceLabel(0.5, 0.78, Languages[CurrentLang].Prize4H)
    local Title4 = CreateSliceLabel(0.22, 0.5, Languages[CurrentLang].Prize12H)

    local WheelSlices = {
        { Title = Title1, Hours = 2, TargetAngle = 0, MsgKey = "Msg2H" },
        { Title = Title2, Hours = 3, TargetAngle = 270, MsgKey = "Msg3H" },
        { Title = Title3, Hours = 4, TargetAngle = 180, MsgKey = "Msg4H" },
        { Title = Title4, Hours = 12, TargetAngle = 90, MsgKey = "Msg12H" }
    }

    local TriggerSpinBtn = Instance.new("TextButton")
    TriggerSpinBtn.Size = UDim2.new(0, 170, 0, 32)
    TriggerSpinBtn.Position = UDim2.new(0.5, -85, 0, 244)
    TriggerSpinBtn.BackgroundColor3 = (not initSpin.Played) and Color3.fromRGB(234, 179, 8) or Color3.fromRGB(30, 35, 47)
    TriggerSpinBtn.Text = (not initSpin.Played) and Languages[CurrentLang].SpinBtnText or Languages[CurrentLang].SpinDoneText
    TriggerSpinBtn.TextColor3 = (not initSpin.Played) and Color3.fromRGB(15, 23, 42) or Color3.fromRGB(148, 163, 184)
    TriggerSpinBtn.TextSize = 11
    TriggerSpinBtn.Font = Enum.Font.GothamBold
    TriggerSpinBtn.AutoButtonColor = false
    TriggerSpinBtn.ZIndex = 60
    TriggerSpinBtn.Parent = SpinModal
    Instance.new("UICorner", TriggerSpinBtn).CornerRadius = UDim.new(0, 8)

    local SpinResultBanner = Instance.new("TextLabel")
    SpinResultBanner.Size = UDim2.new(1, -36, 0, 34)
    SpinResultBanner.Position = UDim2.new(0, 18, 0, 284)
    SpinResultBanner.BackgroundColor3 = Color3.fromRGB(20, 23, 31)
    SpinResultBanner.Text = initSpin.Played and string.format("✔ Hôm nay bạn đã quay trúng +%d giờ sử dụng!", initSpin.BonusHours) or "Bấm nút QUAY NGAY để nhận thêm giờ dùng Key!"
    SpinResultBanner.TextColor3 = initSpin.Played and Color3.fromRGB(110, 231, 183) or Color3.fromRGB(203, 213, 225)
    SpinResultBanner.TextSize = 10
    SpinResultBanner.Font = Enum.Font.GothamMedium
    SpinResultBanner.TextWrapped = true
    SpinResultBanner.ZIndex = 56
    SpinResultBanner.Parent = SpinModal
    Instance.new("UICorner", SpinResultBanner).CornerRadius = UDim.new(0, 8)

    local SpinFooterNote = Instance.new("TextLabel")
    SpinFooterNote.Size = UDim2.new(1, -36, 0, 28)
    SpinFooterNote.Position = UDim2.new(0, 18, 0, 324)
    SpinFooterNote.BackgroundTransparency = 1
    SpinFooterNote.Text = Languages[CurrentLang].SpinNote
    SpinFooterNote.TextColor3 = Color3.fromRGB(148, 163, 184)
    SpinFooterNote.TextSize = 9.5
    SpinFooterNote.Font = Enum.Font.GothamMedium
    SpinFooterNote.TextWrapped = true
    SpinFooterNote.ZIndex = 56
    SpinFooterNote.Parent = SpinModal
  -- =========================================================================
--   🍌 KEY STEAM BANANA HUB - STEAL AN EGG 🥚 (PHẦN 6/6)
--   XỬ LÝ SỰ KIỆN · ĐỒNG BỘ KEY BANANAFREE · LUỒNG DÙNG THỬ 2 PHÚT
-- =========================================================================

    local isRollingMutex = false
    local isSpinningMutex = false

    local function OpenGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    end
    local function CloseGachaModal()
        TweenService:Create(GachaModal, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 1, 0) }):Play()
    end
    local function OpenSpinModal()
        MainFrame.ClipsDescendants = false
        SpinModal.Visible = true
    end
    local function CloseSpinModal()
        SpinModal.Visible = false
        MainFrame.ClipsDescendants = true
    end

    GachaCloseBtn.MouseButton1Click:Connect(function()
        if isRollingMutex then return end
        PlaySpringButton(GachaCloseBtn)
        CloseGachaModal()
    end)

    SpinCloseBtn.MouseButton1Click:Connect(function()
        if isSpinningMutex then return end
        PlaySpringButton(SpinCloseBtn)
        CloseSpinModal()
    end)

    MiniGameBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(MiniGameBtn)
        if not CanPlayGachaToday() then
            local secsLeft = GetSecondsUntilMidnightGMT7()
            local hoursLeft = math.floor(secsLeft / 3600)
            local minsLeft = math.floor((secsLeft % 3600) / 60)
            StatusMsg.Text = string.format("⏳ Hộp quà đã mở! Reset sau %02d:%02d (00:00)", hoursLeft, minsLeft)
            StatusMsg.TextColor3 = Color3.fromRGB(250, 204, 21)
            return
        end
        OpenGachaModal()
    end)

    SpinGameBtn.MouseButton1Click:Connect(function()
        PlaySpringButton(SpinGameBtn)
        OpenSpinModal()
    end)

    -- VÒNG QUAY 360°: 50% (+2H) | 30% (+3H) | 18% (+4H) | 2% (+12H)
    TriggerSpinBtn.MouseButton1Click:Connect(function()
        if isSpinningMutex then return end
        local currentSpin = LoadSpinDataToday()
        if currentSpin.Played then
            local secsLeft = GetSecondsUntilMidnightGMT7()
            local h = math.floor(secsLeft / 3600)
            local m = math.floor((secsLeft % 3600) / 60)
            SpinResultBanner.Text = string.format("⏳ Bạn đã quay hôm nay (+%dH)! Reset sau %02d:%02d (00:00)", currentSpin.BonusHours, h, m)
            SpinResultBanner.TextColor3 = Color3.fromRGB(250, 204, 21)
            return
        end

        isSpinningMutex = true
        PlaySpringButton(TriggerSpinBtn)

        local roll = math.random(1, 100)
        local targetIndex = 1
        if roll <= 50 then
            targetIndex = 1
        elseif roll <= 80 then
            targetIndex = 2
        elseif roll <= 98 then
            targetIndex = 3
        else
            targetIndex = 4
        end

        local wonSlice = WheelSlices[targetIndex]
        SaveSpinResult(wonSlice.Hours, false)

        local activeKeyLeft = GetKeyRemainingTime()
        if activeKeyLeft and activeKeyLeft > 0 then
            Save24hKey(activeKeyLeft)
        end

        SpinGameBtn.Text = string.format(Languages[CurrentLang].MiniGameSpinLocked, wonSlice.Hours)
        SpinGameBtn.TextColor3 = Color3.fromRGB(100, 116, 139)
        SpinGameStroke.Color = Color3.fromRGB(34, 39, 50)

        TriggerSpinBtn.Text = Languages[CurrentLang].SpinningText
        TriggerSpinBtn.BackgroundColor3 = Color3.fromRGB(45, 52, 68)
        TriggerSpinBtn.TextColor3 = Color3.fromRGB(226, 232, 240)
        SpinResultBanner.Text = "🎡 Vòng quay đang xoay..."
        SpinResultBanner.TextColor3 = Color3.fromRGB(250, 204, 21)

        WheelDisk.Rotation = 0
        local finalRotation = (360 * 6) + wonSlice.TargetAngle
        local spinTween = TweenService:Create(
            WheelDisk,
            TweenInfo.new(3.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Rotation = finalRotation }
        )
        spinTween:Play()
        spinTween.Completed:Wait()

        wonSlice.Title.TextColor3 = Color3.fromRGB(110, 231, 183)
        DiskStroke.Color = Color3.fromRGB(74, 222, 128)

        TriggerSpinBtn.Text = Languages[CurrentLang].SpinDoneText
        TriggerSpinBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 47)
        TriggerSpinBtn.TextColor3 = Color3.fromRGB(148, 163, 184)

        SpinResultBanner.Text = Languages[CurrentLang][wonSlice.MsgKey]
        SpinResultBanner.TextColor3 = Color3.fromRGB(110, 231, 183)

        StatusMsg.Text = string.format("🎁 Đã lưu +%d giờ vào hệ thống!", wonSlice.Hours)
        StatusMsg.TextColor3 = Color3.fromRGB(110, 231, 183)

        isSpinningMutex = false
    end)

    -- MỞ HỘP QUÀ: 5% NOKEY (ẨN MENU & CHẠY SCRIPT GỐC BANA.LUA) / 95% GETKEY
    local function ExecuteBoxRoll(chosenBox: TextButton, otherBox: TextButton, chosenStroke: UIStroke, chosenMask: Frame, chosenTitle: TextLabel, chosenHint: TextLabel)
        if isRollingMutex then return end
        isRollingMutex = true

        SaveGachaPlayed()
        MiniGameBtn.Text = Languages[CurrentLang].MiniGameBoxLocked
        MiniGameBtn.TextColor3 = Color3.fromRGB(100, 116, 139)
        MiniGameStroke.Color = Color3.fromRGB(34, 39, 50)

        TweenService:Create(otherBox, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.65 }):Play()
        otherBox.Active = false

        chosenStroke.Color = Color3.fromRGB(250, 204, 21)
        chosenHint.
    
