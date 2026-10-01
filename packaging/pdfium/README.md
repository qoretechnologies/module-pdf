# PDFium dependency package

This directory maintains the separate `qore-pdfium` source package required by
the Debian/Ubuntu PDF module. All upstream revisions and source exclusions are
in `upstream.json`; the native library and GN build tool are built from source.
No network access is needed during `dpkg-buildpackage` or Launchpad builds.

Prepare a source tree and its original tarball (network access is needed only
when the source cache is empty):

```sh
python3 packaging/pdfium/repack.py --cache /path/to/pdfium-cache --output /path/to/output
cd /path/to/output/qore-pdfium-148.0.7778+ds
dpkg-buildpackage -S -us -uc
dpkg-buildpackage -b -us -uc
```

An existing verified upstream checkout with all dependency repositories can be
used with `--sources /path/to/pdfium` instead of `--cache`. The output directory
must be empty or absent. Its original archive is reproducible: file order,
ownership and timestamps are fixed; every source commit is verified.

See `debian/README.source` for feature scope, ABI naming, qualification limits
and security update responsibilities. Keep this recipe and the PPA source
package together when updating the dependency. The Qore module package and
this dependency have independent source and binary versions.

Debian 13 builds use ICU 76 and the Clang 21 toolchain from the official
`trixie-backports` archive. The recipe requires `libicu-dev (>= 76)`; Ubuntu
26.04 satisfies that constraint with its newer ICU. Prepare a separate source
version with a `~deb13` revision and `trixie` changelog distribution for Debian.
Build and test natively for each distribution and architecture.

The qualified Ubuntu 26.04 binaries require glibc 2.43, ICU 78 and `libjpeg8`.
They cannot be installed on stock Debian 13, which supplies glibc 2.41, ICU 76
and `libjpeg62-turbo`. Reuse the pinned source archive and recipe, then rebuild
against Debian's libraries. See `QUALIFICATION-DEBIAN13` for the checked
amd64/arm64 candidate and retained evidence.
