/*
* Gspeak 2.6
* by Thendon.exe
* Sneaky Rocks
*/

#ifdef _WIN32
#pragma warning (disable : 4100)  /* Disable Unreferenced parameter warning */
#include <Windows.h>
#endif

#include <stdio.h>
#include <thread>
#include <ts3_functions.h>
#include <teamspeak/public_errors.h>
#include <teamspeak/public_errors_rare.h>
#include <teamspeak/public_definitions.h>
#include <teamspeak/public_rare_definitions.h>
#include "shared.h"
#include "gspeak.h"
#include <string>

static struct TS3Functions ts3Functions;

#ifdef _WIN32
#define _strcpy(dest, destSize, src) strcpy_s(dest, destSize, src)
#define snprintf sprintf_s
#else
#define _strcpy(dest, destSize, src) { strncpy(dest, src, destSize-1); (dest)[destSize-1] = '\0'; }
#endif
#define PLUGIN_API_VERSION 24

#define PATH_BUFSIZE 512
#define COMMAND_BUFSIZE 128
#define INFODATA_BUFSIZE 128
#define SERVERINFO_BUFSIZE 256
#define CHANNELINFO_BUFSIZE 512
#define RETURNCODE_BUFSIZE 128

#define GSPEAK_VERSION 2600
#define SCAN_SPEED 100
#define VOLUME_MAX 1800
#define SHORT_SIZE 32767

static char* pluginID = NULL;

#ifdef _WIN32
static int wcharToUtf8(const wchar_t* str, char** result) {
	int outlen = WideCharToMultiByte(CP_UTF8, 0, str, -1, 0, 0, 0, 0);
	*result = (char*)malloc(outlen);
	if (WideCharToMultiByte(CP_UTF8, 0, str, -1, *result, outlen, 0, 0) == 0) {
		*result = NULL;
		return -1;
	}
	return 0;
}
#endif

struct Clients *clients;
struct Status *status;

HANDLE hMapFileO;
HANDLE hMapFileV;

TCHAR clientName[] = TEXT("Local\\GMapO");
TCHAR statusName[] = TEXT("Local\\GMapV");

bool statusThreadActive;
bool statusThreadBreak;
bool clientThreadActive;
bool clientThreadBreak;

using namespace std;
//*************************************
// REQUIRED TEAMSPEAK3 FUNCTIONS
//*************************************

const char* ts3plugin_name() {
#ifdef _WIN32
	static char* result = NULL;
	if (!result) {
		const wchar_t* name = L"Gspeak2";
		if (wcharToUtf8(name, &result) == -1) {
			result = "Gspeak2";
		}
	}
	return result;
#else
	return "Gspeak2";
#endif
}

const char* ts3plugin_version() {
	return "2.6";
}

int ts3plugin_apiVersion() {
	return PLUGIN_API_VERSION;
}

const char* ts3plugin_author() {
	return "Sneaky Rocks GbR";
}

const char* ts3plugin_description() {
	return "This plugin connects Garry's Mod with Teamspeak3";
}

void ts3plugin_setFunctionPointers(const struct TS3Functions funcs) {
	ts3Functions = funcs;
}

int ts3plugin_init() {
	printf("[Gspeak] init\n");

	//Open shared memory struct: status
	if (gs_openMapFile(&hMapFileV, statusName, sizeof(Status)) == 1) {
		return 1;
	} 
	status = (Status*)malloc(sizeof(Status));
	status = (Status*)MapViewOfFile(hMapFileV, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(Status));
	if (status == NULL) {
		gs_criticalError(GetLastError());
		printf("[Gspeak] could not view file\n");
		CloseHandle(hMapFileV);
		hMapFileV = NULL;
		return 1;
	}
	status->gspeakV = GSPEAK_VERSION;
	status->command = 0;
	status->clientID = -1;

	//Check for Gspeak Channel
	uint64 serverID = ts3Functions.getCurrentServerConnectionHandlerID();
	anyID clientID;
	if (ts3Functions.getClientID(serverID, &clientID) == ERROR_ok) {
		uint64 channelID;
		if (ts3Functions.getChannelOfClient(serverID, clientID, &channelID) == ERROR_ok) {
			if (gs_isChannel(serverID, channelID)) {
				gs_setActive(serverID, channelID);
				return 0;
			}
		}
	}

	gs_setIdle();
	return 0;
}

void ts3plugin_shutdown() {
	printf("[Gspeak] shutdown\n");

	thread wait(gs_shutdown);
	wait.join();

	if (pluginID) {
		free(pluginID);
		pluginID = NULL;
	}
}

//*************************************
// GSPEAK FUNCTIONS
//*************************************

void gs_initClients(uint64 serverConnectionHandlerID, uint64 channelID) {
	clientThreadBreak = false;
	thread(gs_clientThread, serverConnectionHandlerID, channelID).detach();
}

void gs_initStatus() {
	statusThreadBreak = false;
	thread(gs_statusThread).detach();
}

void gs_shutClients() {
	clientThreadBreak = true;
}

void gs_shutStatus() {
	statusThreadBreak = true;
}

void gs_setIdle() {
	gs_shutClients();
	gs_initStatus();
}

void gs_setActive(uint64 serverConnectionHandlerID, uint64 channelID) {
	gs_shutStatus();
	gs_initClients(serverConnectionHandlerID, channelID);
}

void gs_shutdown() {
	status->gspeakV = -1;

	if (clientThreadActive) gs_shutClients();
	if (statusThreadActive) gs_shutStatus();
	while (true) {
		if (!clientThreadActive && !statusThreadActive) {
			UnmapViewOfFile(status);
			CloseHandle(hMapFileV);
			hMapFileV = NULL;
			status = NULL;
			break;
		}
		this_thread::sleep_for(chrono::milliseconds(SCAN_SPEED));
	}
}

void gs_criticalError(int errorCode) {
	char msg[48];
	sprintf(msg, "[Gspeak] critical error - Code: %d", errorCode);
	ts3Functions.printMessageToCurrentTab(msg);
	printf("%s\n", msg);
}

int gs_openMapFile(HANDLE *hMapFile, TCHAR *name, unsigned int buf_size) {
	*hMapFile = OpenFileMapping(FILE_MAP_ALL_ACCESS, FALSE, name);
	if (*hMapFile == NULL) {
		int code = GetLastError();
		printf("[Gspeak] error code - %d\n", code);
		if (code == 5) {
			ts3Functions.printMessageToCurrentTab("[Gspeak] access denied - restart Teamspeak3 with Administrator!");
			return 1;
		}
		else if (code == 2) {
			*hMapFile = CreateFileMapping(INVALID_HANDLE_VALUE, NULL, PAGE_READWRITE, 0, buf_size, name);
			if (*hMapFile == NULL) {
				gs_criticalError(GetLastError());
				return 1;
			}
		}
		else {
			gs_criticalError(GetLastError());
			return 1;
		}
	}
	return 0;
}

bool gs_searchChannel(uint64 serverConnectionHandlerID, anyID clientID) {
	uint64 *channels;
	if (ts3Functions.getChannelList(serverConnectionHandlerID, &channels) == ERROR_ok) {
		uint64 localChannelID;
		if (ts3Functions.getChannelOfClient(serverConnectionHandlerID, clientID, &localChannelID) != ERROR_ok) 
			return false;

		if (gs_isChannel(serverConnectionHandlerID, localChannelID))
			return true;

		for (int i = 0; channels[i]; i++) {
			if (channels[i] == localChannelID)
				continue;

			if (gs_isChannel(serverConnectionHandlerID, channels[i])) {
				if (ts3Functions.requestClientMove(serverConnectionHandlerID, clientID, channels[i], status->password, NULL) == ERROR_ok)
					return true;
			}
		}
	}
	return false;
}

void gs_clientMoved(uint64 serverConnectionHandlerID, anyID clientID, uint64 channelID) {
	anyID localClientID;
	if (ts3Functions.getClientID(serverConnectionHandlerID, &localClientID) != ERROR_ok) return;
	uint64 localChannelID;
	if (ts3Functions.getChannelOfClient(serverConnectionHandlerID, localClientID, &localChannelID) != ERROR_ok) return;
	if (localChannelID == 0 || channelID == 0) return; //Leaving Server or closing Teamspeak

	if (localClientID == clientID) {
		if (gs_isChannel(serverConnectionHandlerID, channelID))
			gs_setActive(serverConnectionHandlerID, channelID);
		else if (clientThreadActive)
			gs_setIdle();
	}
}

bool gs_isChannel(uint64 serverConnectionHandlerID, uint64 channelID) {
	char *chname;
	if (ts3Functions.getChannelVariableAsString(serverConnectionHandlerID, channelID, CHANNEL_NAME, &chname) == ERROR_ok) {
		std::string str(chname);
		if (str.find("Gspeak") != string::npos) { //MAY CHANGE TO ID
			return true;
		}
	}
	return false;
}

void gs_scanClients(uint64 serverConnectionHandlerID) {
	TS3_VECTOR position;
	for (int i = 0; clients[i].clientID != 0 && i < PLAYER_MAX; i++) {
		position.x = clients[i].pos[0];
		position.y = clients[i].pos[1];
		position.z = clients[i].pos[2];
		ts3Functions.channelset3DAttributes(serverConnectionHandlerID, clients[i].clientID, &position);
	}
}

void gs_cmdCheck(uint64 serverConnectionHandlerID, anyID clientID) {
	if (status->command <= 0)
		return;

	bool success;
	switch (status->command) {
	case CMD_RENAME:
		success = gs_nameCheck(serverConnectionHandlerID, clientID);
		break;
	case CMD_FORCEMOVE:
		success = gs_searchChannel(serverConnectionHandlerID, clientID);
		break;
	}

	if (!success)
	{
		status->command = -2;
		return;
	}

	status->command = -1;
}
/*
void gs_kickClient(uint64 serverConnectionHandlerID, anyID clientID) {
	ts3Functions.requestClientKickFromChannel(serverConnectionHandlerID, clientID, "Gspeak Kick Command", NULL);
}
*/
bool gs_nameCheck(uint64 serverConnectionHandlerID, anyID clientID) {
	if (!gs_inChannel( status ))
		return false;

	char* clientName;
	ts3Functions.getClientVariableAsString(serverConnectionHandlerID, clientID, CLIENT_NICKNAME, &clientName);

	if (strlen(status->name) < 1)
		return true;
	if (strcmp(clientName, status->name) == 0)
		return true;

	if (ts3Functions.setClientSelfVariableAsString(serverConnectionHandlerID, CLIENT_NICKNAME, status->name) != ERROR_ok)
		return false;

	ts3Functions.flushClientSelfUpdates(serverConnectionHandlerID, NULL);
	return true;
}

void gs_setStatusName(uint64 serverConnectionHandlerID, anyID clientID, char* clientName = NULL ) {
	if (!gs_isMe(serverConnectionHandlerID, clientID))
		return;
	if(clientName == NULL)
		ts3Functions.getClientVariableAsString(serverConnectionHandlerID, clientID, CLIENT_NICKNAME, &clientName);

	//causing crashes for special characters
	strcpy_s(status->name, NAME_BUF * sizeof(char), clientName);
}

void gs_clientThread(uint64 serverConnectionHandlerID, uint64 channelID) {
	clientThreadActive = true;
	printf("[Gspeak] clientThread created\n");

	//Open shared memory struct: clients
	if (gs_openMapFile(&hMapFileO, clientName, sizeof(Clients)*PLAYER_MAX) == 1) {
		printf("[Gspeak] openMapFile error\n");
		return;
	}
	clients = (Clients*)MapViewOfFile(hMapFileO, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(Clients)*PLAYER_MAX);
	if (clients == NULL) {
		gs_criticalError(GetLastError());
		printf("[Gspeak] could not view file\n");
		CloseHandle(hMapFileO);
		hMapFileO = NULL;
		return;
	}
	printf("[Gspeak] has been loaded successfully\n");
	ts3Functions.printMessageToCurrentTab("[Gspeak] has been loaded successfully!");

	TS3_VECTOR zero = { 0.0f, 0.0f, 0.0f };
	TS3_VECTOR forward;
	TS3_VECTOR upward;

	anyID clientID;
	ts3Functions.getClientID(serverConnectionHandlerID, &clientID);
	gs_setStatusName(serverConnectionHandlerID, clientID);

	while (!clientThreadBreak) {
		ts3Functions.getClientID(serverConnectionHandlerID, &clientID);
		if (clientID != status->clientID) {
			status->clientID = clientID;
		}
		gs_cmdCheck(serverConnectionHandlerID, clientID);

		forward.x = status->forward[0];
		forward.y = status->forward[1];
		forward.z = status->forward[2];
		upward.x = status->upward[0];
		upward.y = status->upward[1];
		upward.z = status->upward[2];
		ts3Functions.systemset3DListenerAttributes(serverConnectionHandlerID, &zero, &forward, &upward);

		gs_scanClients(serverConnectionHandlerID);

		this_thread::sleep_for(chrono::milliseconds(SCAN_SPEED));
	}	

	UnmapViewOfFile(clients);
	CloseHandle(hMapFileO);
	hMapFileO = NULL;
	clients = NULL;
	ts3Functions.printMessageToCurrentTab("[Gspeak] has been shut down!");

	status->clientID = -1;
	clientThreadActive = false;
	printf("[Gspeak] clientThread destroyed\n");
}

void gs_statusThread() {
	printf("[Gspeak] statusThread created\n");
	statusThreadActive = true;
	while (!statusThreadBreak) {
		//Gmod initialized
		if (status->tslibV > 0) {
			uint64 serverID = ts3Functions.getCurrentServerConnectionHandlerID();
			anyID clientID;
			if (ts3Functions.getClientID(serverID, &clientID) == ERROR_ok) {
				gs_cmdCheck(serverID, clientID);
			}
		}

		this_thread::sleep_for(chrono::milliseconds(SCAN_SPEED));
	}
	statusThreadActive = false;
	printf("[Gspeak] statusThread destroyed\n");
}

int gs_findClient(anyID clientID) {
	for (int i = 0; clients[i].clientID != 0 && i < PLAYER_MAX; i++) {
		if (clients[i].clientID == clientID) return i;
	}
	return -1;
}

void ts3plugin_onClientDisplayNameChanged(uint64 serverConnectionHandlerID, anyID clientID, const char* displayName, const char* uniqueClientIdentifier) {
	gs_setStatusName(serverConnectionHandlerID, clientID, (char*)displayName);
}

void ts3plugin_onClientMoveEvent(uint64 serverConnectionHandlerID, anyID clientID, uint64 oldChannelID, uint64 newChannelID, int visibility, const char* moveMessage) {
	gs_clientMoved(serverConnectionHandlerID, clientID, newChannelID);
}

void ts3plugin_onClientMoveMovedEvent(uint64 serverConnectionHandlerID, anyID clientID, uint64 oldChannelID, uint64 newChannelID, int visibility, anyID moverID, const char* moverName, const char* moverUniqueIdentifier, const char* moveMessage) {
	gs_clientMoved(serverConnectionHandlerID, clientID, newChannelID);
}

void ts3plugin_onConnectStatusChangeEvent(uint64 serverConnectionHandlerID, int newStatus, unsigned int errorNumber) {
	if (newStatus == STATUS_DISCONNECTED)
		if (clientThreadActive)
			gs_setIdle();

	if (newStatus == STATUS_CONNECTION_ESTABLISHED && errorNumber == ERROR_ok){
		//ALL FINE
	}
}

bool gs_isMe(uint64 serverConnectionHandlerID, anyID clientID) {
	anyID localClientID;
	ts3Functions.getClientID(serverConnectionHandlerID, &localClientID);
	if (localClientID == clientID) return true;
	return false;
}

void ts3plugin_onTalkStatusChangeEvent(uint64 serverConnectionHandlerID, int talkStatus, int isReceivedWhisper, anyID clientID) {
	if (!clientThreadActive) return;
	if (gs_isMe(serverConnectionHandlerID, clientID)) {
		if (talkStatus == STATUS_TALKING) status->talking = true;
		else status->talking = false;
	}
	else {
		int it = gs_findClient(clientID);
		if (it > -1) {
			if (talkStatus != STATUS_TALKING) clients[it].talking = false;
		}
	}
}

void ts3plugin_onCustom3dRolloffCalculationClientEvent(uint64 serverConnectionHandlerID, anyID clientID, float distance, float* volume) {
	if (!clientThreadActive) return;
	*volume = 1.0f;
}

void ts3plugin_onEditPostProcessVoiceDataEvent(uint64 serverConnectionHandlerID, anyID clientID, short* samples, int sampleCount, int channels, const unsigned int* channelSpeakerArray, unsigned int* channelFillMask) {
	if (!clientThreadActive) return;
	int it = gs_findClient(clientID);

	//If a client was found in array
	if (it > -1) {
		if (clients[it].talking != true) clients[it].talking = true;
		//If volume between 0 and 1
		if (clients[it].volume_gm > 0 && clients[it].volume_gm <= 1) {
			float sum = 0;
			for (int i = 0; i < sampleCount; i++) {
				unsigned short sample_it = i * channels;
				//Average volume detection for mouth move animation
				if (samples[sample_it] > VOLUME_MAX) sum += VOLUME_MAX;
				else sum += abs(samples[sample_it]);

				if (clients[it].radio){
					if (i % status->radio_downsampler == 0) {
						//Noise
						float noise = (((float)rand() / RAND_MAX) * SHORT_SIZE * 2) - SHORT_SIZE;
						for (int j = 0; j < channels; j++) {
							//Distortion
							short sample_new = (short)((samples[sample_it] > status->radio_distortion ? status->radio_distortion : samples[sample_it] < status->radio_distortion*(-1) ? status->radio_distortion*(-1) : samples[sample_it]) * status->radio_volume * clients[it].volume_gm);
							short sample_noise = (short)(sample_new + noise * status->radio_volume_noise);
							//Downsampling future samples
							bool temp_bool = false;
							for (int n = 0; n < status->radio_downsampler; n++) {
								int temp_it = sample_it + j + n * channels;
								if (temp_bool) {
									samples[temp_it] = sample_noise;
									temp_bool = false;
								}
								else {
									samples[temp_it] = sample_new;
									temp_bool = true;
								}
							}
						}
					}
				}
				else {
					for (int j = 0; j < channels; j++) {
						samples[sample_it + j] = (short)(samples[sample_it + j] * clients[it].volume_gm);
					}
				} 
			}
			//Sending average volume to Gmod
			clients[it].volume_ts = sum / sampleCount / VOLUME_MAX;
			return;
		}
		clients[it].volume_ts = 0;
	}
	for (int i = 0; i < sampleCount; i++) {
		short sample_it = i * channels;
		for (int j = 0; j < channels; j++) {
			samples[sample_it + j] = 0;
		}
	}
}