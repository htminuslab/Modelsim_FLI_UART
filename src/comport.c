//-------------------------------------------------------------------------------------------------
// Modelsim_FLI_UART
//
// Windows Serial port interface
// Copied from various sources on the web (can't remember from where..)
//
// https://github.com/htminuslab            
//  
//-------------------------------------------------------------------------------------------------
// Version   Author          Date          Changes
// 0.1       Hans Tiggeler   13 May 2003   Tested on Modelsim SE 5.7b 
// 0.2       Hans Tiggeler   ??            open_comport/poll_command changed/added
//-------------------------------------------------------------------------------------------------

#include "uart_fli.h"

extern int debug;

void close_comport(HANDLE port)
{
	flushcom(port);
	CloseHandle(port);
	if (debug) mti_PrintMessage("Comport closed\n");
}


void flushcom(HANDLE port)
{
	PurgeComm(port, PURGE_RXCLEAR | PURGE_RXABORT);
	PurgeComm(port, PURGE_TXCLEAR | PURGE_TXABORT);
} 

HANDLE open_comport(char *devicename, int baudrate, int flowctrl)
{
	char mode[]={ '8','N','1',0 };
	char mode_str[128];
	HANDLE port;										// Handle to the serial port

	switch(baudrate) {
		case     110 : strcpy(mode_str, "baud=110");
			break;
		case     300 : strcpy(mode_str, "baud=300");
			break;
		case     600 : strcpy(mode_str, "baud=600");
			break;
		case    1200 : strcpy(mode_str, "baud=1200");
			break;
		case    2400 : strcpy(mode_str, "baud=2400");
			break;
		case    4800 : strcpy(mode_str, "baud=4800");
			break;
		case    9600 : strcpy(mode_str, "baud=9600");
			break;
		case   19200 : strcpy(mode_str, "baud=19200");
			break;
		case   38400 : strcpy(mode_str, "baud=38400");
			break;
		case   57600 : strcpy(mode_str, "baud=57600");
			break;
		case  115200 : strcpy(mode_str, "baud=115200");
			break;
		case  128000 : strcpy(mode_str, "baud=128000");
			break;
		case  256000 : strcpy(mode_str, "baud=256000");
			break;
		case  500000 : strcpy(mode_str, "baud=500000");
			break;
		case  921600 : strcpy(mode_str, "baud=921600");
			break;
		case 1000000 : strcpy(mode_str, "baud=1000000");
			break;
		case 1500000 : strcpy(mode_str, "baud=1500000");
			break;
		case 2000000 : strcpy(mode_str, "baud=2000000");
			break;
		case 3000000 : strcpy(mode_str, "baud=3000000");
			break;
		default      : printf("invalid baudrate\n");
			return(NULL);
			break;
	}

	if (strlen(mode) != 3){
		printf("invalid mode \"%s\"\n", mode);
		return(NULL);
	}

	switch(mode[0])	{
		case '8': strcat(mode_str, " data=8");
			break;
		case '7': strcat(mode_str, " data=7");
			break;
		case '6': strcat(mode_str, " data=6");
			break;
		case '5': strcat(mode_str, " data=5");
			break;
		default : printf("invalid number of data-bits '%c'\n", mode[0]);
			return(NULL);
			break;
	}

	switch(mode[1])	{
		case 'N':
		case 'n': strcat(mode_str, " parity=n");
			break;
		case 'E':
		case 'e': strcat(mode_str, " parity=e");
			break;
		case 'O':
		case 'o': strcat(mode_str, " parity=o");
			break;
		default : printf("invalid parity '%c'\n", mode[1]);
			return(NULL);
			break;
	}

	switch(mode[2])	{
		case '1': strcat(mode_str, " stop=1");
			break;
		case '2': strcat(mode_str, " stop=2");
			break;
		default : printf("invalid number of stop bits '%c'\n", mode[2]);
			return(NULL);
			break;
	}

	if (flowctrl){
		strcat(mode_str, " xon=off to=off odsr=off dtr=on rts=off");
	} else {
		strcat(mode_str, " xon=off to=off odsr=off dtr=on rts=on");
	}


	port = CreateFileA(devicename,
		GENERIC_READ|GENERIC_WRITE,
		0,                          /* no share  */
		NULL,                       /* no security */
		OPEN_EXISTING,
		0,                          /* no threads */
		NULL);                      /* no templates */

	if (port==INVALID_HANDLE_VALUE) {
		printf("unable to open comport\n");
		return(NULL);
	}

	DCB port_settings;
	memset(&port_settings, 0, sizeof(port_settings));  /* clear the new struct  */
	port_settings.DCBlength = sizeof(port_settings);

	if (!BuildCommDCBA(mode_str, &port_settings)) {
		printf("unable to set comport dcb settings\n");
		CloseHandle(port);
		return(NULL);
	}

	if (flowctrl) {
		port_settings.fOutxCtsFlow = TRUE;
		port_settings.fRtsControl = RTS_CONTROL_HANDSHAKE;
	}

	if (!SetCommState(port, &port_settings)) {
		printf("unable to set comport cfg settings\n");
		CloseHandle(port);
		return(NULL);
	}

	COMMTIMEOUTS Cptimeouts;

	Cptimeouts.ReadIntervalTimeout         = MAXDWORD;
	Cptimeouts.ReadTotalTimeoutMultiplier  = 0;
	Cptimeouts.ReadTotalTimeoutConstant    = 0;
	Cptimeouts.WriteTotalTimeoutMultiplier = 0;
	Cptimeouts.WriteTotalTimeoutConstant   = 0;

	if (!SetCommTimeouts(port, &Cptimeouts))	{
		printf("unable to set comport time-out settings\n");
		CloseHandle(port);
		return(NULL);
	}

	flushcom(port);
	
	return port;										// Return Handle or INVALID_HANDLE_VALUE
}


//---------------------------------------------------------------------------
// Write single char to comport
// return 0 if timeout, 1 if OK  
//---------------------------------------------------------------------------
int write_comport(HANDLE port, unsigned char c)
{
	DWORD dwBytesWritten = 0;

    if (WriteFile(port,&c,1,&dwBytesWritten,NULL)) {
		if (dwBytesWritten && debug) {
			mti_PrintFormatted("%02X",c);	
		}			
	} else {
	   mti_PrintFormatted("WriteFile failed error=%d\n",GetLastError());
	}
	//Sleep(1); 												// Required!!??
	return (int)dwBytesWritten; 								
}

int poll_comport(HANDLE port,unsigned char *buf, int size)
{
	int n;

	/* added the void pointer cast, otherwise gcc will complain about */
	/* "warning: dereferencing type-punned pointer will break strict aliasing rules" */

	if (!ReadFile(port, buf, size, (LPDWORD)((void *)&n), NULL)){
		return -1;
	}

	return(n);
}


//---------------------------------------------------------------------------
// get character from comport
// return 0 if timeout, !=0 if OK  
//---------------------------------------------------------------------------
int read_comport(HANDLE port, unsigned char *c)
{
	DWORD dwBytesRead=0;
	unsigned char szRxChar=0;


	if (ReadFile(port, &szRxChar, 1, &dwBytesRead, NULL) != 0) {
		if (dwBytesRead) {
			if (debug) mti_PrintFormatted("%02x",szRxChar);
			*c=szRxChar; 
		}		
	} else {
		mti_PrintFormatted("ReadFile failed with error=%d\n",GetLastError());
	}


   	return dwBytesRead;
}
