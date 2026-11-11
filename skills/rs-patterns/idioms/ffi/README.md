# FFI Idioms

> **rs-patterns · FFI idioms** — *Use when:* writing any `extern "C"` boundary
> **Traces to:** rs-unsafe · **Source:** rust-unofficial/patterns `src/idioms/ffi/intro.md` @ 36fdd17 (MPL-2.0, see ../../SOURCES.md)

Writing FFI code is an entire course in itself. However, there are several
idioms here that can act as pointers, and avoid traps for inexperienced users of
`unsafe` Rust.

This section contains idioms that may be useful when doing FFI.

1. [Idiomatic Errors](errors.md) - Error handling with integer codes and
   sentinel return values (such as `NULL` pointers)

2. [Accepting Strings](accepting-strings.md) with minimal unsafe code

3. [Passing Strings](passing-strings.md) to FFI functions
