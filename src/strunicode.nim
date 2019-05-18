## Swift-like unicode string handling.
## Most (all?) API operations take linear time,
## but in exchange they take constant space.
## Be aware, storing a sequence of grapheme clusters
## may take 10 times as much space as a utf-8 string.
## This is why linear time operations are prefered
## in this case.

import unicode

import graphemes
import normalize

type
  Character* = object {.shallow.}
    ## A unicode grapheme cluster
    s: string
    b: Slice[int]

proc initCharacter*(s: string, b: Slice[int]): Character =
  ## Slice a unicode grapheme cluster out of a string.
  ## This does not create a copy of the string,
  ## but in exchange, the passed string must
  ## never change (i.e: grow/shrink or be modified)
  ## while the returned ``Character`` lives
  assert b.a <= b.b or b.a == b.b+1
  assert b.b < len(s) or b.a == b.b+1
  shallowCopy(result.s, s)
  result.b = b

proc `$`*(c: Character): string =
  c.s[c.b]

proc `==`*(a, b: Character): bool =
  ## Check the characters
  ## are canonically equivalent
  # todo: use toOpenArray and memcmp
  let
    sa = a.s[a.b]
    sb = b.s[b.b]
  result = sa == sb or cmpNfd(sa, sb)

proc `==`*(a: string, b: Character): bool =
  # todo: use toOpenArray and memcmp
  let sb = b.s[b.b]
  result = a == sb or cmpNfd(a, sb)

proc `==`*(a: Character, b: string): bool =
  # todo: use toOpenArray and memcmp
  let sa = a.s[a.b]
  result = sa == b or cmpNfd(sa, b)

proc `[]`*(c: Character, i: int): char =
  if c.b.a+i > c.b.b:
    raise newException(IndexError, "index out of bounds?")
  c.s[c.b.a+i]

proc len*(c: Character): int =
  ## Return number of bytes
  ## that the character takes
  result = c.b.b - c.b.a + 1

iterator items*(c: Character): char {.inline.} =
  for i in c.b:
    yield c.s[i]

iterator runes*(c: Character): Rune {.inline.} =
  ## Iterate over runes of a character
  var
    r: Rune
    n = c.b.a
  while n <= c.b.b:
    fastRuneAt(c.s, n, r, true)
    yield r

# todo: remove, make the graphemes lib yield slices instead
iterator graphemesIt(s: string): Slice[int] =
  var
    a, b = 0
  while b < len(s):
    inc(b, graphemeLenAt(s, b))
    yield a ..< b
    a = b

iterator chars*(s: string): Character =
  ## Iterate over the characters
  ## of the given string
  for bounds in graphemesIt(s):
    yield initCharacter(s, bounds)

proc count*(s: string): int =
  ## Return the number of
  ## characters in the string
  graphemesCount(s)

proc characterAt*(s: string, i: int): Character =
  ## Returns the character
  ## at the given byte index.
  ## Returns an empty character
  ## if the index is out of bounds
  result = initCharacter(s, i ..< graphemeLenAt(s, i)+i)

proc characterAt*(s: string, i: BackwardsIndex): Character =
  ## Returns the character
  ## at the given byte index.
  ## Returns an empty character
  ## if the index is out of bounds
  let j = max(0, s.len - i.int)
  result = initCharacter(s, j-graphemeLenAt(s, i)+1 .. j)

proc at*(s: string, pos: int): Character =
  ## Return the character at the given position.
  ## Prefer ``characterAt`` when the index
  ## in bytes is known
  var j = 0
  for bounds in graphemesIt(s):
    if pos == j:
      result = initCharacter(s, bounds)
      return
    inc j
  raise newException(IndexError, "index out of bounds?")

proc eq*(a, b: string): bool =
  ## Check strings are canonically equivalent
  result = a == b or cmpNfd(a, b)

proc lastCharacter*(s: string): Character =
  ## Return the last character in the string.
  ## It can be used to remove the last character as well.
  ##
  ## .. code-block:: nim
  ##   block:
  ##     var s = "Caf\u0065\u0301"
  ##     s.setLen(s.len - s.lastCharacter.len)
  ##     doAssert s == "Caf"
  ##
  characterAt(s, ^1)

when isMainModule:
  block:
    echo "Test character is a shallow copy"
    var
      s = "abc"
      ca = initCharacter(s, 0 .. 2)
      cb = ca
    doAssert ca[0] == 'a'
    doAssert cb[0] == 'a'
    s[0] = 'z'
    doAssert ca[0] == 'z'
    doAssert cb[0] == 'z'
    let cc = cb
    doAssert cb[0] == 'z'
    doAssert cc[0] == 'z'
    s[0] = 'y'
    doAssert cb[0] == 'y'
    doAssert cc[0] == 'y'
    let cd = cc
    doAssert cc[0] == 'y'
    doAssert cd[0] == 'y'
    s[0] = 'x'
    doAssert cc[0] == 'x'
    doAssert cd[0] == 'x'
  block:
    echo "Test character shallow let"
    let s = "asd"
    var ca = initCharacter(s, 0 .. 2)
    doAssert unsafeAddr(s[0]) == unsafeAddr(ca.s[0])
  block:
    echo "Test character shallow const"
    const s = "asd"
    const ca = initCharacter(s, 0 .. 2)
    doAssert s.repr == ca.s.repr
  block:
    let s = "asd"
    let ca = initCharacter(s, 0 .. 2)
    doAssert unsafeAddr(s[0]) == unsafeAddr(ca.s[0])
  block:
    echo "Test index access"
    var
      s = "abcdef"
      c = initCharacter(s, 1 .. 2)
    doAssert c[0] == 'b'
    doAssert c[1] == 'c'
  block:
    echo "Test `items` of character"
    var
      s = "abcdef"
      expected = ['b', 'c']
      i = 0
    for c in initCharacter(s, 1 .. 2):
      doAssert expected[i] == c
      inc i
    doAssert i == len(expected)
  echo "Test `count` counts characters"
  doAssert "aΪⒶ弢".count == 4
  doAssert "\u0065\u0301".count == 1
  block:
    echo "Test character `len`"
    var s = "abcdef"
    doAssert initCharacter(s, 0 .. 0).len == 1
    doAssert initCharacter(s, 0 .. 1).len == 2
    doAssert initCharacter(s, 0 .. 2).len == 3
  block:
    echo "Test character `at`"
    var
      a = "aΪⒶ弢"
      b = "aΪⒶ弢"
    doAssert a.at(0) == b.at(0)
  block:
    var
      a = "\u00E9"
      b = "\u0065\u0301"
    doAssert a.at(0) == b.at(0)
    doAssert b.at(0) == "\u0065\u0301"
  block:
    var
      a = "\u00E9abc"
      b = "\u0065\u0301abc"
    doAssert a.at(1) == b.at(1)
    doAssert a.at(1) == "a"
  echo "Test strings are canonical equivalent"
  doAssert eq("", "")
  doAssert eq("abc", "abc")
  doAssert eq("eq\u00E9?", "eq\u0065\u0301?")
  doAssert(not eq("abc", "def"))
  block:
    echo "Test `chars` iterator"
    var
      a = "aΪⒶ弢\u00E9\u0065\u0301?"
      expected = ["a", "Ϊ", "Ⓐ", "弢", "\u00E9", "\u0065\u0301", "?"]
      i = 0
    for c in a.chars:
      doAssert expected[i] == c
      inc i
    doAssert i == len(expected)
  block:
    echo "Test `runes` iterator"
    var
      s = "\u0065\u0301"
      c = initCharacter(s, 0 .. 1)
      expected = [0x0065.Rune, 0x0301.Rune]
      i = 0
    for r in c.runes:
      doAssert expected[i] == r
      inc i
    doAssert i == len(expected)
  block:
    echo "Test empty slice is supported"
    var
      s = "abc"
      c = initCharacter(s, 0 .. -1)
    doAssert c == ""
    doAssert c == initCharacter(s, 0 .. -1)
    doAssert len(c) == 0
  block:
    echo "Test `characterAt`"
    var s = "abc"
    doAssert characterAt(s, 0) == "a"
    doAssert characterAt(s, 1) == "b"
    doAssert characterAt(s, 2) == "c"
  block:
    var s = "u̲n̲"
    doAssert characterAt(s, 0) == "u̲"
    doAssert characterAt(s, 3) == "n̲"
    doAssert characterAt(s, 123) == ""
  block:
    var s = "u̲n̲"
    doAssert characterAt(s, ^1) == "n̲"
    doAssert characterAt(s, ^4) == "u̲"
    doAssert characterAt(s, ^123) == ""
  block:
    var s = "abc\u0065\u0301?"
    doAssert characterAt(s, 3) == "\u0065\u0301"
  block:
    echo "Test characters are canonical equivalent"
    var s = "abc"
    doAssert characterAt(s, 0) == initCharacter(s, 0 .. 0)
    doAssert characterAt(s, 1) == initCharacter(s, 1 .. 1)
    doAssert characterAt(s, 2) == initCharacter(s, 2 .. 2)
  block:
    var s = "abc\u0065\u0301?"
    doAssert characterAt(s, 3) == "\u0065\u0301"
  block:
    echo "Test `lastCharacter`"
    block:
      var s = "Caf\u0065\u0301"
      s.setLen(s.len - s.lastCharacter.len)
      doAssert s == "Caf"
    block:
      var s = ""
      doAssert s.lastCharacter.len == 0
