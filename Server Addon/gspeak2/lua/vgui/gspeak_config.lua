local function send_setting( table, client )
	if client then
		gspeak:ChangeSetting(string.Explode( ".", table.name ), gspeak.cl.settings, table.name, table.value)
		return
	end
	net.Start("gspeak_setting_change")
		net.WriteTable( table )
	net.SendToServer()
end

local function gui_think_slider(Panel)
	if Panel.Slider and Panel.Slider:GetDragging() then return end
	local value = math.Round( Panel:GetValue(), Panel:GetDecimals() )
	Panel.last_value = Panel.last_value or value
	if Panel.last_value == value then return end

	Panel.last_value = value
	send_setting( { name = Panel:GetName(), value = value }, Panel.client )
end

local function gui_change(Panel)
	local value
	if Panel.GetChecked then value = Panel:GetChecked()
	else value = Panel:GetValue() end

	send_setting( { name = Panel:GetName(), value = value }, Panel.client )
end

local function gui_key_trapper( TPanel )
	input.StartKeyTrapping()
	local DermaPanel = vgui.Create( "DFrame" )
	DermaPanel:SetName( TPanel:GetName() )
	DermaPanel:Center()
	DermaPanel:SetSize( 250, 75 )
	DermaPanel:SetTitle( "Gspeak Config" )
	DermaPanel:SetDraggable( true )
	DermaPanel:MakePopup()
	DermaPanel.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 50, 50, 50, 255 ) )
	end
	DermaPanel:ShowCloseButton( false )
	DermaPanel.Think = function ( Panel )
		local panel_name = Panel:GetName()
		local key = input.CheckKeyTrapping()
		if key != nil then
			send_setting( { name = panel_name, value = key }, TPanel.Client )
			Panel:Close()
		end
	end
	DermaPanel.OnClose = function ( Panel )
		TPanel:SetDisabled( false )
	end

	local DLabel = vgui.Create( "DLabel", DermaPanel )
	DLabel:SetPos( 25, 25 )
	DLabel:SetSize( 200, 25 )
	DLabel:SetText( "Press the key you want to set!" )
end

local function GetKeyString( key_enum )
	return (key_enum == KEY_NONE ) and "error" or input.GetKeyName(key_enum)
end

local function DrawContent(panel, active)
	local dsizex, dsizey = panel:GetSize()
	local txt_color = Color(255,255,255,255)
	local DermaActive = vgui.Create( "DFrame", panel )
	DermaActive:Center()
	DermaActive:SetTitle("")
	DermaActive:SetPos( 202, 0 )
	DermaActive:SetSize( dsizex - 210, dsizey )
	DermaActive.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 100, 100, 100, 255 ) )
	end
	DermaActive:ShowCloseButton( false )
	local dsizex, dsizey = DermaActive:GetSize()
	local DImage = vgui.Create( "DImage", DermaActive )
	DImage:SetSize( 256, 256 )
	DImage:SetPos(dsizex-256, dsizey-256)
	DImage:SetImage( "gspeak/gspeak_logo_new.png" )
	DImage:SetImageColor(Color(255,255,255,40))

	local xPos = 25
	local yPos = 50
	local diff = 50

	if active == 1 then

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 300, 25 )
		DLabel:SetText( "Talkmode Key" )
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetName( "key" )
		DLabel.Client = true
		DLabel:SetPos( xPos+100, yPos )
		DLabel:SetSize( 150, 25 )
		DLabel:SetColor( Color( 255, 255, 255, 255 ))
		DLabel:SetTextColor( Color(0,0,255,255) )
		DLabel:SetFont("TnfTiny")
		DLabel:SetMouseInputEnabled( true )
		DLabel:SetText( GetKeyString(gspeak.cl.settings.key) )
		DLabel.DoClick = gui_key_trapper
		DLabel.Think = function ( Panel )
			if gspeak.cl.settings[name] != Panel:GetText() then
				Panel:SetText( GetKeyString(gspeak.cl.settings.key) )
			end
		end
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+200, yPos )
		DLabel:SetSize( 300, 25 )
		DLabel:SetText( "(default - "..GetKeyString(gspeak.settings.def_key)..")" )

		if gspeak.settings.radio.use_key then
			yPos = yPos + 50
			local DLabel = vgui.Create( "DLabel", DermaActive )
			DLabel:SetPos( xPos, yPos )
			DLabel:SetSize( 300, 25 )
			DLabel:SetText( "Radio Key" )
			local DLabel = vgui.Create( "DLabel", DermaActive )
			DLabel:SetName( "radio_key" )
			DLabel.Client = true
			DLabel:SetPos( xPos+100, yPos )
			DLabel:SetSize( 150, 25 )
			DLabel:SetColor( Color( 255, 255, 255, 255 ))
			DLabel:SetTextColor( Color(0,0,255,255) )
			DLabel:SetFont("TnfTiny")
			DLabel:SetMouseInputEnabled( true )
			DLabel:SetText( GetKeyString(gspeak.cl.settings.radio_key) )
			DLabel.DoClick = gui_key_trapper
			DLabel.Think = function ( Panel )
				if gspeak.cl.settings[name] != Panel:GetText() then
					Panel:SetText( GetKeyString(gspeak.cl.settings.radio_key) )
				end
			end
			local DLabel = vgui.Create( "DLabel", DermaActive )
			DLabel:SetPos( xPos+200, yPos )
			DLabel:SetSize( 300, 25 )
			DLabel:SetText( "(default - "..GetKeyString(gspeak.settings.radio.def_key)..")" )
		end
		if gspeak.settings.dead_chat then
			yPos = yPos + 50
			local DLabel = vgui.Create( "DLabel", DermaActive )
			DLabel:SetPos( xPos, yPos )
			DLabel:SetSize( 125, 25 )
			DLabel:SetText( "Mute dead/spectator:" )
			local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
			DCheckBox:SetPos( xPos+125, yPos )
			DCheckBox:SetValue( gspeak.cl.dead_muted )
			DCheckBox.OnChange = function( panel )
				gspeak.cl.dead_muted = panel:GetChecked()
			end
		end
	elseif active == 2 then
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "radio.down" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Radio downsampling" )
		DSlider:SetMin( 1 )
		DSlider:SetMax( 10 )
		DSlider:SetDecimals( 0 )
		DSlider:SetValue( gspeak.settings.radio.down )
		DSlider.Think = gui_think_slider
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+300, yPos )
		DLabel:SetSize( 200, 25 )
		DLabel:SetText( "def = 4 (lowering samples)" )
		yPos = yPos + 25
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "radio.dist" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Radio distortion" )
		DSlider:SetMin( 0 )
		DSlider:SetMax( 10000 )
		DSlider:SetDecimals( 0 )
		DSlider:SetValue( gspeak.settings.radio.dist )
		DSlider.Think = gui_think_slider
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+300, yPos )
		DLabel:SetSize( 200, 25 )
		DLabel:SetText( "def = 1500 (cuts each sample)" )
		yPos = yPos + 25
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "radio.volume" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Radio volume" )
		DSlider:SetMin( 0 )
		DSlider:SetMax( 3 )
		DSlider:SetDecimals( 2 )
		DSlider:SetValue( gspeak.settings.radio.volume )
		DSlider.Think = gui_think_slider
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+300, yPos )
		DLabel:SetSize( 200, 25 )
		DLabel:SetText( "def = 1.5 (volume boost for the radio)" )
		yPos = yPos + 25
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "radio.noise" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Radio noise volume" )
		DSlider:SetMin( 0 )
		DSlider:SetMax( 0.1 )
		DSlider:SetDecimals( 3 )
		DSlider:SetValue( gspeak.settings.radio.noise )
		DSlider.Think = gui_think_slider
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+300, yPos )
		DLabel:SetSize( 200, 25 )
		DLabel:SetText( "def = 0.010 (volume of white noise)" )

		local choices = { "start_com", "end_com", "radio_beep1", "radio_beep2", "radio_click1", "radio_click2" }

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Default radio sound" )
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+125, yPos )
		DLabel:SetSize( 50, 25 )
		DLabel:SetText( "Startcom:" )
		local DMulti = vgui.Create( "DComboBox", DermaActive )
		for k, v in pairs(choices) do
			DMulti:AddChoice(v)
		end
		DMulti:SetName( "radio.start" )
		DMulti:SetPos( xPos+175, yPos )
		DMulti:SetSize( 100, 25 )
		DMulti:SetText( gspeak.settings.radio.start )
		DMulti.OnSelect = gui_change
		yPos = yPos + 25
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+125, yPos )
		DLabel:SetSize( 50, 25 )
		DLabel:SetText( "Endcom:" )
		local DMulti = vgui.Create( "DComboBox", DermaActive )
		for k, v in pairs(choices) do
			DMulti:AddChoice(v)
		end
		DMulti:SetName( "radio.stop" )
		DMulti:SetPos( xPos+175, yPos )
		DMulti:SetSize( 100, 25 )
		DMulti:SetText( gspeak.settings.radio.stop )
		DMulti.OnSelect = gui_change

		yPos = yPos + 25
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 200, 25 )
		DLabel:SetText( "Trigger effect at talk" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "trigger_at_talk" )
		DCheckBox:SetPos( xPos+175, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.trigger_at_talk )
		DCheckBox.OnChange = gui_change

		yPos = yPos + 25
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 200, 25 )
		DLabel:SetText( "Auto add custom sounds to FastDL" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "auto_fastdl" )
		DCheckBox:SetPos( xPos+175, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.auto_fastdl )
		DCheckBox.OnChange = gui_change

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Radio Key (on/off)" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "radio.use_key" )
		DCheckBox:SetPos( xPos+100, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.radio.use_key )
		DCheckBox.OnChange = gui_change

		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetName( "radio.def_key" )
		DLabel:SetPos( xPos+130, yPos )
		DLabel:SetSize( 150, 25 )
		DLabel:SetColor( Color( 255, 255, 255, 255 ))
		DLabel:SetTextColor( Color(0,0,255,255) )
		DLabel:SetFont("TnfTiny")
		DLabel:SetMouseInputEnabled( true )
		DLabel:SetText( GetKeyString(gspeak.settings.radio.def_key) )
		DLabel.DoClick = gui_key_trapper
		DLabel.Think = function ( Panel )
			if gspeak.settings[name] != Panel:GetText() then
				Panel:SetText( GetKeyString(gspeak.settings.radio.def_key) )
			end
		end
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos+25 )
		DLabel:SetSize( 325, 25 )
		DLabel:SetText( "If unchecked, radio will start sending when it's holded and\nstop when it's holstered." )

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 125, 50 )
		DLabel:SetText( "Should radios be\nhearable by near\nplayers" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "radio.hearable" )
		DCheckBox:SetPos( xPos+125, yPos+15 )
		DCheckBox:SetValue( gspeak.settings.radio.hearable )
		DCheckBox.OnChange = gui_change
	elseif active == 3 then
		local AppList = vgui.Create( "DListView", DermaActive )
		AppList:SetPos( xPos, yPos )
		AppList:SetSize( 400, 150 )
		AppList:SetMultiSelect( false )
		AppList:AddColumn( "Name" ):SetFixedWidth( 75 )
		AppList:AddColumn( "Range" ):SetFixedWidth( 40 )
		AppList:AddColumn( "Icon" )
		AppList:AddColumn( "Interface" )
		AppList.Refresh = function( panel, update )
			panel:Clear()
			local update_table = {}
			for i=1, #gspeak.settings.distances.modes, 1 do
				local mode = gspeak.settings.distances.modes[i]
				AppList:AddLine( mode.name, mode.range, mode.icon, mode.icon_ui )
				update_table[i]  = { name = mode.name, range = mode.range, icon = mode.icon, icon_ui = mode.icon_ui }
			end
			if !update then return end
			send_setting( { name = "distances.modes", value = update_table } )
		end
		AppList:Refresh()
		yPos = yPos + 150

		local function EditMode( TPanel, ID )
			local DermaPanel = vgui.Create( "DFrame" )
			DermaPanel:SetName( TPanel:GetName() )
			DermaPanel:Center()
			DermaPanel:SetSize( 325, 175 )
			DermaPanel:SetTitle( "Gspeak Config" )
			DermaPanel:SetDraggable( true )
			DermaPanel:MakePopup()

			local xPos = 25
			local diff = 25
			local yPos = 25

			local DLabel = vgui.Create( "DLabel", DermaPanel )
			DLabel:SetPos( xPos, yPos )
			DLabel:SetSize( 75, 25 )
			DLabel:SetText( "Name:" )
			local NameTextEntry = vgui.Create( "DTextEntry", DermaPanel )
			NameTextEntry:SetPos( xPos + 75, yPos )
			NameTextEntry:SetSize( 200, 25 )
			NameTextEntry:SetText( ID and gspeak.settings.distances.modes[ID].name or "" )
			yPos = yPos + diff
			local DLabel = vgui.Create( "DLabel", DermaPanel )
			DLabel:SetPos( xPos, yPos )
			DLabel:SetSize( 75, 25 )
			DLabel:SetText( "Range:" )
			local RangeTextEntry = vgui.Create( "DTextEntry", DermaPanel )
			RangeTextEntry:SetPos( xPos + 75, yPos )
			RangeTextEntry:SetSize( 200, 25 )
			RangeTextEntry:SetText( ID and gspeak.settings.distances.modes[ID].range or "" )
			yPos = yPos + diff
			local DLabel = vgui.Create( "DLabel", DermaPanel )
			DLabel:SetPos( xPos, yPos )
			DLabel:SetSize( 75, 25 )
			DLabel:SetText( "Icon:" )
			local IconTextEntry = vgui.Create( "DTextEntry", DermaPanel )
			IconTextEntry:SetPos( xPos + 75, yPos )
			IconTextEntry:SetSize( 200, 25 )
			IconTextEntry:SetText( ID and gspeak.settings.distances.modes[ID].icon or "" )
			yPos = yPos + diff
			local DLabel = vgui.Create( "DLabel", DermaPanel )
			DLabel:SetPos( xPos, yPos )
			DLabel:SetSize( 75, 25 )
			DLabel:SetText( "Interface:" )
			local IconUiTextEntry = vgui.Create( "DTextEntry", DermaPanel )
			IconUiTextEntry:SetPos( xPos + 75, yPos )
			IconUiTextEntry:SetSize( 200, 25 )
			IconUiTextEntry:SetText( ID and gspeak.settings.distances.modes[ID].icon_ui or "" )

			yPos = yPos + diff + 10
			local DButton = vgui.Create( "DButton", DermaPanel )
			DButton:SetPos( xPos, yPos )
			DButton:SetText( "Cancel" )
			DButton:SetSize( 125, 25 )
			DButton.DoClick = function()
				DermaPanel:Close()
			end
			local DButton = vgui.Create( "DButton", DermaPanel )
			DButton:SetPos( xPos+150, yPos )
			DButton:SetText( "Save" )
			DButton:SetSize( 125, 25 )
			DButton.DoClick = function()
				local insertion = {
					name = NameTextEntry:GetText(),
					range = tonumber(RangeTextEntry:GetText()),
					icon = IconTextEntry:GetText(),
					icon_ui = IconUiTextEntry:GetText()
				}

				if ID then
					gspeak.settings.distances.modes[ID] = insertion
				else
					table.insert( gspeak.settings.distances.modes, insertion);
				end

				AppList:Refresh( true )
				DermaPanel:Close()
			end
		end
		local DButton = vgui.Create( "DButton", DermaActive )
		DButton:SetPos( xPos, yPos )
		DButton:SetText( "Add" )
		DButton:SetSize( 75, 25 )
		DButton.DoClick = function( Panel )
			EditMode( Panel )
		end

		local DButton = vgui.Create( "DButton", DermaActive )
		DButton:SetPos( xPos+75, yPos )
		DButton:SetText( "Edit" )
		DButton:SetSize( 75, 25 )
		DButton.DoClick = function( Panel )
			local ID = AppList:GetSelectedLine()
			if !ID then gspeak:chat_text("you have to select an Item!", true) return end
			EditMode( Panel, ID )
		end
		local DButton = vgui.Create( "DButton", DermaActive )
		DButton:SetPos( xPos+157, yPos )
		DButton:SetText( "" )
		DButton:SetSize( 30, 25 )
		DButton.DoClick = function()
			local ID = AppList:GetSelectedLine()
			if !ID then gspeak:chat_text("you have to select an Item!", true) return end

			local temp_mode = gspeak.settings.distances.modes[ID]
			local switch_mode = gspeak.settings.distances.modes[ID-1]
			if !switch_mode or !temp_mode then return end

			gspeak.settings.distances.modes[ID-1] = temp_mode
			gspeak.settings.distances.modes[ID] = switch_mode

			AppList:Refresh( true )
			AppList:SelectItem( AppList:GetLine(ID-1) )
		end
		DButton.Paint = function() end
		local DImage = vgui.Create( "DImage", DermaActive )
		DImage:SetPos( xPos+160, yPos )
		DImage:SetSize( 20, 25 )
		DImage:SetImage( "gspeak/arrow_up.png" )

		local DButton = vgui.Create( "DButton", DermaActive )
		DButton:SetPos( xPos+187, yPos )
		DButton:SetText( "" )
		DButton:SetSize( 30, 25 )
		DButton.DoClick = function()
			local ID = AppList:GetSelectedLine()
			if !ID then gspeak:chat_text("you have to select an Item!", true) return end

			local temp_mode = gspeak.settings.distances.modes[ID]
			local switch_mode = gspeak.settings.distances.modes[ID+1]
			if !switch_mode or !temp_mode then return end

			gspeak.settings.distances.modes[ID+1] = temp_mode
			gspeak.settings.distances.modes[ID] = switch_mode

			AppList:Refresh( true )
			AppList:SelectItem( AppList:GetLine(ID+1) )
		end
		DButton.Paint = function() end
		local DImage = vgui.Create( "DImage", DermaActive )
		DImage:SetPos( xPos+187, yPos )
		DImage:SetSize( 20, 25 )
		DImage:SetImage( "gspeak/arrow_down.png" )

		local DButton = vgui.Create( "DButton", DermaActive )
		DButton:SetPos( xPos+325, yPos )
		DButton:SetText( "Remove" )
		DButton:SetSize( 75, 25 )
		DButton.DoClick = function()
			local ID = AppList:GetSelectedLine()
			if !ID then gspeak:chat_text("you have to select an Item!", true) return end

			table.remove( gspeak.settings.distances.modes, ID)
			AppList:Refresh( true )
		end

		yPos = yPos + diff - 20
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 300, 25 )
		DLabel:SetText( "Iconview Range" )
		local DTextEntry = vgui.Create( "DTextEntry", DermaActive )
		DTextEntry:SetName( "distances.iconview" )
		DTextEntry:SetPos( xPos+150, yPos )
		DTextEntry:SetSize( 75, 25 )
		DTextEntry:SetText( gspeak.settings.distances.iconview )
		DTextEntry.OnEnter = gui_change
		yPos = yPos + diff - 20
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 300, 25 )
		DLabel:SetText( "Default Radio Range" )
		local DTextEntry = vgui.Create( "DTextEntry", DermaActive )
		DTextEntry:SetName( "distances.radio" )
		DTextEntry:SetPos( xPos+150, yPos )
		DTextEntry:SetSize( 75, 25 )
		DTextEntry:SetText( gspeak.settings.distances.radio )
		DTextEntry.OnEnter = gui_change
		yPos = yPos + diff - 20
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "distances.heightclamp" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Heightclamp" )
		DSlider:SetMin( 0 )
		DSlider:SetMax( 1 )
		DSlider:SetDecimals( 3 )
		DSlider:SetValue( gspeak.settings.distances.heightclamp )
		DSlider.Think = gui_think_slider

		yPos = yPos + diff - 20
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "def_mode" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Default Talkmode" )
		DSlider:SetMin( 1 )
		DSlider:SetMax( #gspeak.settings.distances.modes )
		DSlider:SetDecimals( 0 )
		DSlider:SetValue( gspeak.settings.def_mode )
		DSlider.Think = gui_think_slider

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Make Ranges visible:" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetPos( xPos+125, yPos )
		DCheckBox:SetValue( gspeak.viewranges )
		DCheckBox.OnChange = function( panel )
			gspeak.viewranges = panel:GetChecked()
		end
	elseif active == 4 then
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Shown above head:" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "head_icon" )
		DCheckBox:SetPos( xPos+125, yPos )
		DCheckBox:SetValue( gspeak.settings.head_icon )
		DCheckBox.OnChange = gui_change
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+150, yPos )
		DLabel:SetSize( 50, 25 )
		DLabel:SetText( "Icon" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "head_name" )
		DCheckBox:SetPos( xPos+200, yPos )
		DCheckBox:SetValue( gspeak.settings.head_name )
		DCheckBox.OnChange = gui_change
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+225, yPos )
		DLabel:SetSize( 50, 25 )
		DLabel:SetText( "Name" )

		yPos = yPos + diff
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "HUD.console.x" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Talk UI x" )
		DSlider:SetMin( 0 )
		DSlider:SetMax( 1 )
		DSlider:SetDecimals( 2 )
		DSlider:SetValue( gspeak.settings.HUD.console.x )
		DSlider.Think = gui_think_slider

		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+300, yPos )
		DLabel:SetSize( 50, 25 )
		DLabel:SetText( "align:" )
		local DMulti = vgui.Create( "DComboBox", DermaActive )
		DMulti:AddChoice("tl")
		DMulti:AddChoice("tr")
		DMulti:AddChoice("bl")
		DMulti:AddChoice("br")
		DMulti:SetName( "HUD.console.align" )
		DMulti:SetPos( xPos+350, yPos )
		DMulti:SetSize( 50, 25 )
		DMulti:SetText( gspeak.settings.HUD.console.align )
		DMulti.OnSelect = gui_change

		yPos = yPos + 25
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "HUD.console.y" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Talk UI y" )
		DSlider:SetMin( 0 )
		DSlider:SetMax( 1 )
		DSlider:SetDecimals( 2 )
		DSlider:SetValue( gspeak.settings.HUD.console.y )
		DSlider.Think = gui_think_slider

		yPos = yPos + 25
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "HUD.status.x" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Status UI x" )
		DSlider:SetMin( 0 )
		DSlider:SetMax( 1 )
		DSlider:SetDecimals( 2 )
		DSlider:SetValue( gspeak.settings.HUD.status.x )
		DSlider.Think = gui_think_slider

		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+300, yPos )
		DLabel:SetSize( 50, 25 )
		DLabel:SetText( "align:" )
		local DMulti = vgui.Create( "DComboBox", DermaActive )
		DMulti:AddChoice("tl")
		DMulti:AddChoice("tr")
		DMulti:AddChoice("bl")
		DMulti:AddChoice("br")
		DMulti:SetName( "HUD.status.align" )
		DMulti:SetPos( xPos+350, yPos )
		DMulti:SetSize( 50, 25 )
		DMulti:SetText( gspeak.settings.HUD.status.align )
		DMulti.OnSelect = gui_change

		yPos = yPos + 25
		local DSlider = vgui.Create( "DNumSlider", DermaActive )
		DSlider:SetName( "HUD.status.y" )
		DSlider:SetPos( xPos, yPos )
		DSlider:SetSize( 300, 25 )
		DSlider:SetText( "Status UI y" )
		DSlider:SetMin( 0 )
		DSlider:SetMax( 1 )
		DSlider:SetDecimals( 2 )
		DSlider:SetValue( gspeak.settings.HUD.status.y )
		DSlider.Think = gui_think_slider

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 200, 25 )
		DLabel:SetText( "Display players nick instead of name" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "nickname" )
		DCheckBox:SetPos( xPos+200, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.nickname )
		DCheckBox.OnChange = gui_change
	elseif active == 5 then
		diff = 40

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 300, 25 )
		DLabel:SetText( "Channel Password" )
		local DTextEntry = vgui.Create( "DTextEntry", DermaActive )
		DTextEntry:SetName( "password" )
		DTextEntry:SetPos( xPos+130, yPos )
		DTextEntry:SetSize( 150, 25 )
		DTextEntry:SetText( gspeak.settings.password )
		DTextEntry.OnEnter = gui_change
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+300, yPos )
		DLabel:SetSize( 300, 25 )
		DLabel:SetText( "(less than 32 characters)" )

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 300, 25 )
		DLabel:SetText( "Command" )
		local DTextEntry = vgui.Create( "DTextEntry", DermaActive )
		DTextEntry:SetName( "cmd" )
		DTextEntry:SetPos( xPos+130, yPos )
		DTextEntry:SetSize( 150, 25 )
		DTextEntry:SetText( gspeak.settings.cmd )
		DTextEntry.OnEnter = gui_change

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 300, 25 )
		DLabel:SetText( "Talkmode Default Key" )
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetName( "def_key" )
		DLabel:SetPos( xPos+130, yPos )
		DLabel:SetSize( 150, 25 )
		DLabel:SetColor( Color( 255, 255, 255, 255 ))
		DLabel:SetTextColor( Color(0,0,255,255) )
		DLabel:SetFont("TnfTiny")
		DLabel:SetMouseInputEnabled( true )
		DLabel:SetText( GetKeyString(gspeak.settings.def_key) )
		DLabel.DoClick = gui_key_trapper
		DLabel.Think = function ( Panel )
			if gspeak.settings[name] != Panel:GetText() then
				Panel:SetText( GetKeyString(gspeak.settings.def_key) )
			end
		end

		yPos = yPos + diff + 10
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Override Default Voice" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "overrideV" )
		DCheckBox:SetPos( xPos+125, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.overrideV )
		DCheckBox.OnChange = gui_change

		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+175, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Override Default Chat" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "overrideC" )
		DCheckBox:SetPos( xPos+300, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.overrideC )
		DCheckBox.OnChange = gui_change

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Dead/Spectator Voicechat" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "dead_chat" )
		DCheckBox:SetPos( xPos+125, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.dead_chat )
		DCheckBox.OnChange = gui_change

		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+175, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Should dead hear living?" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "dead_alive" )
		DCheckBox:SetPos( xPos+300, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.dead_alive )
		DCheckBox.OnChange = gui_change

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Initial move into channel?" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "def_initialForceMove" )
		DCheckBox:SetPos( xPos+125, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.def_initialForceMove )
		DCheckBox.OnChange = gui_change

		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos+175, yPos )
		DLabel:SetSize( 125, 25 )
		DLabel:SetText( "Auto rename players in TS3?" )
		local DCheckBox = vgui.Create( "DCheckBox", DermaActive )
		DCheckBox:SetName( "updateName" )
		DCheckBox:SetPos( xPos+300, yPos+5 )
		DCheckBox:SetValue( gspeak.settings.updateName )
		DCheckBox.OnChange = gui_change

		yPos = yPos + diff
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 300, 25 )
		DLabel:SetText( "IP-Address" )
		local DTextEntry = vgui.Create( "DTextEntry", DermaActive )
		DTextEntry:SetName( "ts_ip" )
		DTextEntry:SetPos( xPos+130, yPos )
		DTextEntry:SetSize( 150, 25 )
		DTextEntry:SetText( gspeak.settings.ts_ip )
		DTextEntry.OnEnter = gui_change
		yPos = yPos + 20
		local DLabel = vgui.Create( "DLabel", DermaActive )
		DLabel:SetPos( xPos, yPos )
		DLabel:SetSize( 450, 25 )
		DLabel:SetText( "note: Just an info for the User, Gspeak will work without an entry" )
	end
	return DermaActive
end

local function OpenConfig()
	local DMenu_active = 1
	local DermaActive
	local DermaPanel = vgui.Create( "DFrame" )
	DermaPanel:Center()
	DermaPanel:SetTitle( "Gspeak Config" )
	DermaPanel:SetDraggable( true )
	DermaPanel:MakePopup()
	DermaPanel:SetSize( 800, 400 )
	DermaPanel.Paint = function( self, w, h )
		draw.RoundedBox( 10, 0, 0, w, h, Color( 75, 75, 80, 255 ) )
	end
	local dsizex, dsizey = DermaPanel:GetSize()
	DermaPanel:SetPos( ScrW()/2-dsizex/2, ScrH()/2-dsizey/2)
	DermaPanel:ShowCloseButton( false )

	DermaActive = DrawContent(DermaPanel, DMenu_active)

	local yPos = 45
	local diff = 52
	local btn_color_idl = Color(50,50,50,255)
	local btn_color_act = Color(6,8,66,255)
	local txt_color = Color(255,255,255,255)
	local DMenu = vgui.Create( "DButton", DermaPanel )
	DMenu:SetPos( 0, yPos )
	DMenu:SetText( "User" )
	DMenu:SetFont("TnfTiny")
	DMenu:SetTextColor( txt_color )
	DMenu:SetSize( 200, diff-2. )
	DMenu.Paint = function( self, w, h )
		if DMenu_active == 1 then
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_act )
		else
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_idl )
		end
	end
	DMenu.DoClick = function()
		DermaActive:Close()
		DMenu_active = 1
		DermaActive = DrawContent(DermaPanel, DMenu_active)
	end

	yPos = yPos + 60
	local DMenu = vgui.Create( "DButton", DermaPanel )
	DMenu:SetPos( 0, yPos )
	DMenu:SetText( "Radio" )
	DMenu:SetFont("TnfTiny")
	DMenu:SetTextColor( txt_color )
	DMenu:SetSize( 200, diff-2 )
	DMenu.Paint = function( self, w, h )
		if DMenu_active == 2 then
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_act )
		else
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_idl )
		end
	end
	DMenu.DoClick = function()
		if !LocalPlayer():IsAdmin() and !LocalPlayer():IsSuperAdmin() then return end
		DermaActive:Close()
		DMenu_active = 2
		DermaActive = DrawContent(DermaPanel, DMenu_active)
	end

	yPos = yPos + diff
	local DMenu = vgui.Create( "DButton", DermaPanel )
	DMenu:SetPos( 0, yPos )
	DMenu:SetText( "Ranges" )
	DMenu:SetFont("TnfTiny")
	DMenu:SetTextColor( txt_color )
	DMenu:SetSize( 200, diff-2 )
	DMenu.Paint = function( self, w, h )
		if DMenu_active == 3 then
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_act )
		else
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_idl )
		end
	end
	DMenu.DoClick = function()
		if !LocalPlayer():IsAdmin() and !LocalPlayer():IsSuperAdmin() then return end
		DermaActive:Close()
		DMenu_active = 3
		DermaActive = DrawContent(DermaPanel, DMenu_active)
	end

	yPos = yPos + diff
	local DMenu = vgui.Create( "DButton", DermaPanel )
	DMenu:SetPos( 0, yPos )
	DMenu:SetText( "Interface" )
	DMenu:SetFont("TnfTiny")
	DMenu:SetTextColor( txt_color )
	DMenu:SetSize( 200, diff-2 )
	DMenu.Paint = function( self, w, h )
		if DMenu_active == 4 then
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_act )
		else
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_idl )
		end
	end
	DMenu.DoClick = function()
		if !LocalPlayer():IsAdmin() and !LocalPlayer():IsSuperAdmin() then return end
		DermaActive:Close()
		DMenu_active = 4
		DermaActive = DrawContent(DermaPanel, DMenu_active)
	end

	yPos = yPos + diff
	local DMenu = vgui.Create( "DButton", DermaPanel )
	DMenu:SetPos( 0, yPos )
	DMenu:SetText( "Teamspeak" )
	DMenu:SetFont("TnfTiny")
	DMenu:SetTextColor( txt_color )
	DMenu:SetSize( 200, diff-2 )
	DMenu.Paint = function( self, w, h )
		if DMenu_active == 5 then
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_act )
		else
			draw.RoundedBox( 0, 0, 0, w, h, btn_color_idl )
		end
	end
	DMenu.DoClick = function()
		if !LocalPlayer():IsAdmin() and !LocalPlayer():IsSuperAdmin() then return end
		DermaActive:Close()
		DMenu_active = 5
		DermaActive = DrawContent(DermaPanel, DMenu_active)
	end

	yPos = yPos + 60
	local DMenu = vgui.Create( "DButton", DermaPanel )
	DMenu:SetPos( 0, yPos )
	DMenu:SetText( "Close" )
	DMenu:SetFont("TnfTiny")
	DMenu:SetTextColor( txt_color )
	DMenu:SetSize( 200, diff-2 )
	DMenu.Paint = function( self, w, h )
		draw.RoundedBox( 0, 0, 0, w, h, btn_color_idl )
	end
	DMenu.DoClick = function()
		DermaPanel:Close()
	end

	local DermaActiveEdge = vgui.Create( "DFrame", DermaPanel )
	DermaActiveEdge:Center()
	DermaActiveEdge:SetTitle("")
	DermaActiveEdge:SetPos( dsizex-20, 0 )
	DermaActiveEdge:SetSize( 20, dsizey )
	DermaActiveEdge.Paint = function( self, w, h )
		draw.RoundedBox( 10, 0, 0, w, h, Color( 100, 100, 100, 255 ) )
	end
	DermaActiveEdge:ShowCloseButton( false )

	return DermaPanel
end
--ConCommand
local MainPanel
concommand.Add( "gspeak", function()
	if MainPanel and MainPanel:IsValid() then
		MainPanel:Close()
	else
		MainPanel = OpenConfig()
	end
end)
