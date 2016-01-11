local ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1100)
local VP = nil
local Target = nil

local skinsPB = {};
local skinObjectPos = nil;
local skinHeader = nil;
local dispellHeader = nil;
local skinH = nil;
local skinHPos = nil;

if (string.find(GetGameVersion(), 'Releases/5.24') ~= nil) then
	skinsPB = {
		[1] = 0xCA,
		[10] = 0x68,
		[8] = 0xE8,
		[4] = 0xF8,
		[12] = 0xD8,
		[5] = 0xB8,
		[9] = 0xA8,
		[7] = 0x38,
		[3] = 0x0C,
		[11] = 0x28,
		[6] = 0x78,
		[2] = 0x4C,
	};
	skinObjectPos = 6;
	skinHeader = 0x3A;
	dispellHeader = 0xB7;
	skinH = 0x8C;
	skinHPos = 32;
elseif (string.find(GetGameVersion(), 'Releases/5.23') ~= nil) then
		skinsPB = {
			[1] = 0x74,
			[10] = 0x04,
			[8] = 0x14,
			[4] = 0x34,
			[12] = 0x44,
			[5] = 0x54,
			[9] = 0x84,
			[7] = 0x94,
			[3] = 0xB4,
			[11] = 0xC4,
			[6] = 0xD4,
			[2] = 0xF4,
		};
		skinObjectPos = 16;
		skinHeader = 0x13;
		dispellHeader = 0x13B;
		skinH = 0x74;
		skinHPos = 11;
end;

local initBall = false;
local ballCreated = false;
local ballNetworkID = nil;
local lastFormSeen = nil;
local cougarForm = false;
local spiderForm = false;
local lastTimeTickCalled = 0;
local lastSkin = 0;

local walker = "Hotkeys integrated with your SxOrbWalker Keys";

require "VPrediction"


local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/CooLowbro/BoL/master/SHM.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function _AutoupdaterMsg(msg) 
print("<b><font color=\"#FF0000\">Brand name TBD:</font></b> <font color=\"#FFFFFF\">"..msg.."</font>") 
end
if AUTOUPDATE then
  local ServerData = GetWebResult(UPDATE_HOST, "/CooLowbro/BoL/master/SHM.version")
  if ServerData then
    ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
    if ServerVersion then
      if tonumber(version) < ServerVersion then
        _AutoupdaterMsg("New version available "..ServerVersion)
        _AutoupdaterMsg("Updating, please don't press F9")
        DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () _AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
      else
        _AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
      end
    end
  else
    _AutoupdaterMsg("Error downloading version info")
  end
end

function OnLoad()
	if myHero.charName == "Brand" and tonumber(version) == ServerVersion then
		print("<b><font color=\"#FF0000\">Brand NAME TBD HERE"..version.." loaded!</b></font>")
		InitMenu()
		
		_G.oldDrawCircle = rawget(_G, 'DrawCircle')
		_G.DrawCircle = DrawCircle2

		SendSkinPacket(myHero.charName, skinsPB[Menu['selected' .. myHero.charName .. 'Skin']], myHero.networkID);
		
		Orbwalker()
		VP = VPrediction()
	elseif myHero.charName ~= "Brand" then
		print("<b><font color=\"#FF0000\">Sorry, this script is not supported for this champion!</b></font>")
		return    
	end
end

function OnTick()
	if obwwillwork == true then
		QREADY = (myHero:CanUseSpell(_Q) == READY)
		WREADY = (myHero:CanUseSpell(_W) == READY)
		EREADY = (myHero:CanUseSpell(_E) == READY)
		RREADY = (myHero:CanUseSpell(_R) == READY)
		Target = GetTarget()
		GetTarget()
		ComboMode()
		HarassMode()
		SkinStuff()
		
		if not Menu.draw.LagFree then _G.DrawCircle = _G.oldDrawCircle end
		if Menu.draw.LagFree then
			_G.DrawCircle = DrawCircle2
		end
	end
end

function CastQ()
	if QREADY and ValidTarget(Target) then
		if TargetHaveBuff("brandablaze", Target) then
			local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, 0.25, 50, 1100, 1550, myHero, true)
			if CastPosition and HitChance >= Menu.misc.QHitChance and GetDistance(CastPosition) < 1100 then
				CastSpell(_Q, CastPosition.x, CastPosition.z)
			end
		end
	end
end

function CastE()
	if EREADY and ValidTarget(Target) then
		CastSpell(_E, Target)	
	end
end

function CastW()
	if WREADY and ValidTarget(Target) then
		local CastPosition, HitChance, Position = VP:GetCircularCastPosition(Target, .875, 250, 1000)
		if CastPosition and HitChance >= Menu.misc.WHitChance and GetDistance(CastPosition) < 1000 then
			CastSpell(_W, CastPosition.x, CastPosition.z)
		end
	end
end

function CastR()
	if RREADY and ValidTarget(Target) then
		if GetRDmg(Target) > Target.health then
			CastSpell(_R, Target)	
		end
	end
end

function ComboMode()
	if ComboKey() then
		if Menu.combo.useE then
			CastE()
		end 

		if Menu.combo.useQ then
			CastQ()
		end 

		if Menu.combo.useW then
			CastW()
		end  
		
		if Menu.combo.useR then
			CastR()
		end
	end
end

function HarassMode()
  if HarassKey() then
	if Menu.harass.useQ and (((myHero.mana /  myHero.maxMana) * 100) > Menu.harass.QMana) then
      CastQ()
    end  
	
    if Menu.harass.useW and (((myHero.mana /  myHero.maxMana) * 100) > Menu.harass.WMana) then
      CastW()
    end  
  end
end

function GetRDmg(unit)
   local sLvl = 1
   if sLvl < 1 then return 0 end
   local baseDmg = {150,250,350}
   local scaledDmg = {.5,.5, .5}
   local trueDmg = baseDmg[sLvl] + scaledDmg[sLvl]*myHero.ap
   local finalDmg = unit.healthHealth * .08 + trueDmg
   return myHero:CalcMagicDamage(unit, finalDmg)
end

function InitMenu()
	Menu = scriptConfig("Brand", "BRD")
	
	Menu:addSubMenu("Drawing Menu", "draw")
	Menu.draw:addParam("LagFree", "Activate Lag Free Circles", 1, true)
	Menu.draw:addParam("q", "Draw Q Range", 1, true)
	Menu.draw:addParam("w", "Draw W Range", 1, false)
	Menu.draw:addParam("e", "Draw E Range", 1, false)
	Menu.draw:addParam("r", "Draw R Range", 1, false)
	Menu.draw:addParam("aa", "Draw AA Range", 1, true)
	
	Menu:addSubMenu("Orbwalker Settings","obwc")
	
	Menu:addSubMenu("Hotkeys","hotkeys")
	Menu.hotkeys:addParam("checkhk", "Use Custom Combat Keys", SCRIPT_PARAM_ONOFF, false)
	Menu.hotkeys:setCallback("checkhk",
	function(v)
	if v == true then
		Menu.hotkeys:removeParam("hkcon")
		Menu.hotkeys:removeParam("hkcon")
		Menu.hotkeys:addParam("combo", "Combo Mode", SCRIPT_PARAM_ONKEYDOWN, false, string.byte(" "))
		Menu.hotkeys:addParam("harass", "Harass Mode", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Menu.hotkeys:addParam("laneclear", "Lane Clear Mode", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
		Menu.hotkeys:addParam("lasthit", "Last Hit", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	elseif v == false then
		Menu.hotkeys:addParam("hkcon", walker, SCRIPT_PARAM_INFO, "")
		Menu.hotkeys:removeParam("combo")
		Menu.hotkeys:removeParam("harass")
		Menu.hotkeys:removeParam("laneclear")
		Menu.hotkeys:removeParam("lasthit")
	end
	end)

	if Menu.hotkeys.checkhk == true then
		Menu.hotkeys:addParam("combo", "Combo Mode", SCRIPT_PARAM_ONKEYDOWN, false, string.byte(" "))
		Menu.hotkeys:addParam("harass", "Harass Mode", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Menu.hotkeys:addParam("laneclear", "Lane Clear Mode", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
		Menu.hotkeys:addParam("lasthit", "Last Hit", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	end
	
	Menu:addSubMenu("Combo Settings", "combo")
	Menu.combo:addParam("useQ", "Use Q in Combo", 1, true)
	Menu.combo:addParam("useW", "Use W in Combo", 1, true)
	Menu.combo:addParam("useE", "Use E in Combo", 1, true)
	Menu.combo:addParam("useR", "Use R in Combo", 1, true)
	
	Menu:addSubMenu("Harass Settings", "harass")
	Menu.harass:addParam("QMana", "Q Mana Management", SCRIPT_PARAM_SLICE, 40, 1, 100, decimalPlace)
	Menu.harass:addParam("WMana", "W Mana Management", SCRIPT_PARAM_SLICE, 40, 1, 100, decimalPlace)
	Menu.harass:addParam("useQ", "Use Q in Harass", 1, true)
	Menu.harass:addParam("useW", "Use W in Harass", 1, true)
	Menu.harass:addParam("useE", "Use E in Harass", 1, false)
	Menu.harass:addParam("useR", "Use R in Harass", 1, false)
	
	Menu:addSubMenu("Misc. Settings", "misc")
	Menu.misc:addParam("WHitChance", "W Hit Chance", SCRIPT_PARAM_SLICE, 2, 1, 2, decimalPlace)
	Menu.misc:addParam("QHitChance", "Q Hit Chance", SCRIPT_PARAM_SLICE, 2, 1, 2, decimalPlace)
	
	Menu:addParam("", "", 5, "")
	Menu:addParam('selected' .. myHero.charName .. 'Skin', 'Skin Changer', SCRIPT_PARAM_LIST, 1,skinMeta[myHero.charName]);	
end



function Orbwalker()
  print("<b><font color=\"#FF0000\">Checking for external Orbwalkers! Please wait!</b></font>")
  DelayAction(
    function()
      -- MMA      
      if _G.MMA_Loaded ~= nil then
      print("<b><font color=\"#FF0000\">MMA Detected! Disabling SxOrbWalker!</b></font>")
      Menu.obwc:addParam("mmafd", "MMA Detected", SCRIPT_PARAM_INFO)
	  walker = "Hotkeys integrated with your MMA Keys"
	  Menu.hotkeys:addParam("hkcon", "Hotkeys integrated with your MMA Keys", SCRIPT_PARAM_INFO, "")
      MMA = true
      obwwillwork = true
      -- SAC R
      elseif _G.AutoCarry ~= nil then
      print("<b><font color=\"#FF0000\">SAC:R Detected</b></font>")
      Menu.obwc:addParam("sacfd", "SAC:R Detected", SCRIPT_PARAM_INFO, "")
	  Menu.hotkeys:addParam("hkcon", "Hotkeys integrated with your SAC:R Keys", SCRIPT_PARAM_INFO, "")
	  walker = "Hotkeys integrated with your SAC:R Keys"
      SAC = true
      obwwillwork = true
      -- SxOrbWalker
      elseif FileExist(obw_PATH) then
      print("<b><font color=\"#FF0000\">No external orbwalker found! Activating SxOrbWalker!</b></font>")
      require("SxOrbwalk")
      SxOrb:LoadToMenu(Menu.obwc)
	  Menu.hotkeys:addParam("hkcon", "Hotkeys integrated with your SxOrbWalker Keys", SCRIPT_PARAM_INFO, "")
	  walker = "Hotkeys integrated with your SxOrbWalker Keys"
      SX = true
      obwwillwork = true
      elseif not FileExist(obw_PATH) then
      obwwillwork = false
      print("<b><font color=\"#FF0000\">Downloading SxOrbWalker. Dont press 2xF9! Please wait!</b></font>")      
      --DownloadFile(obw_URL, obw_PATH, function() AutoupdaterMsg("<b><font color=\"#FF0000\">SxOrbWalker downloaded, please reload (2xF9)</b></font>") end)
      return
      end
    end, 10)
end
function LHKey()
  if not Menu.hotkeys.checkhk then
    if SX then
      return SxOrb.isLastHit
    elseif SAC then
      return _G.AutoCarry.Keys.LastHit
    elseif MMA then
      return _G.MMA_IsLastHitting()
    end
  else
    return Menu.hotkeys.lasthit
  end
end
function ComboKey()
  if not Menu.hotkeys.checkhk then
    if SX then
        return SxOrb.isFight
    elseif SAC then
        return _G.AutoCarry.Keys.AutoCarry
    elseif MMA then
        return _G.MMA_IsOrbwalking()
    end
  else
    return Menu.hotkeys.combo
  end
end
function HarassKey()
  if not Menu.hotkeys.checkhk then
    if SX then
        return SxOrb.isHarass
    elseif SAC then
        return _G.AutoCarry.Keys.MixedMode
    elseif MMA then
        return _G.MMA_IsDualCarrying()
    end
  else
    return Menu.hotkeys.harass
  end
end
function LCKey()
  if not Menu.hotkeys.checkhk then
    if SX then
        return SxOrb.isLaneClear
    elseif SAC then
        return _G.AutoCarry.Keys.LaneClear
    elseif MMA then
        return _G.MMA_IsLaneClearing()
    end
  else
    return Menu.hotkeys.laneclear
  end
end
function GetTarget()
  ts:update()
  if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
  if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
  return ts.target
end
function OnDraw()
	if Menu.draw.q and QREADY then
		DrawCircle(myHero.x,myHero.y,myHero.z, 1100, ARGB(255,255,255,255))
	end
	
	if Menu.draw.w and WREADY then
		DrawCircle(myHero.x,myHero.y,myHero.z, 1000, ARGB(255,255,255,255))
	end
	
	if Menu.draw.e and EREADY then
		DrawCircle(myHero.x,myHero.y,myHero.z, 700, ARGB(255,255,255,255))
	end
	
	if Menu.draw.r and RREADY then
		DrawCircle(myHero.x,myHero.y,myHero.z, 800, ARGB(255,255,255,255))
	end
	
	if Menu.draw.aa then
		DrawCircle(myHero.x,myHero.y,myHero.z, 650, ARGB(255,255,255,255))
	end
end
function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
    radius = radius or 300
  quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end
function round(num) 
 if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end
function DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        DrawCircleNextLvl(x, y, z, radius, 1, color, 150) 
    end
end
function OnUnload()
	SendSkinPacket(myHero.charName, nil, myHero.networkID);
end;
function SkinStuff()
	if ((CurrentTimeInMillis() - lastTimeTickCalled) > 200) then
		lastTimeTickCalled = CurrentTimeInMillis();
		if (Menu['selected' .. myHero.charName .. 'Skin'] ~= lastSkin) then
			lastSkin = Menu['selected' .. myHero.charName .. 'Skin'];				
				SendSkinPacket(myHero.charName, skinsPB[Menu['selected' .. myHero.charName .. 'Skin']], myHero.networkID);
		end;
	end;
end
function SendSkinPacket(mObject, skinPB, networkID)
	if (string.find(GetGameVersion(), 'Releases/5.24') ~= nil) then
		local mP = CLoLPacket(0x3A);

    mP.vTable = 0xF351B0;
		mP:EncodeF(myHero.networkID);

		for I = 1, string.len(mObject) do
			mP:Encode1(string.byte(string.sub(mObject, I, I)));
		end;

		for I = 1, (16 - string.len(mObject)) do
			mP:Encode1(0x00);
		end;

		mP:Encode4(0x0000000E);
		mP:Encode4(0x0000000F);
    mP:Encode2(0x0000);
		
		if (skinPB == nil) then
			mP:Encode4(0x82828282);
		else
			mP:Encode1(skinPB);
			for I = 1, 3 do
				mP:Encode1(skinH);
			end;
		end;

    mP:Encode4(0x00000000);
		mP:Encode4(0x00000000);
    mP:Encode1(0x00);
		
		mP:Hide();
		RecvPacket(mP);
	elseif (string.find(GetGameVersion(), 'Releases/5.23') ~= nil) then
			local mP = CLoLPacket(0x13);
      mP.vTable = 0xF4FDE0;
 
			mP:EncodeF(myHero.networkID);
      mP:Encode4(0x00000000);
      mP:Encode1(0x00);
   
      if (skinPB == nil) then
        mP:Encode4(0x2F2F2F2F);
      else

        mP:Encode1(skinPB);
        for I = 1, 3 do
          mP:Encode1(0x74);
        end;

      end;
      mP:Encode1(0x75);

      for I = 1, string.len(mObject) do
        mP:Encode1(string.byte(string.sub(mObject, I, I)));
      end;

      for I = 1, (16 - string.len(mObject)) do
        mP:Encode1(0x00);
      end;

      mP:Encode4(0x00000000);
      mP:Encode4(0x0000000F);
      mP:Encode4(0x00000000);
      mP:Encode1(0x00);
      
      mP:Hide();
      RecvPacket(mP);
	end;
end;
function CurrentTimeInMillis()
	return (os.clock() * 1000);
end;
skinMeta = {
["Brand"]        = {"Classic", "Apocalyptic", "Vandal", "Cryocore", "Zombie", "Spirit Fire"}
}