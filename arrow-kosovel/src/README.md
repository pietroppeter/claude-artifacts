# arrow-kosovel page sources

Apache Arrow explained with the poems of Srečko Kosovel, in a [nimib](https://github.com/pietroppeter/nimib) page.

- `index.nim`: the page, writes `../index.html`. Build: `sh deps.sh && nim r -d:release index.nim`
  (Nim 2.2, `libpcre3`, a C compiler, and python3 with `pyarrow polars duckdb` for the bridge section).
- `data/make_dataset.py`: Kosovel's texts from the Slovenian Wikisource dump
  (`slwikisource-latest-pages-articles.xml.bz2` from dumps.wikimedia.org; the dump of 2026-11-01 was used)
  into `kosovel.parquet`, `kosovel.arrows` (Arrow IPC stream) and `kosovel.json`. Only pages marked *javna last*.
- `lib/layout.nim`: the buffers of a string column in four encodings, pure Nim; used by the code blocks,
  by `cdata.nim`, and (compiled to JS) by the layout explorer, `lib/widgets.nim`.
- `lib/cdata.nim`: the Arrow C Data Interface in plain Nim (structs, builders, export with release, a reader).
- `lib/nanoarrow.nim`: nanoarrow 0.9 bundled (by `deps.sh`) and compiled into the page; reads IPC streams.
- `lib/corpus.nim`: loads the poems from `kosovel.arrows` through nanoarrow; splits words.
- `poc/libkosovel.nim` + `poc/bridge.py`: a shared library exporting Arrow record batches, loaded by Python
  into pyarrow, Polars and DuckDB (run at build time, output in the page).
- `lib/blocks.nim`, `lib/style.nim` (six themes after Slovenian illustrators, CSS only).
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).
