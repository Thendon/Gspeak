#include "shared.h"

bool gs_inChannel( Status *status ) {
	return status->clientID > -1;
}

//Not realy save to say though
bool gs_gmodOnline(Status *status) {
	return !(status->tslibV <= 0);
}

bool gs_tsOnline(Status *status) {
	return !(status->gspeakV <= 0);
}