#!/usr/bin/python3
# Copyright (C) 2026 David Nichols
# SPDX-License-Identifier: MIT
import json, os, pathlib, re, shlex, shutil, subprocess, sys
root = pathlib.Path(__file__).resolve().parent.parent
os.chdir(root)
def run(*args, **kwargs):
    return subprocess.check_output(args, text=True, **kwargs).strip()
def jobs():
    options = os.environ.get('DEB_BUILD_OPTIONS', '').split()
    return next((x.split('=', 1)[1] for x in options if x.startswith('parallel=')), '1')
def configure():
    arch = run('dpkg-architecture', '-qDEB_HOST_ARCH')
    cpu = {'amd64': 'x64', 'arm64': 'arm64'}[arch]
    flags = {}
    for kind in ('CPPFLAGS', 'CFLAGS', 'CXXFLAGS', 'LDFLAGS'):
        flags[kind.lower()] = shlex.split(run('dpkg-buildflags', '--get', kind))
    # Chromium defines level 2; Debian controls fortification (including noopt).
    flags['cppflags'].insert(0, '-U_FORTIFY_SOURCE')
    pathlib.Path('debian/buildflags.gni').write_text(''.join(
        'debian_' + k + ' = ' + json.dumps(v) + '\n' for k, v in flags.items()))
    pathlib.Path('build/config/gclient_args.gni').write_text(
        'build_with_chromium = false\ncheckout_android = false\ncheckout_skia = false\n')
    # A second configure must not overwrite the original GN files with shims.
    for lib in ('icu', 'brotli'):
        dest = pathlib.Path('third_party') / lib / 'BUILD.gn'
        backup = dest.with_suffix('.gn.orig')
        if not backup.exists():
            shutil.copy2(dest, backup)
        shutil.copy2(pathlib.Path('build/linux/unbundle') / (lib + '.gn'), dest)
    subprocess.run(['python3', 'build/gen.py', '--no-last-commit-position'], cwd='gn-src', check=True)
    pathlib.Path('gn-src/out/last_commit_position.h').write_text(
        '#define LAST_COMMIT_POSITION_NUM 2342\n'
        '#define LAST_COMMIT_POSITION "2342 (129ce6b9af1a)"\n')
    subprocess.run(['ninja', '-C', 'gn-src/out', '-j' + jobs(), 'gn'], check=True)
    args = GN_ARGS.replace('target_cpu="x64"', 'target_cpu="' + cpu + '"')
    subprocess.run(['gn-src/out/gn', 'gen', 'out/Release', '--args=' + args], check=True)
def install():
    ma = run('dpkg-architecture', '-qDEB_HOST_MULTIARCH')
    runtime = pathlib.Path('debian/libpdfium-qore148-0')
    dev = pathlib.Path('debian/libpdfium-qore-dev')
    libdir = runtime / 'usr/lib' / ma
    libdir.mkdir(parents=True, exist_ok=True)
    shutil.copy2('out/Release/libpdfium-qore148.so.0', libdir)
    inc = dev / 'usr/include/pdfium-qore'
    inc.mkdir(parents=True, exist_ok=True)
    for header in sorted(pathlib.Path('public').glob('*.h')):
        shutil.copy2(header, inc)
    devlib = dev / 'usr/lib' / ma
    (devlib / 'pkgconfig').mkdir(parents=True, exist_ok=True)
    link = devlib / 'libpdfium-qore148.so'
    if not link.is_symlink():
        link.symlink_to('libpdfium-qore148.so.0')
    (devlib / 'pkgconfig/pdfium-qore.pc').write_text(
        'prefix=/usr\nlibdir=${prefix}/lib/' + ma + '\nincludedir=${prefix}/include/pdfium-qore\n\n'
        'Name: PDFium for Qore\nDescription: PDFium milestone 148 C API\nVersion: 148.0.7778\n'
        'Libs: -L${libdir} -lpdfium-qore148\nCflags: -I${includedir} -DFPDF_SHARED\n')
def clean():
    for directory in ('out', 'gn-src/out'):
        shutil.rmtree(directory, ignore_errors=True)
    for name in ('debian/buildflags.gni', 'build/config/gclient_args.gni'):
        pathlib.Path(name).unlink(missing_ok=True)
    for lib in ('icu', 'brotli'):
        dest = pathlib.Path('third_party') / lib / 'BUILD.gn'
        backup = dest.with_suffix('.gn.orig')
        if backup.exists():
            backup.replace(dest)
GN_ARGS = 'is_debug=false is_component_build=false pdf_is_standalone=true pdf_enable_v8=false pdf_enable_xfa=false pdf_use_skia=false use_sysroot=false clang_use_chrome_plugins=false treat_warnings_as_errors=false target_os="linux" target_cpu="x64" use_custom_libcxx=false is_clang=true clang_base_path="/usr/lib/llvm-21" clang_version="21" use_siso=false use_remoteexec=false pdf_bundle_freetype=false use_system_freetype=true use_system_lcms2=true use_system_libopenjpeg2=true use_system_libpng=true use_system_libtiff=true use_system_zlib=true use_system_libjpeg=true symbol_level=2 use_debug_fission=false forbid_non_component_debug_builds=false use_thin_lto=false use_allocator_shim=false use_partition_alloc_as_malloc=false enable_rust=false'
if __name__ == '__main__':
    {'configure': configure, 'install': install, 'clean': clean,
     'jobs': lambda: print(jobs())}[sys.argv[1]]()
