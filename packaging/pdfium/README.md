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
