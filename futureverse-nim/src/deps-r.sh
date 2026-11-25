#!/bin/sh
# Installs R's futureverse packages (from CRAN) into $FV_RLIB (default ./deps/Rlib), for the R
# blocks of the page, which run at build time. Needs R (Ubuntu: apt-get install r-base-core).
set -e
here=$(cd "$(dirname "$0")" && pwd)
lib=${FV_RLIB:-$here/deps/Rlib}
mkdir -p "$lib"
Rscript -e "options(repos = 'https://cloud.r-project.org'); install.packages(c('future', 'future.apply', 'futurize', 'progressr', 'progressify', 'parallelly'), lib = '$lib', Ncpus = 4, quiet = TRUE)"
