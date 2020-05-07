## Swift-like unicode string handling.
## Most (all?) API operations take linear time,
## and constant space.
##
## Beware, a sequence of ``Character``
## may take 10 times as much space as a utf-8 string,
## thus ``seq[Character]`` should be avoided.
## This library does not use ``seq[Character]``
## in any of its APIs.

import unicode

import graphemes
import normalize

type
  UnicodeImpl = distinct string
  Unicode* = UnicodeImpl
    ## A unicode string
  Character* {.shallow.} = object
    ## A unicode grapheme cluster
    s: string
    b: Slice[int]

template toOpenArray*(c: Character): untyped =
  toOpenArray(c.s, c.b.a, c.b.b)

template toOpenArray*(s: Unicode): untyped =
  toOpenArray(s.string, 0, s.string.len-1)

func initCharacter*(s: Unicode, b: Slice[int]): Character {.inline.} =
  ## Slice a unicode grapheme cluster out of a string.
  ## This does not create a copy of the string,
  ## but in exchange, the passed string must
  ## never change (i.e: grow/shrink or be modified)
  ## while the returned ``Character`` lives
  assert b.a <= b.b or b.a == b.b+1
  assert b.b < len(s.string) or b.a == b.b+1
  shallowCopy(result.s, s.string)
  result.b = b

func `$`*(c: Character): string {.inline.} =
  result = c.s[c.b]

func eqImpl(a, b: openArray[char]): bool {.inline.} =
  result = a == b or cmpNfd(a, b)

func `==`*(a, b: Character): bool {.inline.} =
  ## Check the characters
  ## are canonically equivalent
  runnableExamples:
    const cafeA = "Caf\u00E9".Unicode
    const cafeB = "Caf\u0065\u0301".Unicode
    doAssert cafeA.at(3) == cafeB.at(3)
  eqImpl(a.toOpenArray, b.toOpenArray)

func `==`*(a: openArray[char], b: Character): bool {.inline.} =
  eqImpl(a, b.toOpenArray)

func `==`*(a: Character, b: openArray[char]): bool {.inline.} =
  eqImpl(a.toOpenArray, b)

func `==`*(a: Unicode, b: Character): bool {.inline.} =
  eqImpl(a.string, b.toOpenArray)

func `==`*(a: Character, b: Unicode): bool {.inline.} =
  eqImpl(a.toOpenArray, b.string)

func `[]`*(c: Character, i: int): char {.inline.} =
  ## Return byte of `c` at position `i` as `char`
  if c.b.a+i > c.b.b:
    raise newException(IndexError, "index out of bounds?")
  result = c.s[c.b.a+i]

func len*(c: Character): int {.inline.} =
  ## Return number of bytes
  ## that the character takes
  result = c.b.b - c.b.a + 1

iterator items*(c: Character): char {.inline.} =
  ## Iterate over chars/bytes of a Character
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

func `==`*(a, b: Unicode): bool {.inline.} =
  ## Check strings are canonically equivalent
  runnableExamples:
    const cafeA = "Caf\u00E9".Unicode
    const cafeB = "Caf\u0065\u0301".Unicode
    doAssert cafeA == cafeB
  eqImpl(a.string, b.string)

func `==`*(a: openArray[char], b: Unicode): bool {.inline.} =
  eqImpl(a, b.string)

func `==`*(a: Unicode, b: openArray[char]): bool {.inline.} =
  eqImpl(a.string, b)

func count*(s: Unicode): int {.inline.} =
  ## Return the number of
  ## characters in the string
  runnableExamples:
    doAssert "🇦🇷🇺🇾🇨🇱".Unicode.count == 3
  graphemesCount(s.string)

iterator items*(s: Unicode): Character {.inline.} =
  ## Return characters of `s`
  for bounds in s.string.graphemeBounds:
    yield initCharacter(s, bounds)

template atImpl(
  s: Unicode,
  i: int,
  graphemesItProc: untyped
): untyped =
  var j = 0
  for bounds in graphemesItProc(s.string):
    if i == j:
      result = initCharacter(s, bounds)
      return
    inc j
  raise newException(IndexError, "index out of bounds?")

func at*(s: Unicode, i: int): Character =
  ## Return the character at the given position
  runnableExamples:
    doAssert "🇦🇷🇺🇾🇨🇱".Unicode.at(1) == "🇺🇾"
  atImpl(s, i, graphemeBounds)

func at*(s: Unicode, i: BackwardsIndex): Character =
  atImpl(s, i.int-1, graphemeBoundsReversed)

func atByte*(s: Unicode, i: int): Character {.inline.} =
  ## Returns the character
  ## at the given byte index.
  ## Returns an empty character
  ## if the index is out of bounds
  result = initCharacter(s, i ..< graphemeLenAt(s.string, i)+i)

func atByte*(s: Unicode, i: BackwardsIndex): Character {.inline.} =
  let j = max(0, s.string.len - i.int)
  result = initCharacter(s, j-graphemeLenAt(s.string, i)+1 .. j)

func lastCharacter*(s: Unicode): Character {.inline.} =
  ## Return the last character in the string.
  ## It can be used to remove the last character as well.
  runnableExamples:
    doAssert "🇦🇷🇺🇾🇨🇱".Unicode.lastCharacter == "🇨🇱"
  s.atByte(^1)

func reverse*(s: var Unicode) {.inline.} =
  ## Reverse unicode string `s` in-place
  runnableExamples:
    var s = "🇦🇷🇺🇾🇨🇱".Unicode
    s.reverse
    doAssert s == "🇨🇱🇺🇾🇦🇷"
  s.string.graphemesReverse

iterator reversed*(s: Unicode): Character {.inline.} =
  # Return characters of `s` in reversed order
  for bounds in s.string.graphemeBoundsReversed:
    yield initCharacter(s, bounds)

func reversed*(s: Unicode): Unicode {.inline.} =
  ## Return the reverse of `s`
  runnableExamples:
    doAssert "🇦🇷🇺🇾🇨🇱".Unicode.reversed == "🇨🇱🇺🇾🇦🇷"
  result = s
  result.reverse

when isMainModule:
  template test(s, body: untyped): untyped =
    (proc =
      echo s
      body
    )()

  test "Test character is a shallow copy":
    var
      s = "abc".Unicode
      ca = initCharacter(s, 0 .. 2)
      cb = ca
    doAssert addr(s.string[0]) == addr(ca.s[0])
    doAssert addr(s.string[0]) == addr(cb.s[0])
    doAssert ca[0] == 'a'
    doAssert cb[0] == 'a'
    s.string[0] = 'z'
    doAssert ca[0] == 'z'
    doAssert cb[0] == 'z'
    let cc = cb
    doAssert cb[0] == 'z'
    doAssert cc[0] == 'z'
    s.string[0] = 'y'
    doAssert cb[0] == 'y'
    doAssert cc[0] == 'y'
    let cd = cc
    doAssert cc[0] == 'y'
    doAssert cd[0] == 'y'
    s.string[0] = 'x'
    doAssert cc[0] == 'x'
    doAssert cd[0] == 'x'
  test "Test character shallow let":
    let s = "asd".Unicode
    var ca = initCharacter(s, 0 .. 2)
    doAssert unsafeAddr(s.string[0]) == unsafeAddr(ca.s[0])
    doAssert s.string.repr == ca.s.repr
  test "Test character shallow const":
    const s = "asd".Unicode
    const ca = initCharacter(s, 0 .. 2)
    doAssert s.string.repr == ca.s.repr
  test "Test character shallow const/var":
    const s = "asd".Unicode
    var ca = initCharacter(s, 0 .. 2)
    var cb = initCharacter(s, 0 .. 2)
    doAssert ca.s[0].addr == cb.s[0].addr
  test "Test character shallow const/let":
    const s = "asd".Unicode
    let ca = initCharacter(s, 0 .. 2)
    let cb = initCharacter(s, 0 .. 2)
    doAssert ca.s[0].unsafeAddr == cb.s[0].unsafeAddr
  test "Test index access":
    var
      s = "abcdef".Unicode
      c = initCharacter(s, 1 .. 2)
    doAssert c[0] == 'b'
    doAssert c[1] == 'c'
  test "Test `items` of character":
    var
      s = "abcdef".Unicode
      expected = ['b', 'c']
      i = 0
    for c in initCharacter(s, 1 .. 2):
      doAssert expected[i] == c
      inc i
    doAssert i == len(expected)
  test "Test `count` counts characters":
    doAssert "aΪⒶ弢".Unicode.count == 4
    doAssert "\u0065\u0301".Unicode.count == 1
  test "Test character `len`":
    var s = "abcdef".Unicode
    doAssert initCharacter(s, 0 .. 0).len == 1
    doAssert initCharacter(s, 0 .. 1).len == 2
    doAssert initCharacter(s, 0 .. 2).len == 3
  test "Test character `at`":
    block:
      const
        a = "aΪⒶ弢".Unicode
        b = "aΪⒶ弢".Unicode
      doAssert a.at(0) == b.at(0)
    block:
      var
        a = "\u00E9".Unicode
        b = "\u0065\u0301".Unicode
      doAssert a.at(0) == b.at(0)
      doAssert b.at(0) == "\u0065\u0301"
    block:
      var
        a = "\u00E9abc".Unicode
        b = "\u0065\u0301abc".Unicode
      doAssert a.at(1) == b.at(1)
      doAssert a.at(1) == "a"
    block:
      const s = "".Unicode
      doAssertRaises(IndexError):
        discard s.at(0)
  test "Test strings are canonical equivalent":
    doAssert "".Unicode == "".Unicode
    doAssert "abc".Unicode == "abc".Unicode
    doAssert "eq\u00E9?".Unicode == "eq\u0065\u0301?".Unicode
    doAssert "abc".Unicode != "abz".Unicode

    doAssert "eq\u00E9?" == "eq\u0065\u0301?".Unicode
    doAssert "eq\u00E9?".Unicode == "eq\u0065\u0301?"
    doAssert "eq\u00E9?" != "eq\u0065\u0301?"
  test "Test `chars` iterator":
    var
      a = "aΪⒶ弢\u00E9\u0065\u0301?".Unicode
      expected = ["a", "Ϊ", "Ⓐ", "弢", "\u00E9", "\u0065\u0301", "?"]
      i = 0
    for c in a:
      doAssert expected[i] == c
      inc i
    doAssert i == len(expected)
  test "Test `runes` iterator":
    const
      s = "\u0065\u0301".Unicode
      c = initCharacter(s, 0 .. 1)
      expected = [0x0065.Rune, 0x0301.Rune]
    var i = 0
    for r in c.runes:
      doAssert expected[i] == r
      inc i
    doAssert i == len(expected)
  test "Test empty slice is supported":
    const
      s = "abc".Unicode
      c = initCharacter(s, 0 .. -1)
    doAssert c == ""
    doAssert c == initCharacter(s, 0 .. -1)
    doAssert len(c) == 0
  test "Test `atByte`":
    block:
      const s = "abc".Unicode
      doAssert atByte(s, 0) == "a"
      doAssert atByte(s, 1) == "b"
      doAssert atByte(s, 2) == "c"
    block:
      const s = "u̲n̲".Unicode
      doAssert atByte(s, 0) == "u̲"
      doAssert atByte(s, 3) == "n̲"
      doAssert atByte(s, 123) == ""
    block:
      const s = "u̲n̲".Unicode
      doAssert atByte(s, ^1) == "n̲"
      doAssert atByte(s, ^4) == "u̲"
      doAssert atByte(s, ^123) == ""
    block:
      const s = "abc\u0065\u0301?".Unicode
      doAssert atByte(s, 3) == "\u0065\u0301"
  test "Test characters are canonical equivalent":
    block:
      const s = "abc".Unicode
      doAssert atByte(s, 0) == initCharacter(s, 0 .. 0)
      doAssert atByte(s, 1) == initCharacter(s, 1 .. 1)
      doAssert atByte(s, 2) == initCharacter(s, 2 .. 2)
    block:
      const s = "abc\u0065\u0301?".Unicode
      doAssert atByte(s, 3) == atByte(s, 3)
      doAssert atByte(s, 0) != atByte(s, 3)
    block:
      const s = "abc\u0065\u0301?".Unicode
      doAssert atByte(s, 3) == "\u0065\u0301"
    block:
      const s = "abc\u0065\u0301?".Unicode
      doAssert atByte(s, 3) == "\u0065\u0301".Unicode
    block:
      const s = "abc\u0065\u0301?".Unicode
      doAssert "\u0065\u0301" == atByte(s, 3)
    block:
      const s = "abc\u0065\u0301?".Unicode
      doAssert "\u0065\u0301".Unicode == atByte(s, 3)
    block:
      const s = "".Unicode
      doAssert s.atByte(0) == ""
      doAssert s.atByte(10) == ""
      doAssert s.atByte(^1) == ""
      doAssert s.atByte(^10) == ""
  test "Test `lastCharacter`":
    block:
      var s = "Caf\u0065\u0301".Unicode
      s.string.setLen(s.string.len - s.lastCharacter.len)
      doAssert s == "Caf"
    block:
      const s = "".Unicode
      doAssert s.lastCharacter.len == 0
  test "Test `at` (backward)":
    block:
      const s = "Caf\u0065\u0301".Unicode
      doAssert s.at(^1) == "\u0065\u0301"
      doAssert s.at(^1) != "bad"
      doAssert s.at(^1) != ""
      doAssert s.at(^2) == "f"
      doAssert s.at(^3) == "a"
      doAssert s.at(^4) == "C"
    block:
      const s = "".Unicode
      doAssertRaises(IndexError):
        discard s.at(^1)
    block:
      var s = "Caf\u0065\u0301".Unicode
      s.string.setLen(s.string.len - s.at(^1).len)
      doAssert s == "Caf"
  test "Test `toOpenArray` Character":
    block:
      var s = "abc".Unicode
      doAssert initCharacter(s, 0 .. 0).toOpenArray == "a"
      doAssert initCharacter(s, 1 .. 2).toOpenArray == "bc"
    block:
      func isDiacriticE(s: openArray[char]): bool =
        s == "\u0065\u0301"
      const cafeB = "Caf\u0065\u0301".Unicode
      doAssert cafeB.at(^1).toOpenArray.isDiacriticE
  test "Test `toOpenArray` Unicode":
    doAssert "abc".Unicode.toOpenArray == "abc"
  test "Test reverse":
    var s = "🇦🇷🇺🇾🇨🇱".Unicode
    s.reverse
    doAssert s == "🇨🇱🇺🇾🇦🇷"
  test "Test reversed iterator":
    let s = "🇦🇷🇺🇾🇨🇱".Unicode
    const expected = ["🇨🇱", "🇺🇾", "🇦🇷"]
    var i = 0
    for c in s.reversed:
      doAssert c == expected[i]
      inc i
  test "Test reversed":
    doAssert "🇦🇷🇺🇾🇨🇱".Unicode.reversed == "🇨🇱🇺🇾🇦🇷"
    doAssert "Caf\u0065\u0301".Unicode.reversed == "\u0065\u0301faC"
    doAssert "Caf\u0065\u0301".Unicode.reversed == "\u00E9faC"
    doAssert "Caf\u0065\u0301".Unicode.reversed == "Caf\u00E9".Unicode.reversed
