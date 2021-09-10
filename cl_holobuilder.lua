-- If you have any suggestions you can create an issue at https://github.com/Kistras/2q2WxkSZhzU
---------------
-- Remove holos if script was reloaded
if HOLOBUILDER then
	for k,e in pairs(HOLOBUILDER.Holograms) do
		if e.Entity then
			e.Entity:Remove()
		end
	end
end
-- For interaction with other scripts
HOLOBUILDER = {} -- Global
HOLOBUILDER.Active = true -- Is builder active?
HOLOBUILDER.Holograms = {}
HOLOBUILDER.OriginPos = Vector(0, 0, 0)
HOLOBUILDER.SelectedHolo = nil -- A number
HOLOBUILDER.HighlightedHolo = nil -- A number
HOLOBUILDER.HighlightedDist = nil -- A number
HOLOBUILDER.RadialMenu = false -- If it is opened
HOLOBUILDER.RadialMenuSelected = nil
HOLOBUILDER.DrawnStuff = {} -- Used in radial menu to draw stuff on screen
HOLOBUILDER.Functions = {}  -- Used in radial menu to do stuff
HOLOBUILDER.Used3D2D = {} --
HOLOBUILDER.Mode = "Select"
-- Mode specific stuff
HOLOBUILDER.MoveDistance = nil
--

concommand.Add("holobuilder", function(ply, cmd, args)
	HOLOBUILDER.Active = not HOLOBUILDER.Active
end)

-- Hologram class?
local holoclass = {}
holoclass.Id = 1
holoclass.Model = "models/holograms/cube.mdl"
holoclass.Color = Color(255, 255, 255, 255)
holoclass.Material = "models/debug/debugwhite"
holoclass.Scale = Vector(1, 1, 1)
holoclass.ScaleInUnits = false
holoclass.Clip = {}
holoclass.DisableShadows = false
holoclass.Parent = 1
holoclass.Pos = Vector(0, 0, 0)
holoclass.Angle = Angle(0, 0, 0)
holoclass.Name = "Hologram"
holoclass.Draw = true
holoclass.Entity = nil
HOLOBUILDER.HoloClass = holoclass -- A number

local function applydata(id)
	local holo = HOLOBUILDER.Holograms[id]
	if holo then
		local en = holo.Entity
		if en then
			en:SetPos(HOLOBUILDER.OriginPos + holo.Pos)
			en:SetMaterial(holo.Material)
			en:SetModel(holo.Model)
			en:SetColor(holo.Color)
			if not isnumber(holo.Parent) or holo.Parent == holo.Id or holo.Parent == 0 then
				local ParentHolo = HOLOBUILDER.Holograms[holo.Parent]
				if ParentHolo and IsValid(ParentHolo.Entity) then
					en:SetParent(ParentHolo.Entity)
				end
			else
				en:SetParent() // Unparent, yeah
			end
			local mat = Matrix()
			if holo.ScaleInUnits then
				local boundsMins, boundsMaxs = en:GetModelBounds()
				local size = boundsMaxs - boundsMins
				mat:Scale(Vector(holo.Scale.x / size.x, holo.Scale.y / size.y, holo.Scale.z / size.z))
				//print(holo.Scale / size)
			else
				mat:Scale(holo.Scale)
			end
			en:EnableMatrix("RenderMultiply", mat)
		end
	end
end

local function spawnholo(holo)
	local entity = ClientsideModel(holo.Model)
	entity:SetPos(HOLOBUILDER.OriginPos + holo.Pos)
	entity:Spawn()
	entity:SetRenderMode(RENDERMODE_TRANSCOLOR)
	holo.Entity = entity
	HOLOBUILDER.Holograms[holo.Id] = holo
	applydata(holo.Id)
end
--

-- Functions go brrr
HOLOBUILDER.Functions["New Holo"] = function()
	local trace = LocalPlayer():GetEyeTrace()
	local holo = table.Copy(holoclass)
	holo.Pos = trace.HitPos - HOLOBUILDER.OriginPos + trace.HitNormal * 24
	holo.Pos = Vector(math.Round(holo.Pos.x), math.Round(holo.Pos.y), math.Round(holo.Pos.z))
	-- Iterate thru ids
	local Id = 1
	while HOLOBUILDER.Holograms[Id] do
		Id = Id + 1
	end
	holo.Id = Id
	spawnholo(holo)
	HOLOBUILDER.SelectedHolo = Id
end
HOLOBUILDER.Functions["Save"] = function()
	-- There should be confirmation window or something
	local str = "if(first()){\n"
	for id,holo in pairs(HOLOBUILDER.Holograms) do
		str = str .. "	holoCreate(" .. id .. ") holoPos(" .. id .. ", entity():toWorld(vec(" .. holo.Pos.x .. ", " .. holo.Pos.y .. ", " .. holo.Pos.z .. "))) "
		if not isnumber(holo.Parent) or holo.Parent == holo.Id or holo.Parent == 0 then
			str = str .. "holoParent(" .. id .. ", entity()) "
		else
			local ParentHolo = HOLOBUILDER.Holograms[holo.Parent]
			if ParentHolo and IsValid(ParentHolo.Entity) then
				str = str .. "holoParent(" .. id .. ", " .. holo.Parent .. ") "
			end
		end
		str = str .. "\n"
	end
	str = str .. "}"
	file.Write("expression2/HOLOBUILDER_OUTPUT_123.txt", str)
	chat.AddText("Saved")
end
HOLOBUILDER.Functions["Load"] = function()

end
HOLOBUILDER.Functions["Clear"] = function()

end
HOLOBUILDER.Functions["#Move"] = function()
	HOLOBUILDER.Mode = "Move"
end

--
surface.CreateFont("HoloBuilder", {
	font = "Segoe UI Semibold",
	extended = false,
	size = 30,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})
surface.CreateFont("HoloBuilderRadial", {
	font = "Segoe UI Semibold",
	extended = false,
	size = 20,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

hook.Add("Think", "HoloBuilderHandler", function()
	if HOLOBUILDER.Active then
		if table.IsEmpty(HOLOBUILDER.Holograms) then
			local holo = table.Copy(holoclass)
			holo.Name = "Origin"
			local trace = LocalPlayer():GetEyeTrace()
			HOLOBUILDER.OriginPos = trace.HitPos + trace.HitNormal * 24
			spawnholo(holo)
			print("Origin holo was created.")
		else
			--
		end
	end
end)

-- Get entities player looks at
hook.Add("PreDrawTranslucentRenderables", "HoloBuilderHighlighter", function()
	if HOLOBUILDER.Active then
		local rayStart = EyePos()
		local rayDelta = EyeVector() * 256
		local trace = LocalPlayer():GetEyeTrace()
		local tracelen = rayStart:DistToSqr(trace.HitPos)
		
		local newHolo = nil
		local newDist = 99999
		for id, holo in pairs(HOLOBUILDER.Holograms) do
			if holo.Entity then
				local boxOrigin = holo.Entity:GetPos()
				local boxAngles = holo.Entity:GetAngles()
				-- Entity:OBBMins() or Entity:OBBMaxs() retuns Vector(0,0,0)
				-- So I used Entity:GetModelBounds()
				local boxMins, boxMaxs = holo.Entity:GetModelBounds() 
				if holo.ScaleInUnits then
					/*
					local size = boxMaxs - boxMins
					local propoffset = boxMins + boxMaxs
					propoffset = Vector(propoffset.x / size.x * holo.Scale.x,
										propoffset.y / size.y * holo.Scale.y,
										propoffset.z / size.z * holo.Scale.z)
					-- Usually they compensate each other. Tell me if something is off
					
					boxMins = -holo.Scale / 2 + propoffset
					boxMaxs =  holo.Scale / 2 + propoffset
					*/
					-- The thing above was supposed to compensate model shifting, but I can't do anything with it for now.
					boxMins = -holo.Scale / 2
					boxMaxs =  holo.Scale / 2
				else
					boxMins = Vector(boxMins.x * holo.Scale.x, boxMins.y * holo.Scale.y, boxMins.z * holo.Scale.z)
					boxMaxs = Vector(boxMaxs.x * holo.Scale.x, boxMaxs.y * holo.Scale.y, boxMaxs.z * holo.Scale.z)
				end
				
				local hitPos, normalVec, fraction = util.IntersectRayWithOBB(rayStart, rayDelta, boxOrigin, boxAngles, boxMins, boxMaxs)
				if hitPos then
					local dist = rayStart:DistToSqr(hitPos)
					-- Check if this holo is closer to player than entity in front of them
					-- This way we won't be able to target stuff through walls
					if dist < tracelen then 
						if dist < newDist then -- If this holo is closer to player
							newHolo = id
							newDist = dist
						end
					end
				end
			end
		end
		HOLOBUILDER.HighlightedHolo = newHolo
		HOLOBUILDER.HighlightedDist = newDist
		
		-- Modes
		-- Move
		if HOLOBUILDER.Mode == "Move" and input.IsMouseDown(MOUSE_LEFT) then
			if HOLOBUILDER.MoveDistance == nil and HOLOBUILDER.HighlightedHolo == HOLOBUILDER.SelectedHolo and HOLOBUILDER.HighlightedDist < 100000 then
				HOLOBUILDER.MoveDistance = math.sqrt(HOLOBUILDER.HighlightedDist)
				//print(HOLOBUILDER.MoveDistance)
			end
		elseif HOLOBUILDER.MoveDistance ~= nil then
			HOLOBUILDER.MoveDistance = nil
		end
		if HOLOBUILDER.MoveDistance ~= nil then
			HOLOBUILDER.Holograms[HOLOBUILDER.SelectedHolo].Pos = (EyePos() + EyeVector() * HOLOBUILDER.MoveDistance) - HOLOBUILDER.OriginPos
			applydata(HOLOBUILDER.SelectedHolo)
		end
	end
end)
hook.Add("PreDrawHalos", "HoloBuilderHighlighter", function()
	if HOLOBUILDER.Active then
		if HOLOBUILDER.HighlightedHolo ~= nil and HOLOBUILDER.SelectedHolo ~= HOLOBUILDER.HighlightedHolo then
			local En = HOLOBUILDER.Holograms[HOLOBUILDER.HighlightedHolo].Entity
			if IsValid(En) then
				halo.Add({En}, color_red)
			end
		end
		if HOLOBUILDER.SelectedHolo then
			local En = HOLOBUILDER.Holograms[HOLOBUILDER.SelectedHolo].Entity
			if IsValid(En) then
				halo.Add({En}, color_white)
			end
		end
	end
end)

-- Intercept and replace user input --
local MMOffset = Vector(0, 0, 0)
local maxcldist = 25
local Sensitivity = 10
-- Replace binds
hook.Add("PlayerBindPress", "HoloBuilderInterceptKeys", function(ply, bind, pressed)
	if HOLOBUILDER.Active then
		if string.find(bind, "+zoom") then
			if pressed then
				HOLOBUILDER.RadialMenu = true
				HOLOBUILDER.RadialMenuSelected = nil
				MMOffset = Vector(0, 0, 0)
			else
				local field = HOLOBUILDER.DrawnStuff[HOLOBUILDER.RadialMenuSelected]
				HOLOBUILDER.RadialMenuSelected = nil
				HOLOBUILDER.RadialMenu = false
				if field ~= nil then
					HOLOBUILDER.Functions[field]()
				end
			end
			return true
		elseif string.find(bind, "+attack2") then	
			return true
		elseif string.find(bind, "+attack") then
			if pressed then
				if HOLOBUILDER.HighlightedHolo then
					if HOLOBUILDER.HighlightedHolo == HOLOBUILDER.SelectedHolo then
						-- Maybe modes
					else
						HOLOBUILDER.SelectedHolo = HOLOBUILDER.HighlightedHolo
					end
				else
					HOLOBUILDER.SelectedHolo = nil
					HOLOBUILDER.Mode = "Select"
				end
			end
			return true
		end
	end
end)
-- Get mouse movements for radial menu
hook.Add("InputMouseApply", "RadialMenuControls", function(cmd, x, y)
	if HOLOBUILDER.Active and HOLOBUILDER.RadialMenu then
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)
		
		MMOffset = MMOffset + Vector(x / Sensitivity, y / Sensitivity, 0)
		
		-- Clamp it
		local dist = MMOffset:Length2D()
		if dist > maxcldist then
			MMOffset.x = MMOffset.x / dist * maxcldist
			MMOffset.y = MMOffset.y / dist * maxcldist
			dist = maxcldist
		end
		
		-- Get angles
		local amo = #HOLOBUILDER.DrawnStuff
		
		local ang = MMOffset:Angle().yaw / 360
		-- I have no idea why this happens, but this thing has to have some sort of offset
		-- These numbers... work well for small numbers, but I haven't tested it any further.
		local offset = ((amo - 4) / 4) -- Why
		if ang and dist > 6 then
			HOLOBUILDER.RadialMenuSelected = math.floor(amo * -ang + offset) % amo + 1
		else
			HOLOBUILDER.RadialMenuSelected = nil
		end
		// chat.AddText("" .. ang)
		return true
	end
end)

-- Draw stuff on screen
local bg_color = Color(0, 0, 0, 128)
local InitDistFromCenter = 25
local InitDistToEnd = 100
local InitTextDistToEnd = 90
local GapDistance = 3
local pi05 = math.pi / 2
local pi2 = math.pi * 2
-- https://wiki.facepunch.com/gmod/cam.PushModelMatrix
local function rotatedText(text, x, y, font, color, ang)
	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	local m = Matrix()
	m:Translate(Vector(x, y, 0))
	m:Rotate(Angle(0, ang, 0))

	surface.SetFont(font)
	local w, h = surface.GetTextSize(text)

	m:Translate(-Vector(w / 2, h / 2, 0))

	cam.PushModelMatrix(m)
		draw.DrawText(text, font, 0, 0, color)
	cam.PopModelMatrix()

	render.PopFilterMag()
	render.PopFilterMin()
end

-- DO NOT USE this implementation of radial menu
--   You probably want to check out this:
--   https://steamcommunity.com/sharedfiles/filedetails/?id=265292490
hook.Add("HUDPaint", "HoloBuilderRadialMenu", function()
	if HOLOBUILDER.Active and HOLOBUILDER.RadialMenu then
		surface.SetDrawColor(bg_color)
		draw.NoTexture()
		if HOLOBUILDER.SelectedHolo then
			HOLOBUILDER.DrawnStuff = {
				"#Move",
				"Rotate",
				"Color",
				"Name",
				"#Scale",
				"Material",
				"Parent",
				"Remove"
			}
		else
			HOLOBUILDER.DrawnStuff = {
				"New Holo",
				"Save",
				"Load",
				"Clear"
			}
		end
		
		local amo = #HOLOBUILDER.DrawnStuff
		if amo > 2 then
			local GapMod = GapDistance * (5 / amo) -- Approx. numbers
			local frac = pi2 / amo
			for h, e in pairs(HOLOBUILDER.DrawnStuff) do
				-- Used to make selected things "stand out"
				local PushOut
				if isnumber(HOLOBUILDER.RadialMenuSelected) and HOLOBUILDER.RadialMenuSelected == h then
					PushOut = 20
				else
					PushOut = 0
				end
				local DistFromCenter = InitDistFromCenter + PushOut
				local DistToEnd = InitDistToEnd + PushOut
				local TextDistToEnd = InitTextDistToEnd + PushOut
				-- So basically we need to throw a few (#DrawnStuff) lines, get points perpendicular to it
				--   on some distance (DistToEnd and DistFromCenter), connect those points and we've got
				--   our radial menu. Still broke something with this gap modificator, so I used just
				--   very rough approximated numbers. TODO: Works for now, should be fixed later. 
				local LineStartX, LineStartY = math.sin((h) * frac), math.cos((h) * frac)
				local PerpStartX, PerpStartY = math.sin((h - pi05) * frac), math.cos((h - pi05) * frac)
				local LineEndX, LineEndY = math.sin((h + 1) * frac), math.cos((h + 1) * frac)
				local PerpEndX, PerpEndY = math.sin((h + 1 + pi05) * frac), math.cos((h + 1 + pi05) * frac)
				local Pol = {
					{x = ScrW() / 2 + LineStartX * DistToEnd - PerpStartX * GapMod,
					 y = ScrH() / 2 + LineStartY * DistToEnd - PerpStartY * GapMod},
					{x = ScrW() / 2 + LineStartX * DistFromCenter - PerpStartX * GapMod,
					 y = ScrH() / 2 + LineStartY * DistFromCenter - PerpStartY * GapMod},
					{x = ScrW() / 2 + LineEndX * DistFromCenter - PerpEndX * GapMod,
					 y = ScrH() / 2 + LineEndY * DistFromCenter - PerpEndY * GapMod}, 
					{x = ScrW() / 2 + LineEndX * DistToEnd - PerpEndX * GapMod,
				 	 y = ScrH() / 2 + LineEndY * DistToEnd - PerpEndY * GapMod},
				}
				surface.DrawPoly(Pol)
				//local DistMod = (2 - 1 / math.sqrt(#DrawnStuff))
				//local PosX = (Pol[1].x + Pol[4].x) / 2
				local PosX = (ScrW() + LineStartX * TextDistToEnd + LineEndX * TextDistToEnd) / 2
				local PosY = (ScrH() + LineStartY * TextDistToEnd + LineEndY * TextDistToEnd) / 2
				//print(math.Distance(PosX, PosY, ScrW() / 2, ScrH() / 2))
				rotatedText(e, 
					-- Doesn't work cuz I don't know right formula for distance
					//ScrW() / 2 + math.sin((h + 0.5) * frac) * DistToEnd / DistMod, 
					//ScrH() / 2 + math.cos((h + 0.5) * frac) * DistToEnd / DistMod, 
					PosX, PosY,
					"HoloBuilderRadial", 
					color_white, 
					((-360 / amo) * (h + 0.5) + 90) % 180 - 90
				)
				//print(PerpStartX, PerpStartY)
				/*
				for k,e in pairs(Pol) do
					surface.DrawCircle(e.x, e.y, 15)
					surface.SetTextPos(e.x, e.y)
					surface.DrawText(k .. "")
				end
				//*/
				//break
			end
			
			-- Cursor
			local Poly = {}
			local Frac = pi2 / amo
			local offset = (amo - 4) / 2 * GapMod -- Magic numbers
			for h = 1, amo do 
				table.insert(Poly, 
					{x = ScrW() / 2 + MMOffset.x * 2.5 + math.sin(Frac * (amo - h)) * (InitDistFromCenter - offset), 
					 y = ScrH() / 2 + MMOffset.y * 2.5 + math.cos(Frac * (amo - h)) * (InitDistFromCenter - offset)}
				)
				// surface.SetTextPos(Poly[#Poly].x, Poly[#Poly].y) surface.DrawText(h .. " ")
			end
			surface.SetDrawColor(bg_color)
			surface.DrawPoly(Poly)
		end
	end
end)
local BottomGap = 27 -- Default hud offset for 1920x1280
hook.Add("HUDPaint", "HoloBuilderInfo", function()
	if HOLOBUILDER.Active then
		surface.SetFont("HoloBuilder")
		local Fields = {
			"Current Mode: " .. HOLOBUILDER.Mode,
			"-Selected Hologram Info-"
		}
		local SHoloId = HOLOBUILDER.SelectedHolo
		if isnumber(SHoloId) then
			local SHolo = HOLOBUILDER.Holograms[SHoloId]
			table.Add(Fields, {
				"Name: " .. SHolo.Name,
				"Id: " .. SHolo.Id,
				"Pos: " .. tostring(SHolo.Pos),
			})
		else 
			table.Add(Fields, {
				"No holo selected"
			})
		end
		-- Prepare sizes
		local Height = 23 * (#Fields) + 4
		local Width = 0
		for k,e in pairs(Fields) do
			local size, _ = surface.GetTextSize(e)
			if size > Width then 
				Width = size 
			end
		end
		Width = Width + 8
		surface.SetDrawColor(bg_color)
		surface.DrawRect(ScrW() / 2 - Width / 2, ScrH() - BottomGap - Height, Width, Height)
		
		surface.SetTextColor(color_white)
		for k,e in pairs(Fields) do
			local sizeX, sizeY = surface.GetTextSize(e)
			surface.SetTextPos(ScrW() / 2 - sizeX / 2, ScrH() - BottomGap - Height - sizeY / 2 + 23 * (k - 0.55) + 2)
			surface.DrawText(e)
		end
		--surface.SetDrawColor(255, 0, 0, 255)
		--surface.DrawRect(0, ScrH() - BottomGap - 2, ScrW(), 2)
		
	end
end)