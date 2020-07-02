#ifndef SHARED_H
#define SHARED_H

//#define RADIO_BUF 32
#define PASS_BUF 32
#define PLAYER_MAX 64
#define NAME_BUF 32

#define CMD_RENAME 1
#define CMD_FORCEMOVE 2
#define CMD_KICK 3
#define CMD_BAN 4
#define CMD_BUF 16

struct Clients {
	short clientID;
	float pos[3];
	float volume_gm;
	float volume_ts;
	bool radio;
	bool talking;
};

struct Status {
	short clientID;
	char name[NAME_BUF];
	short tslibV;
	short gspeakV;
	short radio_downsampler;
	short radio_distortion;
	float upward[3];
	float forward[3];
	float radio_volume;
	float radio_volume_noise;
	char password[PASS_BUF];
	bool status; 
	bool talking;
	int command;
};

bool gs_inChannel(Status *status);
bool gs_gmodOnline(Status *status);
bool gs_tsOnline(Status *status);

#endif