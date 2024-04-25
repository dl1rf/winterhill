
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdbool.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <bcm_host.h>
#include <pthread.h>

#include "errors.h"
#include "main.h"
#include "nim.h"
#include "rpi2c.h"
#include "stv0910.h"
#include "stv0910_regs.h"
#include "stv0910_utils.h"
#include "stv6120.h"
#include "stv6120_regs.h"
#include "stv6120_utils.h"
#include "stvvglna.h"
#include "stvvglna_utils.h"

extern uint32_t	GLOBALNIM ;
extern bool		nimspresent[5] ;
extern bool		xlnaspresent[5] ;

