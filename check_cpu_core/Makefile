#CROSS_COMPILE ?= aarch64-linux-gnu-
CC      = $(CROSS_COMPILE)gcc
LD      = $(CROSS_COMPILE)ld

CFLAGS  = -Wall 

SDIR = ./
C_SRCS = $(wildcard $(SDIR)/*.c)
C_OBJS = $(C_SRCS:$(SDIR)/%.c=%.o)


TAR=test

all: clean build
build:
	$(CC) $(TAR).c -o $(TAR).app -D_HELLO $(CFLAGS) $(LDFLAGS)

clean:
	rm -f $(TAR).app
exec:
	./$(TAR).app

