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

SRC= $S/lz77.d $S/halffloat.d \
	$S/sargon.ddoc

PATHSRC= $S/path/package.d $S/path/setext.d

DOC=doc/lz77.html doc/halffloat.html doc/setext.html

OTHERSRC= win32.mak posix.mak LICENSE README.md dub.json

SOURCE= $(SRC) $(PATHSRC) $(OTHERSRC)

all: $B/$(TARGET).a

#################################################

$B/$(TARGET).a : $(SRC)
	$(DMD) -lib -of$B/$(TARGET).a $(SRC) $(DFLAGS)


unittest :
	$(DMD) -unittest -main -cov -of$O/unittest $(SRC) $(DFLAGS)
	$O/unittest

doc : $(DOC)

doc/halffloat.html : $S/sargon.ddoc $S/halffloat.d
	$(DMD) -c -Dddoc $S/sargon.ddoc $S/halffloat.d

doc/lz77.html : $S/sargon.ddoc $S/lz77.d
	$(DMD) -c -Dddoc $S/sargon.ddoc $S/lz77.d

doc\setext.html : $S/sargon.ddoc $S/path/setext.d
	$(DMD) -c -Dfdoc/setext.html $S/sargon.ddoc $S/path/setext.d

clean:
	$(DEL) $O/unittest *.lst $(DOC)


tolf:
	tolf $(SOURCE)


detab:
	detab $(SRC)


zip: detab tolf $(SOURCE)
	$(DEL) sargon.zip
	zip sargon $(SOURCE)
