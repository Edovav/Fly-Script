-- 科幻全息风全平台飞行控制脚本 (Roblox Studio / Delta通用)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local speed = 75 -- 默认科幻速度
local minSpeed = 10
local maxSpeed = 300

local keys = {W = false, S = false, A = false, D = false, E = false, Q = false}
local bv, bg

-- 获取移动端摇杆控制器
local playerScripts = player:WaitForChild("PlayerScripts")
local success, playerModule = pcall(function()
    return require(playerScripts:WaitForChild("PlayerModule"))
end)
local controls = success and playerModule:GetControls() or nil

--------------------------------------------------------------------
-- 1. 创建科幻全息 UI 面板
--------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SciFiFlyGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- 主面板外框 (科幻黑蓝透底)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 260)
mainFrame.Position = UDim2.new(0.5, -210, 0.35, -130)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- 科幻边框发光线
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 180, 255)
stroke.Thickness = 2
stroke.Parent = mainFrame

-- 顶部标题栏
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🚁  ADVANCED FLIGHT CONTROL"
titleLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- 状态指示灯区域
local statusIndicator = Instance.new("Frame")
statusIndicator.Size = UDim2.new(0, 12, 0, 12)
statusIndicator.Position = UDim2.new(0.28, 0, 0.22, 0)
statusIndicator.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
statusIndicator.Parent = mainFrame
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(1, 0)
statusCorner.Parent = statusIndicator

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 200, 0, 25)
statusLabel.Position = UDim2.new(0.32, 0, 0.17, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "STATUS: OFFLINE [F]"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.GothamSemibold
statusLabel.Parent = mainFrame

-- 速度显示区块
local speedTextLabel = Instance.new("TextLabel")
speedTextLabel.Size = UDim2.new(1, 0, 0, 20)
speedTextLabel.Position = UDim2.new(0, 0, 0.38, 0)
speedTextLabel.BackgroundTransparency = 1
speedTextLabel.Text = "FLIGHT VELOCITY"
speedTextLabel.TextColor3 = Color3.fromRGB(140, 160, 200)
speedTextLabel.TextSize = 11
speedTextLabel.Font = Enum.Font.Gotham
speedTextLabel.Parent = mainFrame

-- 减速按钮 (<)
local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 45, 0, 35)
minusBtn.Position = UDim2.new(0.08, 0, 0.48, 0)
minusBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 35)
minusBtn.Text = "◀"
minusBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
minusBtn.TextSize = 16
minusBtn.Font = Enum.Font.GothamBold
minusBtn.Parent = mainFrame
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 6)

-- 加速按钮 (>)
local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 45, 0, 35)
plusBtn.Position = UDim2.new(0.81, 0, 0.48, 0)
plusBtn.BackgroundColor3 = Color3.fromRGB(25, 45, 35)
plusBtn.Text = "▶"
plusBtn.TextColor3 = Color3.fromRGB(80, 255, 120)
plusBtn.TextSize = 16
plusBtn.Font = Enum.Font.GothamBold
plusBtn.Parent = mainFrame
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 6)

-- 中间速度数字框
local speedBoxBg = Instance.new("Frame")
speedBoxBg.Size = UDim2.new(0, 80, 0, 35)
speedBoxBg.Position = UDim2.new(0.5, -40, 0.48, 0)
speedBoxBg.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
speedBoxBg.Parent = mainFrame
Instance.new("UICorner", speedBoxBg).CornerRadius = UDim.new(0, 6)
local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(0, 150, 255)
boxStroke.Parent = speedBoxBg

local speedNumLabel = Instance.new("TextLabel")
speedNumLabel.Size = UDim2.new(1, 0, 1, 0)
speedNumLabel.BackgroundTransparency = 1
speedNumLabel.Text = tostring(speed)
speedNumLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedNumLabel.TextSize = 18
speedNumLabel.Font = Enum.Font.GothamBold
speedNumLabel.Parent = speedBoxBg

--------------------------------------------------------------------
-- 2. 垂直升降控制按钮 (UP / DOWN)
--------------------------------------------------------------------
local function createSciFiButton(name, text, posX, keyName)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 175, 0, 45)
    btn.Position = UDim2.new(posX, 0, 0.70, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 220, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.Parent = mainFrame
    
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(0, 120, 200)
    btnStroke.Parent = btn
    
    btn.MouseButton1Down:Connect(function()
        keys[keyName] = true
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    btn.MouseButton1Up:Connect(function()
        keys[keyName] = false
        btn.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
        btn.TextColor3 = Color3.fromRGB(200, 220, 255)
    end)
    btn.MouseLeave:Connect(function()
        keys[keyName] = false
        btn.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
        btn.TextColor3 = Color3.fromRGB(200, 220, 255)
    end)
    return btn
end

createSciFiButton("UpBtn", "▲  UP [E]", 0.08, "E")
createSciFiButton("DownBtn", "▼  DOWN [Q]", 0.53, "Q")

--------------------------------------------------------------------
-- 3. 核心飞行逻辑与事件绑定
--------------------------------------------------------------------
local function updateSpeedUI()
    speed = math.clamp(speed, minSpeed, maxSpeed)
    speedNumLabel.Text = tostring(math.floor(speed))
end

local function toggleFly()
    flying = not flying
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if flying then
        statusLabel.Text = "STATUS: ACTIVE [F]"
        statusIndicator.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
        stroke.Color = Color3.fromRGB(50, 255, 100)
        if humanoid then humanoid.PlatformStand = true end
        
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp
        
        bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
    else
        statusLabel.Text = "STATUS: OFFLINE [F]"
        statusIndicator.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
        stroke.Color = Color3.fromRGB(0, 180, 255)
        if humanoid then humanoid.PlatformStand = false end
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
end

minusBtn.MouseButton1Click:Connect(function()
    speed = speed - 15
    updateSpeedUI()
end)

plusBtn.MouseButton1Click:Connect(function()
    speed = speed + 15
    updateSpeedUI()
end)

-- 键盘监听
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then toggleFly() end
    if input.KeyCode == Enum.KeyCode.W then keys.W = true end
    if input.KeyCode == Enum.KeyCode.S then keys.S = true end
    if input.KeyCode == Enum.KeyCode.A then keys.A = true end
    if input.KeyCode == Enum.KeyCode.D then keys.D = true end
    if input.KeyCode == Enum.KeyCode.E then keys.E = true end
    if input.KeyCode == Enum.KeyCode.Q then keys.Q = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then keys.W = false end
    if input.KeyCode == Enum.KeyCode.S then keys.S = false end
    if input.KeyCode == Enum.KeyCode.A then keys.A = false end
    if input.KeyCode == Enum.KeyCode.D then keys.D = false end
    if input.KeyCode == Enum.KeyCode.E then keys.E = false end
    if input.KeyCode == Enum.KeyCode.Q then keys.Q = false end
end)

-- 渲染步更新：集成手机摇杆与键盘
RunService.RenderStepped:Connect(function()
    if not flying then return end
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    if bv and bg then
        bg.CFrame = camera.CFrame
        local moveDir = Vector3.new()
        
        -- 移动端摇杆输入
        if controls then
            local rawMove = controls:GetMoveVector()
            if rawMove.Magnitude > 0 then
                moveDir = (camera.CFrame.RightVector * rawMove.X) - (camera.CFrame.LookVector * rawMove.Z)
            end
        end
        
        -- 键盘 WASD 输入
        if keys.W then moveDir = moveDir + camera.CFrame.LookVector end
        if keys.S then moveDir = moveDir - camera.CFrame.LookVector end
        if keys.A then moveDir = moveDir - camera.CFrame.RightVector end
        if keys.D then moveDir = moveDir + camera.CFrame.RightVector end
        
        -- 垂直升降
        if keys.E then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if keys.Q then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        bv.Velocity = moveDir * speed
    end
end)
