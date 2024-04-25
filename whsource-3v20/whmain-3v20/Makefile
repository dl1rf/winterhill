BIN = winterhill-3v20
SRC = main.c rpi2c.c nim.c stv0910.c stv0910_utils.c stvvglna.c stvvglna_utils.c stv6120.c stv6120_utils.c web/web.c web/json.c
OBJ = ${SRC:.c=.o}
LDFLAGS = -L/opt/vc/lib/ -lbcm_host -lwebsockets

CC = gcc 

COPT = -O3 -march=native -mtune=native -I/opt/vc/include/
CFLAGS = -std=c99 -Wall -pthread -fPIC -D_GNU_SOURCE -DHOME_DIR=\"${HOME}\"
CFLAGS += -Wextra -Wunused
#CFLAGS += -Wpedantic

all: ${BIN} 

debug: COPT = -O0
debug: CFLAGS += -ggdb -fno-omit-frame-pointer
debug: all

werror: CFLAGS += -Werror
werror: all

$(BIN): ${OBJ}
	@echo "  LD     "$@
	@${CC} -o $@ ${OBJ} ${COPT} ${CFLAGS} ${LDFLAGS}

%.o: %.c *.h 
	@echo "  CC     "$<
	@${CC} -c $< -o $@ ${COPT} ${CFLAGS}

clean:
	@rm -rf ${BIN} 
	@rm -rf ${OBJ} 

tags:
	@ctags *

.PHONY: all clean

