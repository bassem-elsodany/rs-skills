# Advanced lifetimes — HRTB, GAT, `'static` bounds, trait objects, variance

> **rs-ownership · pattern** — rs-skills original (2026-11-11). Start with `lifetime-patterns.md`; come here when the basic fixes (clone, restructure, owned types) do not apply.

## `'static` is a bound, not a promise to live forever

| You see | Means | Fix |
|---|---|---|
| `T: 'static` | `T` contains no non-static borrows (an owned `String` is `'static`) | pass owned data, `Arc`, or `move` it in |
| `tokio::spawn` "borrowed value does not live long enough" | the future must be `'static` | `move` clones/Arcs into the task; or `JoinSet` + scoped structure; `std::thread::scope` for threads |
| `Box<dyn Trait>` demands `'static` | default object bound is `'static` | `Box<dyn Trait + 'a>` when it borrows |
| `&'static str` from `String` | leak (`Box::leak`) — almost never right | return `String`/`Cow<'_, str>` |

## Higher-ranked trait bounds (HRTB): `for<'a>`

A closure or function that must work for **any** borrow, not one chosen by the caller.

```rust
fn apply<F>(f: F) -> usize
where
    F: for<'a> Fn(&'a str) -> &'a str,        // works for every input lifetime
{
    f("hello").len()
}
```
- You usually don't write `for<'a>` yourself: `F: Fn(&str) -> &str` already means it (elision in `Fn` sugar). You meet it in error messages ("expected a closure that implements `for<'a> Fn(&'a T)`") and in async closures/callbacks returning futures that borrow their argument — there, return an owned future or take the argument by value.
- Error "implementation of `FnOnce` is not general enough": a closure was inferred for one specific lifetime. Annotate the closure parameter type (`|s: &str| …`) or pass a named fn.

## Generic associated types (GAT) — lending iterators and borrowed outputs

```rust
trait LendingIter {
    type Item<'a> where Self: 'a;              // the item borrows from &'a mut self
    fn next<'a>(&'a mut self) -> Option<Self::Item<'a>>;
}
```
Use when an associated type must borrow from `self` (windows over a buffer, streaming parsers). Costs: more complex bounds, weaker inference, trait objects are not supported for GATs. Alternatives first: return `Vec`/owned items, use indices, or iterate with a callback.

## Trait objects and lifetimes

- `&'a dyn Trait` = `&'a (dyn Trait + 'a)`; `Box<dyn Trait>` = `Box<dyn Trait + 'static>`.
- A struct holding `Box<dyn Fn() + 'a>` needs the lifetime parameter on the struct.
- `impl Trait` in argument position is generic (static dispatch); in return position it hides one concrete type; `+ '_`/`+ 'a` captures borrows — edition 2024 captures all in-scope lifetimes by default in return-position `impl Trait`; use `use<..>` bounds to narrow.

## Variance in one table

| Type | Variance in `T` / `'a` | Consequence |
|---|---|---|
| `&'a T` | covariant in `'a` and `T` | a longer borrow can stand in for a shorter one |
| `&'a mut T` | covariant in `'a`, **invariant in `T`** | `&mut Vec<&'long str>` cannot become `&mut Vec<&'short str>` |
| `Cell<T>`, `RefCell<T>`, `*mut T` | invariant | same reason |
| `fn(T)` | contravariant in `T` | |
| `PhantomData<&'a T>` | covariant | use `PhantomData<fn() -> T>`/`PhantomData<*const T>` to choose variance deliberately |

"Lifetime may not live long enough" with `&mut` is usually invariance: introduce a second lifetime parameter or restructure to avoid storing short borrows in a longer-lived `&mut` container.

## Self-referential data

A struct holding a reference to its own field cannot be expressed safely; don't. Use indices into a `Vec`, `Rc`/`Arc` handles, an arena (`bumpalo`/`typed-arena`), or split the owner and the borrowing view into two types. `ouroboros`/`self_cell` exist for the unavoidable case (rs-reuse-first, review the `unsafe`).
