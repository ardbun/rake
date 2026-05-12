local Players,ReplicatedStorage=game:GetService("Players"),game:GetService("ReplicatedStorage")
local lp=Players.LocalPlayer; local vs="1.3 [02/22]"
local workspace,Drawing,WorldToScreen,ipairs,pairs,task=workspace,Drawing,WorldToScreen,ipairs,pairs,task
local toggle={esp=true,hud=true}; local keyHeld={f1=false,f2=false}

-- SAFE DRAWING WRAPPER - prevents crashes
local function safeNewText(p)
    local success, result = pcall(function()
        local t = Drawing.new("Text")
        for k,v in pairs(p) do
            pcall(function() t[k]=v end)
        end
        return t
    end)
    return success and result or nil
end

local FONT = Drawing.Fonts.System
local function T(p) 
    p.Font = FONT
    p.Outline = true
    return safeNewText(p)
end

-- Check if objects exist before using
local TimerValue = ReplicatedStorage and ReplicatedStorage:FindFirstChild("Timer")
local pwrValue = ReplicatedStorage and ReplicatedStorage:FindFirstChild("PowerValues")
local PPMS = pwrValue and pwrValue:FindFirstChild("PPMS")
local RadioChannel = ReplicatedStorage and ReplicatedStorage:FindFirstChild("RadioChannel")
local StationPower = ReplicatedStorage and ReplicatedStorage:FindFirstChild("StationPower")

-- Only create UI if we have the required objects
if not TimerValue or not PPMS then
    print("Required game objects not found - script may not work properly")
end

local pSM={UsingSHDoor="House door is locked",UsingSHLight="House lights are on",UsingTowerLight="Tower floodlights are on",UsingTowerRadar="Tower radar is active"}
local cam=workspace.CurrentCamera

local function anc() 
    if not cam then return Vector2.new(0,0), Vector2.new(0,0), Vector2.new(0,0) end
    local v = cam.ViewportSize
    return Vector2.new(v.X/2, v.Y-80), Vector2.new(70, v.Y-240), Vector2.new(v.X-200, v.Y-100) 
end

-- Create text objects with safety checks
local timerText = T{Center=true,Size=21,Color=Color3.fromHex("#ffffff"),Text="",Visible=true}
local ppmsText = T{Center=true,Size=21,Color=Color3.fromHex("#ffffff"),Text="",Visible=true}
local scrapText = T{Center=true,Size=21,Color=Color3.fromHex("#ffffff"),Text="",Visible=true}
local targetPlayerText = T{Center=true,Size=19,Color=Color3.fromHex("#ffffff"),Text="None",Visible=true}
local timerLabel = T{Center=true,Size=15,Color=Color3.fromHex("#eeeeee"),Text="TIME REMAINING",Visible=true}
local ppmsLabel = T{Center=true,Size=15,Color=Color3.fromHex("#ffce8f"),Text="POWER USAGE",Visible=true}
local scrapLabel = T{Center=true,Size=15,Color=Color3.fromHex("#fff88f"),Text="SALVAGE VALUE",Visible=true}
local targetTitle = T{Center=true,Size=15,Color=Color3.fromHex("#c44b4b"),Text="RAKE'S TARGET",Visible=true}

local pwrLabel = T{Center=false,Size=22,Color=Color3.fromHex("#ffce8f"),Text="POWER ACTIVITY",Visible=false}
local powerLines,pwrLH={},18
for k,v in pairs(pSM) do 
    powerLines[k]=T{Center=false,Size=15,Color=Color3.fromHex("#ffffff"),Text=v,Visible=false} 
end

local radioTitle = T{Center=false,Size=22,Color=Color3.fromHex("#cbffcf"),Text="RADIO ACTIVITY",Visible=true}
local radLine={}; local LINE_H=20
for i=1,7 do 
    radLine[i]={}
    radLine[i].name = T{Center=false,Size=13,Color=Color3.fromHex("#b6b6b6"),Text="",Visible=true}
    radLine[i].msg = T{Center=false,Size=13,Color=Color3.fromHex("#ffffff"),Text="",Visible=true}
end

local rakeRoofTitle = T{Center=true,Size=14,Color=Color3.fromHex("#c0e8ff"),Text="Roof Debris",Visible=false}
local rakeRoofValue = T{Center=true,Size=12,Color=Color3.fromHex("#ebebeb"),Text="",Visible=false}
local rakeRoofModel, rakeRoofHealth, rakeRoofConn = nil, nil, nil

-- Only add valid objects to hudObjects
local hudObjects = {}
local function addToHud(obj)
    if obj then table.insert(hudObjects, obj) end
end

addToHud(timerText); addToHud(ppmsText); addToHud(scrapText); addToHud(targetPlayerText)
addToHud(timerLabel); addToHud(ppmsLabel); addToHud(scrapLabel); addToHud(targetTitle); addToHud(radioTitle)
for i=1,7 do 
    if radLine[i] then
        addToHud(radLine[i].name)
        addToHud(radLine[i].msg)
    end
end

function upPwrPos() 
    local _,_,r=anc()
    if not pwrLabel then return end
    pwrLabel.Position=r-Vector2.new(50,0)
    local off=0
    for _,line in pairs(powerLines) do 
        if line and line.Visible then 
            off=off+1
            line.Position=pwrLabel.Position-Vector2.new(0,off*pwrLH)
        end 
    end 
end

local modLH=18
local modList={"Aitareis","Mr68Moth","ZZZXIIIXZZZ","TZZV","RlFLEM4N","FelixVenue","DeliverCreations","z_papermoon","r3shape","ARRYvvv"}
local modLabel=T{Center=false,Size=22,Color=Color3.fromHex("#ff97f6"),Text="STAFF DETECTED",Visible=false}
local modLines={} 
for i=1,#modList do 
    modLines[i]=T{Center=false,Size=18,Color=Color3.fromHex("#ffffff"),Text="",Visible=false} 
end

function upStaffPos() 
    local _,_,r=anc()
    if not modLabel then return end
    modLabel.Position=r-Vector2.new(50,120)
    local off=0
    for i=1,#modLines do 
        local line=modLines[i]
        if line and line.Visible then 
            off=off+1
            line.Position=modLabel.Position-Vector2.new(0,off*modLH)
        end 
    end 
end

local function updHudPos()
    if not cam then return end
    local c,l=anc()
    local spacing=130
    if timerText then timerText.Position = c + Vector2.new(-1.5*spacing,-30) end
    if ppmsText then ppmsText.Position = c + Vector2.new(-0.5*spacing,-30) end
    if targetPlayerText then targetPlayerText.Position = c + Vector2.new(0.5*spacing,-30) end
    if scrapText then scrapText.Position = c + Vector2.new(1.5*spacing,-30) end
    if timerLabel and timerText then timerLabel.Position = timerText.Position + Vector2.new(0,18) end
    if ppmsLabel and ppmsText then ppmsLabel.Position = ppmsText.Position + Vector2.new(0,18) end
    if scrapLabel and scrapText then scrapLabel.Position = scrapText.Position + Vector2.new(0,18) end
    if targetTitle and targetPlayerText then targetTitle.Position = targetPlayerText.Position + Vector2.new(0,18) end
    if radioTitle then radioTitle.Position = l + Vector2.new(-1,140) end
    for i=1,7 do 
        if radLine[i] then
            local y=l.Y+(i-1)*LINE_H
            if radLine[i].name then radLine[i].name.Position=Vector2.new(l.X,y) end
            if radLine[i].msg then radLine[i].msg.Position=Vector2.new(l.X+70,y) end
        end
    end
    upPwrPos(); upStaffPos()
end

-- Delay first position update to avoid startup crash
task.wait(0.5)
pcall(updHudPos)

local tList,tempObj = {},{}
local espObj = {
 FlareGunPickUp={Type="Model",Root="FlareGun",Text="Flare Gun",Color=Color3.fromHex("#f05757"),ExactName=true},
 BaseCampMSG={Type="BasePart",Text="Camp",Color=Color3.fromHex("#c6f1c8")},
 SafehouseMSG={Type="BasePart",Text="House",Color=Color3.fromHex("#c6f1c8"), offY=25},
 StationMSG={Type="BasePart",Text="Power",Color=Color3.fromHex("#c6f1c8")},
 ShopMSG={Type="BasePart",Text="Shop",Color=Color3.fromHex("#c6f1c8")},
 ObservationTowerMSG={Type="BasePart",Text="Tower",Color=Color3.fromHex("#c6f1c8")},
 Scrap1={Type="Model",Root="Scrap",Text="Scrap 1",Color=Color3.fromHex("#aa8d4e")},
 Scrap2={Type="Model",Root="Scrap",Text="Scrap 2",Color=Color3.fromHex("#cca248")},
 Scrap3={Type="Model",Root="Scrap",Text="Scrap 3",Color=Color3.fromHex("#e2ae3c")},
 Scrap4={Type="Model",Root="Scrap",Text="Scrap 4",Color=Color3.fromHex("#ecca30")},
 Scrap5={Type="Model",Root="Scrap",Text="Scrap 5",Color=Color3.fromHex("#ffd000")},
 RakeTrapModel={Type="Model",Root="HitBox",Text="Trap",Color=Color3.fromHex("#ffd2d2")},
 Box={Type="Model",Root="HitBox",Text="Crate",Color=Color3.fromHex("#85e2ff")},
 SupplyCrate={Type="Model",Root="HitBox",Text="Crate",Color=Color3.fromHex("#85e2ff")}
}

local function fmt(s) 
    s=math.max(0,math.floor(s or 0))
    return ("%d:%02d"):format(math.floor(s/60),s%60) 
end

local function getModelFromInstance(i) 
    if not i then return end 
    if i:IsA("Model") then return i end 
    if i:IsA("BasePart") and i.Parent and i.Parent:IsA("Model") then return i.Parent end 
end

-- Simplified addObj with more safety
local function addObj(v)
    pcall(function()
        if not v then return end
        local model=getModelFromInstance(v)
        local addr = model and tostring(model) or tostring(v)
        if not addr or tempObj[addr] then return end
        
        -- Simple ESP entry check
        local entry = nil
        if model and espObj[model.Name] then
            entry = espObj[model.Name]
        end
        if not entry and model then
            local scrapIdx = tostring(model.Name):match("^Scrap(%d+)")
            if scrapIdx then
                local key = "Scrap"..tostring(tonumber(scrapIdx))
                entry = espObj[key]
            end
        end
        
        if not entry then return end
        
        local object = nil
        if entry.Type == "BasePart" and v:IsA("BasePart") then
            object = v
        elseif model then
            object = model:FindFirstChild(entry.Root, true)
        end
        
        if not object then return end
        
        local name = T{Text=entry.Text,Color=entry.Color,Outline=true,Center=true,Size=14,Font=FONT,Visible=false}
        if not name then return end
        
        tempObj[addr]=true
        table.insert(tList, {object=object, name=name, offY=entry.offY or 0})
    end)
end

local function updObj()
    pcall(function()
        -- Scan for objects
        local f=workspace:FindFirstChild("Filter")
        if f then 
            local s=f:FindFirstChild("ScrapSpawns") 
            if s then 
                for _,sp in pairs(s:GetChildren()) do 
                    if sp.Name:match("ItemSpawn") then 
                        for _,v in pairs(sp:GetChildren()) do addObj(v) end
                    end 
                end 
            end
            local l=f:FindFirstChild("LocationPoints") 
            if l then 
                for _,p in pairs(l:GetChildren()) do addObj(p) end
            end 
        end
        for _,v in pairs(workspace:GetChildren()) do 
            if v.Name=="FlareGunPickUp" or v.Name=="Rake" then addObj(v) end
        end
        local d=workspace:FindFirstChild("Debris") 
        if d then 
            local t=d:FindFirstChild("Traps") 
            if t then 
                for _,v in pairs(t:GetChildren()) do addObj(v) end
            end 
            local c=d:FindFirstChild("SupplyCrates") 
            if c then 
                for _,v in pairs(c:GetChildren()) do addObj(v) end
            end 
        end
    end)
end

local function updPos()
    pcall(function()
        if not toggle.esp then 
            for _,v in ipairs(tList) do 
                if v and v.name then v.name.Visible=false end
            end 
            if rakeRoofTitle then rakeRoofTitle.Visible=false end
            if rakeRoofValue then rakeRoofValue.Visible=false end
            return 
        end
        
        for i=#tList,1,-1 do 
            local v=tList[i]
            if not v or not v.object or not v.object.Parent then 
                if v and v.name then v.name:Remove() end
                table.remove(tList, i)
            else 
                local success, pos = pcall(function() return v.object.Position end)
                if success and pos then
                    local success2, s, on = pcall(WorldToScreen, pos)
                    if success2 and on and s then 
                        pcall(function() 
                            v.name.Position = Vector2.new(s.X, s.Y - 12 + (v.offY or 0))
                            v.name.Visible = true
                        end)
                    else 
                        pcall(function() v.name.Visible = false end)
                    end
                else
                    pcall(function() v.name.Visible = false end)
                end
            end 
        end
        
        if rakeRoofModel and rakeRoofHealth then
            local part = rakeRoofModel:FindFirstChildWhichIsA("BasePart",true)
            if part then 
                local success, s, on = pcall(WorldToScreen, part.Position)
                if success and on and s then 
                    if rakeRoofTitle then rakeRoofTitle.Position = Vector2.new(s.X, s.Y - 15) end
                    if rakeRoofValue then rakeRoofValue.Position = Vector2.new(s.X, s.Y - 3) end
                    if rakeRoofTitle then rakeRoofTitle.Visible = true end
                    if rakeRoofValue then rakeRoofValue.Visible = true end
                else 
                    if rakeRoofTitle then rakeRoofTitle.Visible = false end
                    if rakeRoofValue then rakeRoofValue.Visible = false end
                end
            else 
                if rakeRoofTitle then rakeRoofTitle.Visible = false end
                if rakeRoofValue then rakeRoofValue.Visible = false end
            end
        else 
            if rakeRoofTitle then rakeRoofTitle.Visible = false end
            if rakeRoofValue then rakeRoofValue.Visible = false end
        end
    end)
end

local function getCharacterFromPart(p) 
    while p do 
        if p:FindFirstChild("Humanoid") then return p end 
        p=p.Parent 
    end 
    return nil 
end

local RakeModel,TargetVal=nil,nil
spawn(function() 
    while true do 
        pcall(function()
            local r=workspace:FindFirstChild("Rake",true) 
            if r and r~=RakeModel then 
                RakeModel=r
                TargetVal=r:FindFirstChild("TargetVal")
            end
        end)
        task.wait(0.5) 
    end 
end)

-- Simplified connection handling
local currentPoints = nil
local currentConn = nil

local function tryHookPoints()
    pcall(function()
        if not lp then return end
        local bp = lp:FindFirstChild("Backpack") or lp:FindFirstChild("backpack")
        if bp then
            local sf = bp:FindFirstChild("ScrapFolder")
            local pts = sf and sf:FindFirstChild("Points")
            if pts and pts:IsA("IntValue") and pts ~= currentPoints then
                if currentConn then pcall(function() currentConn:Disconnect() end) end
                currentPoints = pts
                if scrapText then scrapText.Text = tostring(pts.Value) end
                currentConn = pts.Changed:Connect(function() 
                    if scrapText then scrapText.Text = tostring(pts.Value) end
                end)
            end
        end
    end)
end

local function tryHookRakeBreak()
    pcall(function()
        local map=workspace:FindFirstChild("Map")
        local safehouse=map and map:FindFirstChild("SafeHouse")
        local rakeBreak=safehouse and safehouse:FindFirstChild("RakeBreak",true)
        local breakModel=rakeBreak and rakeBreak:FindFirstChild("BreakModel",true)
        local health=breakModel and breakModel:FindFirstChild("Health",true)
        if breakModel and health and health:IsA("IntValue") then
            if health~=rakeRoofHealth then 
                if rakeRoofConn then pcall(function() rakeRoofConn:Disconnect() end) end
                rakeRoofModel=breakModel
                rakeRoofHealth=health
                if rakeRoofValue then rakeRoofValue.Text="["..tostring(health.Value).."/30]" end
                rakeRoofConn=health.Changed:Connect(function() 
                    if rakeRoofValue then rakeRoofValue.Text="["..tostring(health.Value).."/30]" end
                end)
            end
        else
            if rakeRoofConn then pcall(function() rakeRoofConn:Disconnect() end) end
            rakeRoofModel=nil
            rakeRoofHealth=nil
        end
    end)
end

spawn(function() 
    while true do 
        tryHookPoints()
        tryHookRakeBreak()
        task.wait(0.5) 
    end 
end)

spawn(function()
    while true do
        pcall(function()
            if TimerValue and timerText then 
                timerText.Text = fmt(TimerValue.Value)
                timerText.Color = TimerValue.Value <= 15 and Color3.fromHex("#c44b4b") or Color3.fromHex("#ffffff")
            end
            if PPMS and ppmsText then
                if StationPower and StationPower.Value == false then 
                    ppmsText.Text = "Blackout"
                    ppmsText.Color = Color3.fromHex("#dac6ac")
                else 
                    ppmsText.Text = string.format("%.2f", PPMS.Value)
                    ppmsText.Color = Color3.fromHex("#ffffff")
                end
            end
        end)
        task.wait(0.1)
    end
end)

spawn(function()
    while true do
        pcall(function()
            if RadioChannel then
                for i=1,7 do
                    local f=RadioChannel:FindFirstChild("Line"..i)
                    local n,m="",""
                    if f then
                        local nv=f:FindFirstChild("Name")
                        local mg=f:FindFirstChild("Msg")
                        if nv and nv.Value~=nil then n=tostring(nv.Value) end
                        if mg and mg.Value~=nil then m=tostring(mg.Value) end
                    end
                    if radLine[i] then
                        if radLine[i].name then radLine[i].name.Text=n end
                        if radLine[i].msg then radLine[i].msg.Text=m end
                        if radLine[i].name then radLine[i].name.Visible=toggle.hud end
                        if radLine[i].msg then radLine[i].msg.Visible=toggle.hud end
                    end
                end
            end

            -- Update power lines
            for bn,l in pairs(powerLines) do
                if l and pwrValue then
                    local vv=pwrValue:FindFirstChild(bn)
                    l.Visible = toggle.hud and vv and vv.Value or false
                end
            end
            
            -- Update mod list
            local count=0
            for i,entry in ipairs(modList) do 
                local p=Players:FindFirstChild(entry) 
                if p and modLines[i] then 
                    count=count+1
                    modLines[i].Text=p.Name
                    modLines[i].Visible=toggle.hud
                elseif modLines[i] then 
                    modLines[i].Visible=false
                end 
            end
            if modLabel then modLabel.Visible = toggle.hud and count>0 end
            
            if TargetVal and TargetVal.Value and TargetVal.Value:IsA("Part") then 
                local c=getCharacterFromPart(TargetVal.Value)
                if targetPlayerText then targetPlayerText.Text = c and c.Name or "Unknown" end
            elseif targetPlayerText then 
                targetPlayerText.Text = "None"
            end
        end)
        task.wait(0.5)
    end
end)

-- Start with delay to prevent startup crash
task.wait(1)
spawn(function() while true do pcall(updObj); task.wait(1) end end)
spawn(function() while true do pcall(updPos); task.wait() end end)

-- Keybind loop with delay
task.wait(0.5)
spawn(function() 
    while true do 
        pcall(function()
            if iskeypressed(0x70) then 
                if not keyHeld.f1 then 
                    keyHeld.f1=true
                    toggle.esp=not toggle.esp
                    for _,v in ipairs(tList) do 
                        if v and v.name then v.name.Visible=false end
                    end 
                end 
            else 
                keyHeld.f1=false 
            end 
            
            if iskeypressed(0x71) then 
                if not keyHeld.f2 then 
                    keyHeld.f2=true
                    toggle.hud=not toggle.hud
                    for _,o in ipairs(hudObjects) do 
                        if o then o.Visible=toggle.hud end
                    end 
                end 
            else 
                keyHeld.f2=false 
            end 
        end)
        task.wait() 
    end 
end)

print(("saint | version %s"):format(vs))
print("F1 toggles ESP, F2 toggles HUD.")
