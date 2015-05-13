
/**
 * Convert binary data to hex and ASCII.
 *
 * Copyright: Copyright Digital Mars 2015-2015
 * License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   $(WEB digitalmars.com, Walter Bright)
 * Source:    $(SARGONSRC src/sargon/_dumphex.d)
 */

module sargon.dumphex;

private import std.range;


/**********************************
    Transform ubytes into hex and ASCII.

    Params:
        r = input range of ubytes
        startoffset = offset of start of bytes

    Returns:
        range of chars with r's contents in hex and ASCII
 */

auto dumpHex(Range)(Range r, ulong startoffset = 0)
    if (isInputRange!Range && is(ElementType!Range == ubyte))
{
    import core.stdc.ctype;

    struct Result
    {
        enum PerLine = 16;
        enum OffsetDigits = 16;

        this(Range r, ulong startoffset)
        {
            this.r = r;
            this.offset = startoffset;
        }

        @property bool empty()
        {
            return nleft == 0 && r.empty;
        }

        @property char front()
        {
            immutable char[16] hexDigits = "0123456789abcdef";

            if (!nleft)
            {
                line[0 .. $ - 1] = ' ';
                line[OffsetDigits] = ':';
                line[$ - 1] = '\n';

                size_t ndigits;
                auto offs = offset;
                while (ndigits < 4 || offs)
                {
                    line[OffsetDigits - ndigits - 1] = hexDigits[offs & 0x0F];
                    offs >>= 4;
                    line[OffsetDigits - ndigits - 2] = hexDigits[offs & 0x0F];
                    offs >>= 4;
                    ndigits += 2;
                }

                size_t i;
                while (!r.empty)
                {
                    ubyte c = r.front;
                    r.popFront();

                    line[OffsetDigits + 2 + i * 3]     = (c >> 4) ? hexDigits[c >> 4] : ' ';
                    line[OffsetDigits + 2 + i * 3 + 1] = hexDigits[c & 0x0F];
                    line[OffsetDigits + 2 + PerLine * 3 + 3 + i] = core.stdc.ctype.isprint(c) ? c : '.';
                    if (++i == PerLine)
                        break;
                }
                nleft = line.length - OffsetDigits + ndigits;
                offset += PerLine;
            }
            return line[line.length - nleft];
        }

        void popFront()
        {
            if (!nleft)
                front();
            --nleft;
        }

        static if (isForwardRange!Range)
        {
            @property typeof(this) save()
            {
                auto ret = this;
                ret.r = r.save;
                return ret;
            }
        }

      private:
        Range r;
        ulong offset;
        char[OffsetDigits + 2 + PerLine * 3 + 3 + PerLine + 1] line;
        size_t nleft;
    }

    return Result(r, startoffset);
}

unittest
{
    import std.conv;
    import std.array;

  {
    ubyte[] data = cast(ubyte[])hexString!"65 74 29 3b 0d 0a 7d 0d 0a";
    auto s = data.dumpHex(0x0ad0).array;
    assert(s == "0ad0: 65 74 29 3b  d  a 7d  d  a                         et);..}..       \n");
  }
  {
    ubyte[] data = cast(ubyte[])"65 74 29 3b 0d 0a 7d 0d 0a";
    auto s = data.dumpHex(0x0ad578).array;
    assert(s == "0ad578: 36 35 20 37 34 20 32 39 20 33 62 20 30 64 20 30    65 74 29 3b 0d 0
0ad588: 61 20 37 64 20 30 64 20 30 61                      a 7d 0d 0a      \n");
  }
  {
    ubyte[] data = cast(ubyte[])hexString!"65 74 29 3b 0d 0a 7d 0d 0a";
    auto r = data.dumpHex(0x0ad0);
    auto s = r.save;
    r.popFront();
    assert(s.front == '0');
    assert(r.front == 'a');
  }
}
