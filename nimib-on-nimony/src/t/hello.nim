import ../nimiboth/nimiboth

nbInit("Hello nimiboth", "hello.html")
nbText """
# Hello nimiboth
Some **bold**, *italic*, `code` and a [link](https://nim-lang.org).

- one
- two, with a long line
  that continues
"""
nbCode:
  let x = 6 * 7
  echo "x = ", x
nbCode:
  echo "again: ", x + 1
nbFile("hello.nim")
nbSave()
