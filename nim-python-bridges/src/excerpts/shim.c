/* mari_qjs.c: QuickJS's JSValue stays on the C side */
void *mari_js_new(const char *code, size_t len, char **err);   /* runtime + context, script evaluated */
char *mari_js_call(void *h, const char *fn, const char *arg, size_t len, int *ok);
void  mari_js_free_str(char *s);
void  mari_js_close(void *h);
