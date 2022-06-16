/* -------------------------------------------------------------------------------------------------- */
/* The LongMynd receiver: main.h                                                                      */
/* Copyright 2019 Heather Lomond                                                                      */
/* -------------------------------------------------------------------------------------------------- */
/*
    This file is part of longmynd.

    Longmynd is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Longmynd is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with longmynd.  If not, see <https://www.gnu.org/licenses/>.
*/

#ifndef MAIN_H
#define MAIN_H

#include <stdint.h>
#include <stdbool.h>
#include <inttypes.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <time.h>

/* states of the main loop state machine */
/* for WinterHill, change these to match the value in HEADER_MODE stv0910:Px_DMDSTATE */

#define STATE_DEMOD_HUNTING      	0
#define STATE_SEARCH			 	STATE_DEMOD_HUNTING
#define STATE_DEMOD_FOUND_HEADER 	1
#define STATE_HEADER_S2			 	STATE_DEMOD_FOUND_HEADER
#define STATE_DEMOD_S2           	2
#define STATE_DEMOD_S            	3
#define STATE_LOST				 	0x80							
#define STATE_TIMEOUT				0x81							// TS leaving the building has timed out
#define STATE_IDLE					0x82							// not searching for nor receiving a signal

/* define the various status reports */

#define STATUS_STATE               1
#define STATUS_LNA_GAIN            2
#define STATUS_PUNCTURE_RATE       3
#define STATUS_POWER_I             4 
#define STATUS_POWER_Q             5
#define STATUS_CARRIER_FREQUENCY   6
#define STATUS_CONSTELLATION_I     7
#define STATUS_CONSTELLATION_Q     8
#define STATUS_SYMBOL_RATE         9
#define STATUS_VITERBI_ERROR_RATE 10
#define STATUS_BER                11
#define STATUS_MER                12
#define STATUS_SERVICE_NAME       13		// usually callsign
#define STATUS_SERVICE_PROVIDER_NAME  14
#define STATUS_TS_NULL_PERCENTAGE 15
#define STATUS_ES_PID             16
#define STATUS_ES_TYPE            17
#define STATUS_MODCOD             18
#define STATUS_FRAME_TYPE         19
#define STATUS_PILOTS             20
#define STATUS_ERRORS_LDPC_COUNT  21
#define STATUS_ERRORS_BCH_COUNT   22
#define STATUS_ERRORS_BCH_UNCORRECTED   23
#define STATUS_LNB_SUPPLY         24
#define STATUS_LNB_POLARISATION_H 25


// new statuses added for WinterHill

#define STATUS_MULTISTREAM0   	  26		// B3:B2:B1:B0 = PDELCTR1,PDELCTRL0,MATSTR1,MATSTR0  
#define STATUS_MULTISTREAM1   	  27		//       B1:B0 = ISIBITENA,ISIENTRY
#define STATUS_DEBUG0			  28		//		 B1:B0 = TSSTATUS2,TSSTATUS 
#define STATUS_DEBUG1			  29		//		 B1:B0 = TSSTATUS,TSSTATUS
#define STATUS_DNUMBER			  30		// MER value - MER decode threshold (can be negative)		
#define STATUS_VIDEO_TYPE		  31		// 0x02=MPEG2, 0x1b=H264, 0x24=H265	
#define STATUS_ROLLOFF			  32		// 0,1,2,3 = 0.35,0.25,0.20,0.15	
#define STATUS_ANTENNA			  33		// 1:2 = TOP:BOT
#define STATUS_AUDIO_TYPE		  34		// 0x03=MP2, 0x0f=AAC	


#define STATUS_TITLEBAR		  	  94		// text put into the VLC title bar

#define STATUS_VLCSTOPS		  	  96		// STOP commands sent by the WH main application
#define STATUS_VLCNEXTS			  97		// NEXT commands sent by the WH main application
#define STATUS_MODECHANGES		  98		// increments on a new command, new callsign, new codec
#define STATUS_IPCHANGES		  99		// incremented when a command comes from a different IP address

#define EIT_PID				18
#define ESC					27
#define EVENTID				0						// for EIT
#define INFOPERIOD      	500 	               	// time in ms between info outputs 
#define MAXFREQ				2600000
#define MAXFREQSTOSCAN		16
#define MAXINFOS			100
#define MAXINICOMMANDS		16						// maximum number of commands in the ini file
#define MAXINPACKETS      	256						// packets in each input ring buffers
#define MAXOUTPACKETS      	256						// packets in the  output ring buffer
#define MAXPIDS				8						// numbers of allowed pids for a program
#define MAXSRSTOSCAN		16						// number of SRs to scan
#define MAXRECEIVERS       	4
#define MINFREQ				144000
#define MAXSR				45000
#define MINSR				25
#define NETWORK				0						// not needed by VLC for EIT
#define NULL_PID			8191
#define NULL2_PID			8190					// fake null packet insert by some modulators
#define	ON					1
#define OFF					0
#define PAT_PID				0
#define PORTINFOLMEX		1						// textual status for all receivers
#define PORTINFOMULTIRX		2						// 4 line receiver summary
#define PORTINFOLMEX2		3						// copy of 1
#define PORTINFOMULTIRX2	4						// copy of 2
#define PORTINFOLMBASE		60						// LongMynd textual status for receivers
#define PORTLISTENBASE		20						// listen for receive commands on this + RX number (1-4)
#define PORTTSBASE			40						// output TS to this + RX number
#define QO100NO				0
#define QO100BAND			1
#define QO100BEACON			2
#define QTHEADER			1						// QuickTune command header seen
#define SDT_PID				17
#define SERVICE_H262		0x02		
#define SERVICE_H264		0x1b
#define SERVICE_H265		0x24
#define SERVICE_MPA			0x03			
#define SERVICE_AAC			0x0f
#define SERVICE_AC3			0x77	// ???
#define TSID				0						// not needed by VLC for EIT
#define DAY0 				0xc957 					// 31 December 1999 in Julian days
#define WHHEADER			2						// WinterHill command header seen

#define MODE_ANYWHERE		0						// TS is sent to where the command came from
#define MODE_MULTICAST		1						// TS is sent to the multicast address
#define MODE_LOCAL			2						// TS is sent to the address supplied at startup
#define MODE_FIXED			3						// TS is sent to a fixed address

#define IP_OFFNET			0
#define IP_MYPC				1
#define IP_MYNET			2
#define IP_MULTI			3


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@
//@  control structure for each of the total of 4 possible receivers on the total of 2 possible NIMs
//@  there are 5 structures: 0 is used by the system for IP control
//@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

typedef struct 
{
    uint8_t      		    receiver ;        	        	// 1-4 receiver number in the system
    uint8_t             nimreceiver ;              		// 1/2 = first/second receiver in each NIM
    uint8_t             xlnaexists ;            		// not all NIMs have external LNAs
    uint8_t             nim ;                   		// 1/2 = NIMA/NIMB
    char	            nimtype			[16] ;  		// FTS4334L, FTS4335
    uint8_t       		active ;						//  /1 = actively receiving or searching
    uint8_t             antenna ;               		// 1/2 = TOP/BOT
    uint8_t       		scanstate ;             		// searching/locked etc

	uint32_t				audiotype ;						// audio service type indicator
	char				commandip		[16] ;			// the IP address that the command came from
	uint32_t			commandreceivedtime ;			// the time at which the command arrived (ms)
	uint32_t			debug0 ;
	uint8_t				sendnullpackets ;	    		//  /1 = send null packets on the output UDP streams
	int32_t				demodfreq ;						// frequency offset detected by the demodulator
    uint32_t            enablefreqscan ;        		// scan the 'frequencies' list
    uint32_t    		frequencies [MAXFREQSTOSCAN] ;	// kHz; multiple frequencies may be scanned
	uint16_t              freqindex ;             		// the index of the current frequency in 'frequencies'
	uint8_t				eitcontinuity ;					// sequence number for injected EIT packets
	uint8_t				eitversion ;					// incrementing version number for injected EIT packets
	char				eitlist 		[64] ;  		// list of info item numbers to put into a pid 18 EIT packet; 0 = end of list
    uint32_t            enablesrscan ;          		// scan the 'symbolrates' list           
	uint32_t			errors_outsequence ;
	uint32_t			errors_insequence ;
	uint32_t			errors_restart ;
	uint32_t			errors_overflow ;
	uint32_t			errors_sync ;
	uint32_t			forbidden ;						// cannot send this TS to RPi VLC
	uint32_t			hardwarefreq ;					// frequency passed to the tuner
	uint32_t			highsideloc ;					// /1 = LO is on the high side
    uint16_t      		summaryport ;			    	// port for sending 4 line info 
	int					summarysock ;					// . . (same info for all receivers)
	struct sockaddr_in 	summarysockaddr ;	    			 
    uint16_t     		summary2port ;			
	int					summary2sock ;					
	struct sockaddr_in 	summary2sockaddr ;	    			 
    uint16_t      		lminfoport ;			   		// port for sending original LM $ info   	
	int					lminfosock ;		    			
	struct sockaddr_in 	lminfosockaddr ;	    			 
    uint16_t      		expinfoport ;			   		// port for sending expanded WH $ info 
	int					expinfosock ;		    		// 	. . (same for all receivers)	
	struct sockaddr_in 	expinfosockaddr ;	    			
    uint16_t      		expinfo2port ;			    		// future expansion
	int					expinfo2sock ;		    			 
	struct sockaddr_in 	expinfo2sockaddr ;	    			 
	uint32_t			insequence ;					// 4 bit counter inserted by the PIC for each packet
    char	    		interfaceaddress[16] ;			// network interface to use, if more than one is available
    char	    		ipaddress 		[16] ;			// address for all outgoing operations
	uint32_t			ipchanges ;						// incremented when a command comes from a different IP
	uint32_t			iptype ;						// destination IP type: MYPC, MYNET, OFFNET, MULTICAST
	uint32_t			lastmodulation ;				// last modcod / FEC seen
    uint16_t      		listenport ;	        		// port for incoming commands
	int					listensock ;		    		// 
	struct sockaddr_in 	listensockaddr ;	    		// 
	uint32_t			modechanges ;					// increments on new command, new callsign, new codec
    char	    		newipaddress 	[16] ;			// command came from a new IP address
	uint32_t			programcount ;					// number of programs in the TS
	int32_t				qo100locerror ;
	uint32_t				qo100mode ;						// 0 / 1 / 2 = NO / QO-100 band / QO-100 beacon
	uint32_t				requestedfreq ;					// the frequency in the incoming command
	uint32_t				requestedloc ;					// the local oscillator the incoming command
	uint32_t				requestedprog ;					// the program number in the incoming command
    uint32_t      		symbolrates [MAXSRSTOSCAN] ;	// kS;  multiple symbol rates may be scanned
	uint16_t             srindex ;               		// the index of the current symbol rate in 'symbolrates'
	uint32_t				timeoutholdoffcount ;			// info is sent a number of times after timing out
    uint16_t      		tsport ;			    		// port    for transport stream output
	int					tssock ;		    			// socket  for transport stream output
	struct sockaddr_in 	tssockaddr ;	    			//
	uint32_t				outsequence ;					// 4 bit counter inserted by each PIC 
	uint32_t				packetcountprogram ;			// total since the program started
	uint32_t				packetcountrx ;					// total for this reception
	uint32_t				nullpacketcountprogram ;		// total null packets since the program started
	uint32_t				nullpacketcountrx ;				// total null packets for this reception
	uint16_t				network ;						// TS network number; 0xffff for beacon; not needed for VLC EIT
	uint32_t				signalacquiredtime ;			// time when the received signal was first acquired
	uint32_t				signallosttime ;				// time when the received signal was lost
	uint32_t				timedouttime ;					// time when the transmission timeout occurred
	uint16_t				tsid ;							// TS ID; 0xaaaa for beacon; not needed for VLC EIT
	uint16_t				pmtpid ;						// program map table pid
	uint16_t				pcrpid ;						
	uint16_t				serviceid ;						// TS program service ID; 0x0001 for beacon; NEEDED for VLC EIT
	uint32_t				videotype ;						// video service type indicator
	uint32_t				vlcnextcount ;					// incremented when N command sent to VLC
	uint32_t				vlcstopcount ;					// incremented when S command sent to VLC
	uint32_t				vlcstopped ;					// S command sent to VLC
	uint32_t				xdotoolid ;						// xdotool ID for the VLC window			
    int32_t               rawinfos  [MAXINFOS] ;  		// raw values of the info items  
    char                textinfos [MAXINFOS][256] ;  	// formatted items for info or EIT output, indexed by parameter number  
}  rxcontrol; 


typedef struct
{
    uint8_t               data [188] ;
    union
    {
        uint32_t          statusreg ;
        struct
        {
            uint32_t      crc8            :8 ;
            uint32_t      valid           :1 ;
            uint32_t      restart         :1 ;
            uint32_t      overflow        :1 ;
            uint32_t      filtering       :1 ;
            uint32_t      receiver        :2 ;
            uint32_t      spare0          :1 ;
            uint32_t      highwater       :1 ;
            uint32_t      crcnim          :1 ;          	// 1 = CRC provided by NIM
            uint32_t      crcstatus       :1 ;           
            uint32_t      spare1          :2 ;                                        
            uint32_t      nullpackets     :4 ;
            uint32_t      outsequence     :4 ;
            uint32_t      insequence      :4 ;
        } ;
    } ;
} packetx_t ;


struct eitx
{
    uint                sync            :8  ;
	
    uint                pid1208         :5  ;
    uint                tspriority      :1  ;
    uint                payloadstart    :1  ;    
    uint                tserror         :1  ;
	
    uint                pid0700         :8  ;

    uint                continuity      :4  ;
    uint                adaption        :2  ;
    uint                scrambling      :2  ;
	
    uint                pointer         :8  ;

    uint8_t               tableid             ;

    uint                filler1         :4  ;                
    uint                reserved0       :2  ;
    uint                filler2         :1  ;
    uint                syntax          :1  ;
	
    uint8_t               sectionlength       ;

    uint                servicehigh     :8  ;   // upper byte of service id
    uint                servicelow      :8  ;

    uint                currentnext     :1  ;
    uint                version         :5  ;
    uint                reserved1       :2  ;
	
    uint                section         :8  ;
    uint                lastsection     :8  ; 

    uint                tsidhigh        :8  ;   // upper byte of ts id
    uint                tsidlow	        :8  ;

    uint                networkhigh     :8  ;   // upper byte of network id
    uint                networklow      :8  ;

    uint                lastsegment     :8  ;
    uint                lasttable       :8  ;
    
    uint8_t               loop                ;

    uint8_t               filler0 [168]       ;
} ;

 
struct modinfo
{
    char    modtext [16] ;								// MODCOD gives modulation and FEC
    int32_t 	minmer ;									// required MER threshold for decode in tenths
} ;

typedef struct {
    uint8_t *main_state_ptr;
    uint8_t *main_err_ptr;
    uint8_t thread_err;
    rxcontrol *rcv;

    //longmynd_config_t *config;
    //longmynd_status_t *status;
} thread_vars_t;

void configureip(int32_t rx, char *newIp);
int configurefrequency(int32_t rx, int32_t freqx, int32_t locx, int32_t srx);

#endif

