// Written in the D programming language.

/** This module contains asForwardRange().

    Authors:
        $(WEB digitalmars.com, Walter Bright)
    Copyright:
        Copyright (c) 2014-, the authors. All rights reserved.
    License:
        $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Source:
        $(SARGONSRC src/sargon/_array/_asforwardrange.d)
*/
module sargon.array.asforwardrange;

import sargon.array.asinputrange;

/**
 * Turn an array into a ForwardRange, useful for unittesting.
 *
 * Params:
 *      a = is an array of elements of type E
 *
 * Returns:
 *      a ForwardRange
 */
auto ref asForwardRange(E)(E[] a)
{
    static struct asForwardRangeImpl
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

        @property asForwardRangeImpl save()
        {
            return this;
        }

      private:
        E[] a;
        bool hasData;
    }
    return asForwardRangeImpl(a);
}

///
unittest
{
    import std.range;

    static assert(isForwardRange!(typeof(asForwardRange("hello"))));

    void testrange(string f, string result)
    {
        char[50] s;
        int i;
        foreach (c; f.asForwardRange())
        {
            s[i++] = c;
        }
        assert(s[0 .. i] == result);
    }
    testrange("file", "file");

    {   // various boundary conditions
        auto r = "foo".asForwardRange;
        auto s = r.save;
        assert(!r.empty);
        assert(!r.empty);
        r.popFront();
        r.popFront();
        r.popFront();
        assert(r.empty);

        assert(!s.empty);
        assert(!s.empty);
        s.popFront();
        s.popFront();
        s.popFront();
        assert(s.empty);
    }
}

private import std.range;

/***************************************
 * Takes an ForwardRange as input and verifies
 * that it can be iterated following protocol.
 *
 * Params:
 *      r = is a ForwardRange
 */

void testForwardRange(R)(R r) if (isForwardRange!R)
{
    auto rsave = r.save;
    testInputRange(rsave);

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
    testForwardRange(asForwardRange("betty"));
}
