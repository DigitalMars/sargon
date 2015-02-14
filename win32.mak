#_ win32.mak
# Build win32 version of sargon
# Needs Digital Mars D compiler to build, available free from:
# http://www.digitalmars.com/d/

DMD=dmd
DEL=del
S=src\sargon
O=obj
B=bin

TARGET=sargon

DFLAGS=-g -Isrc/
LFLAGS=-L/map/co
#DFLAGS=
#LFLAGS=

.d.obj :
	$(DMD) -c $(DFLAGS) $*

SRC= $S\lz77.d $S\halffloat.d \
	$S\textmac.d \
	$S\std.ddoc

ARRAYSRC= $S\array\package.d $S\array\asinputrange.d $S\array\asforwardrange.d

PATHSRC= $S\path\package.d $S\path\setext.d $S\path\stripext.d

DOC=doc\lz77.html doc\halffloat.html doc\textmac.html doc\asinputrange.html doc\asforwardrange.html doc\setext.html doc\stripext.html

OTHERSRC= win32.mak posix.mak LICENSE README.md dub.json

SOURCE= $(SRC) $(ARRAYSRC) $(PATHSRC) $(OTHERSRC) doc\css\style.css

IMG= doc\images\Sargon_of_Akkad.jpg

all: $B\$(TARGET).lib

#################################################

$B\$(TARGET).lib : $(SRC)
	$(DMD) -lib -of$B\$(TARGET).lib $(SRC) $(ARRAYSRC) $(PATHSRC) $(DFLAGS)


unittest :
	$(DMD) -unittest -main -cov -of$O\unittest.exe $(SRC) $(ARRAYSRC) $(PATHSRC) $(DFLAGS)
	$O\unittest.exe

doc : $(DOC)

doc\halffloat.html : $S\std.ddoc $S\halffloat.d
	$(DMD) -c -Isrc/ -Dddoc $S\std.ddoc $S\halffloat.d

doc\lz77.html : $S\std.ddoc $S\lz77.d
	$(DMD) -c -Isrc/ -Dddoc $S\std.ddoc $S\lz77.d

doc\textmac.html : $S\std.ddoc $S\textmac.d
	$(DMD) -c -Isrc/ -Dddoc $S\std.ddoc $S\textmac.d

doc\asinputrange.html : $S\std.ddoc $S\array\asinputrange.d
	$(DMD) -c -Isrc/ -Dfdoc\asinputrange.html $S\std.ddoc $S\array\asinputrange.d

doc\asforwardrange.html : $S\std.ddoc $S\array\asforwardrange.d
	$(DMD) -c -Isrc/ -Dfdoc\asforwardrange.html $S\std.ddoc $S\array\asforwardrange.d

doc\setext.html : $S\std.ddoc $S\path\setext.d
	$(DMD) -c -Isrc/ -Dfdoc\setext.html $S\std.ddoc $S\path\setext.d

doc\stripext.html : $S\std.ddoc $S\path\stripext.d
	$(DMD) -c -Isrc/ -Dfdoc\stripext.html $S\std.ddoc $S\path\stripext.d

clean:
	$(DEL) $O\unittest.exe *.lst $(DOC)


tolf:
	tolf $(SOURCE) $(OTHERSRC)


detab:
	detab $(SRC) $(ARRAYSRC) $(PATHSRC)


zip: detab tolf $(SOURCE) $(IMG)
	$(DEL) sargon.zip
	zip32 sargon $(SOURCE) $(IMG)

scp: detab tolf $(SOURCE)
	$(SCP) $(OTHERSRC) $(SCPDIR)/
	$(SCP) $(SRC) $(SCPDIR)/src/sargon
	$(SCP) $(ARRAYSRC) $(SCPDIR)/src/sargon/array
	$(SCP) $(PATHSRC) $(SCPDIR)/src/sargon/path
	$(SCP) $(IMG) $(SCPDIR)/doc/images
	$(SCP) doc/css/style.css $(SCPDIR)/doc/css

