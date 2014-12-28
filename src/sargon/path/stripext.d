// Written in the D programming language.

/** This module contains stripExt().

    Authors:
        Lars Tandle Kyllingstad,
        $(WEB digitalmars.com, Walter Bright),
        Grzegorz Adam Hankiewicz,
        Thomas K&uuml;hne,
        $(WEB erdani.org, Andrei Alexandrescu)
    Copyright:
        Copyright (c) 2000-2014, the authors. All rights reserved.
    License:
        $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Source:
        $(SARGONSRC src/sargon/_path/_stripext.d)
*/
module sargon.path.stripext;


import std.range;
import std.traits;
import std.utf;

/** Returns slice of $(D path[]) with the extension stripped off.

    stripExt is an algorithm that does not allocate nor throw, it is $(D pure) and $(D @safe).

    Params:
        path = a $(WEB dlang.org/phobos/std_range.html#.isRandomAccessRange, RandomAccessRange) that can be sliced.

    Returns:
        a slice of path

    Examples:
    ---
    assert (stripExt("file")           == "file");
    assert (stripExt("file.ext")       == "file");
    assert (stripExt("file.ext1.ext2") == "file.ext1");
    assert (stripExt("file.")          == "file");
    assert (stripExt(".file")          == ".file");
    assert (stripExt(".file.ext")      == ".file");
    assert (stripExt("dir/file.ext")   == "dir/file");

    {
	import std.internal.scopebuffer;

        char[10] tmpbuf = void;
        auto buf = ScopeBuffer!char(tmpbuf);
        scope(exit) buf.free();

        buf.length = 0;
        "file.ext".byChar().stripExt().copy(&buf);
        assert(buf[] == "file");
    }
    ---
*/
auto stripExt(R)(R path)
{
    static if (isRandomAccessRange!R && hasSlicing!R && isSomeChar!(ElementType!R) ||
        isNarrowString!R)
    {
	auto i = extSeparatorPos(path);
	return (i == -1) ? path : path[0 .. i];
    }
    else
    {
	import core.stdc.stdio;

	alias tchar = Unqual!(ElementEncodingType!R);
	static struct stripExtImpl
	{
	    this(ref R r)
	    {
		this.r = r;
	    }

	    @property bool empty()
	    {
		if (haveChar)
		    return false;
		while (1)
		{
		    if (i < nLeft)
		    {
			ch = buf[i];
			++i;
			lastIsSeparator = isSeparator(ch);
			assert(lastIsSeparator == false);
			haveChar = true;
			return false;
		    }
		    if (r.empty)
			return true;

		    ch = r.front;
		    r.popFront;
		    if (ch != '.' ||
                        lastIsSeparator)
		    {
			lastIsSeparator = isSeparator(ch);
			haveChar = true;
			return false;
		    }
		    nLeft = 0;
		    while (1)
		    {
			buf[nLeft++] = ch;
			if (r.empty)
			{
			    nLeft = 0;
			    break;
			}
			ch = r.front;
			if (ch == '.' ||
                            isSeparator(ch) ||
			    nLeft == buf.length)
			{
			    break;
			}
			r.popFront();
		    }
		    i = 0;
		}
	    }

	    @property auto front()
	    {
		return ch;
	    }

	    void popFront()
	    {
		haveChar = false;
	    }

	  private:
	    R r;
	    bool lastIsSeparator = true;
	    bool haveChar = false;
	    uint nLeft;
	    uint i;
	    tchar ch;
	    tchar[FILENAME_MAX] buf = void;
	}
	return stripExtImpl(path);
    }
}

// Turn an array into an InputRange, used for unittesting

private auto ref byInputRange(T)(T[] s)
{
    static struct byInputRangeImpl
    {
	this(T[] s)
	{
	    this.s = s;
	}

	@property bool empty()
	{
	    return s.length == 0;
	}

	@property auto front()
	{
	    return s[0];
	}

	void popFront()
	{
	    s = s[1 .. s.length];
	}

      private:
	T[] s;
    }
    return byInputRangeImpl(s);
}

unittest
{
    import std.algorithm;
    import std.internal.scopebuffer;

    assert (stripExt("file") == "file");
    assert (stripExt("file.ext"w) == "file");
    assert (stripExt("file.ext1.ext2"d) == "file.ext1");
    assert (stripExt(".foo".dup) == ".foo");
    assert (stripExt(".foo.ext"w.dup) == ".foo");

    assert (stripExt("dir/file"d.dup) == "dir/file");
    assert (stripExt("dir/file.ext") == "dir/file");
    assert (stripExt("dir/file.ext1.ext2"w) == "dir/file.ext1");
    assert (stripExt("dir/.foo"d) == "dir/.foo");
    assert (stripExt("dir/.foo.ext".dup) == "dir/.foo");

    {
        char[10] tmpbuf = void;
        auto buf = ScopeBuffer!char(tmpbuf);
        scope(exit) buf.free();

        buf.length = 0;
        "file.ext".byChar().stripExt().copy(&buf);
        assert(buf[] == "file");
    }

    void testrange(string f, string result)
    {
	char[50] s;
	int i;
	foreach (c; f.byInputRange().stripExt())
	{
	    s[i++] = c;
	}
	assert(s[0 .. i] == result);
    }
    testrange("file", "file");
    testrange("file.", "file");
    testrange("file.ext", "file");
    testrange("file.ext.", "file.ext");
    testrange("file.ext1.ext2", "file.ext1");
    testrange(".foo", ".foo");
    testrange("dir/file", "dir/file");
    testrange("dir/file.ext", "dir/file");
    testrange("dir/file.ext1.ext2", "dir/file.ext1");
    testrange("dir/.foo", "dir/.foo");
    testrange("dir/.foo.ext", "dir/.foo");

    {   // various boundary conditions
	auto r = "f.o".byInputRange.stripExt;
	assert(!r.empty);
	assert(!r.empty);
	r.popFront();
	r.popFront();
	r.popFront();
	assert(r.empty);
    }

    version(Windows)
    {
    assert (stripExt("dir\\file") == "dir\\file");
    assert (stripExt("dir\\file.ext") == "dir\\file");
    assert (stripExt("dir\\file.ext1.ext2") == "dir\\file.ext1");
    assert (stripExt("dir\\.foo") == "dir\\.foo");
    assert (stripExt("dir\\.foo.ext") == "dir\\.foo");

    assert (stripExt("d:file") == "d:file");
    assert (stripExt("d:file.ext") == "d:file");
    assert (stripExt("d:file.ext1.ext2") == "d:file.ext1");
    assert (stripExt("d:.foo") == "d:.foo");
    assert (stripExt("d:.foo.ext") == "d:.foo");
    }

    static assert (stripExt("file") == "file");
    static assert (stripExt("file.ext"w) == "file");
}

/*  Helper function that returns the position of the filename/extension
    separator dot in path.  If not found, returns -1.
*/
private ptrdiff_t extSeparatorPos(R)(const R path)
    if (isRandomAccessRange!R && hasSlicing!R && isSomeChar!(ElementType!R) ||
        isNarrowString!R)
{
    auto i = (cast(ptrdiff_t) path.length) - 1;
    while (i >= 0 && !isSeparator(path[i]))
    {
        if (path[i] == '.' && i > 0 && !isSeparator(path[i-1])) return i;
        --i;
    }
    return -1;
}

private bool isSeparator(dchar c) @safe pure nothrow @nogc
{
    version (Windows)
	return c == ':' || c == '/' || c == '\\';
    else
	return c == '/';
}

