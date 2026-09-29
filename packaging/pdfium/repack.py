#!/usr/bin/python3
# Copyright (C) 2026 David Nichols
# SPDX-License-Identifier: MIT
"""Prepare pinned PDFium/GN source for an offline Debian package build."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import tarfile

HERE = Path(__file__).resolve().parent
SOURCE_NAME = 'qore-pdfium-148.0.7778+ds'


def run(*args, **kwargs):
    return subprocess.check_output(args, **kwargs)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--cache', type=Path, help='private source checkout cache; downloads missing revisions')
    source.add_argument('--sources', type=Path, help='existing read-only source checkout with dependency repositories')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        parser.error('output directory must be empty')
    spec = json.loads((HERE / 'upstream.json').read_text())
    sources = args.sources.resolve() if args.sources else args.cache.resolve() / 'pdfium'
    dest = output / SOURCE_NAME
    dest.mkdir()
    dependencies = {'': spec['upstream']['pdfium'], **spec['upstream']['dependencies']}
    for name, dependency in dependencies.items():
        relative = Path(name)
        if relative.is_absolute() or '..' in relative.parts:
            raise ValueError('invalid dependency path: ' + name)
        revision = dependency['revision']
        if not re.fullmatch('[0-9a-f]{40}', revision) or not dependency['url'].startswith('https://'):
            raise ValueError('dependency must have a full pinned revision and HTTPS URL')
        checkout = sources / relative
        if args.cache and not (checkout / '.git').exists():
            checkout.mkdir(parents=True, exist_ok=True)
            subprocess.run(['git', 'init', str(checkout)], check=True)
            subprocess.run(['git', '-C', str(checkout), 'remote', 'add', 'origin', dependency['url']], check=True)
            subprocess.run(['git', '-C', str(checkout), 'fetch', '--depth=1', 'origin', revision], check=True)
            subprocess.run(['git', '-C', str(checkout), 'checkout', '--detach', 'FETCH_HEAD'], check=True)
        actual = run('git', '-C', str(checkout), 'rev-parse', 'HEAD', text=True).strip()
        if actual != revision:
            raise ValueError('source revision differs: ' + name)
        data = run('git', '-C', str(checkout), 'archive', '--format=tar', revision)
        with tarfile.open(fileobj=io.BytesIO(data)) as archive:
            for member in archive:
                member.name = (name + '/' + member.name).lstrip('/')
                if any(member.name == excluded or member.name.startswith(excluded + '/')
                       for excluded in spec['excluded']):
                    continue
                archive.extract(member, dest, filter='data')
    shim = spec['shim']
    data = (HERE / 'upstream-tools/generate_shim_headers.py').read_bytes()
    if hashlib.sha256(data).hexdigest() != shim['sha256']:
        raise ValueError('shim header generator checksum differs')
    target = dest / 'tools/generate_shim_headers/generate_shim_headers.py'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    target.chmod(0o644)
    (dest / 'QORE-SOURCE-MANIFEST.json').write_text(json.dumps(spec, indent=2) + '\n')
    archive = output / 'qore-pdfium_148.0.7778+ds.orig.tar.xz'
    subprocess.run(['tar', '--sort=name', '--mtime=2026-09-29 00:00:00Z', '--owner=0', '--group=0',
                    '--numeric-owner', '-cJf', str(archive), SOURCE_NAME], cwd=output, check=True)
    shutil.copytree(HERE / 'debian', dest / 'debian')
    print(hashlib.sha256(archive.read_bytes()).hexdigest(), archive.name)
    print('Source tree:', dest)


if __name__ == '__main__':
    main()
