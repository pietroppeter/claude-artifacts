"""Nim -> pyarrow -> Polars -> DuckDB, and back, through the Arrow C Data Interface.
Not one byte of the columns is copied on the way: only two small structs change hands."""
import ctypes, sys
import pyarrow as pa, polars as pl, duckdb

lib = ctypes.CDLL(sys.argv[1])
if len(sys.argv) > 2:
    lib.kosovel_set_words(open(sys.argv[2], encoding="utf-8").read().strip().encode())

# room for one ArrowSchema (72 bytes) and one ArrowArray (80 bytes), owned by Python
schema, array = ctypes.create_string_buffer(72), ctypes.create_string_buffer(80)
lib.kosovel_export_batch(schema, array)
batch = pa.RecordBatch._import_from_c(ctypes.addressof(array), ctypes.addressof(schema))
batch.validate(full=True)
print(batch.schema)
print()
try:
    pl.from_arrow(batch)
except Exception as e:                       # not every consumer speaks every type
    print("Polars:", str(e).splitlines()[0])
    print("DuckDB:", end=" ")
    try:
        duckdb.sql("select word_runs from batch").fetchall(); print("ok with run-end")
    except Exception as e2:
        print(str(e2).splitlines()[0])
print()
df = pl.from_arrow(batch.drop_columns(["word_runs"]))
print(df.head(6))
print()
print(duckdb.sql("""select word_dict as word, count(*) as n, any_value(letters) as letters
                    from batch group by all order by n desc, word limit 8"""))

# and back: pyarrow makes a column, Nim reads it where it lies
col = pa.array(["Srečko", "Kosovel", "Tomaj", "Sežana", "Trst", "žalost", None])
s2, a2 = ctypes.create_string_buffer(72), ctypes.create_string_buffer(80)
col._export_to_c(ctypes.addressof(a2), ctypes.addressof(s2))
lib.kosovel_count_diacritics.restype = ctypes.c_int64
print("č/š/ž counted by Nim in a pyarrow column:", lib.kosovel_count_diacritics(s2, a2))
