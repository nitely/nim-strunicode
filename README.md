# strunicode

A library for unicode string handling,
inspired by the Swift language.

## Install

```
nimble install strunicode
```

## Compatibility

Nim +0.18.0

## Usage

```nim
import strunicode

# both of these strings read as "Café"
# when printed, but have different
# unicode representation
var
  cafeA = "Caf\u00E9"
  cafeB = "Caf\u0065\u0301"

# canonical comparison
assert eq(cafeA, cafeB)

# count characters
assert cafeA.count == cafeB.count

# get character at position 3
assert cafeA.at(3) == cafeB.at(3)
assert $cafeA.at(3) == "\u00E9"
assert $cafeB.at(3) == "\u0065\u0301"

# iterate over characters
block:
  var
    expected = ["C", "a", "f", "\u0065\u0301"]
    i = 0
  for c in cafeB.chars:
    assert $c == expected[i]
    inc i
```
|
|
 -> There's more, [read the docs](https://nitely.github.io/nim-strunicode/)

## Tests

```
nimble test
```

## LICENSE

MIT
