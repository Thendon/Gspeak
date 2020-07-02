local last_load_w = 0
local last_load_a = 0

function gspeak_players_create_list( DList )
	if !gspeak.hearable then return end
	if last_load_w > CurTime() - 1 then return end
	last_load_w = CurTime()
	DList:Clear()

	for k, v in pairs(gspeak.hearable) do
		local radio = v.radio_id
		local ent = v.ent_id
		local id = tonumber(k)
		local talking = false
		if v.radio and gspeak:radio_valid(Entity(v.radio_id)) and gspeak:player_valid(Entity(v.radio_id):GetSpeaker()) then
			radio = gspeak:GetName( Entity(v.radio_id):GetSpeaker() )
		else
			radio = ""
		end
		if gspeak:player_valid(Entity(v.ent_id)) then
			ent = Entity(v.ent_id)
		elseif gspeak:radio_valid(Entity(v.ent_id)) and gspeak:player_valid(Entity(v.ent_id):GetSpeaker()) then
			ent = Entity(v.ent_id):GetSpeaker()
		end
		if id < 10 then
			id = tostring("0"..id)
		end

		DList:AddLine( id, gspeak:GetName( ent ), v.radio, radio, ent.talking )
	end
	DList:SortByColumn( 1 )
end

function gspeak_array_create_list( DList )
	if last_load_a > CurTime() - 1 then return end
	last_load_a = CurTime()
	DList:Clear()
	--local players_hearable = tslib.getAllID()
	for k, v in pairs(tslib.getArray()) do
		DList:AddLine( tonumber(k), v )
	end
	DList:SortByColumn( 1 )
end

concommand.Add("gspeakwho", function()
	if gspeak.who == nil or gspeak.who == false then
		Gspeak_who_list = vgui.Create( "DListView" )
		Gspeak_who_list:SetSize( 450, 450 )
		Gspeak_who_list:SetPos( 25, 200 )
		Gspeak_who_list:AddColumn( "ID" ):SetFixedWidth( 25 )
		Gspeak_who_list:AddColumn( "Who?" )
		Gspeak_who_list:AddColumn( "Radio?..." ):SetFixedWidth( 50 )
		Gspeak_who_list:AddColumn( "...of" )
		Gspeak_who_list:AddColumn( "talking?" ):SetFixedWidth( 50 )
		Gspeak_who_list:SetSortable( false )
		Gspeak_who_list.Think = gspeak_players_create_list
		gspeak.who = true
	else
		Gspeak_who_list:Remove()
		gspeak.who = false
	end
end)

concommand.Add("gspeakarray", function()
	if gspeak.array == nil or gspeak.array == false then
		Gspeak_array_list = vgui.Create( "DListView" )
		Gspeak_array_list:SetSize( 100, 1050 )
		Gspeak_array_list:SetPos( 1820, 0 )
		Gspeak_array_list:AddColumn( "It" ):SetFixedWidth( 25 )
		Gspeak_array_list:AddColumn( "clientID" ):SetFixedWidth( 75 )
		Gspeak_array_list:SetSortable( false )
		Gspeak_array_list.Think = gspeak_array_create_list
		gspeak.array = true
	else
		Gspeak_array_list:Remove()
		gspeak.array = false
	end
end)
