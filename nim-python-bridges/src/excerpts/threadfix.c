/* mari_qjs.c */
char *mari_js_call(void *h, const char *fn, const char *arg, size_t len, int *ok) {
  MariJs *m = h; JSContext *ctx = m->ctx;
  /* QuickJS measures the stack from where the runtime was made: a call from another
     thread (a Python thread pool) would look like a stack overflow without this. */
  JS_UpdateStackTop(m->rt);
  ...
