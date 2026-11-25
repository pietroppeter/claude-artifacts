## The tasks of the page: plain Nim procs, registered so that worker processes can run them too.
import std/[math, os]
import ../fv

proc slowSquare*(x: int): int =
  ## The paper's slow_fcn: 50 ms of "work", then x².
  sleep 50
  x * x

proc chatty*(x: int): float =
  ## Talks while it works: the output is relayed, in order, to the main thread.
  say "x = ", x
  sqrt(x.float)

proc noisy*(x: int): float =
  ## Uses random numbers: the mean of x draws from a normal distribution.
  for _ in 1 .. x: result += gauss()
  result /= x.float

proc fragile*(x: int): int =
  ## Fails on 3.
  if x == 3: raise newException(ValueError, "I don't like 3")
  x * 10

registerTask slowSquare
registerTask chatty
registerTask noisy
registerTask fragile
