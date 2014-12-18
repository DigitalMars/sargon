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
        $(SARGONSRC src/sargon/_path/_setext.d)
*/

module sargon.path.setext;

import std.path;

import std.range;
import std.traits : isSomeChar;
import std.utf : byChar;

/** Algorithm that accepts a _path as an InputRange and a file extension as an InputRange,
    and returns an InputRange that produces a char string containing the _path given
    by $(D path), but where
    the extension has been set to $(D ext).

    If the filename already has an extension, it is replaced. If not, the
    extension is simply appended to the filename. Including a leading dot
    in $(D ext) is optional.

    If the extension is empty, this function produces the equivalent of
    $(LREF stripExtension) applied to path.

    The algorithm is lazy, does not allocate, does not throw, and is pure.
*/
auto setExt(R1, R2)(R1 path, R2 ext)
    if (isInputRange!R1 && isSomeChar!(ElementType!R1) &&
        isInputRange!R2 && isSomeChar!(ElementType!R2))
{
    return chain(path.stripExtension().byChar(),
                 "."[0 .. 1 - cast(size_t)(ext.empty || ext.front() == '.')].byChar(),
                 ext.byChar());
}

///
unittest
{
    import std.algorithm : copy;
    import std.array : appender;

    auto buf = appender!(char[])();

    "file".setExt("ext").copy(&buf);
    assert(buf.data == "file.ext");
}

unittest
{
    import std.internal.scopebuffer;
    import std.stdio;
    import std.path;
    import std.array;
    import std.algorithm;
    import std.typetuple : TypeTuple;
    import std.conv : to;

    void test(C1,C2)(const(C1)[] file, const(C2)[] ext, string expectedResult)
    {
        char[10] tmpbuf = void;
        auto buf = ScopeBuffer!char(tmpbuf);
        scope(exit) buf.free();

        buf.length = 0;
        file.setExt(ext).byChar().copy(&buf);
        assert(buf[] == expectedResult);
    }

    auto testData = [
        ["file", "ext", "file.ext"],
        ["file", ".ext", "file.ext"],
        ["file.", ".ext", "file.ext"],
        ["file.", "ext", "file.ext"],
        ["file.old", "new", "file.new"],
        ["file", "", "file"],
        ["file.exe", "", "file"]
    ];

    foreach (S1; TypeTuple!(string, wstring, dstring))
    {
        foreach (S2; TypeTuple!(string, wstring, dstring))
        {
            foreach (testCase; testData)
            {
                test(testCase[0].to!S1, testCase[1].to!S2, testCase[2]);
            }
        }
    }

    auto abuf = appender!(char[])();
    "file".setExt("ext").copy(&abuf);
    assert(abuf.data == "file.ext");
}



