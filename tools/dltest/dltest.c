/*
 * dltest — minimal dlopen probe.
 *
 * Loads a shared object and reports the failure reason (or success) so you
 * can tell if a mod / plugin would be loadable by the game under the same
 * LD_LIBRARY_PATH the launcher script provides.
 *
 * Usage:
 *   dltest <path-to-.so> [symbol-to-resolve ...]
 *
 * Exit codes:
 *   0  dlopen succeeded (and every requested symbol resolved)
 *   1  dlopen failed
 *   2  dlopen ok but a requested symbol was missing
 *   3  bad arguments
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <link.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void dump_loaded_path(void *h)
{
    struct link_map *lm = NULL;
    if (dlinfo(h, RTLD_DI_LINKMAP, &lm) == 0 && lm && lm->l_name && lm->l_name[0]) {
        fprintf(stderr, "loaded: %s\n", lm->l_name);
    }
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "usage: %s <path-to-.so> [symbol ...]\n", argv[0]);
        return 3;
    }

    const char *so = argv[1];
    fprintf(stderr, "dlopen(\"%s\", RTLD_NOW)\n", so);

    void *h = dlopen(so, RTLD_NOW);
    if (!h) {
        fprintf(stderr, "FAIL: %s\n", dlerror());
        fprintf(stderr, "hint: run `ldd %s` and `LD_DEBUG=libs %s ...` to see which dep is missing.\n", so, argv[0]);
        return 1;
    }
    fprintf(stderr, "OK: dlopen succeeded\n");
    dump_loaded_path(h);

    int rc = 0;
    for (int i = 2; i < argc; ++i) {
        (void)dlerror();
        void *sym = dlsym(h, argv[i]);
        const char *err = dlerror();
        if (err || !sym) {
            fprintf(stderr, "symbol MISSING: %s%s%s\n", argv[i], err ? " — " : "", err ? err : "");
            rc = 2;
        } else {
            fprintf(stderr, "symbol ok: %s @ %p\n", argv[i], sym);
        }
    }

    dlclose(h);
    return rc;
}
