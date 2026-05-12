local Players,ReplicatedStorage=game:GetService("Players"),game:GetService("ReplicatedStorage")
local lp=Players.LocalPlayer; local vs="1.3 [02/22]"
local workspace,Drawing,WorldToScreen,ipairs,pairs,task=workspace,Drawing,WorldToScreen,ipairs,pairs,task
local toggle={esp=true,hud=true}; local keyHeld={f1=false,f2=false}
local function newText(p)local t=Drawing.new("Text"); for k,v in pairs(p) do t[k]=v end return t end
local FONT=Drawing.Fonts.System
local function T(p)p.Font=FONT; p.Outline=true; return newText(p) end

local TimerValue=ReplicatedStorage:WaitForChild("Timer")
local pwrValue=ReplicatedStorage:WaitForChild("PowerValues")
local PPMS=pwrValue:WaitForChild("PPMS")
local RadioChannel=ReplicatedStorage:WaitForChild("RadioChannel")
local StationPower=ReplicatedStorage:WaitForChild("StationPower")

local pSM={UsingSHDoor="House door is locked",UsingSHLight="House lights are on",UsingTowerLight="Tower floodlights are on",UsingTowerRadar="Tower radar is active"}
local cam=workspace.CurrentCamera
local function anc() local v=cam.ViewportSize; return Vector2.new(v.X/2,v.Y-80),Vector2.new(70,v.Y-240),Vector2.new(v.X-200,v.Y-100) end

local timerText=T{Center=true,Size=21,Color=Color3.fromHex("#ffffff"),Text="",Visible=true}
local ppmsText=T{Center=true,Size=21,Color=Color3.fromHex("#ffffff"),Text="",Visible=true}
local scrapText=T{Center=true,Size=21,Color=Color3.fromHex("#ffffff"),Text="",Visible=true}
local targetPlayerText=T{Center=true,Size=19,Color=Color3.fromHex("#ffffff"),Text="None",Visible=true}
local timerLabel=T{Center=true,Size=15,Color=Color3.fromHex("#eeeeee"),Text="TIME REMAINING",Visible=true}
local ppmsLabel=T{Center=true,Size=15,Color=Color3.fromHex("#ffce8f"),Text="POWER USAGE",Visible=true}
local scrapLabel=T{Center=true,Size=15,Color=Color3.fromHex("#fff88f"),Text="SALVAGE VALUE",Visible=true}
local targetTitle=T{Center=true,Size=15,Color=Color3.fromHex("#c44b4b"),Text="RAKE'S TARGET",Visible=true}

local pwrLabel=T{Center=false,Size=22,Color=Color3.fromHex("#ffce8f"),Text="POWER ACTIVITY",Visible=false}
local powerLines,pwrLH={},18
for k,v in pairs(pSM) do powerLines[k]=T{Center=false,Size=15,Color=Color3.fromHex("#ffffff"),Text=v,Visible=false} end

local radioTitle=T{Center=false,Size=22,Color=Color3.fromHex("#cbffcf"),Text="RADIO ACTIVITY",Visible=true}
local radLine={}; local LINE_H=20
for i=1,7 do radLine[i]={name=T{Center=false,Size=13,Color=Color3.fromHex("#b6b6b6"),Text="",Visible=true}, msg=T{Center=false,Size=13,Color=Color3.fromHex("#ffffff"),Text="",Visible=true}} end

local rakeRoofTitle=T{Center=true,Size=14,Color=Color3.fromHex("#c0e8ff"),Text="Roof Debris",Visible=false}
local rakeRoofValue=T{Center=true,Size=12,Color=Color3.fromHex("#ebebeb"),Text="",Visible=false}
local rakeRoofModel, rakeRoofHealth, rakeRoofConn = nil, nil, nil

local hudObjects={timerText,ppmsText,scrapText,targetPlayerText,timerLabel,ppmsLabel,scrapLabel,targetTitle,radioTitle}
for i=1,7 do hudObjects[#hudObjects+1]=radLine[i].name; hudObjects[#hudObjects+1]=radLine[i].msg end

function upPwrPos() local _,_,r=anc(); pwrLabel.Position=r-Vector2.new(50,0); local off=0; for _,line in pairs(powerLines) do if line.Visible then off=off+1; line.Position=pwrLabel.Position-Vector2.new(0,off*pwrLH) end end end

local modLH=18
local modList={"Aitareis","Mr68Moth","ZZZXIIIXZZZ","TZZV","RlFLEM4N","FelixVenue","DeliverCreations","z_papermoon","r3shape","ARRYvvv"}
local modLabel=T{Center=false,Size=22,Color=Color3.fromHex("#ff97f6"),Text="STAFF DETECTED",Visible=false}
local modLines={} for i=1,#modList do modLines[i]=T{Center=false,Size=18,Color=Color3.fromHex("#ffffff"),Text="",Visible=false} end
function upStaffPos() local _,_,r=anc(); modLabel.Position=r-Vector2.new(50,120); local off=0; for i=1,#modLines do local line=modLines[i]; if line.Visible then off=off+1; line.Position=modLabel.Position-Vector2.new(0,off*modLH) end end end

local function updHudPos()
  local c,l=anc(); local spacing=130
  timerText.Position = c + Vector2.new(-1.5*spacing,-30)
  ppmsText.Position  = c + Vector2.new(-0.5*spacing,-30)
  targetPlayerText.Position = c + Vector2.new(0.5*spacing,-30)
  scrapText.Position = c + Vector2.new(1.5*spacing,-30)
  timerLabel.Position = timerText.Position + Vector2.new(0,18)
  ppmsLabel.Position  = ppmsText.Position + Vector2.new(0,18)
  scrapLabel.Position = scrapText.Position + Vector2.new(0,18)
  targetTitle.Position = targetPlayerText.Position + Vector2.new(0,18)
  radioTitle.Position = l + Vector2.new(-1,140)
  for i=1,7 do local y=l.Y+(i-1)*LINE_H; radLine[i].name.Position=Vector2.new(l.X,y); radLine[i].msg.Position=Vector2.new(l.X+70,y) end
  upPwrPos(); upStaffPos()
end

updHudPos(); upPwrPos(); upStaffPos()

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

local function fmt(s) s=math.max(0,math.floor(s)); return ("%d:%02d"):format(math.floor(s/60),s%60) end
local function getModelFromInstance(i) if not i then return end if i:IsA("Model") then return i end if i:IsA("BasePart") and i.Parent and i.Parent:IsA("Model") then return i.Parent end end
local function safeAddress(i) if not i then return end if i.Address then return i.Address end return tostring(i) end

local STUDS_TO_METERS = 1/3.5714285714

local function updatePowerLinesVisibility()
  local anyVisible=false
  for bn,l in pairs(powerLines) do
    local vv=pwrValue and pwrValue:FindFirstChild(bn)
    l.Visible = toggle.hud and vv and vv.Value or false
    if l.Visible then anyVisible=true end
  end
  pwrLabel.Visible = toggle.hud and anyVisible
  upPwrPos()
end

local function addObj(v)
 if not v then return end
 local model=getModelFromInstance(v)
 local addr=(model and safeAddress(model)) or safeAddress(v)
 if not addr or tempObj[addr] then return end
 local entry,object,modelRec=nil,nil,model
 if model and espObj[model.Name] then local e=espObj[model.Name]; if not e.ExactName or model.Name=="FlareGunPickUp" then entry=e end end
 if not entry and model then local scrapIdx=tostring(model.Name):match("^Scrap(%d+)") if scrapIdx then local key="Scrap"..tostring(tonumber(scrapIdx)) if espObj[key] then entry=espObj[key] end end end
 if not entry then
  for name,e in pairs(espObj) do
   if e.Root then
    local src=model or (v.Parent and v.Parent:IsA("Model") and v.Parent)
    if src then
     if name=="FlareGunPickUp" then
      if src.Name=="FlareGunPickUp" then local f=src:FindFirstChild(e.Root,true) if f and f:IsA("BasePart") then entry=e; object=f; modelRec=src; break end end
     else local f=src:FindFirstChild(e.Root,true) if f and f:IsA("BasePart") then entry=e; object=f; modelRec=src; break end end
    end
   end
  end
 end
 if not entry then return end
 if model and model.Name=="SupplyCrate" then if not model:FindFirstChild(entry.Root,true) then local inner=model:FindFirstChild("Box") if inner and inner:IsA("Model") then modelRec=inner end end end
 object=object or (entry.Type=="BasePart" and v:IsA("BasePart") and v) or (modelRec and modelRec:FindFirstChild(entry.Root,true))
 if not object then return end
 local recAddr=safeAddress(modelRec or object)
 if not recAddr or tempObj[recAddr] then return end
 local off = entry.offY or 0
 local name=newText{Text=entry.Text,Color=entry.Color,Outline=true,Center=true,Size=14,Font=FONT,Visible=false}
 tempObj[recAddr]=true
 tList[#tList+1]={object=object,model=modelRec or object.Parent,name=name,Address=recAddr,offY=off}
end

-- FIXED: Added pcall and better error handling
local function updObj()
 pcall(function()
  local f=workspace:FindFirstChild("Filter")
  if f then 
   local s=f:FindFirstChild("ScrapSpawns") 
   if s then 
    for _,sp in pairs(s:GetChildren()) do 
     if sp.Name:match("ItemSpawn") then 
      for _,v in pairs(sp:GetChildren()) do 
       pcall(function() addObj(v) end)
      end 
     end 
    end 
   end
   local l=f:FindFirstChild("LocationPoints") 
   if l then 
    for _,p in pairs(l:GetChildren()) do 
     pcall(function() addObj(p) end)
    end 
   end 
  end
  for _,v in pairs(workspace:GetChildren()) do 
   if v.Name=="FlareGunPickUp" or v.Name=="Rake" then 
    pcall(function() addObj(v) end)
   end 
  end
  local d=workspace:FindFirstChild("Debris") 
  if d then 
   local t=d:FindFirstChild("Traps") 
   if t then 
    for _,v in pairs(t:GetChildren()) do 
     pcall(function() addObj(v) end)
    end 
   end 
   local c=d:FindFirstChild("SupplyCrates") 
   if c then 
    for _,v in pairs(c:GetChildren()) do 
     pcall(function() addObj(v) end)
    end 
   end 
  end
 end)
end

-- FIXED: Added nil check before WorldToScreen
local function updPos()
 if not toggle.esp then 
  for _,v in ipairs(tList) do 
   pcall(function() v.name.Visible=false end)
  end 
  rakeRoofTitle.Visible=false; rakeRoofValue.Visible=false
  return 
 end
 
 for i=#tList,1,-1 do 
  local v=tList[i]
  if not v then 
   tList[i]=nil
   break
  end
  local o=v.object
  if not o or not o.Parent then 
   pcall(function() v.name:Remove() end)
   tempObj[v.Address]=nil
   tList[i]=tList[#tList]
   tList[#tList]=nil
  else 
   local s,on
   pcall(function()
    local p=o.Position
    if p and typeof(p)=="Vector3" then
     s,on=WorldToScreen(p)
    end
   end)
   if on and s then 
    local y=v.offY or 0
    pcall(function() v.name.Position=Vector2.new(s.X, s.Y - 12 + y) end)
    pcall(function() v.name.Visible=true end)
   else 
    pcall(function() v.name.Visible=false end)
   end 
  end 
 end
 
 if rakeRoofModel and rakeRoofHealth then
   local part=rakeRoofModel:FindFirstChildWhichIsA("BasePart",true)
   if part then 
    local s,on
    pcall(function()
     s,on=WorldToScreen(part.Position)
    end)
    if on and s then 
     rakeRoofTitle.Position=Vector2.new(s.X, s.Y - 15)
     rakeRoofValue.Position=Vector2.new(s.X, s.Y - 3)
     rakeRoofTitle.Visible=toggle.esp
     rakeRoofValue.Visible=toggle.esp
    else 
     rakeRoofTitle.Visible=false
     rakeRoofValue.Visible=false
    end 
   else 
    rakeRoofTitle.Visible=false
    rakeRoofValue.Visible=false
   end
 else 
  rakeRoofTitle.Visible=false
  rakeRoofValue.Visible=false
 end
end

local function getCharacterFromPart(p) 
 while p do 
  if p:FindFirstChild("Humanoid") then 
   return p 
  end 
  p=p.Parent 
 end 
 return nil 
end

local RakeModel,TargetVal=nil,nil
spawn(function() 
 while true do 
  pcall(function()
   local r=workspace:FindFirstChild("Rake",true) 
   if r~=RakeModel then 
    RakeModel=r
    TargetVal=r and r:FindFirstChild("TargetVal") or nil 
   elseif r then 
    local tv=r:FindFirstChild("TargetVal") 
    if tv~=TargetVal then 
     TargetVal=tv 
    end 
   end
  end)
  task.wait(0.5) 
 end 
end)

local playerChildConn,backpackChildConn=nil,nil
local currentPoints,currentConn=nil,nil

local function disconnectCurrent()
  if currentConn then pcall(function() currentConn:Disconnect() end) currentConn=nil end
  if backpackChildConn then pcall(function() backpackChildConn:Disconnect() end) backpackChildConn=nil end
  if playerChildConn then pcall(function() playerChildConn:Disconnect() end) playerChildConn=nil end
end

local function tryHookPoints()
  if not lp then return end
  pcall(function()
   local bp = lp:FindFirstChild("Backpack") or lp:FindFirstChild("backpack")
   if bp then
    local sf = bp:FindFirstChild("ScrapFolder")
    local pts = sf and sf:FindFirstChild("Points")
    if pts and pts:IsA("IntValue") then
     if pts~=currentPoints then
      disconnectCurrent()
      currentPoints=pts
      scrapText.Text=tostring(pts.Value)
      local ok,conn = pcall(function() return pts.Changed:Connect(function() scrapText.Text=tostring(pts.Value) end) end)
      if ok and conn then currentConn=conn end
     end
    else
     if not backpackChildConn then
      local ok,conn = pcall(function() return bp.ChildAdded:Connect(function(child) if child.Name=="ScrapFolder" then task.wait(0.02); tryHookPoints() end end) end)
      if ok and conn then backpackChildConn=conn end
     end
    end
   else
    if not playerChildConn then
     local ok,conn = pcall(function() return lp.ChildAdded:Connect(function(child) if child.Name=="Backpack" or child.Name=="backpack" then task.wait(0.02); tryHookPoints() end end) end)
     if ok and conn then playerChildConn=conn end
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
     if rakeRoofConn then pcall(function() rakeRoofConn:Disconnect() end) rakeRoofConn=nil end
     rakeRoofModel=breakModel
     rakeRoofHealth=health
     rakeRoofValue.Text="["..tostring(health.Value).."/30]"
     local ok,conn=pcall(function() return health.Changed:Connect(function() rakeRoofValue.Text="["..tostring(health.Value).."/30]" end) end)
     if ok and conn then rakeRoofConn=conn end
    end
   else
    if rakeRoofConn then pcall(function() rakeRoofConn:Disconnect() end) rakeRoofConn=nil end
    rakeRoofModel=nil
    rakeRoofHealth=nil
   end
  end)
end

spawn(function() while true do tryHookPoints(); tryHookRakeBreak(); task.wait(0.1) end end)

spawn(function()
 local last=cam.ViewportSize
 while true do
  pcall(function()
   if cam.ViewportSize~=last then last=cam.ViewportSize; updHudPos() end
   local t=TimerValue.Value
   timerText.Text=fmt(t)
   timerText.Color=t<=15 and Color3.fromHex("#c44b4b") or Color3.fromHex("#ffffff")
   if StationPower and StationPower.Value==false then 
    ppmsText.Text="Blackout"
    ppmsText.Color=Color3.fromHex("#dac6ac")
   else 
    ppmsText.Text=string.format("%.2f",PPMS.Value)
    ppmsText.Color=Color3.fromHex("#ffffff")
   end
   timerLabel.Position=timerText.Position+Vector2.new(0,18)
   ppmsLabel.Position=ppmsText.Position+Vector2.new(0,18)
  end)
  task.wait(0.1)
 end
end)

spawn(function()
 while true do
  pcall(function()
   for i=1,7 do
    local f=RadioChannel:FindFirstChild("Line"..i)
    local n,m=""
    if f then
     local nv=f:FindFirstChild("Name")
     local mg=f:FindFirstChild("Msg")
     if nv and nv.Value~=nil then local s=tostring(nv.Value); n=(#s>10 and s:sub(1,10) or s) end
     if mg and mg.Value~=nil then local s=tostring(mg.Value); m=(#s>70 and s:sub(1,70).."..." or s) end
    end
    radLine[i].name.Text=n
    radLine[i].msg.Text=m
    radLine[i].name.Visible=toggle.hud
    radLine[i].msg.Visible=toggle.hud
   end

   updatePowerLinesVisibility()

   local count=0
   for i,entry in ipairs(modList) do 
    local p=nil 
    if entry then p=Players:FindFirstChild(entry) end 
    if p then 
     count=count+1
     modLines[i].Text=p.Name
     modLines[i].Visible=toggle.hud
    else 
     modLines[i].Visible=false
    end 
   end
   modLabel.Visible=toggle.hud and count>0
   upStaffPos()
   
   local h=TargetVal and TargetVal.Value 
   if h and h:IsA("Part") then 
    local c=getCharacterFromPart(h)
    targetPlayerText.Text=c and c.Name or "Unknown"
   else 
    targetPlayerText.Text="None"
   end
   scrapText.Visible=toggle.hud
   scrapLabel.Visible=toggle.hud
  end)
  task.wait(0.5)
 end
end)

spawn(function() while true do pcall(updObj); task.wait(0.5) end end)

-- FIXED: Added pcall to main loop
spawn(function() 
 while true do 
  pcall(function()
   updPos()
   if iskeypressed(0x70) then 
    if not keyHeld.f1 then 
     keyHeld.f1=true
     toggle.esp=not toggle.esp
     for _,v in ipairs(tList) do 
      pcall(function() v.name.Visible=false end)
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
      pcall(function() o.Visible=toggle.hud end)
     end 
     updatePowerLinesVisibility()
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
