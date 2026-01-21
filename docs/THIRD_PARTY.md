# Third-Party Sources

## PoDoFo

- Source: https://github.com/podofo/podofo
- Version: 1.0.3
- License: LGPL-2.0-or-later (see `third_party/podofo/COPYING`)
- Local patch: free the cffread context (`cfrFree`) in
  `src/podofo/private/FontUtils_AFDKO.cpp` to fix a CFF font-embedding leak.
- Status: bundled temporarily until the upstream fix is merged and released.

When updating PoDoFo, re-apply the patch if it is not yet upstream and re-run
the module's tests with `qore -penable-debug` and valgrind (`qore -b`).
