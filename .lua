local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local flying = false
local speed = 50
local minSpeed = 10
local maxSpeed = 300

local keys = {W = false, S = false, A = false, D = false, E = false, Q = false}
local bv, bg

-- 获取 Roblox 移动端默认控制器 (ControlModule)
local playerScripts = player:WaitForChild("PlayerScripts")
local success, playerModule = pcall(function()
    return require(playerScripts:WaitForChild("PlayerModule"))
end)
local controls = success and playerModule:GetControls() or nil

--------------------------------------------------------------------
-- 1. 创建 UI 面板
--------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlyControlGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 210)
mainFrame.Position = UDim2.new(0, 20, 0.35, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

-- 标题
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🚁 Roblox Fly"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

-- 开关按钮
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.05, 0, 0.16, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
toggleBtn.Text = "飞行状态: 关闭"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Parent = mainFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtn

-- 速度文本显示
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 25)
speedLabel.Position = UDim2.new(0, 0, 0.35, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "飞行速度: " .. tostring(speed)
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextSize = 13
speedLabel.Font = Enum.Font.SourceSans
speedLabel.Parent = mainFrame

-- 减速按钮 (-)
local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 30, 0, 25)
minusBtn.Position = UDim2.new(0.05, 0, 0.47, 0)
minusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
minusBtn.Text = "-"
minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minusBtn.TextSize = 16
minusBtn.Font = Enum.Font.SourceSansBold
minusBtn.Parent = mainFrame

local minusCorner = Instance.new("UICorner")
minusCorner.CornerRadius = UDim.new(0, 4)
minusCorner.Parent = minusBtn

-- 加速按钮 (+)
local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 30, 0, 25)
plusBtn.Position = UDim2.new(0.81, 0, 0.47, 0)
plusBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
plusBtn.Text = "+"
plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plusBtn.TextSize = 16
plusBtn.Font = Enum.Font.SourceSansBold
plusBtn.Parent = mainFrame

local plusCorner = Instance.new("UICorner")
plusCorner.CornerRadius = UDim.new(0, 4)
plusCorner.Parent = plusBtn

-- 速度滑动条背景
local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(0.56, 0, 0, 8)
sliderBg.Position = UDim2.new(0.22, 0, 0.52, 0)
sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
sliderBg.BorderSizePixel = 0
sliderBg.Parent = mainFrame

local sliderBgCorner = Instance.new("UICorner")
sliderBgCorner.CornerRadius = UDim.new(0, 4)
sliderBgCorner.Parent = sliderBg

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new((speed - minSpeed) / (maxSpeed - minSpeed), 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg

local sliderFillCorner = Instance.new("UICorner")
sliderFillCorner.CornerRadius = UDim.new(0, 4)
sliderFillCorner.Parent = sliderFill

--------------------------------------------------------------------
-- 2. 移动端垂直升降触控按钮 (上升 / 下降)
--------------------------------------------------------------------
local function createVerticalButton(name, text, pos, keyName)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.42, 0, 0, 35)
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = mainFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    btn.MouseButton1Down:Connect(function()
        keys[keyName] = true
        btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    end)
    btn.MouseButton1Up:Connect(function()
        keys[keyName] = false
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    end)
    btn.MouseLeave:Connect(function()
        keys[keyName] = false
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    end)
    
    return btn
end

createVerticalButton("UpBtn", "⬆", UDim2.new(0.05, 0, 0.63, 0), "E")
createVerticalButton("DownBtn", "⬇", UDim2.new(0.53, 0, 0.63, 0), "Q")

--------------------------------------------------------------------
-- 3. 核心逻辑与事件绑定
--------------------------------------------------------------------
local function updateSpeedUI()
    speed = math.clamp(speed, minSpeed, maxSpeed)
    speedLabel.Text = "飞行速度: " .. tostring(math.floor(speed))
    sliderFill.Size = UDim2.new((speed - minSpeed) / (maxSpeed - minSpeed), 0, 1, 0)
end

local function toggleFly()
    flying = not flying
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if flying then
        toggleBtn.Text = "飞行状态: 开启"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
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
        toggleBtn.Text = "飞行状态: 关闭"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        if humanoid then humanoid.PlatformStand = false end
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
    end
end

toggleBtn.MouseButton1Click:Connect(toggleFly)

minusBtn.MouseButton1Click:Connect(function()
    speed = speed - 10
    updateSpeedUI()
end)

plusBtn.MouseButton1Click:Connect(function()
    speed = speed + 10
    updateSpeedUI()
end)

-- 滑动条拖动支持
local draggingSlider = false
sliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local mousePos = UserInputService:GetMouseLocation().X
        local sliderAbsPos = sliderBg.AbsolutePosition.X
        local sliderWidth = sliderBg.AbsoluteSize.X
        
        local percent = math.clamp((mousePos - sliderAbsPos) / sliderWidth, 0, 1)
        speed = minSpeed + percent * (maxSpeed - minSpeed)
        updateSpeedUI()
    end
end)

-- 键盘快捷键支持 (电脑端)
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

-- 每帧渲染更新位移
RunService.RenderStepped:Connect(function()
    if not flying then return end
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    if bv and bg then
        bg.CFrame = camera.CFrame
        local moveDir = Vector3.new()
        
        -- 1. 移动端原生摇杆方向
        if controls then
            local rawMove = controls:GetMoveVector()
            if rawMove.Magnitude > 0 then
                moveDir = (camera.CFrame.RightVector * rawMove.X) - (camera.CFrame.LookVector * rawMove.Z)
            end
        end
        
        -- 2. 键盘控制叠加 (PC端 WASD)
        if keys.W then moveDir = moveDir + camera.CFrame.LookVector end
        if keys.S then moveDir = moveDir - camera.CFrame.LookVector end
        if keys.A then moveDir = moveDir - camera.CFrame.RightVector end
        if keys.D then moveDir = moveDir + camera.CFrame.RightVector end
        
        -- 3. 垂直升降控制 (面板上升/下降按钮 或 键盘 E/Q)
        if keys.E then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if keys.Q then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        bv.Velocity = moveDir * speed
    end
end)