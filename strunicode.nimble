# Package

version = "0.8.0"
author = "Esteban Castro Borsani (@nitely)"
description = "Swift-like unicode string handling"
license = "MIT"
srcDir = "src"

# Dependencies

requires "nim >= 0.19.0"
requires "normalize >= 0.6.0"
requires "graphemes >= 0.7.0"

task test, "Test":
  exec "nim c -r src/strunicode.nim"
  # Test runnable examples
  exec "nim doc -o:./docs/ugh/ugh.html ./src/strunicode.nim"

task docs, "Docs":
  exec "nim doc --project -o:./docs/ ./src/strunicode.nim"
  exec "mv ./docs/strunicode.html ./docs/index.html"
