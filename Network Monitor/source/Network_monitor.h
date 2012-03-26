//#Network Monitor licence GPL v3.0 http://www.gnu.org/copyleft/gpl.html
struct station{
	char IP[64];
	char mac[64];
	char owner[256];
	struct station *next;
};

typedef struct station station_T;
