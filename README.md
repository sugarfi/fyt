# fyt

fyt is a small lang. it is designed to be limited, but still powerful, because programming with limitations is fun.

## installation

install crystal. then run:
```
crystal build src/main.cr -p -o fyt --release --no-debug
```
to build an optimized release build.

## usage

run `./fyt` for an interactive interpreter, or `./fyt file.fyt` to run a file.

## docs

fyt has a very simple syntax. this is by design; the language is easy to learn, and while it
can be challenging to use, hopefully it is entertaining.

### basic syntax

fyt code is written as a series of expressions seperated by semicolons. it is whitespace insensitive.

### comments

comments use a `#`.

### literals

there are several types of literals in fyt:

#### numbers

numbers are written using the syntax you would expect: `5`, `-5`, `5.5`, `-5.5`, etc. they are stored internally as 32 bit floats.

#### strings

strings are written using double quotes: `""`, `"abc"`, etc. a few escape sequences are available: `\n` for a newline, `\r` for a
carriage return, and `\e` for ascii 27, the start of an ansi escape sequence.

#### symbols

symbols are written using a `!` and then any combination of alphanumber characters, underscores, dollar signs, or at signs. for
example: `!a`, `!a_b`, `!$$$`, etc.

#### maps

maps are a cross between an array and a hashmap. they are written using `[]`. maps consist of several values, seperated by whitespace.
a key and a value can be provided, seperated by a `=>`, or just a value can be provided in which case a number will be used as a key.
whenever a key is not provided, a counter is used, which is incremented each time. a few examples: `[ !a => 5 !b => 6 ]`, `[ 1 2 ]`.
these forms can be mixed and matched: for example, `[ 1 !a => 2 3 ]` would be equivalent to `[ 0 => 1 !a => 2 1 => 3 ]`. the counter
starts at `0` and is used for a key. then `!a` is used as a key, so the counter remains at `0`. then again a key is left out, so the
counter is incremented and `1` is used. thus, this is equivalent to `[ 1 3 !a => 2 ]`, `[ !a => 2 1 3 ]`, etc.

#### blocks

blocks are like lambdas in some languages or subs in perl. they are written using `{ }` with code in between. for example:
`{ 5; 6; 7; }`. a block cannot be empty.

### operators

operators use prefix syntax. there are several operators available:

- `%eq`: tests for equality. on numbers, strings, symbols, and maps, this works as you would expect: it returns `1` on true and `0`
  on false. on blocks it always returns `0`.
- `%ne`: tests for inequality. simply returns the opposite of `%eq`: `0` for `1` and `1` for `0`.
- `%lt`: tests for less than. on numbers it returns `1` if the first number is less than the second and `0` otherwise. on strings,
  it compares string length. on all other values it errors.
- `%gt`: returns the opposite of `%lt`.
- `+`: adds two values. behaves as you would expect on numbers. with strings and symbols, it adds the values together, whatever the
  type, as long as the first is a string or symbol. on maps, merges the two maps. on blocks, it returns a new block, which executes
  both of the first blocks. otherwise it errors.
- `-`: subtracts two values. behaves as you would expect on numbers, errors on all other values.
- `*`: multiplies two values. behaves as expected on numbers. on strings, repeats the value the given number of times. errors on all
  other values.
- `/`: divides two values. behaves as you would expect of numbers, on strings and symbols counts how many times a substring occurs.
  errors on all other values.
- `^`: raises one number to the power of another. errors on all other values.

examples:
```
+ 5 5 # 10
+++ 5 5 5 5 # 20
"a" * 3 # "aaa"
"abcabc" / "a" # 2
```

### assignment

assignments use `=`. for example: `a = 5`. destructuring is done by using a map on the left and right hand sides. the same rules
about counters apply to both sides. for example:
```
[ a b c ] = [ 1 2 3 ];
```
would set `a` to `1`, `b` to `2`, and `c` to `3`.
```
[ !a => a b ] = [ 1 !a => 2 ];
```
would set `a` to `2` and `b` to `1`.

### calling

calls use a context, a callee, a `.`, and the arguments. a context is used like a reciever in other languages, to implement objects.
it is specified using `<>`. for example, to call a function `f` in the context of `x` with arguments `5` and `6`, one would write:
`<x>f.5 6`. if there is no context, one can use `?` as syntatic sugar: `<>f.` is the same as `?f.`. the callee can be either a map
or a block. if it is a map, only one argument is allowed, and it behaves like indexing: `?[ 1 2 3 ].0` would return `1`, etc. this
also works with symbols and other explicit keys: `?[ !a => 5 ].!a` would return `5`. if the key is a symbol, a name can be used
instead of the full symbol: `?[ !a => 5 ].a` is also `5`. keep in mind: this only results if the name is not defined: if `a` is set
to a value, it will be used to index instead of `!a`. when it is a block, a new scope is created, that is a mirror of the old one.
the variable `$` is set to the context if there is one,a nd the variable `@` is set to the arguments as a map that you can
destructure. by default, all variables in the block are lost when it goes out of scope. however, you can use `%ex` or `%export` to
make the block exported, meaning that all the variables in it will be written to the parent scope on exit. for example:
```
a = 5;
?{ a = 6; }.;
a; # 5
?(%ex { a = 6; }).;
a; # 6
```

recursion is allowed. a block returns the value of the last expression in it.

### includes

other files can be included using `%in` or `%include` followed by a path name as a string literal. the file will be searched for in
the environment variable `FYT_PATH`, which should be a colon-seperated list of directories. if it is not found there, the file will 
simply be loaded relative to the current directory. if `FYT_PATH` is not set, the default value is `~/fytlib`, so you can place
any files you want to include there.

### stdlib

there are 3 functions in the stdlib so far: `put`, which prints all of the arguments, `get`, which reads a string from stdin and
returns it, and `if`. `if` takes a condition as context, and if it is `0` returns the second argument and if it is anything else
returns the first. by default both arguments are evaluated before the function is called, so unless you're using it as a simple
ternary, you should use blocks and call the result. for example:
```
?(<%eq a b>if.{ "equal"; } { "not equal"; });
```

### objects

an object system of sorts can be implemented using maps. for example, to create an object with a method `get_a` that returns the
`a` property on it:
```
type = [
    !get_a => { $.a; }
];

test = [ !a => 5 ];
<test>type.get_a.; # 5
```

the use of contexts for objects allows a trait-like system of sorts. to set properties, one can use (at the moment) adding to
maps:
```
type = [
    !set_a => { + $ [ !a => 5 ] }
];

test = [];
test = <test>type.set_a.;
test.a; # 5
```

### examples

the `examples` folder contains a few examples, and i may add more at some point.

### todo

the language is not complete. several features are on the roadmap:

- file i/o
- setting object properties better maybe
- full-fledged module system

### contributing and license

do whatever with the code. credit is not necessary. prs welcome.

### bugs

there are a bunch of bugs that i can't remember at the moment. if you find, one submit an issue or email `gender@sugarfi.dev` or smth
and i might address it.

---

uwu
