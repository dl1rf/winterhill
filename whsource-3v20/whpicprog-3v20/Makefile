BIN = whpicprog-3v20
SRC = whpicprog-3v20.c

VER = "whpicprog-3v20"

CC = gcc

COPT = -O3 -march=native -mtune=native -I/opt/vc/include/
CFLAGS = -std=c99 -D_GNU_SOURCE -DVERSION=\"${VER}\"
CFLAGS += -Wall -Wextra
#CFLAGS += -pedantic

LDFLAGS = -L/opt/vc/lib/ -lbcm_host

all: ${BIN}

debug: COPT = -O0 -march=native -mtune=native
debug: CFLAGS += -ggdb -fno-omit-frame-pointer
debug: all

werror: CFLAGS += -Werror
werror: all

$(BIN): $(SRC)
	@echo "  ${CC}" $< -o $@ ${COPT} ${CFLAGS} ${LDFLAGS}
	@${CC} $< -o $@ ${COPT} ${CFLAGS} ${LDFLAGS}

clean:
	@rm -rf ${BIN} 

tags:
	@ctags *

.PHONY: all clean

