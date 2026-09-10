# Project: A Text Report

We will count newline terminators, ASCII-whitespace-delimited words, and UTF-8
bytes in a file. This modest definition is deliberate: terminal line wrapping
and language-aware word segmentation are different problems.

You need [Getting Started](getting-started.md), variables, loops, and functions.
Complete the stages in order. The final program keeps computation separate
from command-line and filesystem work so tests do not need real files.

## 1. Start with one pure function

Create an empty directory, enter it, and run `encore init --name text_report`,
then `encore add std`. Create the `src/stats` directory and save the following
function in `src/stats/mod.enq`:

```encore
{{#include ../examples/guide/src/tutorial/mod.enq:count_lines}}
```

`usize` is the target-sized unsigned integer used for lengths. `mut` permits
updating the local count and index. Byte 10 is LF, the newline terminator.
The bounds check precedes byte access. UTF-8 continuation bytes cannot equal
ASCII LF, so counting this delimiter does not require decoding characters.

For this stage, this is the complete `src/main.enq`:

```encore
import refrain::stats::count_lines
import std::io::println

fn main() -> u32 {
    let input = "one\ntwo\n"
    println(f"lines={count_lines(input)}")
    ret 0_u32
}
```

Run `encore run`. The expected output is `lines=2`. A final line without LF
does not increase this count. Our name refers to newline terminators, not the
number of nonempty text fragments.

## 2. Return structured data

Append these declarations to `src/stats/mod.enq`:

```encore
{{#include ../examples/guide/src/tutorial/mod.enq:report}}
```

`Report` gives each result a name and unit. `in_word` remembers whether the
previous byte belonged to a word. Increment only on a transition from a
separator to a non-separator; multiple spaces do not create empty words.
Non-ASCII bytes remain in the current word. This is not Unicode word breaking.

## 3. Validate arguments before reading

At the top of `src/stats/mod.enq`, add:

```encore
import core::option::Option
import core::result::Result
```

Then append:

```encore
{{#include ../examples/guide/src/tutorial/mod.enq:argument}}
```

The parser accepts one nonempty argument. `Option` distinguishes an absent
argument from an empty one; `Result` lets the entrypoint explain a failure.

Replace `src/main.enq` with this complete program:

```encore
import core::result::Result
import refrain::stats::{analyze, input_path}
import std::io::{eprintln, println}
import std::os::{argv, file_exists, read_file}

fn main() -> u32 {
    match input_path(argv(1_usize), argv(2_usize)) {
        Result::Ok(path) => {
            if !file_exists(path) {
                eprintln("input file does not exist: " + path)
                ret 1_u32
            }
            let report = analyze(read_file(path))
            println(f"{report.lines} {report.words} {report.bytes}")
            ret 0_u32
        }
        Result::Err(message) => {
            eprintln(message)
            ret 2_u32
        }
    }
}
```

Save `one two` and `three` on two lines in `sample.txt`, with an LF after each
line. `encore run -- sample.txt` prints:

```text
2 3 14
```

CRLF files have additional bytes; do not expect the same byte count after a
text editor converts line endings. Running without an argument prints usage
and exits nonzero; giving two paths also fails.

**Current API limitation:** `read_file` returns `str`, not `Result`. The
existence check catches the common missing-path case, but does not establish
read permission or prevent a race. This example is not a lossless I/O-error
abstraction. Do not claim an empty return proves a successful read. A production
tool needs a file API that reports read failures explicitly.

## 4. Test without the filesystem

Append these tests to `src/stats/mod.enq`:

```encore
{{#include ../examples/guide/src/tutorial/mod.enq:report_tests}}
```

Run `encore test --filter book_text_report_cases`. Returning `false` fails the
test. The test covers empty input, an ordinary file, missing final LF, Unicode,
and repeated separators. Run `encore check` and `encore format` before sharing
the project.

**Exercise:** make the tool also report the number of Unicode scalar values.
Do not replace the byte count: add a separate named field.

<details><summary>Solution</summary>

Add a `characters: usize` field, populate it with `text.char_len()`, and print
it explicitly. Add a test with `"é"`: two UTF-8 bytes, one scalar value. A
scalar count still does not count user-perceived grapheme clusters.

</details>
