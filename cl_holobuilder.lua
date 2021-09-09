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
HOLOBUILDER.RadialMenu = false -- If it is opened

concommand.Add("holobuilder", function(ply, cmd, args)
	HOLOBUILDER.Active = not HOLOBUILDER.Active
end)

-- Hologram class?
local holoclass = {}
holoclass.Id = 0
holoclass.Model = "models/props_interiors/pot01a.mdl"
holoclass.Color = Color(255, 255, 255, 200)
holoclass.Material = "models/magnusson/magnusson_face"
holoclass.Scale = Vector(1, 1, 1)
holoclass.ScaleInUnits = false
holoclass.Clip = {}
holoclass.DisableShadows = false
holoclass.Parent = 0
holoclass.Pos = Vector(0, 0, 0)
holoclass.Angle = Angle(0, 0, 0)
holoclass.Name = "Hologram"
holoclass.Draw = true
holoclass.Entity = nil
HOLOBUILDER.HoloClass = holoclass -- A number

local function spawnholo(holo)
	local entity = ClientsideModel(holo.Model)
	entity:SetPos(HOLOBUILDER.OriginPos + holo.Pos)
	entity:Spawn()
	holo.Entity = entity
	HOLOBUILDER.Holograms[holo.Id] = holo
end

local DownGap = 27 -- Default hud offset for 1920x1280

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
				
				local hitPos, normalVec, fraction = util.IntersectRayWithOBB(rayStart, rayDelta, boxOrigin, boxAngles, boxMins, boxMaxs)
				if hitPos then
					local dist = rayStart:DistToSqr(hitPos)
					-- Check if this holo is closer to player than entity in front of them
					-- This way we won't be able to target stuff through walls
					if dist < tracelen then 
						if dist < newDist then -- If this holo is closer to player
							newHolo = id
							netDist = dist
						end
					end
				end
			end
		end
		HOLOBUILDER.HighlightedHolo = newHolo
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

-- Intercept and replace user input
hook.Add("PlayerBindPress", "HoloBuilderInterceptKeys", function(ply, bind, pressed)
	if HOLOBUILDER.Active then
		if string.find(bind, "+attack3") or input.IsMouseDown(MOUSE_MIDDLE) then
			HOLOBUILDER.RadialMenu = true
			return true
		elseif string.find(bind, "+attack2") then	
			
		elseif string.find(bind, "+attack") then
			if HOLOBUILDER.HighlightedHolo then
				HOLOBUILDER.SelectedHolo = HOLOBUILDER.HighlightedHolo
			else
				HOLOBUILDER.SelectedHolo = nil
			end
			return true
		end
	end
end)

-- Draw stuff on screen
local bg_color = Color(0, 0, 0, 128)
local DistFromCenter = 25
local DistToEnd = 100
local GapMod = 3
local pi2 = math.pi / 2
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

hook.Add("HUDPaint", "HoloBuilderRadialMenu", function()
	if HOLOBUILDER.Active and HOLOBUILDER.RadialMenu then
		surface.SetDrawColor(bg_color)
		draw.NoTexture()
		local DrawnStuff
		if HOLOBUILDER.SelectedHolo then
			DrawnStuff = {
				"Move",
				"Rotate",
				"Color",
				"Name",
				"Scale",
				"Material",
				"Parent",
				"Clone"
			}
		else
			DrawnStuff = {
				"NewHolo",
				"Save",
				"Load",
				"Clear"
			}
		end

		if #DrawnStuff > 2 then
			local frac = math.pi * 2 / #DrawnStuff
			for h, e in pairs(DrawnStuff) do
				local LineStartX, LineStartY = math.sin((h) * frac), math.cos((h) * frac)
				local PerpStartX, PerpStartY = math.sin((h - pi2) * frac), math.cos((h - pi2) * frac)
				local LineEndX, LineEndY = math.sin((h + 1) * frac), math.cos((h + 1) * frac)
				local PerpEndX, PerpEndY = math.sin((h + 1 + pi2) * frac), math.cos((h + 1 + pi2) * frac)
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
				local PosX = (Pol[1].x + Pol[4].x) / 2
				local PosY = (Pol[1].y + Pol[4].y) / 2
				//print(math.Distance(PosX, PosY, ScrW() / 2, ScrH() / 2))
				rotatedText(e, 
					//ScrW() / 2 + math.sin((h + 0.5) * frac) * DistToEnd / DistMod, 
					//ScrH() / 2 + math.cos((h + 0.5) * frac) * DistToEnd / DistMod, 
					PosX, PosY,
					"default", 
					color_white, 
					((-360 / (#DrawnStuff)) * (h + 0.5) + 90) % 180 - 90
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
		end
	end
end)
hook.Add("HUDPaint", "HoloBuilderInfo", function()
	if HOLOBUILDER.Active then
		surface.SetFont("HoloBuilder")
		local Fields = {
			"Selected Hologram Info"
		}
		if SelectedHolo and isnumber(SelectedHolo.Id) then
			table.Add(Fields, {
				"Id: " .. SelectedHolo.Id
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
		surface.DrawRect(ScrW() / 2 - Width / 2, ScrH() - DownGap - Height, Width, Height)
		
		surface.SetTextColor(color_white)
		for k,e in pairs(Fields) do
			local sizeX, sizeY = surface.GetTextSize(e)
			surface.SetTextPos(ScrW() / 2 - sizeX / 2, ScrH() - DownGap - Height - sizeY / 2 + 23 * (k - 0.55) + 2)
			surface.DrawText(e)
		end
		--surface.SetDrawColor(255, 0, 0, 255)
		--surface.DrawRect(0, ScrH() - DownGap - 2, ScrW(), 2)
		
	end
end)
