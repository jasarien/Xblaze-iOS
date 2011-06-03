
COM=gcc -Wall -fobjc-exceptions

##############################################

all:	build_games

build_games:	build_games.o
	$(COM) -framework Cocoa build_games.o -o build_games

##############################################

build_games.o:	build_games.m
	$(COM) -c build_games.m

