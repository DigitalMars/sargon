#_ win32.mak
# Build win32 version of sargon
# Needs Digital Mars D compiler to build, available free from:
# http://www.digitalmars.com/d/

DMD=dmd
DEL=del
S=src\sargon
O=obj
B=bin

TARGET=undead

DFLAGS=-g -Isrc/
LFLAGS=-L/map/co
#DFLAGS=
#LFLAGS=

.d.obj :
	$(DMD) -c $(DFLAGS) $*

SRC= $S\lz77.d $S\halffloat.d


OTHERSRC= win32.mak posix.mak LICENSE README.md dub.json

SOURCE= $(SRC) $(OTHERSRC)

all: $B\$(TARGET).lib

#################################################

$B\$(TARGET).lib : $(SRC)
	$(DMD) -lib -of$B\$(TARGET).lib $(SRC) $(DFLAGS)


unittest :
	$(DMD) -unittest -main -cov -of$O\unittest.exe $(SRC) $(DFLAGS)
	$O\unittest.exe


clean:
	$(DEL) $O\unittest.exe *.lst


tolf:
	tolf $(SOURCE)


detab:
	detab $(SRC)


zip: detab tolf $(SOURCE)
	$(DEL) sargon.zip
	zip32 sargon $(SOURCE)

scp: detab tolf $(SOURCE)
	$(SCP) $(OTHERSRC) $(SCPDIR)/
	$(SCP) $(SRC) $(SCPDIR)/src/sargon
