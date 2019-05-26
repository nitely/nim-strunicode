# strunicode

[![Build Status](https://img.shields.io/travis/nitely/nim-strunicode.svg?style=flat-square)](https://travis-ci.org/nitely/nim-strunicode)
[![licence](https://img.shields.io/github/license/nitely/nim-strunicode.svg?style=flat-square)](https://raw.githubusercontent.com/nitely/nim-strunicode/master/LICENSE)


A library for unicode string handling,
inspired by the Swift language.

## Install

```
nimble install strunicode
```

## Compatibility

Nim +0.19.0

## Usage

```nim
import strunicode

# both of these strings read as "Café"
# when printed, but have different
# unicode representation
const
  cafeA = "Caf\u00E9".Unicode
  cafeB = "Caf\u0065\u0301".Unicode

# canonical comparison
# (note: none of this will copy)
assert cafeA == cafeB
assert cafeA == cafeB.string
assert cafeA == "Caf\u00E9"
assert cafeA == "Caf\u0065\u0301"
assert cafeA.string != cafeB.string

# count characters
assert cafeA.count == cafeB.count

# get character at position 3
assert cafeA.at(3) == cafeB.at(3)
assert cafeA.at(3) == "\u00E9"
assert cafeB.at(3) == "\u0065\u0301"

# iterate over characters
block:
  var
    expected = ["C", "a", "f", "\u0065\u0301"]
    i = 0
  for c in cafeB:
    assert c == expected[i]
    inc i

# remove last character
block:
  var s = "Caf\u0065\u0301"
  s.setLen(s.len - s.Unicode.at(^1).len)
  assert s == "Caf"
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
