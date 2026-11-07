# before: cross-compiling for Windows, `/` and parentDir use "\" on a Linux path
qjsDir = currentSourcePath().parentDir / "vendor" / "quickjs"
#   Error: cannot find: \home\user\diagrammari\experiments\python\nim\vendor\quickjs\quickjs.c
# after: join with "/" by hand
here = currentSourcePath().replace('\\', '/').rsplit('/', 1)[0]
qjsDir = here & "/vendor/quickjs"
