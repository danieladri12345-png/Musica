--[[
    OH-HUB PACKET LAGGER | PC SIMPLE EDITION v3.0
    Interfaz compacta inspirada en la distribución de Cypher.

    AJUSTES (botón engranaje):
      · Cambiar teclas con un clic y pulsando la nueva tecla.
      · Tres atajos: activar, mostrar/ocultar y minimizar.
      · Auto Steal (detección del atributo Stealing), RGB, sonidos.
    PANEL PRINCIPAL: potencia 1-100000, +/- 1000, activar/desactivar.
    Extras: intro full screen, panel lateral animado, arrastre,
      minimizado, botón flotante de reapertura y configuración.

    IMPORTANTE: el estado ACTIVAR es una simulación local; este script
    NO envía paquetes de red, no satura servidores ni roba objetos.
    No se ha probado en Madium.
--]]

local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local SoundService = game:GetService('SoundService')
local HttpService = game:GetService('HttpService')
local Workspace = game:GetService('Workspace')
local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild('PlayerGui')

local NAME = 'OH-HUB PACKET LAGGER'
local FILE = 'OH_HUB_PACKET_LAGGER_PC_SIMPLE_V3.json'
local W, H, MINI_H = 355, 247, 124
local SIDE_W, SIDE_H = 260, 362
local C = {
    bg = Color3.fromRGB(9, 12, 25),
    panel = Color3.fromRGB(16, 21, 39),
    field = Color3.fromRGB(23, 31, 53),
    edge = Color3.fromRGB(61, 77, 112),
    white = Color3.fromRGB(244, 249, 255),
    muted = Color3.fromRGB(150, 161, 185),
    violet = Color3.fromRGB(161, 111, 255),
    cyan = Color3.fromRGB(79, 233, 228),
    red = Color3.fromRGB(230, 86, 130),
}
local function new(class, parent, props)
    local obj = Instance.new(class)
    if props then for k, v in pairs(props) do obj[k] = v end end
    obj.Parent = parent
    return obj
end
local function tw(obj, changes, secs, easing)
    if not obj or not obj.Parent then return end
    local tween = TweenService:Create(obj, TweenInfo.new(secs or .2,
        easing or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), changes)
    tween:Play()
    return tween
end
local function round(obj, size)
    return new('UICorner', obj, {CornerRadius = UDim.new(0, size or 10)})
end
local function border(obj, color, thickness, transparency)
    return new('UIStroke', obj, {Color = color or C.edge,
        Thickness = thickness or 1, Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
end
local function text(parent, value, x, y, w, h, fontSize, color, bold)
    return new('TextLabel', parent, {
        Position = UDim2.fromOffset(x,y), Size = UDim2.fromOffset(w,h),
        BackgroundTransparency = 1, Text = value,
        TextColor3 = color or C.white, TextSize = fontSize or 13,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 10,
    })
end
local buttons = {}
local function button(parent, value, position, size, color, fontSize, radius)
    local b = new('TextButton', parent, {
        Position = position, Size = size, BackgroundColor3 = color or C.field,
        BorderSizePixel = 0, Text = value, TextSize = fontSize or 13,
        TextColor3 = C.white, Font = Enum.Font.GothamBold,
        AutoButtonColor = false, ZIndex = 12,
    })
    round(b, radius or 9)
    border(b, C.edge, 1, .35)
    local zoom = new('UIScale', b, {Scale = 1})
    table.insert(buttons, {element = b, zoom = zoom})
    return b
end
local function decodeKeys(s)
    if type(s) ~= 'string' then return nil end
    local ok, val = pcall(function() return Enum.KeyCode[s] end)
    if ok and val and val ~= Enum.KeyCode.Unknown then return val end
end
local default = {toggle = Enum.KeyCode.G,
    visibility = Enum.KeyCode.RightShift, minimize = Enum.KeyCode.Insert}
local actions = {'toggle', 'visibility', 'minimize'}
local actionNames = {toggle = 'ACTIVAR / DESACTIVAR',
    visibility = 'MOSTRAR / OCULTAR', minimize = 'MINIMIZAR / RESTAURAR'}
local st = {
    power = 10000, auto = false, active = false, rgb = true, sfx = true,
    mini = false, hidden = false, settings = false, listening = nil,
    x = 0, y = 0, keys = {toggle = default.toggle,
        visibility = default.visibility, minimize = default.minimize},
}
local function loadFile(path)
    if type(readfile) ~= 'function' then return nil end
    local ok, result = pcall(function()
        if type(isfile) == 'function' and not isfile(path) then return nil end
        return HttpService:JSONDecode(readfile(path))
    end)
    if ok and type(result) == 'table' then return result end
end
local config = loadFile(FILE)
    or loadFile('OH_HUB_PACKET_LAGGER_PC.json')
    or loadFile('OH_HUB_PACKET_LAGGER.json')
    or loadFile('CYPHER_Config.json')
if config then
    local p = tonumber(config.Intensity)
    if p then st.power = math.clamp(math.floor(p), 1, 100000) end
    st.auto = config.AutoStealState == true
    if type(config.RGB) == 'boolean' then st.rgb = config.RGB end
    if type(config.SFX) == 'boolean' then st.sfx = config.SFX end
    if type(config.Hotkeys) == 'table' then
        for _, action in ipairs(actions) do
            st.keys[action] = decodeKeys(config.Hotkeys[action]) or st.keys[action]
        end
    end
    st.keys.toggle = decodeKeys(config.Keybind) or st.keys.toggle
    st.x = tonumber(config.OffsetX) or 0
    st.y = tonumber(config.OffsetY) or 0
end
-- Quitar duplicados que pudieran venir de un archivo antiguo.
local used = {}
for _, action in ipairs(actions) do
    local k = st.keys[action]
    if used[k.Name] then
        k = default[action]
        if used[k.Name] then
            for _, option in ipairs({Enum.KeyCode.G, Enum.KeyCode.RightShift,
                Enum.KeyCode.Insert, Enum.KeyCode.F7, Enum.KeyCode.F8}) do
                if not used[option.Name] then k = option; break end
            end
        end
    end
    st.keys[action] = k
    used[k.Name] = true
end
local function save()
    if type(writefile) ~= 'function' then return false end
    local cfg = {
        Intensity = st.power, AutoStealState = st.auto,
        RGB = st.rgb, SFX = st.sfx,
        Keybind = st.keys.toggle.Name,
        Hotkeys = {toggle = st.keys.toggle.Name,
            visibility = st.keys.visibility.Name,
            minimize = st.keys.minimize.Name},
        OffsetX = st.x, OffsetY = st.y,
    }
    return pcall(function() writefile(FILE, HttpService:JSONEncode(cfg)) end)
end

-- Limpiar la instancia anterior para no acumular atajos al ejecutar otra vez.
local old = playerGui:FindFirstChild(NAME)
if old then
    local quit = old:FindFirstChild('OH_Shutdown')
    if quit and quit:IsA('BindableEvent') then pcall(function() quit:Fire() end) end
    old:Destroy()
end
local soundsOld = SoundService:FindFirstChild('OH_HUB_V3_SOUNDS')
if soundsOld then soundsOld:Destroy() end
local gui = new('ScreenGui', playerGui, {Name = NAME,
    IgnoreGuiInset = true, ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 600})
local shutdown = new('BindableEvent', gui, {Name = 'OH_Shutdown'})
local alive, connections = true, {}
local function connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(connections, conn)
    return conn
end
local sf = new('Folder', SoundService, {Name = 'OH_HUB_V3_SOUNDS'})
local sfx = {}
for key, id in pairs({click=9114282417, start=9114300981,
    stop=9114303932, hover=9114294822, bind=9114310303}) do
    sfx[key] = new('Sound', sf, {Name = key,
        SoundId = 'rbxassetid://'..id,
        Volume = key == 'hover' and .1 or .24})
end
local function play(key)
    if not st.sfx or not sfx[key] then return end
    pcall(function() sfx[key]:Stop(); sfx[key]:Play() end)
end

-- PANEL PRINCIPAL: no hay pestañas ni scroll.
local main = new('Frame', gui, {
    Name='Window', AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.new(.5, st.x, .5, st.y),
    Size=UDim2.fromOffset(W,H), BackgroundColor3=C.bg,
    BorderSizePixel=0, ClipsDescendants=false, Visible=false, ZIndex=2,
})
round(main, 16)
local mainBorder = border(main, C.violet, 1.8, .04)
new('UIGradient', main, {Rotation=120, Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(15,21,40)),
    ColorSequenceKeypoint.new(1, C.bg)})})
local mainScale = new('UIScale', main, {Scale=1})
local header = new('Frame', main, {Name='Drag', Size=UDim2.new(1,0,0,58),
    BackgroundColor3=C.panel, BorderSizePixel=0, ZIndex=5})
round(header, 16)
-- banda inferior para cubrir las esquinas inferiores redondeadas del header
new('Frame', header, {Position=UDim2.new(0,0,1,-14),
    Size=UDim2.new(1,0,0,14), BackgroundColor3=C.panel,
    BorderSizePixel=0, ZIndex=5})
local thin = new('Frame', header, {Position=UDim2.new(0,12,1,-2),
    Size=UDim2.new(1,-24,0,2), BackgroundColor3=C.violet,
    BorderSizePixel=0,ZIndex=7})
round(thin, 2)
local gear = button(header, '⚙', UDim2.fromOffset(11,13),
    UDim2.fromOffset(31,31), C.field, 17)
text(header, 'OH-HUB', 50, 6, 204, 26, 19, C.white, true)
text(header, 'P A C K E T   L A G G E R', 50, 31, 225, 17, 10, C.cyan, true)
local minimize = button(header, '−', UDim2.fromOffset(279,13),
    UDim2.fromOffset(29,31), C.field, 21)
local hide = button(header, '×', UDim2.fromOffset(315,13),
    UDim2.fromOffset(29,31), C.field, 20)
local body = new('Frame', main, {Position=UDim2.fromOffset(13,63),
    Size=UDim2.fromOffset(W-26,H-68), BackgroundTransparency=1, ZIndex=6})
text(body, 'OMAHAD POWER', 2, 0, 280, 18, 11, C.muted, true)
local minus = button(body, '−', UDim2.fromOffset(0,23),
    UDim2.fromOffset(38,39), C.field, 23)
local plus = button(body, '+', UDim2.fromOffset(291,23),
    UDim2.fromOffset(38,39), C.field, 21)
local power = new('TextBox', body, {Position=UDim2.fromOffset(45,23),
    Size=UDim2.fromOffset(239,39), BackgroundColor3=C.panel,
    BorderSizePixel=0, Text=tostring(st.power),
    TextColor3=C.white, PlaceholderColor3=C.muted,
    Font=Enum.Font.GothamBold, TextSize=18,
    ClearTextOnFocus=false, ZIndex=10})
round(power,9)
border(power,C.edge,1,.2)
local indicator = new('Frame', body, {Position=UDim2.fromOffset(2,78),
    Size=UDim2.fromOffset(10,10), BackgroundColor3=C.muted,
    BorderSizePixel=0, ZIndex=10})
round(indicator,10)
local status = text(body,'EN ESPERA',20,72,170,22,12,C.muted,true)
local keyHint = text(body,'G · TECLA PARA ACTIVAR',175,72,153,22,10,C.muted,true)
keyHint.TextXAlignment=Enum.TextXAlignment.Right
local activate = button(body, 'ACTIVAR', UDim2.fromOffset(0,106),
    UDim2.fromOffset(329,43), C.violet, 16, 12)
local activateBorder = border(activate,C.cyan,1.5,.05)
local foot = text(body, 'SIMULACIÓN LOCAL  ·  SIN ENVÍO DE PAQUETES',
    3,153,326,19,9,C.muted,true)
foot.TextXAlignment=Enum.TextXAlignment.Center
local miniButton = button(main, 'ACTIVAR', UDim2.fromOffset(13,70),
    UDim2.fromOffset(329,42), C.violet,15,12)
miniButton.Visible=false

-- PANEL LATERAL tipo Cypher: todas las opciones en la misma vista.
local side = new('Frame', main, {Name='Settings',
    Position=UDim2.fromOffset(-SIDE_W-12,0),
    Size=UDim2.fromOffset(SIDE_W,SIDE_H),
    BackgroundColor3=C.panel, BorderSizePixel=0,
    Visible=false, ClipsDescendants=false, ZIndex=20})
round(side,14)
local sideStroke=border(side,C.violet,1.5,.08)
text(side,'⚙  AJUSTES',14,10,198,25,15,C.white,true).ZIndex=23
local sideClose=button(side,'×',UDim2.fromOffset(223,10),
    UDim2.fromOffset(25,25),C.field,16)
sideClose.ZIndex=25
local sideRule=new('Frame',side,{Position=UDim2.fromOffset(13,42),
    Size=UDim2.fromOffset(234,1),BackgroundColor3=C.edge,
    BorderSizePixel=0,ZIndex=22})
local autoLabel=text(side,'AUTO STEAL BRAINROT',14,51,190,22,11,C.muted,true)
autoLabel.ZIndex=23
local auto=button(side,st.auto and 'ON' or 'OFF',
    UDim2.fromOffset(183,53),UDim2.fromOffset(64,29),C.field,12)
auto.ZIndex=25
local autoNote=text(side,'Detecta si tienes Stealing',14,77,220,17,10,C.muted)
autoNote.ZIndex=23
local keyTitle=text(side,'CONFIGURAR TECLAS',14,105,220,20,11,C.cyan,true)
keyTitle.ZIndex=23
local keyButtons={}
for i,action in ipairs(actions) do
    local y=132+(i-1)*50
    local row=new('Frame',side,{Position=UDim2.fromOffset(12,y),
        Size=UDim2.fromOffset(236,43),BackgroundColor3=C.bg,
        BorderSizePixel=0,ZIndex=22})
    round(row,9)
    local label=text(row,actionNames[action],9,2,133,39,10,C.white,true)
    label.ZIndex=24
    local b=button(row,st.keys[action].Name,
        UDim2.fromOffset(145,6),UDim2.fromOffset(84,31),C.field,11,7)
    b.ZIndex=25
    keyButtons[action]=b
end
local rgb=button(side,'RGB: ON',UDim2.fromOffset(12,288),
    UDim2.fromOffset(113,30),C.field,11)
local sound=button(side,'SFX: ON',UDim2.fromOffset(135,288),
    UDim2.fromOffset(113,30),C.field,11)
rgb.ZIndex=25
sound.ZIndex=25
local help=text(side,'CLIC EN UNA TECLA Y PULSA LA NUEVA',12,327,236,17,9,C.muted,true)
help.TextXAlignment=Enum.TextXAlignment.Center
help.ZIndex=24
local helpExtra=text(side,'ESC: CANCELAR  ·  BACKSPACE: RESTAURAR',12,343,236,14,8,C.muted)
helpExtra.TextXAlignment=Enum.TextXAlignment.Center
helpExtra.ZIndex=24

-- Acceso fácil cuando se oculta la ventana.
local dock=button(gui,'OH-HUB  ·  ABRIR',UDim2.new(1,-163,1,-62),
    UDim2.fromOffset(148,43),C.panel,12,11)
dock.Visible=false
dock.ZIndex=65
local dockStroke=border(dock,C.cyan,1.6,.04)

-- Adaptación al tamaño de la pantalla y ventana que nunca se pierde.
local function viewport()
    local camera=Workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280,720)
end
local function clampPanel()
    local vp=viewport()
    local height=st.mini and MINI_H or H
    local scale=mainScale.Scale
    local xx=math.max(0,(vp.X-W*scale)*.5-8)
    local yy=math.max(0,(vp.Y-height*scale)*.5-8)
    st.x=math.clamp(st.x,-xx,xx)
    st.y=math.clamp(st.y,-yy,yy)
    main.Position=UDim2.new(.5,st.x,.5,st.y)
end
local function sideTarget()
    local vp=viewport()
    local left=vp.X*.5+st.x-W*mainScale.Scale*.5
    local right=left+W*mainScale.Scale
    local needed=(SIDE_W+12)*mainScale.Scale
    -- Preferencia por la izquierda, como Cypher; derecha si falta espacio.
    if left>=needed+5 then return UDim2.fromOffset(-SIDE_W-12,0) end
    if vp.X-right>=needed+5 then return UDim2.fromOffset(W+12,0) end
    -- Ventana pequeña: al lado que tenga más espacio.
    return UDim2.fromOffset((left>vp.X-right) and (-SIDE_W-12) or (W+12),0)
end
local function resize()
    local vp=viewport()
    mainScale.Scale=math.clamp(math.min(vp.X/390,vp.Y/400),.72,1)
    clampPanel()
    if st.settings then side.Position=sideTarget() end
end
resize()
if Workspace.CurrentCamera then
    connect(Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),resize)
end
connect(Workspace:GetPropertyChangedSignal('CurrentCamera'),function()
    if Workspace.CurrentCamera then
        connect(Workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'),resize)
    end
    resize()
end)

local function refresh()
    power.Text=tostring(st.power)
    keyHint.Text=st.keys.toggle.Name..' · ACTIVAR'
    local on=st.active
    activate.Text=on and 'DESACTIVAR' or 'ACTIVAR'
    miniButton.Text=activate.Text
    status.Text=on and 'SIMULACIÓN ACTIVA' or 'EN ESPERA'
    status.TextColor3=on and C.cyan or C.muted
    tw(indicator,{BackgroundColor3=on and C.cyan or C.muted},.18)
    tw(activate,{BackgroundColor3=on and C.red or C.violet},.18)
    tw(miniButton,{BackgroundColor3=on and C.red or C.violet},.18)
    auto.Text=st.auto and 'ON' or 'OFF'
    rgb.Text=st.rgb and 'RGB: ON' or 'RGB: OFF'
    sound.Text=st.sfx and 'SFX: ON' or 'SFX: OFF'
    tw(auto,{BackgroundColor3=st.auto and C.violet or C.field},.18)
    for _,action in ipairs(actions) do
        local b=keyButtons[action]
        b.Text=st.listening==action and 'PULSA...' or st.keys[action].Name
        tw(b,{BackgroundColor3=st.listening==action and C.violet or C.field},.13)
    end
end
local function setPower(value)
    local number=tonumber(value)
    if not number then number=st.power end
    st.power=math.clamp(math.floor(number),1,100000)
    refresh()
    save()
end
local function setActive(on)
    if st.active==on then return end
    st.active=on
    refresh()
    play(on and 'start' or 'stop')
end
local function toggleActive() setActive(not st.active) end
local function carrying()
    local character=player.Character
    return player:GetAttribute('Stealing')==true or
        (character~=nil and character:GetAttribute('Stealing')==true)
end
local function autoUpdate()
    if not st.auto then return end
    setActive(carrying())
end
local settingsToken=0
local function setSettings(show)
    st.settings=show and not st.mini and not st.hidden
    settingsToken=settingsToken+1
    local token=settingsToken
    if st.settings then
        side.Position=UDim2.fromOffset(-8,0)
        side.Visible=true
        tw(side,{Position=sideTarget(),BackgroundTransparency=0},.25,Enum.EasingStyle.Quart)
    elseif side.Visible then
        tw(side,{BackgroundTransparency=1},.17)
        task.delay(.19,function()
            if alive and token==settingsToken then
                side.Visible=false
                side.BackgroundTransparency=0
            end
        end)
    end
end
local function setMini(value)
    st.mini=value
    st.listening=nil
    setSettings(false)
    body.Visible=not value
    miniButton.Visible=value
    minimize.Text=value and '+' or '−'
    tw(main,{Size=UDim2.fromOffset(W,value and MINI_H or H)},.24,
        Enum.EasingStyle.Quart)
    task.delay(.26,function() if alive then clampPanel() end end)
    refresh()
    play('click')
end
local function setHidden(value)
    st.hidden=value
    if value then st.listening=nil; setSettings(false) end
    main.Visible=not value
    dock.Visible=value
    refresh()
    play('click')
end
local function toggleAuto()
    st.auto=not st.auto
    if st.auto then autoUpdate() else setActive(false) end
    refresh()
    play('click')
    save()
end

connect(gear.MouseButton1Click,function()
    setSettings(not st.settings)
    play('click')
end)
connect(sideClose.MouseButton1Click,function() setSettings(false); play('click') end)
connect(minimize.MouseButton1Click,function() setMini(not st.mini) end)
connect(hide.MouseButton1Click,function() setHidden(true) end)
connect(dock.MouseButton1Click,function() setHidden(false) end)
connect(activate.MouseButton1Click,toggleActive)
connect(miniButton.MouseButton1Click,toggleActive)
connect(minus.MouseButton1Click,function() setPower(tonumber(power.Text) and tonumber(power.Text)-1000 or st.power-1000); play('click') end)
connect(plus.MouseButton1Click,function() setPower(tonumber(power.Text) and tonumber(power.Text)+1000 or st.power+1000); play('click') end)
connect(power.FocusLost,function() setPower(power.Text); play('click') end)
connect(auto.MouseButton1Click,toggleAuto)
connect(rgb.MouseButton1Click,function()
    st.rgb=not st.rgb; refresh(); save(); play('click')
end)
connect(sound.MouseButton1Click,function()
    st.sfx=not st.sfx; refresh(); save(); play('click')
end)
local function setHelp(message)
    help.Text=message
    task.delay(2.2,function()
        if alive and not st.listening then
            help.Text='CLIC EN UNA TECLA Y PULSA LA NUEVA'
        end
    end)
end
for _,action in ipairs(actions) do
    local current=action
    connect(keyButtons[current].MouseButton1Click,function()
        st.listening=current
        setHelp('PULSA UNA TECLA · ESC CANCELA')
        refresh()
        play('bind')
    end)
end
local prohibited={
    [Enum.KeyCode.Unknown]=true,
    [Enum.KeyCode.LeftControl]=true,
    [Enum.KeyCode.RightControl]=true,
    [Enum.KeyCode.LeftAlt]=true,
    [Enum.KeyCode.RightAlt]=true,
    [Enum.KeyCode.Escape]=true,
}
connect(UIS.InputBegan,function(input,processed)
    if not alive or input.UserInputType~=Enum.UserInputType.Keyboard then return end
    local key=input.KeyCode
    if st.listening then
        if key==Enum.KeyCode.Escape then
            st.listening=nil
            setHelp('CAMBIO CANCELADO')
        else
            local action=st.listening
            if key==Enum.KeyCode.Backspace then key=default[action] end
            local conflict=false
            for _,other in ipairs(actions) do
                if other~=action and st.keys[other]==key then conflict=true end
            end
            if prohibited[key] or conflict then
                setHelp(conflict and 'TECLA YA UTILIZADA' or 'ELIGE OTRA TECLA')
            else
                st.keys[action]=key
                st.listening=nil
                save()
                setHelp('GUARDADO: '..key.Name)
                play('bind')
            end
        end
        refresh()
        return
    end
    if processed or UIS:GetFocusedTextBox() then return end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then return end
    if key==st.keys.toggle then
        toggleActive()
    elseif key==st.keys.visibility then
        setHidden(not st.hidden)
    elseif key==st.keys.minimize then
        if st.hidden then setHidden(false) end
        setMini(not st.mini)
    end
end)

-- Drag por la barra superior, sin que los botones provoquen arrastres.
local dragging=false
local dragStart, offsetAtStart, dragTouch
connect(header.InputBegan,function(input)
    if input.UserInputType~=Enum.UserInputType.MouseButton1 and
        input.UserInputType~=Enum.UserInputType.Touch then return end
    local point=input.Position
    for _,b in ipairs({gear,minimize,hide}) do
        local pos,sz=b.AbsolutePosition,b.AbsoluteSize
        if point.X>=pos.X and point.X<=pos.X+sz.X and
           point.Y>=pos.Y and point.Y<=pos.Y+sz.Y then return end
    end
    dragging=true
    dragStart=point
    offsetAtStart=Vector2.new(st.x,st.y)
    dragTouch=(input.UserInputType==Enum.UserInputType.Touch) and input or nil
    connect(input.Changed,function()
        if input.UserInputState==Enum.UserInputState.End then
            dragging=false; dragTouch=nil
            save()
        end
    end)
end)
connect(UIS.InputChanged,function(input)
    if not dragging then return end
    if dragTouch then
        if input~=dragTouch then return end
    elseif input.UserInputType~=Enum.UserInputType.MouseMovement then return end
    local delta=input.Position-dragStart
    st.x=offsetAtStart.X+delta.X
    st.y=offsetAtStart.Y+delta.Y
    clampPanel()
    if st.settings then side.Position=sideTarget() end
end)

-- Hover sutil: nunca modifica el tamaño/posición real del panel.
for _,pair in ipairs(buttons) do
    local b,zoom=pair.element,pair.zoom
    connect(b.MouseEnter,function()
        if not b.Visible then return end
        tw(zoom,{Scale=1.035},.12)
        local stroke=b:FindFirstChildOfClass('UIStroke')
        if stroke then tw(stroke,{Transparency=0},.12) end
        play('hover')
    end)
    connect(b.MouseLeave,function()
        tw(zoom,{Scale=1},.12)
        local stroke=b:FindFirstChildOfClass('UIStroke')
        if stroke then tw(stroke,{Transparency=.35},.13) end
    end)
end

-- Detección automática con el atributo, igual que la opción Cypher.
local characterChanged
local function attachCharacter(character)
    if characterChanged then characterChanged:Disconnect(); characterChanged=nil end
    if character then
        characterChanged=connect(character:GetAttributeChangedSignal('Stealing'),autoUpdate)
    end
    autoUpdate()
end
connect(player:GetAttributeChangedSignal('Stealing'),autoUpdate)
connect(player.CharacterAdded,attachCharacter)
attachCharacter(player.Character)
task.spawn(function()
    while alive and gui.Parent do
        if st.auto then autoUpdate() end
        task.wait(.15)
    end
end)

-- RGB animado eficiente: actualiza únicamente bordes y detalles.
local elapsed=0
connect(RunService.Heartbeat,function(dt)
    elapsed=elapsed+dt
    if elapsed<.05 then return end
    elapsed=0
    local tone=st.rgb and Color3.fromHSV((os.clock()*.10)%1,.67,1) or C.violet
    mainBorder.Color=tone
    sideStroke.Color=tone
    dockStroke.Color=tone
    thin.BackgroundColor3=tone
    activateBorder.Color=tone
end)

-- INTRO DE PANTALLA COMPLETA. Se puede omitir inmediatamente.
local intro=new('Frame',gui,{Name='OH_Intro',Size=UDim2.fromScale(1,1),
    BackgroundColor3=C.bg,BorderSizePixel=0,ZIndex=100})
new('UIGradient',intro,{Rotation=40,Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(7,18,40)),
    ColorSequenceKeypoint.new(.5,Color3.fromRGB(27,11,47)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(6,29,37))})})
local flash=new('Frame',intro,{AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.fromScale(.5,.5),Size=UDim2.new(.05,0,0,3),
    BackgroundColor3=C.cyan,BackgroundTransparency=.25,
    BorderSizePixel=0,ZIndex=101})
local introOH=new('TextLabel',intro,{Position=UDim2.new(.10,0,.29,0),
    Size=UDim2.new(.8,0,.18,0), BackgroundTransparency=1,
    Text='OH-HUB', TextColor3=C.white, TextScaled=true,
    Font=Enum.Font.GothamBlack,TextTransparency=1,ZIndex=103})
local introName=new('TextLabel',intro,{Position=UDim2.new(.1,0,.46,0),
    Size=UDim2.new(.8,0,.12,0), BackgroundTransparency=1,
    Text='PACKET LAGGER',TextColor3=C.cyan,TextScaled=true,
    Font=Enum.Font.GothamBlack,TextTransparency=1,ZIndex=103})
local introSmall=new('TextLabel',intro,{Position=UDim2.new(.2,0,.62,0),
    Size=UDim2.new(.6,0,.04,0), BackgroundTransparency=1,
    Text='P C   ·   S I M P L E   E D I T I O N',
    TextColor3=C.muted,TextScaled=true,
    Font=Enum.Font.GothamBold,TextTransparency=1,ZIndex=103})
local barBg=new('Frame',intro,{AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.fromScale(.5,.735), Size=UDim2.new(.52,0,0,5),
    BackgroundColor3=C.field,BorderSizePixel=0,ZIndex=102})
round(barBg,5)
local bar=new('Frame',barBg,{Size=UDim2.fromScale(0,1),
    BackgroundColor3=C.cyan,BorderSizePixel=0,ZIndex=103})
round(bar,5)
local skip=button(intro,'SALTAR INTRO',UDim2.new(1,-151,1,-57),
    UDim2.fromOffset(134,37),C.panel,11)
skip.ZIndex=105
local finished=false
local function finishIntro()
    if finished or not alive then return end
    finished=true
    main.Visible=true
    main.BackgroundTransparency=1
    main.Size=UDim2.fromOffset(W,73)
    tw(main,{Size=UDim2.fromOffset(W,H),BackgroundTransparency=0},.47,
        Enum.EasingStyle.Back)
    for _,element in ipairs(intro:GetDescendants()) do
        if element:IsA('TextLabel') or element:IsA('TextButton') then
            tw(element,{TextTransparency=1},.26)
        elseif element:IsA('Frame') then
            tw(element,{BackgroundTransparency=1},.26)
        end
    end
    tw(intro,{BackgroundTransparency=1},.30)
    task.delay(.35,function()
        if intro.Parent then intro:Destroy() end
        if alive then clampPanel() end
    end)
end
connect(skip.MouseButton1Click,finishIntro)
tw(introOH,{TextTransparency=0},.38)
task.delay(.14,function() if alive and not finished then tw(introName,{TextTransparency=0},.48) end end)
task.delay(.3,function() if alive and not finished then tw(introSmall,{TextTransparency=0},.48) end end)
tw(bar,{Size=UDim2.fromScale(1,1)},2.0,Enum.EasingStyle.Sine)
tw(flash,{Size=UDim2.new(.85,0,0,3),BackgroundTransparency=.8},1.9)
task.delay(2.05,finishIntro)

connect(shutdown.Event,function()
    if not alive then return end
    alive=false
    st.active=false
    if characterChanged then characterChanged:Disconnect() end
    for _,conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
    if sf and sf.Parent then sf:Destroy() end
    if gui and gui.Parent then gui:Destroy() end
end)
refresh()
autoUpdate()
