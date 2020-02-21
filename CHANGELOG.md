0.7.1
==================

* Add `toOpenArray` for `Character` and `Unicode`
* Change all procs to funcs

0.7.0
==================

* Add `Unicode` type
* Add `==` for `Character`, `Unicode` and `string` mix
* Add `at` taking `BackwardsIndex`
* Remove compatibility with `string` type.
  Do `"foo".Unicode` instead where needed
* Remove `eq` function. Do
  `"foo".Unicode == "foo".Unicode` instead
* Remove `chars` iterator
* Rename `characterAt` to `atByte`
* Inline most functions

0.6.1
==================

* Remove restriction on static string

0.6.0
==================

* Update to unicode 12.1

0.5.0
==================

* Drop Nim 0.18 support
* Allow passing `let` var to all APIs

0.4.0
==================

* Drop Nim 0.17 support
* Add Nim 0.19 support
* Update dependencies
* Add `==` API to compare `Character` against a `string`

0.3.0
==================

* Update to unicode 11

0.2.0
==================

* Adds `characterAt` with `BackwardsIndex` and
  `lastCharacter`
* Updates dependencies

0.1.0
==================

* Initial release
