
/**
 * Text macro processor
 *
 * Copyright: Copyright Digital Mars 1999-2015
 * License:   $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Authors:   $(WEB digitalmars.com, Walter Bright)
 * Source:    $(SARGONSRC src/sargon/_textmac.d)
 */

module sargon.textmac;

import core.stdc.ctype;
import std.outbuffer;

private:

enum ubyte[2] BLUEL = [0xFF, '{'];
enum ubyte[2] BLUER = [0xFF, '}'];

/**********************************************************
 * Given buffer p[], extract argument marg[].
 * Params:
 *      n =     0:      get entire argument
 *              1..9:   get nth argument
 *              -1:     get 2nd through end
 *      html = skip over html comments and tags
 * Returns:
 *      number of characters from start of p[] to end of argument
 */

size_t extractArgN(T)(T[] p, out T[] marg, int n, bool html = false) pure nothrow @nogc @safe
{
    /* Scan forward for matching right parenthesis.
     * Nest parentheses.
     * Skip over 0xFF { ... 0xFF } blue paint
     * Skip over "..." and '...' strings inside HTML tags.
     * Skip over <!-- ... --> comments.
     * Skip over previous macro insertions
     */
    size_t end = p.length;
    uint parens = 1;            // inside ( ), can nest
    char instring = 0;          // either 0, ' or "
    bool incomment = false;     // in <!-- ... -->
    bool intag = false;
    uint inexp = 0;             // inside 0xFF { ... 0xFF }, can nest
    uint argn = 0;

    size_t v = 0;

  Largstart:
    // Skip first space, if any, to find the start of the macro argument
    if (n != 1 && v < end && isspace(p[v]))
        v++;

    auto vstart = v;

    for (; v < end; v++)
    {   char c = p[v];

        switch (c)
        {
            case ',':
                if (!inexp && !instring && !incomment && parens == 1)
                {
                    argn++;
                    if (argn == 1 && n == -1)
                    {   v++;
                        goto Largstart;
                    }
                    if (argn == n)
                        break;
                    if (argn + 1 == n)
                    {   v++;
                        goto Largstart;
                    }
                }
                continue;

            case '(':
                if (!inexp && !instring && !incomment)
                    parens++;
                continue;

            case ')':
                if (!inexp && !instring && !incomment && --parens == 0)
                {
                    break;
                }
                continue;

            case '"':
            case '\'':
                if (!inexp && !incomment && intag)
                {
                    if (c == instring)
                        instring = 0;
                    else if (!instring)
                        instring = c;
                }
                continue;

            case '<':
                if (html && !inexp && !instring && !incomment)
                {
                    if (v + 6 < end &&
                        p[v + 1] == '!' &&
                        p[v + 2] == '-' &&
                        p[v + 3] == '-')
                    {
                        incomment = true;
                        v += 3;
                    }
                    else if (v + 2 < end &&
                        isalpha(p[v + 1]))
                        intag = true;
                }
                continue;

            case '>':
                if (!inexp)
                    intag = false;
                continue;

            case '-':
                if (!inexp &&
                    !instring &&
                    incomment &&
                    v + 2 < end &&
                    p[v + 1] == '-' &&
                    p[v + 2] == '>')
                {
                    incomment = false;
                    v += 2;
                }
                continue;

            case BLUEL[0]:
                if (v + 1 < end)
                {
                    if (p[v + 1] == BLUEL[1])
                        inexp++;
                    else if (p[v + 1] == BLUER[1])
                        inexp--;
                }
                continue;

            default:
                continue;
        }
        break;
    }
    if (argn == 0 && n == -1)
        marg = p[v .. end];
    else
        marg = p[vstart .. v];
    //printf("extractArg%d('%.*s') = '%.*s'\n", n, end, p, *pmarglen, *pmarg);
    return v;
}

///
unittest
{
    import std.stdio;

    size_t v;
    string marg;

    v = extractArgN(" hello", marg, 0);
    assert(marg == "hello" && v == 6);

    v = extractArgN(" hello", marg, 1);
    assert(marg == " hello" && v == 6);

    v = extractArgN(" hello", marg, 2);
    assert(marg == "hello" && v == 6);

    v = extractArgN(" hello", marg, -1);
    assert(marg == "" && v == 6);

    v = extractArgN(" hello)x", marg, 0);
    assert(marg == "hello" && v == 6);

    v = extractArgN(" hell(o)x", marg, 0);
    assert(marg == "hell(o)x" && v == 9);

    v = extractArgN(" he,l,lo", marg, 0);
    assert(marg == "he,l,lo" && v == 8);

    v = extractArgN(" he,l,lo", marg, 1);
    assert(marg == " he" && v == 3);

    v = extractArgN(" he, l, lo", marg, 2);
    assert(marg == "l" && v == 6);

    v = extractArgN(" he, l, lo", marg, 3);
    assert(marg == "lo" && v == 10);

    v = extractArgN(" he, l, lo", marg, 4);
    assert(marg == "he, l, lo" && v == 10);

    v = extractArgN(" he, l, lo", marg, -1);
    assert(marg == "l, lo" && v == 10);

    v = extractArgN(" he<!--, -->", marg, 1, true);
    assert(marg == " he<!--, -->" && v == 12);

    v = extractArgN(" he<tag ',' \",\">", marg, 1, true);
    assert(marg == " he<tag ',' \",\">" && v == 16);

    v = extractArgN(" he\xFF{ , \xFF}a", marg, 1);
    //writefln("v = %s, marg = '%s'", v, marg);
    assert(marg == " he\xFF{ , \xFF}a" && v == 11);
}


/*****************************************************
 * Expand macro.
 *
 * The macro processor is the same one used in Ddoc.
 *
 * Params:
 *      text = source text to expand
 *      table = table of name=value macro definitions
 *      html = true if recognize HTML tags and comments
 *
 * Returns:
 *      The source text after macro expansion.
 *      The return string is GC allocated.
 */


public

string expand(const(char)[] text, string[string] table, bool html = false)
{
    //import std.stdio;
    import core.stdc.stdlib : malloc, free;

    OutBuffer buf;

    void expandImpl(size_t start, size_t *pend, char[] arg, void *pinuse = null)
    {
        version (none)
        {
            writefln("expand(buf[%s..%s], arg = '%s')\n", start, *pend, arg);
            writefln("Buf is: '%s'", cast(string)buf.data[start .. *pend]);
        }

        static int nest;
        if (nest > 100)             // limit recursive expansion
            return;
        nest++;

        static struct Inuse
        {
            Inuse* next;
            string value;
        }

        bool isInuse(string value)
        {
            for (Inuse* p = cast(Inuse*)pinuse; p; p = p.next)
            {
                if (p.value is value)
                    return true;
            }
            return false;
        }

        // Alloc/free a temporary buf that uses a stack buffer and overflows to malloc/free
        static char[] bufdup(const(char)[] src, char[] tmp)
        {
            char[] result;
            if (src.length < tmp.length)
                result = tmp[0 .. src.length];
            else
            {
                char* p = cast(char*)core.stdc.stdlib.malloc(src.length * char.sizeof);
                assert(p);
                result = p[0 .. src.length];
            }
            result[] = src[];
            return result;
        }

        static void buffree(char[] buf, const char[] tmp)
        {
            if (buf.ptr != tmp.ptr)
                core.stdc.stdlib.free(buf.ptr);
        }

        size_t end = *pend;
        assert(start <= end);
        assert(end <= buf.offset);

        // copy arg[] as it may be a slice into buf[] which may shift
        version (unittest)
            char[2] argtmp = void;
        else
            char[10] argtmp = void;
        arg = bufdup(arg, argtmp);
        scope (exit) buffree(arg, argtmp);

        /* First pass - replace $x where x is a digit or '+'
         */
        for (size_t u = start; u + 1 < end; )
        {
            char* p = cast(char *)buf.data.ptr;   // buf->data is not loop invariant

            /* Look for $x, but not $$x, and replace it with arg.
             */
            if (p[u] == '$' && (isdigit(p[u + 1]) || p[u + 1] == '+'))
            {
                if (u > start && p[u - 1] == '$')
                {   // Don't expand $$x, but replace it with $x
                    buf.remove(u - 1, 1);
                    end--;
                    u += 1; // now u is one past the x
                    continue;
                }

                auto c = p[u + 1];
                int n = (c == '+') ? -1 : c - '0';

                char[] marg;
                if (n == 0)             // if $0
                    marg = arg;
                else
                    extractArgN(arg, marg, n, html);

                if (marg.length == 0)
                {   // Just remove macro invocation
                    //printf("Replacing '$%c' with '%.*s'\n", p[u + 1], marglen, marg);
                    buf.remove(u, 2);
                    end -= 2;
                }
                else if (c == '+')      // if $+
                {
                    // Replace '$+' with 'marg'
                    //printf("Replacing '$%c' with '%.*s'\n", p[u + 1], marglen, marg);
                    buf.remove(u, 2);
                    buf.insert(u, cast(ubyte[])marg);
                    end += marg.length - 2;

                    // Scan replaced text for further expansion
                    size_t mend = u + marg.length;
                    expandImpl(u, &mend, null, pinuse);
                    end += mend - (u + marg.length);
                    u = mend;
                }
                else
                {
                    // Replace '$n' with 'BLUEL marg BLUER'
                    //printf("Replacing '$%c' with '\xFF{%.*s\xFF}'\n", p[u + 1], marglen, marg);
                    buf.data[u] = BLUEL[0];
                    buf.data[u + 1] = BLUEL[1];
                    buf.insert(u + 2, cast(ubyte[])marg);
                    buf.insert(u + 2 + marg.length, cast(ubyte[])(BLUER[]));
                    end += -2 + BLUEL.length + marg.length + BLUER.length;

                    // Scan replaced text for further expansion
                    size_t mend = u + 2 + marg.length;
                    expandImpl(u + 2, &mend, null, pinuse);
                    end += mend - (u + 2 + marg.length);
                    u = mend;
                }
                //printf("u = %d, end = %d\n", u, end);
                //printf("#%.*s#\n", end, buf.data.ptr);
                continue;
            }

            u++;
        }

        /* Second pass - replace other macros
         */
        for (size_t u = start; u + 4 < end; )
        {
            char *p = cast(char *)buf.data.ptr;   // buf->data is not loop invariant

            /* A valid start of macro expansion is $(c, where c is
             * an id start character, and not $$(c.
             */
            if (p[u] == '$' &&
                p[u + 1] == '(' &&
                isIdStart(p+u+2))
            {
                //printf("\tfound macro start '%c'\n", p[u + 2]);
                char[] name;

                size_t v;
                /* Scan forward to find end of macro name and
                 * beginning of macro argument (marg).
                 */
                for (v = u + 2; v < end; v += utfStride(p+v))
                {

                    if (!isIdTail(p+v))
                    {   // We've gone past the end of the macro name.
                        name = p[u + 2 .. v];
                        break;
                    }
                }

                char[] marg;
                v += extractArgN(p[v .. end], marg, 0, html);
                assert(v <= end);

                if (v < end)
                {   // v is on the closing ')'
                    if (u > start && p[u - 1] == '$')
                    {   // Don't expand $$(NAME), but replace it with $(NAME)
                        buf.remove(u - 1, 1);
                        end--;
                        u = v;      // now u is one past the closing ')'
                        continue;
                    }

                    auto pm = name in table;
                    if (pm)
                    {
                        auto m = *pm;
                        bool mIsInuse = isInuse(m);

                        //writefln("mIsInuse = %s, arg = '%s', marg =  '%s'", mIsInuse, arg, marg);
                        if (mIsInuse && marg.length == 0)
                        {   // Remove macro invocation because it expands to nothing
                            buf.remove(u, v + 1 - u);
                            end -= v + 1 - u;
                        }
                        else if (mIsInuse &&
                                 (arg == marg ||
                                  (arg.length + 4 == marg.length &&
                                   marg[0] == BLUEL[0] &&
                                   marg[1] == BLUEL[1] &&
                                   arg == marg[2 .. marg.length - 2] &&
                                   marg[marg.length - 2] == BLUER[0] &&
                                   marg[marg.length - 1] == BLUER[1]
                                 )
                                )
                               )
                        {   // Recursive expansion; just leave in place
                        
                        }
                        else
                        {
                            //writefln("\tmacro '%s'(%s) = '%s'\n", name, marg, m);

                            // copy marg[] as it is a slice into buf which will shift
                            version (unittest)
                                char[2] margtmp = void;
                            else
                                char[10] margtmp = void;
                            marg = bufdup(marg, margtmp);
                            scope (exit) buffree(marg, margtmp);

                            // Insert replacement text
                            buf.spread(v + 1, BLUEL.length + m.length + BLUER.length);
                            buf.data[v + 1] = BLUEL[0];
                            buf.data[v + 2] = BLUEL[1];
                            buf.data[v + 3 .. v + 3 + m.length] = cast(ubyte[])m[];
                            buf.data[v + 3 + m.length]     = BLUER[0];
                            buf.data[v + 3 + m.length + 1] = BLUER[1];

                            end += 2 + m.length + 2;

                            // Scan replaced text for further expansion
                            Inuse inuse;
                            inuse.next = cast(Inuse *)pinuse;
                            inuse.value = m;

                            size_t mend = v + 1 + 2+m.length+2;
                            expandImpl(v + 1, &mend, marg, &inuse);
                            end += mend - (v + 1 + 2+m.length+2);

                            buf.remove(u, v + 1 - u);
                            end -= v + 1 - u;
                            u += mend - (v + 1);

                            //printf("u = %d, end = %d\n", u, end);
                            //printf("#%.*s#\n", end - u, &buf->data[u]);
                            continue;
                        }
                    }
                    else
                    {
                        // Replace $(NAME) with nothing
                        buf.remove(u, v + 1 - u);
                        end -= (v + 1 - u);
                        continue;
                    }
                }
            }
            u++;
        }
        *pend = end;
        nest--;
    }

    buf = new OutBuffer();
    buf.write(text);
    size_t end = buf.offset;
    expandImpl(0, &end, null);
    assert(end == buf.offset);

    /* Remove the blue paint
     */
    size_t j;
    for (size_t i = 0; i < buf.offset; ++i)
    {
        char c = buf.data[i];
        if (c == BLUEL[0] && i + 1 < buf.offset)
            ++i;
        else
            buf.data[j++] = c;
    }

    // Convert result to string
    return cast(string)buf.data[0 .. j];
}

///
unittest
{
    import std.stdio;

    string[string] table;
    string s;

    s = expand("hello", table);
    assert(s == "hello");

    table["ABC"] = "def";
    s = expand("foo$(ABC)", table);
    assert(s == "foodef");

    s = expand("foo$(DEF)", table);
    assert(s == "foo");

    table["GHI"] = "";
    s = expand("foo$(GHI)x", table);
    assert(s == "foox");

    table["JKI"] = "$(JKI)";
    s = expand("foo$(JKI)x", table);
    assert(s == "foox");

    s = expand("foo$$(JKI)x", table);
    assert(s == "foo$(JKI)x");

    s = expand("foo$(123)x", table);
    assert(s == "foo$(123)x");

    table["M3"] = "$0";
    s = expand("foo$(M3)x", table);
    assert(s == "foox");

    s = expand("foo$(M3 $(M3 1) 1)x", table);
    assert(s == "foo1 1x");

    table["M4"] = "$+";
    s = expand("foo$(M4 1,2,3)x", table);
    assert(s == "foo2,3x");

    table["M5"] = "$$1";
    s = expand("foo$(M5 1,2,3)x", table);
    assert(s == "foo$1x");

    table["M6"] = "$(M6 $0)";
    s = expand("foo$(M6 1)x", table);
//writefln("s = '%s'", s);
    assert(s == "foo$(M6 1)x");
}

void remove(OutBuffer buf, size_t index, size_t nbytes)
{
    //writefln("%s %s %s", index, nbytes, buf.offset);
    assert(index + nbytes <= buf.offset);
    for (size_t i = 0; i < buf.offset - (index + nbytes); ++i)
    {
        buf.data[index + i] = buf.data[index + i + nbytes];
    }
    buf.offset -= nbytes;
}

void insert(OutBuffer buf, size_t index, ubyte[] data)
{
    buf.spread(index, data.length);
    for (size_t i = 0; i < data.length; ++i)
    {
        buf.data[index + i] = data[i];
    }
}

int isIdStart(const char *p)
{
    char c = *p;
    if (isalpha(c) || c == '_')
        return 1;
/+ fix later
    if (c >= 0x80)
    {   size_t i = 0;
        if (utf_decodeChar(p, 4, &i, &c))
            return 0;   // ignore errors
        if (std.uni.isAlpha(c))
            return 1;
    }
+/
    return 0;
}

int isIdTail(const char *p)
{
    char c = *p;
    if (isalnum(c) || c == '_')
        return 1;
    if (c >= 0x80)
    {
        return isIdStart(p);
    }
    return 0;
}

int utfStride(const char *p)
{
    char c = *p;
    if (c < 0x80)
        return 1;

    import core.bitop : bsr;
    immutable msbs = 7 - bsr(~c);
    if (msbs < 2 || msbs > 4)
        return 1;                       // errors consume 1 character
    return msbs;
}



