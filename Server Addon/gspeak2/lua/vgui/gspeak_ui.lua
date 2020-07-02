function gspeak:DrawHUD()
	if LocalPlayer().talking then
		local x, y = gspeak:hud_pos(gspeak.settings.HUD.console.x, gspeak.settings.HUD.console.y, 55, 20, gspeak.settings.HUD.console.align)
		local mode_name, _, _, mode_mat_ui = gspeak:get_talkmode_details(gspeak.cl.settings.talkmode)
		gspeak:DrawText(mode_name, x, y, gspeak.cl.color.green)
		x = x - 75
		y = y - 45
		local size = 128
		surface.SetDrawColor( gspeak.cl.color.white )
		surface.SetMaterial( mode_mat_ui or gspeak.cl.materials.default_icon_ui )
		surface.DrawTexturedRect( x, y, size, size)
	end

	if !gspeak:player_alive(LocalPlayer()) and gspeak.cl.dead_muted then
		local sizeX = 200
		local sizeY = 50
		local x, y = gspeak:hud_pos(gspeak.settings.HUD.status.x, gspeak.settings.HUD.status.y, sizeX, sizeY, gspeak.settings.HUD.status.align)
		draw.RoundedBox(8, x, y, sizeX, sizeY, Color(50, 50, 50, 155))
		draw.DrawText( "Dead muted", "Trebuchet24", x+45, y+12, gspeak.cl.color.red, TEXT_ALIGN_LEFT )
	end
end

function gspeak:get_talkmode_details( ID )
	local mode = gspeak.settings.distances.modes[ID]
	if !mode then return "(error)", 0, gspeak.cl.materials.error, gspeak.cl.materials.error end
	return mode.name, mode.range, mode.material, mode.material_ui
end

//Thendon speichers einfach in gspeak.cl.
function gspeak:hud_pos( x, y, width, height, align )
	x = ScrW() * x
	y = ScrH() * y
	if align == "tr" then
		x = ScrW() - x - width
	elseif align == "bl" then
		y = ScrH() - y - height
	elseif align == "br" then
		x = ScrW() - x - width
		y = ScrH() - y - height
	end
	return x, y
end

//Thank you Chessnut
local blur = Material("pp/blurscreen")
local function DrawBlurRect(x, y, w, h)
	local X, Y = 0,0

	surface.SetDrawColor(255,255,255)
	surface.SetMaterial(blur)

	for i = 1, 5 do
		blur:SetFloat("$blur", (i / 3) * (1))
		blur:Recompute()

		render.UpdateScreenEffectTexture()

		render.SetScissorRect(x, y, x+w, y+h, true)
			surface.DrawTexturedRect(X * -1, Y * -1, ScrW(), ScrH())
		render.SetScissorRect(0, 0, 0, 0, false)
	end

   draw.RoundedBox(0,x,y,w,h,Color(0,0,0,205))
   surface.SetDrawColor(0,0,0)
end

function gspeak:DrawTalkMenu()
  local srcw = ScrW()
  local srch = ScrH()
  local hsrcw = srcw*0.5
  local hsrch = srch*0.5
  local inner = hsrch*0.526
  local outer = 1.9

  DrawBlurRect(0,0,srcw,srch)
  surface.SetDrawColor(Color(0,0,0,100))
  surface.SetMaterial(gspeak.cl.materials.circle)
  surface.DrawTexturedRect(hsrcw-hsrch,0,srch,srch)
  local modes = gspeak.settings.distances.modes
  local cakes = 2*math.pi / #modes

  local mouseX, mouseY = gui.MousePos()
  mouseX = mouseX - hsrcw
  mouseY = mouseY - hsrch
  length = math.sqrt(mouseX*mouseX + mouseY*mouseY)
  mouseX = mouseX / length
  mouseY = mouseY / length
  local mouse_degree = math.atan2(mouseY, mouseX) - math.pi * 0.5
  local octan = math.floor(((#modes*mouse_degree) / (2*math.pi) + #modes) % #modes)
  if octan == 0 then octan = #modes end

  for i=1, #modes, 1 do
    local degree = math.pi*0.5 + i * cakes
    local cakex = math.cos(degree) * inner
    local cakey = math.sin(degree) * inner
	  surface.SetDrawColor(Color(255,255,255,10))
    surface.DrawLine( hsrcw + cakex, hsrch + cakey, hsrcw + cakex * outer, hsrch + cakey * outer )

    cakex = math.cos(degree + (cakes*0.5)) * inner * 1.5
    cakey = math.sin(degree + (cakes*0.5)) * inner * 1.5

    local col = Color( 255, 255, 255, 50 )
    if i == octan then
      col.a = 255
      gspeak.cl.tmm.selected = i
    end

    draw.DrawText( modes[i].name, "TnfSmall", hsrcw + cakex, hsrch + cakey, col, TEXT_ALIGN_CENTER )
  end
end

function gspeak:DrawText(text, x, y, ColorTable)
	local text_l = string.len(text)*23+100
	draw.RoundedBox(8, x-text_l, y-10, text_l, 60, Color(50, 50, 50, 155))
	draw.DrawText( text, "TnfSmall", x+15-text_l, y, ColorTable, TEXT_ALIGN_LEFT )
end

function gspeak:DrawLoading(x, y, offset, size, color)
	surface.SetDrawColor( color )
	surface.SetMaterial( gspeak.cl.materials.loading )
	for i = 0, 2, 1 do
		surface.DrawTexturedRect( x+offset*i, y+gspeak.cl.loadanim.state[i+1]*offset*(-1), size, size)
	end
end

function gspeak:DrawStatus()
	if gspeak.cl.TS.inChannel and LocalPlayer().ts_id and LocalPlayer().ts_id != -1 then return end

	local diffY = 40
	local sizeX = 320
	local sizeY = 200
	local posX, posY = gspeak:hud_pos(gspeak.settings.HUD.status.x, gspeak.settings.HUD.status.y, sizeX, sizeY, gspeak.settings.HUD.status.align)

	local textX = posX+10
	local loadingX = posX+sizeX-100
	local errorY = 0
	draw.RoundedBox(8, posX, posY, sizeX, sizeY, Color(50, 50, 50, 155))

	posY = posY + 35
	color = gspeak.cl.color.yellow
	local loadingY = posY
	local header = "TsLib: Scanning"
	local text = "Searching for gmcl_tslib_win32.dll!"
	if gspeak.cl.failed then
		color = gspeak.cl.color.red
		errorY = posY - 10
		if gspeak.cl.tslib.wrongVersion then
			header = "TsLib: Wrong Version"
			text = "Your gmcl_tslib_win32.dll file is on\nversion "..tostring(gspeak.cl.tslib.version/1000).."! Please "..gspeak:VersionWord(gspeak.cl.tslib).." version "..tostring(gspeak.cl.tslib.req/1000).."!"
		else
			header = "TsLib: Failed"
			text = "Could not find gmcl_tslib_win32.dll! Please\ndownload & install TsLib version "..tostring(gspeak.cl.tslib.req/1000).."!"
		end
	elseif gspeak.cl.running then
		color = gspeak.cl.color.green
	end
	draw.DrawText( "TSlib", "TnfSmall", textX, posY, color, TEXT_ALIGN_LEFT )
	draw.DrawText( tostring(gspeak.cl.tslib.req/1000), "Trebuchet24", posX+85, posY+13, color, TEXT_ALIGN_LEFT )

	posY = posY + diffY
	color = white
	if gspeak.cl.TS.failed then
		color = gspeak.cl.color.red
		errorY = posY - 10
		header = "Gspeak: Wrong Version"
		text = "Your Gspeak Teamspeak3 plugin is on\nversion "..tostring(gspeak.cl.TS.version/1000).."! Please "..gspeak:VersionWord(gspeak.cl.TS).." version "..tostring(gspeak.cl.TS.req/1000).."!"
	elseif gspeak.cl.running and !gspeak.cl.TS.connected then
		color = gspeak.cl.color.yellow
		loadingY = posY
		header = "Scanning for Teamspeak3"
		text = "Please start Teamspeak3 and/or enable the\nGspeak plugin! (Tools->Options->Addons)"
	elseif gspeak.cl.TS.connected then
		color = gspeak.cl.color.green
	end
	draw.DrawText( "Gspeak", "TnfSmall", textX, posY, color, TEXT_ALIGN_LEFT )
	draw.DrawText( tostring(gspeak.cl.TS.req / 1000), "Trebuchet24", posX + 120, posY + 13, color, TEXT_ALIGN_LEFT )

	posY = posY + diffY
	color = white
	if gspeak.cl.TS.connected and !gspeak.cl.TS.inChannel then
		color = gspeak.cl.color.yellow
		loadingY = posY
		header = "Scanning for Teamspeak3"
		text = "Join our Teamspeak3 Server: " .. gspeak.settings.ts_ip .. "\nand enter the Gspeak Channel!"
	elseif gspeak.cl.TS.inChannel then
		color = gspeak.cl.color.green
	end
	draw.DrawText( "Channel", "TnfSmall", textX, posY, color, TEXT_ALIGN_LEFT )

	if !gspeak.cl.failed and !gspeak.cl.TS.failed then
		gspeak:DrawLoading(loadingX, loadingY, 28, 28, gspeak.cl.color.white)
	else
		surface.SetDrawColor( gspeak.cl.color.white )
		surface.SetMaterial( gspeak.cl.materials.error )
		surface.DrawTexturedRect( loadingX, errorY, 64, 64)
	end

	if gspeak.cl.TS.connected and gspeak.cl.TS.inChannel and (!LocalPlayer().ts_id or LocalPlayer().ts_id == -1) then
		header = "Broadcasting Variables"
		text = "Sending your information to the other players."
	end

	posY = posY + diffY
	draw.DrawText( header, "Trebuchet24", posX + 10, posY - 140, white, TEXT_ALIGN_LEFT )
	draw.DrawText( text, "HudHintTextLarge", posX + 10, posY, white, TEXT_ALIGN_LEFT )
end
--[[
function gspeak:DrawHUD() return end
function gspeak:DrawTalkMenu() return end
function gspeak:DrawLoading(x, y, offset, size, color) return end
function gspeak:DrawStatus() return end
]]
