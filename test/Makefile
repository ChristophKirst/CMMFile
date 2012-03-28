# ----------------------------------- #
# Makefile for CMMFile testing        #
# ----------------------------------- #

EXE = test_cmm
CC     = g++
LD     = g++
CFLAGS =
LDFLAGS  = -L.

all : $(EXE)

$(EXE) : test_cmm.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(EXE) test_cmm.o

test_cmm.o : test_cmm.cpp cmmfile.h

clean :
	rm -f *.o *~
	rm $(EXE)

