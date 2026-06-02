local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer
local vs = "2.0 [05/17]"
local Drawing = Drawing
local WorldToScreen = WorldToScreen
local ipairs = ipairs
local pairs = pairs
local task = task

local toggle = { esp = true, hud = true }
local keyHeld = { f1 = false, f2 = false, f3 = false, f4 = false }
local FONT = Drawing.Fonts.UI

local function newText(props)
    local ok, o = pcall(function() return Drawing.new("Text") end)
    if not ok or not o then return nil end
    for k, v in pairs(props or {}) do o[k] = v end
    return o
end

local function T(p)
    if not p then p = {} end
    p.Font = FONT
    p.Outline = true
    return newText(p)
end

local TimerValue = ReplicatedStorage:WaitForChild("Timer")
local pwrValue = ReplicatedStorage:WaitForChild("PowerValues")
local PPMS = pwrValue:WaitForChild("PPMS")
local StationPower = ReplicatedStorage:WaitForChild("StationPower")

local pSM = {
    UsingSHDoor = "house_door_locked",
    UsingSHLight = "house_lights_on",
    UsingTowerLight = "tower_lights_on",
    UsingTowerRadar = "tower_radar_on"
}

local cam = workspace.CurrentCamera

local function anc()
    local v = cam.ViewportSize
    return Vector2.new(v.X / 2, v.Y - 80), Vector2.new(70, v.Y - 240), Vector2.new(v.X - 200, v.Y - 100)
end

local timerText = T({ Center = true, Size = 22, Color = Color3.fromHex("#ffffff"), Text = "0:00", Visible = true })
local scrapText = T({ Center = true, Size = 22, Color = Color3.fromHex("#ffffff"), Text = "0", Visible = true })
local timerLabel = T({ Center = true, Size = 22, Color = Color3.fromHex("#ffffff"), Text = "timer", Visible = true })
local scrapLabel = T({ Center = true, Size = 22, Color = Color3.fromHex("#fff89a"), Text = "scrap", Visible = true })
local pwrLabel = T({ Center = false, Size = 22, Color = Color3.fromHex("#ffe0b8"), Text = "power_activity", Visible = false })
local powerLines = {}
local pwrLH = 18
for k, v in pairs(pSM) do
    powerLines[k] = T({ Center = false, Size = 22, Color = Color3.fromHex("#ffffff"), Text = v, Visible = false })
end

local rakeRoofTitle = T({ Center = true, Size = 13, Color = Color3.fromHex("#f5d3ff"), Text = "roof", Visible = false })
local rakeRoofValue = T({ Center = true, Size = 13, Color = Color3.fromHex("#ebebeb"), Text = "", Visible = false })
local rakeRoofModel, rakeRoofHealth, rakeRoofConn = nil, nil, nil

local hudObjects = { timerText, scrapText, timerLabel, scrapLabel }

local function upPwrPos()
    local _, _, r = anc()
    pwrLabel.Position = r - Vector2.new(50, 0)
    local off = 0
    for _, line in pairs(powerLines) do
        if line.Visible then
            off += 1
            line.Position = pwrLabel.Position - Vector2.new(0, off * pwrLH)
        end
    end
end

local modLH = 18
local modList = { "Aitareis", "Mr68Moth", "ZZZXIIIXZZZ", "TZZV", "RlFLEM4N", "FelixVenue", "DeliverCreations", "z_papermoon", "r3shape", "ARRYvvv" }
local modLabel = T({ Center = false, Size = 13, Color = Color3.fromHex("#ff97f6"), Text = "staff_detected", Visible = false })
local modLines = {}
for i = 1, #modList do
    modLines[i] = T({ Center = false, Size = 13, Color = Color3.fromHex("#ffffff"), Text = "", Visible = false })
end

local function upStaffPos()
    local _, _, r = anc()
    modLabel.Position = r - Vector2.new(50, 120)
    local off = 0
    for i = 1, #modLines do
        local line = modLines[i]
        if line.Visible then
            off = off + 1
            line.Position = modLabel.Position - Vector2.new(0, off * modLH)
        end
    end
end

local function updHudPos()
    local c, l = anc()
    timerText.Position = Vector2.new(c.X - 80, c.Y - 100)
    scrapText.Position = Vector2.new(c.X + 80, c.Y - 100)
    timerLabel.Position = timerText.Position + Vector2.new(0, 18)
    scrapLabel.Position = scrapText.Position + Vector2.new(0, 18)
    upPwrPos()
    upStaffPos()
end

updHudPos()
upPwrPos()
upStaffPos()

local tList = {}
local tempObj = {}

local crateColSpacing = 55
local crateRowSpacing = 16
local crateItemsYOffset = 70
local crateItemColor = Color3.fromHex("#ffffff")
local crateBgColor = Color3.fromHex("#000000")
local crateBgOpacity = 0.3
local crateBgPadX = 28
local crateBgPadY = 10
local crateBgStaticWidth = (crateColSpacing * 2) + (crateBgPadX * 2)
local crateShowDistance = 30

local crateItemDisplayNames = {
    FirstAidKit = "medkit",
    Vitamins = "vitamin",
    UV_Lamp = "uv_lamp",
    StunStick = "stun",
    Vest = "vest",
    Tracker = "tracker"
}

local crateItemColors = {
    FirstAidKit = Color3.fromHex("#dbffde"),
    Vitamins = Color3.fromHex("#d1d3ff"),
    UV_Lamp = Color3.fromHex("#e694ff"),
    StunStick = Color3.fromHex("#ffed9d"),
    Vest = Color3.fromHex("#9fd4ff"),
    Tracker = Color3.fromHex("#cdceff"),
}

local function newBg()
    local ok, b = pcall(function() return Drawing.new("Square") end)
    if not ok or not b then return nil end
    b.Filled = true
    b.Transparency = crateBgOpacity
    b.Color = crateBgColor
    b.Visible = false
    return b
end

local espObj = {
    FlareGunPickUp = { Type = "Model", Root = "FlareGun", Text = "flare", Color = Color3.fromHex("#ff6b6b"), ExactName = true },
    BaseCampMSG = { Type = "BasePart", Text = "base", Color = Color3.fromHex("#6ba5ff"), offY = 25 },
    SafehouseMSG = { Type = "BasePart", Text = "house", Color = Color3.fromHex("#6ba5ff"), offY = 25 },
    StationMSG = { Type = "BasePart", Text = "electricity", Color = Color3.fromHex("#6ba5ff") },
    ShopMSG = { Type = "BasePart", Text = "shop", Color = Color3.fromHex("#6ba5ff") },
    ObservationTowerMSG = { Type = "BasePart", Text = "tower", Color = Color3.fromHex("#6ba5ff") },
    Scrap1 = { Type = "Model", Root = "Scrap", Text = "scrap 1", Color = Color3.fromHex("#a79266") },
    Scrap2 = { Type = "Model", Root = "Scrap", Text = "scrap 2", Color = Color3.fromHex("#c9aa68") },
    Scrap3 = { Type = "Model", Root = "Scrap", Text = "scrap 3", Color = Color3.fromHex("#dfb65d") },
    Scrap4 = { Type = "Model", Root = "Scrap", Text = "scrap 4", Color = Color3.fromHex("#ecca30") },
    Scrap5 = { Type = "Model", Root = "Scrap", Text = "scrap 5", Color = Color3.fromHex("#ffd000") },
    RakeTrapModel = { Type = "Model", Root = "HitBox", Text = "trap", Color = Color3.fromHex("#ffc6c6") },
    Box = { Type = "Model", Root = "HitBox", Text = "crate", Color = Color3.fromHex("#e4c3ff") },
    SupplyCrate = { Type = "Model", Root = "HitBox", Text = "crate", Color = Color3.fromHex("#e4c3ff") },
}

local function fmt(s)
    s = math.max(0, math.floor(s))
    return ("%d:%02d"):format(math.floor(s / 60), s % 60)
end

local function getModelFromInstance(i)
    if not i then return nil end
    if i:IsA("Model") then return i end
    if i:IsA("BasePart") and i.Parent and i.Parent:IsA("Model") then return i.Parent end
    return nil
end

local function safeAddress(i)
    if not i then return nil end
    if i.Address then return i.Address end
    return tostring(i)
end

local studConv = 1 / 3.5714285714

local function updatePowerLinesVisibility()
    local anyVisible = false
    for bn, l in pairs(powerLines) do
        local vv = pwrValue:FindFirstChild(bn)
        l.Visible = toggle.hud and vv and vv.Value or false
        if l.Visible then anyVisible = true end
    end
    pwrLabel.Visible = toggle.hud and anyVisible
    upPwrPos()
end

local radQuality = 100
local scrapRadius = 2.2
local scrapRadOff = 1
local boxRadius = 6

local circleRadiusWorld = {
    Scrap1 = scrapRadius, Scrap2 = scrapRadius, Scrap3 = scrapRadius,
    Scrap4 = scrapRadius, Scrap5 = scrapRadius, FlareGunPickUp = scrapRadius,
    Box = boxRadius, SupplyCrate = boxRadius, RakeTrapModel = scrapRadius
}

local circleYOffset = {
    Scrap1 = scrapRadOff, Scrap2 = scrapRadOff, Scrap3 = scrapRadOff,
    Scrap4 = scrapRadOff, Scrap5 = scrapRadOff, FlareGunPickUp = scrapRadOff,
    Box = 3.2, SupplyCrate = 3.2, RakeTrapModel = 0
}

local MSG_ENTRIES = {
    BaseCampMSG = true, SafehouseMSG = true, StationMSG = true,
    ShopMSG = true, ObservationTowerMSG = true
}

local fadeDistance = 40

local function newLineSegment()
    local ok, l = pcall(function() return Drawing.new("Line") end)
    if not ok or not l then return nil end
    l.Visible = false
    l.From = Vector2.new(0, 0)
    l.To = Vector2.new(0, 0)
    l.Thickness = 2
    return l
end

local function createFallbackRingSegments(n)
    local segs = {}
    for i = 1, n do
        local l = newLineSegment()
        if l then segs[#segs + 1] = l end
    end
    return segs
end

local function removeCircleData(cd)
    if not cd then return end
    if cd.segs then
        for _, s in ipairs(cd.segs) do
            pcall(function() if s then s.Visible = false; s:Remove() end end)
        end
        cd.segs = nil
    end
end

local function hideCircleData(cd)
    if not cd then return end
    if cd.segs then
        for _, s in ipairs(cd.segs) do
            pcall(function() if s then s.Visible = false end end)
        end
    end
end

local function ensureCircleSegments(cd)
    if not cd then return end
    if cd.isMsg then return end
    if cd.segs == nil then cd.segs = createFallbackRingSegments(100) end
end

local function getViewerPos()
    local ch = lp and lp.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if hrp and hrp.Position then return hrp.Position end
    local ok, pos = pcall(function() return cam and cam.CFrame and cam.CFrame.Position end)
    if ok and pos then return pos end
    return Vector3.new(0, 0, 0)
end

local function addObj(v)
    if not v then return end
    local model = getModelFromInstance(v)
    local addr = (model and safeAddress(model)) or safeAddress(v)
    if addr and tempObj[addr] then return end
    local entry, object, modelRec, entryName = nil, nil, model, nil
    
    if model and model.Name == "RakeTrapModel" then
        entry = { Type = "Model", Text = "trap", Color = Color3.fromHex("#ffc6c6") }
        entryName = "RakeTrapModel"
        object = model:FindFirstChild("HitBox", true)
    end
    
    if not entry and model and espObj[model.Name] then
        local e = espObj[model.Name]
        if not e.ExactName or model.Name == "FlareGunPickUp" then
            entry = e; entryName = model.Name
        end
    end
    
    if not entry and model then
        local scrapIdx = tostring(model.Name):match("^Scrap(%d+)")
        if scrapIdx then
            local key = "Scrap" .. tostring(tonumber(scrapIdx))
            if espObj[key] then entry = espObj[key]; entryName = key end
        end
    end
    
    if not entry then
        for name, e in pairs(espObj) do
            if e.Root then
                local src = model or (v.Parent and v.Parent:IsA("Model") and v.Parent)
                if src then
                    local f = src:FindFirstChild(e.Root, true)
                    if f and f:IsA("BasePart") then
                        entry = e; object = f; modelRec = src; entryName = name; break
                    end
                end
            end
        end
    end
    
    if not entry then return end
    if model and model.Name == "SupplyCrate" and not model:FindFirstChild(entry.Root, true) then
        local inner = model:FindFirstChild("Box")
        if inner and inner:IsA("Model") then modelRec = inner end
    end
    object = object or (entry.Type == "BasePart" and v:IsA("BasePart") and v) or (modelRec and modelRec:FindFirstChild(entry.Root, true))
    if not object then return end
    local recAddr = safeAddress(modelRec or object)
    if not recAddr then return end
    if tempObj[recAddr] then
        for _, existing in ipairs(tList) do
            if existing.Address == recAddr then
                if not existing.itemsFolder then
                    local boxModel = modelRec
                    if boxModel and boxModel.Name ~= "Box" then boxModel = boxModel:FindFirstChild("Box") end
                    local itemsFolderNew = boxModel and boxModel:FindFirstChild("Items_Folder")
                    if itemsFolderNew then
                        existing.itemsFolder = itemsFolderNew
                        existing.itemBG = existing.itemBG or newBg()
                        existing.itemTexts = existing.itemTexts or {}
                        local children = itemsFolderNew:GetChildren()
                        for i = 1, #children do
                            if not existing.itemTexts[i] then
                                existing.itemTexts[i] = newText({ Text = crateItemDisplayNames[children[i].Name] or children[i].Name, Color = crateItemColor, Outline = false, Center = true, Size = 13, Font = FONT, Visible = false })
                            end
                        end
                        for i = #children + 1, 6 do
                            if not existing.itemTexts[i] then
                                existing.itemTexts[i] = newText({ Text = "", Color = crateItemColor, Outline = false, Center = true, Size = 13, Font = FONT, Visible = false })
                            end
                        end
                    end
                end
                break
            end
        end
        return
    end
    local off = entry.offY or 0
    local name = newText({ Text = entry.Text, Color = entry.Color, Outline = true, Center = true, Size = 13, Font = FONT, Visible = false })
    local dist = newText({ Text = "0m", Color = Color3.fromHex("#c9c9c9"), Outline = true, Center = true, Size = 13, Font = FONT, Visible = false })
    local itemBG, itemTexts, itemsFolder = nil, nil, nil
    if entryName == "Box" or entryName == "SupplyCrate" or (modelRec and modelRec.Name == "Box") then
        local boxModel = modelRec
        if boxModel and boxModel.Name ~= "Box" then boxModel = boxModel:FindFirstChild("Box") end
        if boxModel then
            itemsFolder = boxModel:FindFirstChild("Items_Folder")
            if itemsFolder then
                itemBG = newBg()
                itemTexts = {}
                local children = itemsFolder:GetChildren()
                for i = 1, #children do
                    local child = children[i]
                    itemTexts[#itemTexts + 1] = newText({ Text = crateItemDisplayNames[child.Name] or child.Name, Color = crateItemColor, Outline = true, Center = true, Size = 13, Font = FONT, Visible = false })
                end
                for i = #children + 1, 6 do
                    itemTexts[#itemTexts + 1] = newText({ Text = "", Color = crateItemColor, Outline = true, Center = true, Size = 13, Font = FONT, Visible = false })
                end
            end
        end
    end
    tempObj[recAddr] = true
    tList[#tList + 1] = {
        object = object, model = modelRec or object.Parent,
        name = name, dist = dist, Address = recAddr, offY = off,
        itemTexts = itemTexts, itemBG = itemBG, itemsFolder = itemsFolder
    }
    local worldRadius = 1.8
    if entryName and circleRadiusWorld[entryName] then worldRadius = circleRadiusWorld[entryName] end
    local yoff = 1.0
    if entryName and circleYOffset[entryName] then yoff = circleYOffset[entryName] end
    local isMsg = entryName and MSG_ENTRIES[entryName]
    local segs = (not isMsg) and createFallbackRingSegments(radQuality) or nil
    tList[#tList].circleData = { segs = segs, worldRadius = worldRadius, color = entry.Color or Color3.fromHex("#ffffff"), yOffset = yoff, isMsg = isMsg }
end

local function updObj()
    local f = workspace:FindFirstChild("Filter")
    if f then
        local s = f:FindFirstChild("ScrapSpawns")
        if s then
            for _, sp in pairs(s:GetChildren()) do
                if sp.Name:match("ItemSpawn") then
                    for _, v in pairs(sp:GetChildren()) do addObj(v) end
                end
            end
        end
        local l = f:FindFirstChild("LocationPoints")
        if l then
            for _, p in pairs(l:GetChildren()) do addObj(p) end
        end
    end
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "FlareGunPickUp" then addObj(v) end
    end
    local d = workspace:FindFirstChild("Debris")
    if d then
        local t = d:FindFirstChild("Traps")
        if t then for _, v in pairs(t:GetChildren()) do addObj(v) end end
        local c = d:FindFirstChild("SupplyCrates")
        if c then for _, v in pairs(c:GetChildren()) do addObj(v) end end
    end
end

local function updPos()
    if not toggle.esp then
        for _, v in ipairs(tList) do
            if v.name then v.name.Visible = false end
            if v.dist then v.dist.Visible = false end
            if v.circleData and v.circleData.segs then
                for _, s in ipairs(v.circleData.segs) do if s then s.Visible = false end end
            end
            if v.itemTexts then for _, it in ipairs(v.itemTexts) do if it then it.Visible = false end end end
            if v.itemBG then v.itemBG.Visible = false end
        end
        rakeRoofTitle.Visible = false
        rakeRoofValue.Visible = false
        return
    end
    local viewerPos = getViewerPos()
    for i = #tList, 1, -1 do
        local v = tList[i]
        local o = v.object
        if not o or not o.Parent then
            if v.name then v.name:Remove() end
            if v.dist then v.dist:Remove() end
            removeCircleData(v.circleData)
            if v.itemTexts then for _, it in ipairs(v.itemTexts) do if it then it:Remove() end end end
            if v.itemBG then pcall(function() v.itemBG.Visible = false; v.itemBG:Remove() end) end
            tempObj[v.Address] = nil
            tList[i] = tList[#tList]
            tList[#tList] = nil
        else
            local p = o.Position
            local s, on = WorldToScreen(p)
            if on then
                local studs = 0
                if viewerPos then
                    studs = math.sqrt((p.X - viewerPos.X)^2 + (p.Y - viewerPos.Y)^2 + (p.Z - viewerPos.Z)^2)
                end
                local meters = studs * studConv
                local y = v.offY or 0
                if v.name then v.name.Position = Vector2.new(s.X, s.Y - 12 + y); v.name.Visible = true end
                if v.dist then v.dist.Position = Vector2.new(s.X, s.Y + 0.7 + y); v.dist.Text = tostring(math.floor(meters)) .. "m"; v.dist.Visible = true end
                if v.itemTexts and v.itemsFolder then
                    local children = v.itemsFolder:GetChildren()
                    local anyVisible = false
                    for idx = 1, #v.itemTexts do
                        local it = v.itemTexts[idx]
                        local child = children[idx]
                        local i0 = idx - 1
                        local row = math.floor(i0 / 3)
                        local col = i0 % 3
                        local xOffset = (col - 1) * crateColSpacing
                        local yOffset = row * crateRowSpacing
                        local textPos = Vector2.new(s.X + xOffset, s.Y - 12 + y + yOffset + crateItemsYOffset)
                        if child and meters <= crateShowDistance and toggle.esp then
                            it.Text = crateItemDisplayNames[child.Name] or child.Name
                            it.Position = textPos
                            it.Color = crateItemColors[child.Name] or crateItemColor
                            it.Visible = true
                            anyVisible = true
                        else
                            it.Visible = false
                        end
                    end
                    if v.itemBG then
                        if anyVisible then
                            local minY = math.huge
                            local maxY = -math.huge
                            for _, it in ipairs(v.itemTexts) do
                                if it and it.Visible then
                                    local pos = it.Position
                                    local bounds = it.TextBounds
                                    minY = math.min(minY, pos.Y - bounds.Y / 2)
                                    maxY = math.max(maxY, pos.Y + bounds.Y / 2)
                                end
                            end
                            minY -= crateBgPadY
                            maxY += crateBgPadY
                            local bgH = maxY - minY
                            v.itemBG.Size = Vector2.new(crateBgStaticWidth, bgH)
                            v.itemBG.Position = Vector2.new(s.X - crateBgStaticWidth / 2, minY)
                            v.itemBG.Visible = true
                        else
                            v.itemBG.Visible = false
                        end
                    end
                end
                local cd = v.circleData
                if cd and cd.segs then
                    local segCount = #cd.segs
                    local alpha = math.clamp(1 - (meters / fadeDistance), 0, 1)
                    if alpha <= 0 then
                        for j = 1, segCount do if cd.segs[j] then cd.segs[j].Visible = false end end
                    else
                        local centerWorld = p - Vector3.new(0, cd.yOffset or 1.0, 0)
                        for j = 1, segCount do
                            local a1 = (j - 1) * (2 * math.pi / segCount)
                            local a2 = j * (2 * math.pi / segCount)
                            local w1 = centerWorld + Vector3.new(math.cos(a1) * cd.worldRadius, 0, math.sin(a1) * cd.worldRadius)
                            local w2 = centerWorld + Vector3.new(math.cos(a2) * cd.worldRadius, 0, math.sin(a2) * cd.worldRadius)
                            local sp1, on1 = WorldToScreen(w1)
                            local sp2, on2 = WorldToScreen(w2)
                            local seg = cd.segs[j]
                            if on1 and on2 and toggle.esp then
                                seg.From = sp1
                                seg.To = sp2
                                seg.Color = cd.color
                                pcall(function() seg.Transparency = alpha end)
                                local dx = sp2.X - sp1.X
                                local dy = sp2.Y - sp1.Y
                                local lens = math.max(1, math.floor((dx * dx + dy * dy)^0.5 / 18))
                                seg.Thickness = math.clamp(lens, 2, 4)
                                seg.Visible = true
                            else
                                if seg then seg.Visible = false end
                            end
                        end
                    end
                end
            else
                if v.name then v.name.Visible = false end
                if v.dist then v.dist.Visible = false end
                if v.itemTexts then for _, it in ipairs(v.itemTexts) do if it then it.Visible = false end end end
                if v.itemBG then v.itemBG.Visible = false end
                if v.circleData and v.circleData.segs then
                    for _, s in ipairs(v.circleData.segs) do if s then s.Visible = false end end
                end
            end
        end
    end
    if rakeRoofModel and rakeRoofHealth then
        local part = rakeRoofModel:FindFirstChildWhichIsA("BasePart", true)
        if part then
            local s, on = WorldToScreen(part.Position)
            if on then
                rakeRoofTitle.Position = Vector2.new(s.X, s.Y - 15)
                rakeRoofValue.Position = Vector2.new(s.X, s.Y - 3)
                rakeRoofTitle.Visible = toggle.esp
                rakeRoofValue.Visible = toggle.esp
            else
                rakeRoofTitle.Visible = false
                rakeRoofValue.Visible = false
            end
        else
            rakeRoofTitle.Visible = false
            rakeRoofValue.Visible = false
        end
    else
        rakeRoofTitle.Visible = false
        rakeRoofValue.Visible = false
    end
end

local function getCharacterFromPart(p)
    while p do
        if p:FindFirstChild("Humanoid") then return p end
        p = p.Parent
    end
    return nil
end

local RakeModel, TargetVal = nil, nil
spawn(function()
    while true do
        local r = workspace:FindFirstChild("Rake", true)
        if r ~= RakeModel then
            RakeModel = r
            TargetVal = r and r:FindFirstChild("TargetVal") or nil
        elseif r then
            local tv = r:FindFirstChild("TargetVal")
            if tv ~= TargetVal then TargetVal = tv end
        end
        task.wait(0.5)
    end
end)

local playerChildConn, backpackChildConn = nil, nil
local currentPoints, currentConn = nil, nil

local function disconnectCurrent()
    if currentConn then pcall(function() currentConn:Disconnect() end); currentConn = nil end
    if backpackChildConn then pcall(function() backpackChildConn:Disconnect() end); backpackChildConn = nil end
    if playerChildConn then pcall(function() playerChildConn:Disconnect() end); playerChildConn = nil end
end

local function tryHookPoints()
    if not lp then return end
    local bp = lp:FindFirstChild("Backpack") or lp:FindFirstChild("backpack")
    if bp then
        local sf = bp:FindFirstChild("ScrapFolder")
        local pts = sf and sf:FindFirstChild("Points")
        if pts and pts:IsA("IntValue") then
            if pts ~= currentPoints then
                disconnectCurrent()
                currentPoints = pts
                scrapText.Text = tostring(pts.Value)
                local ok, conn = pcall(function()
                    return pts:GetPropertyChangedSignal("Value"):Connect(function()
                        scrapText.Text = tostring(pts.Value)
                    end)
                end)
                if ok and conn then currentConn = conn end
            end
        else
            if not backpackChildConn then
                local ok, conn = pcall(function()
                    return bp.ChildAdded:Connect(function(child)
                        if child.Name == "ScrapFolder" then task.wait(0.02); tryHookPoints() end
                    end)
                end)
                if ok and conn then backpackChildConn = conn end
            end
        end
    else
        if not playerChildConn then
            local ok, conn = pcall(function()
                return lp.ChildAdded:Connect(function(child)
                    if child.Name == "Backpack" or child.Name == "backpack" then task.wait(0.02); tryHookPoints() end
                end)
            end)
            if ok and conn then playerChildConn = conn end
        end
    end
end

local function findChildRecursive(parent, name)
    for _, v in ipairs(parent:GetChildren()) do
        if v.Name == name then return v end
        local f = findChildRecursive(v, name)
        if f then return f end
    end
    return nil
end

local function deleteFallDamage()
    local evt = findChildRecursive(ReplicatedStorage, "FD_Event")
    if evt then pcall(function() evt:Destroy() end) end
end
deleteFallDamage()

local function tryHookRakeBreak()
    local map = workspace:FindFirstChild("Map")
    local safehouse = map and map:FindFirstChild("SafeHouse")
    local rakeBreak = safehouse and safehouse:FindFirstChild("RakeBreak", true)
    local breakModel = rakeBreak and rakeBreak:FindFirstChild("BreakModel", true)
    local health = breakModel and breakModel:FindFirstChild("Health", true)
    if breakModel and health and health:IsA("IntValue") then
        if health ~= rakeRoofHealth then
            if rakeRoofConn then pcall(function() rakeRoofConn:Disconnect() end); rakeRoofConn = nil end
            rakeRoofModel = breakModel
            rakeRoofHealth = health
            rakeRoofValue.Text = tostring(health.Value) .. "/30"
            local ok, conn = pcall(function()
                return health:GetPropertyChangedSignal("Value"):Connect(function()
                    rakeRoofValue.Text = tostring(health.Value) .. "/30"
                end)
            end)
            if ok and conn then rakeRoofConn = conn end
        end
    else
        if rakeRoofConn then pcall(function() rakeRoofConn:Disconnect() end); rakeRoofConn = nil end
        rakeRoofModel = nil
        rakeRoofHealth = nil
    end
end

local function teleportToScrap()
    local char = lp and lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, v in ipairs(tList) do
        if v.model and v.model.Name:match("^Scrap%d+") then
            local root = v.model:FindFirstChildWhichIsA("UnionOperation", true) or v.model:FindFirstChildWhichIsA("BasePart", true)
            if root then hrp.Position = root.Position; return end
        end
    end
end

local function teleportToFlare()
    local char = lp and lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, v in ipairs(tList) do
        if v.model and v.model.Name == "FlareGunPickUp" then
            local root = v.object and v.object:IsA("BasePart") and v.object or v.model:FindFirstChildWhichIsA("BasePart", true)
            if root then hrp.Position = root.Position; return end
        end
    end
end

spawn(function()
    while true do
        tryHookPoints()
        tryHookRakeBreak()
        task.wait(0.1)
    end
end)

spawn(function()
    local last = cam.ViewportSize
    while true do
        if cam.ViewportSize ~= last then
            last = cam.ViewportSize
            updHudPos()
        end
        local t = TimerValue.Value
        timerText.Text = fmt(t)
        timerText.Color = t <= 15 and Color3.fromHex("#fc8f8f") or Color3.fromHex("#ffffff")
        timerLabel.Position = timerText.Position + Vector2.new(0, 18)
        task.wait(0.1)
    end
end)

spawn(function()
    while true do
        updatePowerLinesVisibility()
        local count = 0
        for i, entry in ipairs(modList) do
            local p = Players:FindFirstChild(entry)
            if p then
                count = count + 1
                modLines[i].Text = p.Name
                modLines[i].Visible = toggle.hud
            else
                modLines[i].Visible = false
            end
        end
        modLabel.Visible = toggle.hud and count > 0
        upStaffPos()
        scrapText.Visible = toggle.hud
        scrapLabel.Visible = toggle.hud
        task.wait(0.5)
    end
end)

spawn(function()
    while true do
        updObj()
        task.wait(0.5)
    end
end)

spawn(function()
    while true do
        updPos()
        if iskeypressed(0x70) then
            if not keyHeld.f1 then
                keyHeld.f1 = true
                toggle.esp = not toggle.esp
                if not toggle.esp then
                    for _, v in ipairs(tList) do
                        if v.name then v.name.Visible = false end
                        if v.dist then v.dist.Visible = false end
                        if v.circleData then hideCircleData(v.circleData) end
                        if v.itemTexts then for _, it in ipairs(v.itemTexts) do if it then it.Visible = false end end end
                        if v.itemBG then v.itemBG.Visible = false end
                    end
                else
                    for _, v in ipairs(tList) do
                        if v.name then v.name.Visible = true end
                        if v.dist then v.dist.Visible = true end
                        if v.circleData then ensureCircleSegments(v.circleData) end
                    end
                end
            end
        else
            keyHeld.f1 = false
        end
        if iskeypressed(0x71) then
            if not keyHeld.f2 then
                keyHeld.f2 = true
                toggle.hud = not toggle.hud
                for _, o in ipairs(hudObjects) do if o then o.Visible = toggle.hud end end
                updatePowerLinesVisibility()
            end
        else
            keyHeld.f2 = false
        end
        if iskeypressed(0x72) then
            if not keyHeld.f3 then keyHeld.f3 = true; teleportToScrap() end
        else
            keyHeld.f3 = false
        end
        if iskeypressed(0x73) then
            if not keyHeld.f4 then keyHeld.f4 = true; teleportToFlare() end
        else
            keyHeld.f4 = false
        end
        task.wait()
    end
end)

print(("saint | version %s"):format(vs))
print("F1 = toggle esp | F2 = toggle hud | F3 = tp to scrap | F4 = tp to flare")
