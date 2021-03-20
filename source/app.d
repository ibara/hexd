import std.stdio;
import core.stdc.stdlib : exit;
import openbsd.pledge;
import std.ascii;

void main(string[] args)
{
    ubyte[16] array;
    ulong size = 0;

    /+
     + file.rawRead() uses system calls within the rpath promise.
     + So we cannot tighten our pledge as well as we could in C.
     +/
    version (OpenBSD) {
        if (pledge("stdio rpath", null) == -1)
            exit(1);
    }

    if (args.length != 2) {
        stderr.writefln("usage: %s file", args[0]);
        exit(1);
    }

    File file = File(args[1], "r");

    if (file.eof())
        exit(0);

    while (true) {
        for (int value = 0; value < array.length; value++)
            array[value] = '\0';

        for (int value = 0; value < array.length; value++) {
            auto ch = file.rawRead(new char[1]);

            if (value == 0)
                writef("%08x ", size);

            if (!file.eof()) {
                if (value == 0)
                    writef("| ");
                writef("%02x ", ch[0]);
                if (isPrintable(ch[0]))
                    array[value] = ch[0];
                else
                    array[value] = '.';
            } else {
                size += value;

                if (value == 0) {
                    writef("\n");
                    file.close();
                    return;
                }

                if (value < 8)
                    writef(" ");

                while (++value < array.length) {
                    writef("   ");
                    array[value] = ' ';
                }
                writef("   | ");

                for (int value2 = 0; value2 < array.length; value2++)
                    writef("%c", cast(char)array[value2]);
                writefln("\n%08x", size);

                file.close();

                return;
            }

            if (value == 7)
                writef(" ");
        }

        writef("| ");
        for (int value = 0; value < array.length; value++)
            writef("%c", cast(char)array[value]);
        writef("\n");
	size += array.length;
    }
}
