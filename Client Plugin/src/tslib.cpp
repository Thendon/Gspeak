/*
* Gspeak 2.6
* by Thendon.exe
* Sneaky Rocks
*/

#define GMMODULE
#define TSLIB_VERSION 2600

#include <GarrysMod/Lua/Interface.h>
#include <Windows.h>
#include <stdio.h>
#include <list>
#include "shared.h"

struct Clients_local {
	int clientID;
	int entID;
	int radioID;
};

struct Clients *clients;
struct Clients_local *clients_local;
struct Status *status;

struct CMD {
	int key;
	int callback;

	CMD(int key, int callback) : key(key), callback(callback){}
};

std::list<CMD> commandList;

HANDLE hMapFileO;
HANDLE hMapFileV;

TCHAR clientName[] = TEXT("Local\\GMapO");
TCHAR statusName[] = TEXT("Local\\GMapV");

//*************************************
// GSPEAK FUNCTIONS
//*************************************

int gs_printError(lua_State* state, char* error_string, int error_code = -1) {
	LUA->PushSpecial(GarrysMod::Lua::SPECIAL_GLOB);
	LUA->GetField(-1, "print");
	LUA->PushString(error_string);

	if (error_code == -1) {
		LUA->Call(1, 0);
	}
	else {
		LUA->PushNumber(error_code);
		LUA->Call(2, 0);
	}
	LUA->Pop();

	return 0;
}

int gs_openMapFile(lua_State* state, HANDLE *hMapFile, TCHAR *name, unsigned int buf_size) {
	*hMapFile = OpenFileMapping(FILE_MAP_ALL_ACCESS, FALSE, name);
	if (*hMapFile == NULL) {
		int code = GetLastError();
		gs_printError(state, "[Gspeak] error ", code);
		if (code == 5) {
			gs_printError(state, "[Gspeak] access denied - restart Teamspeak3 with Administrator!");
			return 1;
		}
		else if (code == 2) {
			*hMapFile = CreateFileMapping(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0, buf_size, name);
			if (*hMapFile == NULL) {
				gs_printError(state, "[Gspeak] critical error ", GetLastError());
				return 1;
			}
		}
		else {
			gs_printError(state, "[Gspeak] critical error ", GetLastError());
			return 1;
		}
	}
	return 0;
}

int gs_connectTS(lua_State* state)
{
	if (hMapFileO != NULL && hMapFileV != NULL) {
		LUA->PushBool(true);
		return 1;
	}

	if (gs_openMapFile(state, &hMapFileO, clientName, sizeof(Clients)*PLAYER_MAX) == 1 ) {
		LUA->PushBool(false);
		return 1;
	}
	clients = (Clients*)MapViewOfFile(hMapFileO, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(Clients)*PLAYER_MAX);
	clients_local = (Clients_local*)malloc(sizeof(Clients_local)*PLAYER_MAX);
	if (clients == NULL) {
		gs_printError(state, "[Gspeak] mapview error ", GetLastError());
		CloseHandle(hMapFileO);
		hMapFileO = NULL;
		LUA->PushBool(false);
		return 1;
	}

	if (gs_openMapFile(state, &hMapFileV, statusName, sizeof(Status)) == 1) {
		LUA->PushBool(false);
		return 1;
	}
	status = (Status*)MapViewOfFile(hMapFileV, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(Status));
	if (status == NULL) {
		gs_printError(state, "[Gspeak] mapview error ", GetLastError());
		CloseHandle(hMapFileV);
		hMapFileV = NULL;
		LUA->PushBool(false);
		return 1;
	}
	status->tslibV = TSLIB_VERSION;

	LUA->PushBool(true);
	return 1;
}

int gs_discoTS()
{
	UnmapViewOfFile(clients);
	CloseHandle(hMapFileO);
	hMapFileO = NULL;
	clients = NULL;
	UnmapViewOfFile(status);
	CloseHandle(hMapFileV);
	hMapFileV = NULL;
	status = NULL;
	return 0;
}

int gs_searchPlayer(lua_State* state, int clientID, bool *exist)
{
	int free_spot = -1;
	int del_spot = -1;
	int spot = 0;

	for (spot; clients[spot].clientID != 0 && spot < PLAYER_MAX; spot++) {
		//return already claimed spot
		if (clients[spot].clientID == clientID) {
			*exist = true;
			return spot;
		}

		//Check if spot free
		if (clients[spot].clientID == -1) {
			//set first free spot
			if (free_spot == -1) 
				free_spot = spot;
			//set first deletable spot
			if (del_spot == -1)
				del_spot = spot;
		}

		//Check if spot not free
		if (clients[spot].clientID > -1)
			//reset deletable spot
			if (del_spot != -1)
				del_spot = -1;
	}

	//clear spots from first deletable spot to next clientID = 0
	if (del_spot != -1)
		for (int i = del_spot; del_spot <= spot && i < PLAYER_MAX; i++) {
			clients[i].clientID = 0;
			clients_local[i].clientID = 0;
		}

	//return free spot
	if (free_spot > -1)
		return free_spot;
	//return first avaliable spot if nothing was deleted
	if (del_spot == -1)
		return spot;
	//return first deleted spot
	return del_spot;

}

int gs_sendSettings(lua_State* state) {
	LUA->CheckType(1, GarrysMod::Lua::Type::STRING); char* password = (char*)LUA->GetString(1);
	LUA->CheckType(2, GarrysMod::Lua::Type::NUMBER); short radio_downsampler = (short)LUA->GetNumber(2);
	LUA->CheckType(3, GarrysMod::Lua::Type::NUMBER); short radio_distortion = (short)LUA->GetNumber(3);
	LUA->CheckType(4, GarrysMod::Lua::Type::NUMBER); float radio_volume = (float)LUA->GetNumber(4);
	LUA->CheckType(5, GarrysMod::Lua::Type::NUMBER); float radio_volume_noise = (float)LUA->GetNumber(5);

	if (strlen(password) >= PASS_BUF) {
		LUA->PushBool(false);
		return 1;
	}

	strcpy_s(status->password, PASS_BUF*sizeof(char), password);
	status->radio_downsampler = radio_downsampler > 0 ? radio_downsampler : 1;
	status->radio_distortion = radio_distortion;
	status->radio_volume = radio_volume;
	status->radio_volume_noise = radio_volume_noise;

	LUA->PushBool(true);
	return 1;
}

void gs_pushCMD(lua_State* state, int key, int callback) {
	if (commandList.size() >= CMD_BUF) {
		gs_printError(state, "CommandList full - check for sendName / forceMove spam");
		return;
	}
	CMD cmd(key, callback);
	commandList.push_back(cmd);
}

int gs_sendName(lua_State* state) {
	LUA->CheckType(1, GarrysMod::Lua::Type::STRING); char* name = (char*)LUA->GetString(1);

	int callback = -1;
	if (LUA->GetType(2) == GarrysMod::Lua::Type::FUNCTION) {
		LUA->Push(2); 
		callback = LUA->ReferenceCreate();
	}

	if (strlen(name) > NAME_BUF - 2)
		name[NAME_BUF - 2] = '\0';

	strcpy_s(status->name, NAME_BUF * sizeof(char), name);
	gs_pushCMD(state, (int)CMD_RENAME, callback);
	return 0;
}

int gs_compareName(lua_State* state) {
	LUA->CheckType(1, GarrysMod::Lua::Type::STRING); char* name = (char*)LUA->GetString(1);
	if (strlen(name) > NAME_BUF - 2)
		name[NAME_BUF - 2] = '\0';

	if (strcmp(status->name, name) == 0)
		LUA->PushBool(true);
	else
		LUA->PushBool(false);
	return 1;
}

int gs_forceMove(lua_State* state) {
	LUA->CheckType(1, GarrysMod::Lua::Type::FUNCTION); LUA->Push(1); int callback = LUA->ReferenceCreate();
	gs_pushCMD(state, (int)CMD_FORCEMOVE, callback);
	return 0;
}

int gs_update(lua_State* state) {
	//Free reference
	if (status->command == -10) {
		LUA->ReferenceFree(commandList.front().callback);
		status->command = 0;
	}
	else if (status->command < 0) {
		//execute callback function of given cmd; -2 = ERROR; -1 = SUCCESS
		if (commandList.front().callback >= 0) {
			LUA->ReferencePush(commandList.front().callback);
			LUA->PushBool((bool)(status->command == -1));
			LUA->Call(1, 0);
			LUA->Pop();
		}

		//Set ready for next cmd
		commandList.pop_front();
		status->command = 0;
	}
	
	//Ready for next in list
	if (status->command == 0 && commandList.size() > 0) {
		status->command = commandList.front().key;
	}

	return 0;
}

int gs_sendClientPos(lua_State* state) {
	LUA->CheckType(1, GarrysMod::Lua::Type::NUMBER); float forX = (float)LUA->GetNumber(1);
	LUA->CheckType(2, GarrysMod::Lua::Type::NUMBER); float forY = (float)LUA->GetNumber(2);
	LUA->CheckType(3, GarrysMod::Lua::Type::NUMBER); float forZ = (float)LUA->GetNumber(3);
	LUA->CheckType(4, GarrysMod::Lua::Type::NUMBER); float upX = (float)LUA->GetNumber(4);
	LUA->CheckType(5, GarrysMod::Lua::Type::NUMBER); float upY = (float)LUA->GetNumber(5);
	LUA->CheckType(6, GarrysMod::Lua::Type::NUMBER); float upZ = (float)LUA->GetNumber(6);

	status->forward[0] = forX;
	status->forward[1] = forZ; //might be wrong
	status->forward[2] = forY;
	status->upward[0] = upX;
	status->upward[1] = upZ; //might be wrong
	status->upward[2] = upY;
	return 0;
}

int gs_sendPos(lua_State* state)
{
	LUA->CheckType(1, GarrysMod::Lua::Type::NUMBER); int clientID = (int)LUA->GetNumber(1);
	LUA->CheckType(2, GarrysMod::Lua::Type::NUMBER); float volume = (float)LUA->GetNumber(2);
	LUA->CheckType(3, GarrysMod::Lua::Type::NUMBER); int entID = (int)LUA->GetNumber(3);
	LUA->CheckType(4, GarrysMod::Lua::Type::NUMBER); float x = (float)LUA->GetNumber(4);
	LUA->CheckType(5, GarrysMod::Lua::Type::NUMBER); float y = (float)LUA->GetNumber(5);
	LUA->CheckType(6, GarrysMod::Lua::Type::NUMBER); float z = (float)LUA->GetNumber(6);
	LUA->CheckType(7, GarrysMod::Lua::Type::BOOL); bool isRadio = (bool)LUA->GetBool(7);

	int radioID = -1;
	if (isRadio == true) {
		LUA->CheckType(8, GarrysMod::Lua::Type::NUMBER); radioID = (int)LUA->GetNumber(8);
	}

	bool exist = false;
	int i = gs_searchPlayer(state, clientID, &exist);

	if (exist) {
		//if (clients_local[i].clientID == clientID) {
			//If same sending device update data
			if (clients_local[i].radioID == radioID && clients_local[i].entID == entID) {
				clients[i].volume_gm = volume;
				clients[i].pos[0] = x;
				clients[i].pos[1] = z;
				clients[i].pos[2] = y;
				return 0;
			}
			//If other device more far away than stored device return
			else if (volume < clients[i].volume_gm) {
				return 0;
			}
		//}
	}

	//Add new data
	clients[i].clientID = clientID;
	clients[i].volume_gm = volume;
	clients[i].pos[0] = x;
	clients[i].pos[1] = z;
	clients[i].pos[2] = y;
	clients[i].radio = isRadio;

	clients_local[i].clientID = clientID;
	clients_local[i].entID = entID;
	clients_local[i].radioID = radioID;

	LUA->PushSpecial(GarrysMod::Lua::SPECIAL_GLOB);
	LUA->GetField(-1, "gspeak");
	LUA->GetField(-1, "setHearable");
	LUA->PushNumber(entID);
	LUA->PushBool(true);
	LUA->Call(2, 0);
	LUA->Pop();

	return 0;
}

int gs_delPos(lua_State* state) {
	LUA->CheckType(1, GarrysMod::Lua::Type::NUMBER); int entID = (int)LUA->GetNumber(1);
	LUA->CheckType(2, GarrysMod::Lua::Type::BOOL); bool isRadio = (bool)LUA->GetBool(2);

	int radioID = -1;
	if (isRadio == true) {
		LUA->CheckType(3, GarrysMod::Lua::Type::NUMBER); radioID = (int)LUA->GetNumber(3);
	}

	for (int i = 0; clients[i].clientID != 0 && i < PLAYER_MAX; i++) {
		if (clients_local[i].entID == entID && clients_local[i].radioID == radioID) {
			clients[i].clientID = -1;
			clients_local[i].clientID = -1;
			break;
		}
	}

	LUA->PushSpecial(GarrysMod::Lua::SPECIAL_GLOB);
	LUA->GetField(-1, "gspeak");
	LUA->GetField(-1, "setHearable");
	LUA->PushNumber(entID);
	LUA->PushBool(false);
	LUA->Call(2, 0);
	LUA->Pop();

	return 0;
}

int gs_delAll(lua_State* state) {
	for (int i = 0; clients[i].clientID != 0 && i < PLAYER_MAX; i++) {
		clients[i].clientID = 0;
		clients_local[i].clientID = 0;
	}
	return 0;
}

int gs_getTsID(lua_State* state) {
	if (status->gspeakV == 0) LUA->PushNumber(-1);
	else LUA->PushNumber(status->clientID);
	return 1;
}

int gs_getInChannel(lua_State* state) {
	if (status->clientID == -1 || status->gspeakV == 0) LUA->PushBool(false);
	else LUA->PushBool(true);
	return 1;
}

int gs_getArray(lua_State* state) {
	char it[3];
	LUA->PushSpecial(GarrysMod::Lua::Type::TABLE);
	LUA->CreateTable();
	for (int i = 0; i < PLAYER_MAX; i++) {
		LUA->PushNumber(clients[i].clientID);
		sprintf_s(it, sizeof(it), "%d", i);
		LUA->SetField(-2, it);
	}
	return 1;
}

int gs_talkCheck(lua_State* state) {
	if (status->talking == true) {
		LUA->PushBool(true);
	}
	else {
		LUA->PushBool(false);
	}
	return 1;
}

int gs_getGspeakVersion(lua_State* state) {
	LUA->PushNumber(status->gspeakV);
	return 1;
}

int gs_getName(lua_State* state) {
	LUA->PushString(status->name);
	return 1;
}

int gs_getTslibVersion(lua_State* state) {
	LUA->PushNumber(TSLIB_VERSION);
	return 1;
}

int gs_getAllID(lua_State* state) {
	char it[3];
	LUA->PushSpecial(GarrysMod::Lua::Type::TABLE);
	LUA->CreateTable();
	for (int i = 0; clients[i].clientID != 0 && i < PLAYER_MAX; i++) {
		if (clients[i].clientID != -1){
			LUA->CreateTable();
			LUA->PushNumber(clients_local[i].entID); LUA->SetField(-2, "ent_id");
			LUA->PushBool(clients[i].radio); LUA->SetField(-2, "radio");
			LUA->PushNumber(clients_local[i].radioID); LUA->SetField(-2, "radio_id");
			LUA->PushNumber(clients[i].volume_ts); LUA->SetField(-2, "volume");
			LUA->PushBool(clients[i].talking); LUA->SetField(-2, "talking");
			sprintf_s(it, sizeof(it),"%d", i);
			LUA->SetField(-2, it);
		}
	}

	return 1;
}

//*************************************
// REQUIRED GMOD FUNCTIONS
//*************************************

GMOD_MODULE_OPEN()
{
	LUA->PushSpecial(GarrysMod::Lua::SPECIAL_GLOB);
	LUA->CreateTable();
	LUA->PushCFunction(gs_connectTS); LUA->SetField(-2, "connectTS");
	LUA->PushCFunction(gs_sendSettings); LUA->SetField(-2, "sendSettings");
	LUA->PushCFunction(gs_sendName); LUA->SetField(-2, "sendName");
	LUA->PushCFunction(gs_getName); LUA->SetField(-2, "getName");
	LUA->PushCFunction(gs_compareName); LUA->SetField(-2, "compareName");
	LUA->PushCFunction(gs_forceMove); LUA->SetField(-2, "forceMove");
	LUA->PushCFunction(gs_update); LUA->SetField(-2, "update");
	LUA->PushCFunction(gs_sendClientPos); LUA->SetField(-2, "sendClientPos");
	LUA->PushCFunction(gs_sendPos); LUA->SetField(-2, "sendPos");
	LUA->PushCFunction(gs_delPos); LUA->SetField(-2, "delPos");
	LUA->PushCFunction(gs_delAll); LUA->SetField(-2, "delAll");
	LUA->PushCFunction(gs_getTsID); LUA->SetField(-2, "getTsID");
	LUA->PushCFunction(gs_getInChannel); LUA->SetField(-2, "getInChannel");
	LUA->PushCFunction(gs_getArray); LUA->SetField(-2, "getArray");
	LUA->PushCFunction(gs_talkCheck); LUA->SetField(-2, "talkCheck");
	LUA->PushCFunction(gs_getGspeakVersion); LUA->SetField(-2, "getGspeakVersion");
	LUA->PushCFunction(gs_getTslibVersion); LUA->SetField(-2, "getVersion");
	//LUA->PushCFunction(gs_getVolumeOf); LUA->SetField(-2, "getVolumeOf");
	LUA->PushCFunction(gs_getAllID); LUA->SetField(-2, "getAllID");
	LUA->SetField(-2, "tslib");
	LUA->Pop();
	return 0;
}

GMOD_MODULE_CLOSE()
{
	gs_discoTS();
	return 0;
}