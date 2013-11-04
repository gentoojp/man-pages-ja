#! /usr/bin/env python3
#
# check.py - check latest stable versions
#
#   Copyright (c) 2013 Akinori Hattori <hattya@gmail.com>
#
#   Permission is hereby granted, free of charge, to any person
#   obtaining a copy of this software and associated documentation files
#   (the "Software"), to deal in the Software without restriction,
#   including without limitation the rights to use, copy, modify, merge,
#   publish, distribute, sublicense, and/or sell copies of the Software,
#   and to permit persons to whom the Software is furnished to do so,
#   subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be
#   included in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
#   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
#   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.
#

import os
import re
import sys
import urllib.request
import xml.etree.ElementTree


PACKAGES_URI = 'https://packages.gentoo.org/package/{C}/{PN}'

ns = {'html': 'http://www.w3.org/1999/xhtml'}
ver_re = re.compile(r'^(?P<pn>\w+)_VERSION\s+:=\s+(?P<pvr>[^\s]+)\s+$')


def main(argv):
    pkgs = dict(parse_makefile())
    for i, pn in enumerate(os.listdir(path_for('..', 'en'))):
        if 0 < i:
            print()
        c = 'sys-apps' if pn == 'portage' else 'app-portage'
        print('*', c + '/' + pn)
        curr = pkgs.get(pn)
        print('  current:', curr)
        pvr = packages(c, pn)
        if not pvr:
            print('no stable versions')
        elif curr == pvr:
            print('already up-to-date')
        else:
            print('   stable:', pvr)


def parse_makefile():
    with open(path_for('..', 'Makefile')) as fp:
        for l in fp:
            m = ver_re.match(l)
            if m:
                yield m.group('pn').replace('_', '-'), m.group('pvr')


def packages(c, pn):
    with urllib.request.urlopen(PACKAGES_URI.format(C=c, PN=pn)) as resp:
        if resp.getcode() != 200:
            return
        root = xml.etree.ElementTree.fromstring(resp.read())
    for tr in root.iterfind('.//html:table[@class="main"]/html:tr', ns):
        if tr.get('class') is None:
            arches = tr.findall('./html:td', ns)
            for td in arches[1:]:
                if 'stable' in td.get('class').split():
                    return arches[0].text.strip()


def path_for(*args):
    return os.path.normpath(os.path.join(os.path.dirname(__file__), *args))


if __name__ == '__main__':
    sys.exit(main(sys.argv))
