// Written in the D programming language.

/** This module is used to manipulate _path strings.

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


import std.algorithm;
import std.array;
import std.conv;
import std.range;
import std.string;
import std.traits;
import std.path;
import std.utf;

/** Returns slice of path[] with the extension stripped off.

    Examples:
    ---
    assert (stripExt("file")           == "file");
    assert (stripExt("file.ext")       == "file");
    assert (stripExt("file.ext1.ext2") == "file.ext1");
    assert (stripExt("file.")          == "file");
    assert (stripExt(".file")          == ".file");
    assert (stripExt(".file.ext")      == ".file");
    assert (stripExt("dir/file.ext")   == "dir/file");
    ---
*/
auto stripExt(R)(R path)
    if (isRandomAccessRange!R && hasSlicing!R && isSomeChar!(ElementType!R) ||
        isNarrowString!R)
//inout(C)[] stripExt(C)(inout(C)[] path)  @safe pure nothrow @nogc
//    if (isSomeChar!C)
{
    auto i = extSeparatorPos(path);
    if (i == -1) return path;
    else return path[0 .. i];
}


unittest
{
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

