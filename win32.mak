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

SRC= $S\lz77.d $S\halffloat.d \
	$S\std.ddoc

PATHSRC= $S\path\package.d $S\path\setext.d

DOC=doc\lz77.html doc\halffloat.html doc\setext.html

OTHERSRC= win32.mak posix.mak LICENSE README.md dub.json

SOURCE= $(SRC) $(PATHSRC) $(OTHERSRC) doc\css\style.css

IMG= doc\images\Sargon_of_Akkad.jpg

all: $B\$(TARGET).lib

#################################################

$B\$(TARGET).lib : $(SRC)
	$(DMD) -lib -of$B\$(TARGET).lib $(SRC) $(DFLAGS)


unittest :
	$(DMD) -unittest -main -cov -of$O\unittest.exe $(SRC) $(DFLAGS)
	$O\unittest.exe

doc : $(DOC)

doc\halffloat.html : $S\std.ddoc $S\halffloat.d
	$(DMD) -c -Dddoc $S\std.ddoc $S\halffloat.d

doc\lz77.html : $S\std.ddoc $S\lz77.d
	$(DMD) -c -Dddoc $S\std.ddoc $S\lz77.d

doc\setext.html : $S\std.ddoc $S\path\setext.d
	$(DMD) -c -Dfdoc\setext.html $S\std.ddoc $S\path\setext.d

clean:
	$(DEL) $O\unittest.exe *.lst $(DOC)


tolf:
	tolf $(SOURCE)


detab:
	detab $(SRC)


zip: detab tolf $(SOURCE) $(IMG)
	$(DEL) sargon.zip
	zip32 sargon $(SOURCE) $(IMG)

scp: detab tolf $(SOURCE)
	$(SCP) $(OTHERSRC) $(SCPDIR)/
	$(SCP) $(SRC) $(SCPDIR)/src/sargon
	$(SCP) $(PATHSRC) $(SCPDIR)/src/sargon/path
	$(SCP) $(IMG) $(SCPDIR)/doc/images
	$(SCP) doc/css/style.css $(SCPDIR)/doc/css

