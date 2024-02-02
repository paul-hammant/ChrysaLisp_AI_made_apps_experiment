# Environments and Symbols

In this document we cover the ChrysaLisp environment system. The types of
symbols available, the functions to bind and search for them, and how this
relates to the Lisp environment, both the root environment and individual
function environments, plus custom properties.

## Symbols

A symbol is a ChrysaLisp object that's a sequence of characters, similar to
string objects, but the difference is that a symbol has been 'interned'. What
this means is that during the `(read)` part of the REPL, when symbols are read,
a test is made to see if this symbol already exists. If it does then the symbol
that has been read is replaced with the existing symbol object, if not a new
symbol object is created and stored.

In this way ALL symbol objects that have the same character sequence become the
exact same object in memory, and share the same memory location.

Why do this ? Why bother ? Well it allows some very useful things to happen if
you know that a symbol has only one object instance no matter how or where that
symbol was read in. It makes for very fast hash map key searches and find
operations if all you need to do is check that the address of the objects match
rather than compare the character sequences.

### Standard symbols

```vdu
bert
alf
a
z57u
```

These are examples of plain old symbols. Any sequence of characters that don't
start with a ':' or a numeral.

They can be bound to a value, any other object, using `(def)` or `(defq)` like
so.

```vdu
(defq bert 56)
(defq alf "ABCD" a '(1 2 3))
(def (env) 'z57u 78)
```

`(defq)` is just the same as `(def)` but it assumes that the environment to
bind the symbol within is the current environment `(env)` and that the symbols
don't need to be quoted, hence the name `(defq)`.

To change the binding of an existing bound symbol, and this will raise an error
if the symbol is not bound, you use the `(set)` and `(setq)` functions like so.

```vdu
(setq bert 56)
(setq alf "ABCD" a '(1 2 3))
(set (env) 'z57u 78)
```

You can look up the binding for a symbol with the `(get)` function. If the
symbol is not bound this will return `:nil`.

```vdu
(get 'bert)
56
(get 'alf)
"ABCD"
(get 'a)
'(1 2 3)
(get 'z57u)
78
(get 'xyz)
:nil
```

It is possible to unbind a symbol by using `(undef)` like so.

```vdu
(undef (env) 'bert 'alf)
(get 'bert)
:nil
(get 'alf)
:nil
```

`(get)` can take an optional environment to work from. `(get sym [e])` and if
given the search for the symbol binding will start from that environment.

A string can be 'interned' by user code by use of the `(sym)` function. This is
often very useful when creating and managing your own fast lookup functions or
caches. Or you may be generating a symbol programmatically for your own
reasons.

```vdu
(def (env) (sym "ABCDEF") 23)
(get 'ABCDEF)
23
ABCDEF
23
```

### Keyword Symbols

Keyword symbols are symbols that start with a ':' character, and they have
special consideration when evaluated, they always evaluate to themselves ! Now
why would that be useful ?

It certainly makes using `(def)`, `(set)`, `(get)` and `(undef)` easier, due to
not having to quote the symbol ! But that's not the only reason.

As these symbols always evaluate to themselves, they pass up/down through
layers of evaluation without changing and that's a VERY useful property.

They can still be bound to values like standard symbols but `(eval)` will never
see the value they are bound to, but your own properties system will be able to
use this to its advantage.

We will cover this later, first we need to talk about environments.

## Environments

An environment is a set of symbol bindings. Under the hood it's just a hash map
that associates symbols with values.

You can look at the current environment by typing `(tolist (env))` at the REPL.

```vdu
(tolist (env))
((stdio @class/stdio/vtable) (args (4446511344)) (stdin
@class/in/vtable) (stdout @class/out/vtable) (stderr @class/out/vtable))
```

This is showing you the symbols and bindings that exist at the current level,
in this case the 'lisp' application you happen to be inside.

If you want to look up the parent of an environment you can use `(penv)`, try
typing `(tolist (penv (env)))` at the REPL prompt. I'm not going to print that
here as it's way too big, but that's the boot environment that all Lisp tasks
have as their shared parent environment. It's populated via the
`class/lisp/root.inc` file that's evaluated for every Lisp task launched.

### Function environments

Every function, ie. lambda or macro, that's called is provided with its own
empty environment, the parent of that environment is the current environment
present at invocation.

This environment is initially populated with the formal parameter symbols,
bound to the arguments that are passed to said function on invocation. So
before your function body starts to run it'll already be able to 'see' the
formal parameter symbol bindings. It's then free to add more and use the
current bindings as it wishes.

`(defq)` or `(bind)` functions will always bind symbols in the current
environment. `(setq)` will search the environment parentage to find a bound
symbol to operate on.

`(def)`, `(set)` and `(undef)` are given the environment explicitly, so can be
used to manipulate bindings that are not within the current functions
environment.

`(get)` is given the environment optionally, so can search for bindings that
are not within the current functions environment.

`(eval)` is given the environment, to evaluate the form within, optionally !!!
You can create private or library/object specific environments and access them
with `(eval form [e])` !

It is possible to manually push and pop the current environment using the
`(env-push [e])` and `(env-pop [e])` functions ! The optional environment
parameter allows construction of user environment stacks and trees. This is
extremely low level and should be used with caution !

### Properties

Properties are just environments created and managed by user code. While they
are free to use standard symbols they most often use keyword symbols.

How do you create a user property environment ? By use of the optional
parameter to the `(env)` function.

You can use the `(tolist e)` function to convert an environment to a list of
pairs in order to interface with other code.

```vdu
(defq e (env 1))
(tolist (e))
()
(def e :p1 78 :p2 89)
(tolist (e))
((:p1 78) (:p2 89))
(get :p1 e)
78
(get :p2 e)
89
(get :p3 e)
:nil
```

The optional parameter, to `(env)`, is used to create a new isolated
environment, ie. no parent. You can increase the number of buckets in the
current environment by use of the `(env-resize num [e])` function.

You may wish to increase the number of buckets in the current environment,
beyond the default of 1, if it's going to contain an extremely large number of
symbol bindings ! Environments are just a chain of hash maps, and there is a
trade off to be made between a single bucket and its great cache line affects
and massive amounts of entries swamping those cache affects !

### Modules

A module is an imported library or class that prepares or defines its own
internal workings within a transient environment and then exports only those
symbols and functions it wishes to be known externally.

First of all a new empty environment is pushed using `(env-push)`. Then you are
free to define new functions and variables, constants etc and use them to
construct other functions and classes. These symbols will not be visible to the
outside world, only the symbols, functions and classes you deliberately export
with the `(export env symbols)`, `(export-symbols symbols)` and
`(export-classes classes)` functions.

In effect all your 'workings' will be turned into anonymous references due to
the effect of `(prebind)` as the library is read in via the `(repl ...)` !

```file
lib/options/options.inc
```

Here only the final function `(options)` is visible to the outside.

The command application `forward` is available to scan your source code and
tell you if you are using a forward reference to a function or macro not yet
defined ! Such a function will not be available to be prebound !. It's easy to
use it to scan the entire source tree, like so:

```code
files | grep -r "\.(inc|lisp|vp)" | forward | sort
```
