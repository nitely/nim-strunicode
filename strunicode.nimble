# Package

version = "0.2.0"
author = "Esteban Castro Borsani (@nitely)"
description = "Swift-like unicode string handling"
license = "MIT"
srcDir = "src"

# Dependencies

requires "nim >= 0.18.0"
requires "normalize >= 0.2.2 & < 0.3"
requires "graphemes >= 0.3.0 & < 0.4"

task test, "Test":
  exec "nim c -r src/strunicode"

task docs, "Docs":
  exec "nim doc2 -o:./docs/index.html ./src/strunicode.nim"
