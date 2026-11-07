/* mari_qjs.c: inside the lock, tell QuickJS which stack this thread is on */
char *mari_js_call(void *h, const char *fn, const char *arg, size_t len, int *ok) {
  MariJs *m = h; JSContext *ctx = m->ctx;
  JS_UpdateStackTop(m->rt);
  ...
