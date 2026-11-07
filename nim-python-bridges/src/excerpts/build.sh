$ uv build --wheel                                   # Linux x86-64, natively
$ NIMLANG_TARGET=aarch64-linux-gnu.2.17 uv build --wheel
$ NIMLANG_TARGET=aarch64-macos  uv build --wheel
$ NIMLANG_TARGET=x86_64-macos   uv build --wheel
$ NIMLANG_TARGET=x86_64-windows uv build --wheel
