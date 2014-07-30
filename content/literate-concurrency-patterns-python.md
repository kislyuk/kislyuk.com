# Literate concurrency patterns in Python

Typical modern literate pattern is to write code that looks procedural, but provides implicit guarantees of
synchronization of blocks:

```
op1
op2
x = yield y
op3
op4
```

Decorator with event loop:

```
@async_driven
def f(...):
    op1
    op2
    x = yield y(z)
    op3
    op4

@async_driven
def y(...):
    ...

```

