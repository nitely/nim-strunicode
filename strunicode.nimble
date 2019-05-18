# Package

version = "0.6.1"
author = "Esteban Castro Borsani (@nitely)"
description = "Swift-like unicode string handling"
license = "MIT"
srcDir = "src"

# Dependencies

requires "nim >= 0.19.0"
requires "normalize >= 0.5.0"
requires "graphemes >= 0.4.0"

task test, "Test":
  exec "nim c -r src/strunicode"

task docs, "Docs":
  exec "nim doc2 -o:./docs/index.html ./src/strunicode.nim"
