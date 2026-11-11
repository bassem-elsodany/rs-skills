# Rust Compiler Error Code Index

Quick lookup table: Error code → Skill routing

## Ownership & Lifetimes (rs-ownership)

| Error Code | Message | Skill | Common Fix |
|------------|---------|-------|------------|
| E0382 | use of moved value | rs-ownership | Use `clone()`, restructure ownership |
| E0597 | borrowed value does not live long enough | rs-ownership | Extend lifetime, restructure scopes |
| E0499 | cannot borrow as mutable more than once | rs-ownership | Use `RefCell`, restructure code |
| E0502 | cannot borrow as mutable while immutable borrow exists | rs-ownership | Split borrows, use interior mutability |
| E0506 | cannot assign to borrowed value | rs-ownership | Drop borrow before assignment |
| E0507 | cannot move out of borrowed content | rs-ownership | Use `clone()`, `take()`, or restructure |
| E0515 | cannot return reference to local variable | rs-ownership | Return owned value, use lifetime params |
| E0716 | temporary value dropped while borrowed | rs-ownership | Bind to variable, extend lifetime |
| E0621 | explicit lifetime required in the type | rs-ownership | Add lifetime annotations |

## Mutability (rs-mutability)

| Error Code | Message | Skill | Common Fix |
|------------|---------|-------|------------|
| E0596 | cannot borrow as mutable | rs-mutability | Add `mut`, use interior mutability |

## Type System (rs-traits)

| Error Code | Message | Skill | Common Fix |
|------------|---------|-------|------------|
| E0277 | the trait bound `X` is not satisfied | rs-traits / rs-concurrency | Implement trait, add bound, use `dyn` |
| E0308 | mismatched types | rs-traits | Type conversion, fix generics |
| E0599 | no method named `X` found for type `Y` | rs-traits | Import trait, check types |

## Concurrency (rs-concurrency)

| Error Code | Message | Skill | Common Fix |
|------------|---------|-------|------------|
| E0277 (Send) | `X` cannot be sent between threads safely | rs-concurrency | Use `Arc`, ensure `Send` |
| E0277 (Sync) | `X` cannot be shared between threads safely | rs-concurrency | Use `Mutex`, ensure `Sync` |

## Ecosystem (rs-ecosystem)

| Error Code | Message | Skill | Common Fix |
|------------|---------|-------|------------|
| E0425 | cannot find value `X` in this scope | rs-ecosystem | Import with `use`, check visibility |
| E0433 | failed to resolve: could not find `X` | rs-ecosystem | Add dependency, fix path |
| E0603 | `X` is private | rs-ecosystem | Use public API, check exports |

## Quick Diagnosis Flow

```
Compiler Error
    ↓
Contains "moved" or "borrow"?
    → rs-ownership
    ↓
Contains "mutable"?
    → rs-mutability
    ↓
Contains "Send" or "Sync" or "thread"?
    → rs-concurrency
    ↓
Contains "trait bound" or "type"?
    → rs-traits
    ↓
Contains "cannot find" or "private"?
    → rs-ecosystem
```

## Common Error Patterns

### "value moved here" → m01
```rust
let s = String::from("hello");
let s2 = s;  // s moved here
println!("{}", s);  // E0382: use of moved value
```

### "does not live long enough" → m01
```rust
fn dangling() -> &str {
    let s = String::from("hello");
    &s  // E0597: s does not live long enough
}
```

### "cannot be sent between threads" → m07
```rust
let rc = Rc::new(42);
thread::spawn(move || {
    println!("{}", rc);  // E0277: Rc<i32> cannot be sent
});
```

### "trait bound not satisfied" → m04
```rust
fn print_debug<T: Debug>(t: T) {
    println!("{:?}", t);
}
print_debug(SomeType);  // E0277 if SomeType: !Debug
```
