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
            hasData = (a.length != 0);
            return !hasData;
        }

        @property ref E front()
        {
            assert(hasData);
            return a[0];
        }

        void popFront()
        {
            a = a[1 .. $];
            hasData = false;
        }

      private:
        E[] a;
        bool hasData;
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

private import std.range;

/***************************************
 * Takes an InputRange as input and verifies
 * that it can be iterated following protocol.
 *
 * Params:
 *      r = is an InputRange
 */

void testInputRange(R)(R r) if (isInputRange!R)
{
    static if (isInfinite!R)
    {
        foreach (i; 0 .. 10)
        {
            while (!r.empty)
            {
                auto e = r.front;
                auto e2 = r.front;
                assert(e == e2);
                r.popFront();
            }
        }
    }
    else
    {
        while (!r.empty)
        {
            auto e = r.front;
            auto e2 = r.front;
            assert(e == e2);
            r.popFront();
        }
    }
}

///
unittest
{
    testInputRange(asInputRange("betty"));
}
