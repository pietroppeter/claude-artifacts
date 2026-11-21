// Tiny C ABI over simdutf, so Nim (C backend) can call it.
#include "simdutf.h"
extern "C" {
size_t nsu_max_len(const char *in, size_t n) { return simdutf::maximal_binary_length_from_base64(in, n); }
// returns decoded length, or (size_t)-1 on error
size_t nsu_decode(const char *in, size_t n, char *out) {
  auto r = simdutf::base64_to_binary(in, n, out);
  return r.error == simdutf::error_code::SUCCESS ? r.count : (size_t)-1;
}
const char *nsu_impl() { return simdutf::get_active_implementation()->name().data(); }
const char *nsu_version() { return SIMDUTF_VERSION; }
}
