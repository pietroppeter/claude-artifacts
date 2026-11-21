# lemire-base64 page sources

[Daniel Lemire's MIME base64 decoding ranking](https://lemire.me/blog/2026/11/20/decoding-base64-email-attachments/)
(20 Nov 2026) run again on a cloud VM, with Zig, and with Nim decoders added. A [nimib](https://github.com/pietroppeter/nimib)
page; tables by [tabelline](https://pietroppeter.github.io/tabelline/); files shown with nimib's `nbFile` from PR #269
(pinned in `deps.sh`).

- `index.nim`: the page, writes `../index.html`. Build: `sh deps.sh && nim r index.nim` (Nim 2.2, `libpcre3`, and
  [nimsimd](https://github.com/guzba/nimsimd) installed with nimble, for the decoders the page runs).
- `bench/`: Lemire's files, unchanged (commit in `UPSTREAM_COMMIT`), `run_cloud.sh` (one run on this machine's tools).
- `bench/nim/`: the Nim decoders (`b64scalar`, `b64avx2`, `b64avx512`, `simdutf` + `simdutf_wrap.cpp`), `bench.nim`, `test.nim`.
- `data/`: raw result lines, ours (`results_cloud_run*.txt`) and Lemire's (`results_big4_run*.txt`), and the test output.
- `lib/`: `data.nim` (reads the results), `blocks.nim` (notes, stats, bars), `style.nim` (every colour and rule).
- The review mode is tabelline's, from `shared/review/` at the root of the repository (`config.nims`).

To rerun the benchmark: in `bench/`, `python3 gen.py`; build as in Lemire's `run.sh` (Zig 0.17.1:
`pip install ziglang==0.17.1`, `python3 -m ziglang build-exe -O ReleaseFast -lc zig/main.zig -femit-bin=build/zigbench`);
compile simdutf and `nim/simdutf_wrap.cpp` with `g++ -O3 -c` into `nim/`; `nim c -d:danger nim/bench.nim`;
then `./run_cloud.sh > ../data/results_cloud_runN.txt` a few times and rebuild the page.
