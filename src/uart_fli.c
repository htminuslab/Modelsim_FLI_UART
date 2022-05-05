//-------------------------------------------------------------------------------------------------
// Modelsim_FLI_UART
//
// FLI-UART interface
//
// https://github.com/htminuslab            
//  
//-------------------------------------------------------------------------------------------------
// Version   Author          Date          Changes
// 0.1       Hans Tiggeler   13 May 2003   Tested on Modelsim SE 5.7b   
// 0.2       Hans Tiggeler   02 May 2022   Updated/cleaned up, tested on Modelsim 2022.2
//-------------------------------------------------------------------------------------------------
#include "uart_fli.h"

int debug=0;

static void uart_proc(void *param);  

//-------------------------------------------------------------------------------------------------
// Drive std_logic_vector
//-------------------------------------------------------------------------------------------------
void drive_lv_uint(mtiSignalIdT bus, mtiDriverIdT * drivers, uint32_t newval, mtiDelayT delay)
{
	char 	* sigval;
	mtiInt32T arraylen;
	
	arraylen=mti_TickLength(mti_GetSignalType(bus));
	sigval = (char *)mti_GetArraySignalValue(bus, 0);
	
	if (arraylen>32) {
		mti_PrintFormatted("*** ERROR: Vector length %d > 32bits\n",arraylen);
		mti_FatalError(); 											// Do not continue
	} else {
		for (int i=arraylen-1;i>=0;i--) { 
			sigval[i]= (newval&1) ? STD_LOGIC_1 : STD_LOGIC_0;
		 	mti_ScheduleDriver(drivers[i], (long)sigval[i], delay, MTI_INERTIAL );
			newval>>=1;
		}
	}	
}

//-------------------------------------------------------------------------------------------------
// Convert std_logic_vector into an integer
//-------------------------------------------------------------------------------------------------
mtiUInt32T conv_std_logic_vector(mtiSignalIdT stdvec)
{
   	mtiSignalIdT * 	elem_list;
	mtiTypeIdT 		sigtype;
	mtiInt32T 		i,num_elems;
	mtiUInt32T 		retvalue,shift;	

	sigtype = mti_GetSignalType(stdvec);			// signal type
	num_elems = mti_TickLength(sigtype);			// Get number of elements
	elem_list = mti_GetSignalSubelements(stdvec, 0);

	shift=(mtiUInt32T) pow(2.0,(double)num_elems-1);// start position
	
	retvalue=0;
   	for (i=0; i < num_elems; i++ ) {
	 	if (mti_GetSignalValue(elem_list[i])==3) {
	 		retvalue=retvalue+shift;
	 	} 
		shift=shift>>1;
	}

	mti_VsimFree(elem_list);

	return(retvalue);
}

//-------------------------------------------------------------------------------------------------
// Release Malloc'd memory and comport
//-------------------------------------------------------------------------------------------------
void call_cleanup(void * param)
{
	inst_rec * ip = (inst_rec *)param;			
	mti_PrintMessage("Cleaning up.....\n");
	close_comport(ip->comport);	
	mti_Free(ip);
}


void cif_init(mtiRegionIdT region, char *param, mtiInterfaceListT *generics, mtiInterfaceListT *ports)
{
    inst_rec     *ip;												// Declare ports			
    mtiProcessIdT proc;												// current process id
	mtiDriverIdT txdrvid;
	
	mti_PrintMessage("Starting FLI");	
	mti_GetProductVersion();										// Used for Debugger

    ip = (inst_rec *)mti_Malloc(sizeof(inst_rec));	   				// allocate memory for ports
	
    ip->clk    = mti_FindPort(ports, "clk");
    ip->rdrf   = mti_FindPort(ports, "rdrf");
    ip->resetn = mti_FindPort(ports, "resetn");
    ip->rxreg  = mti_FindPort(ports, "rxreg");
    ip->tdre   = mti_FindPort(ports, "tdre");
	  
    ip->rd     = mti_CreateDriver(mti_FindPort(ports, "rd"));		// Add drivers    	
    ip->wr     = mti_CreateDriver(mti_FindPort(ports, "wr"));	
	
	ip->txreg 	 = mti_FindPort(ports, "txreg");	
	txdrvid 		 = mti_CreateDriver(ip->txreg);						
	ip->txreg_elems = mti_GetDriverSubelements(txdrvid, 0);
	
	                        
    proc = mti_CreateProcess("uart_proc", uart_proc, ip);
    mti_Sensitize(proc, ip->clk, MTI_EVENT);	 					// Add sensitivity signals
    mti_Sensitize(proc, ip->resetn, MTI_EVENT);
	
	mti_SetDriverOwner(ip->rd,proc);			 					// Set Owner of output drivers (required?)
    mti_SetDriverOwner(txdrvid,proc);
	mti_SetDriverOwner(ip->wr,proc);
				  		   		
	//---------------------------------------------------------------------------------------------
	// Open Comport 
	//---------------------------------------------------------------------------------------------
	if ((ip->comport=open_comport(COMPORT, BAUDRATE, 0))==INVALID_HANDLE_VALUE) {
      	mti_PrintFormatted("\nFailed to open comport %s\n",COMPORT);
      	mti_FatalError(); 
	}
	flushcom(ip->comport);
	
	mti_AddQuitCB(call_cleanup,ip);
	mti_AddRestartCB(call_cleanup,ip);
	
	mti_PrintFormatted("\n%s opened at %d N,8,1,0\n",COMPORT,BAUDRATE);
	
}

static void uart_proc(void *param)									
{
	inst_rec * ip = (inst_rec *)param;
	unsigned int x;
	static int nb=0;												// Number of received bytes
	static int bufptr=0;											// Buffer pointer
	static unsigned char buf[RXBUFFER];

	enum rxstates_enum {wait4rx,procrx,proctdre};
	static enum rxstates_enum rxstate=wait4rx;
	
	enum txstates_enum {wait4tx,proctx};
	static enum txstates_enum txstate=wait4tx;

	if (mti_GetSignalValue(ip->resetn)==STD_LOGIC_0) { 				// Async Reset
		mti_ScheduleDriver(ip->wr, STD_LOGIC_0, 0, MTI_INERTIAL);
		mti_ScheduleDriver(ip->rd, STD_LOGIC_0, 0, MTI_INERTIAL);		
		bufptr=0;													// Receive buffer pointer
	} else {
		if (mti_GetSignalValue(ip->clk)==STD_LOGIC_1) {				// Rising Edge		
			
			switch(rxstate) {										// FLI2UART
				case wait4rx:	
					if ((nb=poll_comport(ip->comport,buf, RXBUFFER))) {			// Any characters pending from "real" UART? 	
						if (debug) mti_PrintFormatted("Received %d character(s)\n",nb);
						bufptr=0;											
						rxstate=procrx;						
					}
					break;
				case procrx: 	
					mti_PrintFormatted("Rx:%c ",buf[bufptr]);
					drive_lv_uint(ip->txreg, ip->txreg_elems, buf[bufptr++], 0);
					mti_ScheduleDriver(ip->wr, STD_LOGIC_1, 0, MTI_INERTIAL);// Start Write cycle
					rxstate=proctdre;	
					break;
					
				case proctdre:
					mti_ScheduleDriver(ip->wr, STD_LOGIC_0, 0, MTI_INERTIAL);
					if (mti_GetSignalValue(ip->tdre)==STD_LOGIC_1) {// TX buffer is empty
						if (nb==bufptr) {
							rxstate=wait4rx;
						} else {
							rxstate=procrx;
						}
					}
					break;
			}

			switch(txstate) {										// UART2FLI
				case wait4tx:	
					if (mti_GetSignalValue(ip->rdrf)==STD_LOGIC_1){	
						x=conv_std_logic_vector(ip->rxreg);					
						mti_PrintFormatted("Tx:%c\n",(unsigned char)x);
						write_comport(ip->comport,(unsigned char)x);						
						mti_ScheduleDriver(ip->rd, STD_LOGIC_1, 0, MTI_INERTIAL);
						txstate=proctx;								// Perform read cycle to clear RDRF
					}					
					break;
				case proctx:
					mti_ScheduleDriver(ip->rd, STD_LOGIC_0, 0, MTI_INERTIAL);
					txstate=wait4tx;								// Wait for next char
					break;
			}
		}
	}
}


