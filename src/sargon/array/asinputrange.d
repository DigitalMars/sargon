// Written in the D programming language.

/** This module contains asInputRange().

    Authors:
        $(WEB digitalmars.com, Walter Bright)
    Copyright:
        Copyright (c) 2014-, the authors. All rights reserved.
    License:
        $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Source:
        $(SARGONSRC src/sargon/_array/_asinputrange.d)
*/
module sargon.array.asinputrange;

/**
 * Turn an array into an InputRange, useful for unittesting.
 *
 * Params:
 *      a = is an array of elements of type E
 *
 * Returns:
 *      an InputRange
 */
auto ref asInputRange(E)(E[] a)
{
    static struct asInputRangeImpl
    {
        this(E[] a)
        {
            this.a = a;
        }

        @property bool empty()
        {
            return a.length == 0;
        }

        @property auto front()
        {
            return a[0];
        }

        void popFront()
        {
            a = a[1 .. a.length];
        }

      private:
        E[] a;
    }
    return asInputRangeImpl(a);
}

///
unittest
{
    import std.range;

    static assert(isInputRange!(typeof(asInputRange("hello"))));

    void testrange(string f, string result)
    {
        char[50] s;
        int i;
        foreach (c; f.asInputRange())
        {
            s[i++] = c;
        }
        assert(s[0 .. i] == result);
    }
    testrange("file", "file");

    {   // various boundary conditions
        auto r = "foo".asInputRange;
        assert(!r.empty);
        assert(!r.empty);
        r.popFront();
        r.popFront();
        r.popFront();
        assert(r.empty);
    }
}

