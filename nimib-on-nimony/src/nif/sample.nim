import std/syncio

proc square(x: int): int = x * x

var total = 0
for i in 1 .. 3:
  total += square(i)
echo "total: ", total
