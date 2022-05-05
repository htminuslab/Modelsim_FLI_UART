//-------------------------------------------------------------------------------------------------
// Modelsim_FLI_UART
//
// FLI-UART header file
//
// https://github.com/htminuslab            
//  
//-------------------------------------------------------------------------------------------------
// Version   Author          Date          Changes
// 0.1       Hans Tiggeler   13 May 2003   Tested on Modelsim SE 5.7b   
//-------------------------------------------------------------------------------------------------

#pragma once 

#include <stdio.h>  
#include <ctype.h>   
#include <math.h>
#include <string.h>
#include <time.h>
#include <windows.h>
#include <stdint.h>

#include "mti.h"			  										// MTI Headers & Prototypes

#define RXBUFFER 	32												// Buffer bytes received from "real" comport	
#define COMPORT		"\\\\.\\COM3"									// One of the com0com ports
#define BAUDRATE	9600 											
			
typedef enum {														// std_logic enumerated type
	STD_LOGIC_U,					
	STD_LOGIC_X,					
	STD_LOGIC_0,					
	STD_LOGIC_1,					
	STD_LOGIC_Z,					
	STD_LOGIC_W,					
	STD_LOGIC_L,					
	STD_LOGIC_H,					
	STD_LOGIC_D					
} StdLogicType;					
					
typedef struct {			  										// Status_Register Entity ports 
     mtiSignalIdT clk;                         
     mtiSignalIdT rdrf;                 
     mtiSignalIdT resetn;                      
     mtiSignalIdT rxreg;                         
     mtiSignalIdT tdre;                            	 
     mtiDriverIdT rd;  	 
	 mtiSignalIdT txreg;         									// Transmit Register  
	 mtiDriverIdT * txreg_elems; 
	 mtiDriverIdT wr; 	
	 HANDLE comport;												// Handle to serial port
} inst_rec;	


//---------------------------------------------------------------------------
// Prototypes
//---------------------------------------------------------------------------
void close_comport(HANDLE port);
HANDLE open_comport(char *devicename, int baudrate, int flowctrl);
int poll_comport(HANDLE port,unsigned char *buf, int size);
int write_comport(HANDLE port, unsigned char c);
int read_comport(HANDLE port, unsigned char *c);
void flushcom(HANDLE port);