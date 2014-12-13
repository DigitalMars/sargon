#_ posix.mak
# Build posix version of sargon
# Needs Digital Mars D compiler to build, available free from:
# http://www.digitalmars.com/d/

DMD=dmd
DEL=rm
S=src/sargon
O=obj
B=bin

TARGET=undead

DFLAGS=-g -Isrc/
LFLAGS=-L/map/co
#DFLAGS=
#LFLAGS=

.d.obj :
	$(DMD) -c $(DFLAGS) $*

SRC= $S/lz77.d $S/halffloat.d


SOURCE= $(SRC) win32.mak posix.mak LICENSE README.md dub.json

all: $B/$(TARGET).a

#################################################

$B/$(TARGET).a : $(SRC)
	$(DMD) -lib -of$B/$(TARGET).a $(SRC) $(DFLAGS)


unittest :
	$(DMD) -unittest -main -cov -of$O/unittest $(SRC) $(DFLAGS)
	$O/unittest


clean:
	$(DEL) $O/unittest *.lst


tolf:
	tolf $(SOURCE)


detab:
	detab $(SRC)


zip: detab tolf $(SOURCE)
	$(DEL) sargon.zip
	zip sargon $(SOURCE)
