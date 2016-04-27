.SUFFIXES : .o .cpp .c

OBJS =\
 cont_stalta.o\
 main.o\
 stalta.o\
 station_collection.o\
 station_trace.o\
 julday.o\
 caldat.o\
 utl_time.o

EXEC         = ms_picker
LIBS         = -L /Users/baillard/_Moi/Programmation/Scripts/dataselect-3.17/libmseed
INCLUDES     = -I /usr/include/c++/4.2.1/ -I /Users/baillard/_Moi/Programmation/Scripts/dataselect-3.17/libmseed/
DEFINES      = 
CCFLAGS      = -ggdb -Wall
LDFLAGS      =
CXXFLAGS     = $(CCFLAGS) $(DEFINES) $(INCLUDES)
CFLAGS       = $(CCFLAGS) $(DEFINES) $(INCLUDES)

CCPLUS = g++
CC     = gcc

.cpp.o: ; $(CCPLUS) -c $(CXXFLAGS) $*.cpp
.c.o: ; $(CC) -c $(CFLAGS) $*.c

all: $(EXEC)

$(EXEC): $(OBJS) 
	$(CCPLUS) $(LDFLAGS) -o $@ $(INCLUDES) $(OBJS) $(LIBS)

clean:
	$(RM) *.o *~ $(EXEC) Makefile.bak Makefile.BAK

depend:
	makedepend $(INCLUDES) *.cpp

# DO NOT DELETE

