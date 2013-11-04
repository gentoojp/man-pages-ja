#! /usr/bin/env python3
#
# update.py - update Makefile and po4a configuration files
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

import collections
import hashlib
import io
import os
import re
import subprocess
import sys
import time


perl_re = re.compile(r'#!.*\bperl\b')
var_re = re.compile(r"""
    (?P<pn>\w+)
    _
    (?P<kind>NAME|VERSION|DATE|SOURCES|PODS|MANS)
    \s+
    :=
""", re.VERBOSE)

# templates for po4a
PO4A_CFG = """\
[po4a_langs] ja
[po4a_paths] $(podir)/$master.pot $lang:$(podir)/$master.$lang.po
"""
MAN_T = """\
[type: man] $(srcdir)/{0} $lang:$(builddir)/{0} \\
            add_$lang:?$(podir)/{0}.txt\
"""
POD_T = '[type: pod] $(srcdir)/{} $lang:$(builddir)/{}'

# templates for addenda
POD_TXT = time.strftime("""\
.\\"
.\\" Japanese Version Copyright (c) %Y FULL NAME <EMAIL@ADDRESS>
.\\"
""")
MAN_TXT = 'PO4A-HEADER: mode=before; position=^\.TH\n' + POD_TXT


def main(argv):
    try:
        mk = Makefile(path_for('..', 'Makefile'))
    except Exception as e:
        print('ERROR:', e, file=sys.stderr)
        return 1
    for pn in os.listdir(path_for('..', 'en')):
        pkg = mk.package(pn)
        for f in os.listdir(path_for('..', 'en', pn)):
            if f.endswith(('.diff', '.patch')):
                # ignore patches
                continue
            elif is_man(f):
                if os.path.exists(path_for('..', 'ja', pn, f)):
                    # not po4a-ized
                    continue
                pkg.mans.append(f)
            elif f.endswith('.pod'):
                pkg.pods.append(f)
            else:
                try:
                    with open(path_for('..', 'en', pn, f),
                              encoding='utf-8') as fp:
                        if perl_re.match(fp.readline()):
                            pkg.pl.append(f)
                except Exception as e:
                    print('ERROR:', e, file=sys.stderr)
        # sort files
        pkg.sort()
        # update po4a.cfg
        po4a = Po4a(path_for('..', 'po', pn, pn + '.cfg'))
        po4a.update(pkg)
    mk.update()
    return 0


class Makefile:

    def __init__(self, path):
        self.path = path

        self._all = -1
        self._phony = -1
        self._pos = -1
        self._lines = []
        self._pkgs = collections.defaultdict(Package)

        self._po = collections.defaultdict(list)

        self._sha1 = None
        self._data = io.StringIO()
        self._parse()

    def _parse(self):
        with open(self.path, encoding='utf-8') as fp:
            m = hashlib.new('sha1')
            beg = -1
            cont = pod = False
            for i, l in enumerate(fp):
                m.update(l.encode())
                l = l.rstrip()
                self._lines.append(l)
                # line continuation
                prev_cont, cont = cont, l.endswith('\\')
                if prev_cont:
                    continue
                # skip auto-generated po4a targets
                if (not l and
                    pod):
                    break

                if l.startswith('.PHONY:'):
                    # delete package variables
                    if beg == -1:
                        raise Exception('cannot parse Makefile')
                    self._pos = beg
                    del self._lines[beg:i - 2]
                    # mark .PHONY
                    self._phony = len(self._lines) - 1
                elif l.startswith('all:'):
                    # mark all
                    self._all = len(self._lines) - 1
                elif l.startswith('pod:'):
                    pod = True
                else:
                    mo = var_re.match(l)
                    if mo:
                        if beg == -1:
                            beg = i
                        pn = mo.group('pn').replace('_', '-')
                        kind = mo.group('kind')
                        v = l.split(':=')[-1].strip()
                        if kind == 'NAME':
                            self._pkgs[pn].name = v
                        elif kind == 'VERSION':
                            self._pkgs[pn].version = v
                        elif kind == 'DATE':
                            self._pkgs[pn].date = v
            for l in fp:
                m.update(l.encode())
            self._sha1 = m.hexdigest()

    def package(self, pn):
        return self._pkgs[pn]

    def update(self):
        # check difference
        sha1 = hashlib.new('sha1', self._generate().encode()).hexdigest()
        if sha1 != self._sha1:
            notify('update', self.path)
            save(self.path, self._generate())

        for pn in sorted(self._po):
            cmdline = 'make PN={} po'.format(pn)
            notify('run', cmdline)
            subprocess.call(cmdline.split())

    def _generate(self):
        if 0 < self._data.tell():
            return self._data.getvalue()

        names = sorted(self._pkgs)
        tgts = ' '.join(names)
        for i, l in enumerate(self._lines):
            if i == self._pos:
                # generate variables
                for j, pn in enumerate(names):
                    if 0 < j:
                        self._print()
                    self._gen_vars(pn)
            elif i == self._phony:
                # update .PHONY target
                l = l[:l.find(' pod ') + 5] + tgts
            elif i == self._all:
                # update all target
                l = l[:5] + tgts
            self._print(l)
        # generate po4a targets
        for pn in names:
            self._gen_po4a(pn)

        return self._data.getvalue()

    def _gen_vars(self, pn):
        pkg = self._pkgs[pn]
        v = pn.replace('-', '_')
        width = 7

        def var(kind, rhs):
            n = len(rhs)
            if n == 1:
                self._print('{}_{:{w}} := {}'.format(v, kind, rhs[0], w=width))
            elif 1 < n:
                s = '{}_{:{w}} := '.format(v, kind, w=width)
                indent = ' ' * len(s)
                for i, r in enumerate(rhs, 1):
                    self._print(('{}{}' if i == n else '{}{} \\').format(s, r))
                    s = indent

        var('NAME', [pkg.name])
        var('VERSION', [pkg.version])
        if pkg.date:
            var('DATE', [pkg.date])
        # sources
        srcs = []
        for f in pkg.files:
            srcs.append('{}/{}'.format(pn, f))
            po = '{}/{}.ja.po'.format(pn, f)
            if not os.path.exists(path_for('..', 'po', po)):
                self._po[pn].append(po)
            srcs.append(po)
            if not is_man(f):
                f = os.path.splitext(f)[0] + '.1'
            srcs.append('{}/{}.txt'.format(pn, f))
        srcs.append('{0}/{0}.cfg'.format(pn))
        var('SOURCES', srcs)
        # pods
        npods = len(pkg.pl) + len(pkg.pods)
        pods = ['$(builddir)/{}/{}.pod'.format(pn, f) for f in pkg.pl]
        if 1 < npods:
            pods.append('$(addprefix $(builddir)/,'
                        '$(filter %.pod,$({}_SOURCES)))'.format(v))
        var('PODS', pods)
        # mans
        sects = ' '.join('%' + ext
                         for ext in sorted(set(os.path.splitext(f)[1]
                                               for f in pkg.mans)))
        mans = []
        if sects:
            mans.append('$(addprefix $(builddir)/,'
                        '$(filter {},$({}_SOURCES)))'.format(sects, v))
        if 0 < npods:
            mans.append('$(patsubst %.pod,%.1,$({}_PODS))'.format(v))
        var('MANS', mans)

    def _gen_po4a(self, pn):
        pkg = self._pkgs[pn]
        v = pn.replace('-', '_')
        self._print()
        if (pkg.pl or
            pkg.pods):
            self._print('{}:'.format(pn))
            self._print('\t$(MAKE) PN=$@ pod')
            self._print('$({0}_MANS): $({0}_PODS)'.format(v))
            self._print('$({}_PODS): .{}.po4a-stamp'.format(v, pn))
        else:
            self._print('{}: $({}_MANS)'.format(pn, v))
            self._print('$({}_MANS): .{}.po4a-stamp'.format(v, pn))
        self._print('.{}.po4a-stamp: $({}_SOURCES)'.format(pn, v))
        self._print('\t$(call po4a,{})'.format(pn))
        self._print('\ttouch $@')

    def _print(self, *args, **kwargs):
        kwargs['file'] = self._data
        print(*args, **kwargs)


class Package:

    __slots__ = ('name', 'version', 'date', 'mans', 'pods', 'pl')

    def __init__(self):
        self.name = ''
        self.version = ''
        self.date = ''
        self.mans = []
        self.pods = []
        self.pl = []

    @property
    def files(self):
        return self.mans + self.pods + self.pl

    def sort(self):
        def man_key(path):
            root, ext = os.path.splitext(path)
            return ext, root

        self.mans.sort(key=man_key)
        if self.name.lower() == 'portage':
            portage, eclass = split_portage(self.mans)
            self.mans = portage + eclass
        self.pods.sort()
        self.pl.sort()


class Po4a:

    def __init__(self, path):
        self.path = path
        self.podir = os.path.dirname(path)

        self._sha1 = None
        self._data = io.StringIO()
        try:
            with open(path, encoding='utf-8') as fp:
                m = hashlib.new('sha1')
                for l in fp:
                    if l.startswith('[po4a_'):
                        self._data.write(l)
                    m.update(l.encode())
                self._sha1 = m.hexdigest()
        except (IOError, OSError):
            pass
        if self._data.tell() == 0:
            print(PO4A_CFG, file=self._data)
        else:
            print(file=self._data)

    def update(self, pkg):
        def create_addendum(name, data):
            path = os.path.join(self.podir, name)
            if not os.path.exists(path):
                notify('create', path)
                save(path, data)

        if not os.path.exists(self.podir):
            notify('create', self.podir)
            os.makedirs(self.podir)

        # type: man
        pos = self._data.tell()
        if self.podir.endswith('portage'):
            portage, eclass = split_portage(pkg.mans)
            for m in portage:
                create_addendum(m + '.txt', MAN_TXT)
                print(MAN_T.format(m), file=self._data)
            print(file=self._data)
            for m in eclass:
                create_addendum(m + '.txt', MAN_TXT)
                print(MAN_T.format(m), file=self._data)
        else:
            for m in pkg.mans:
                create_addendum(m + '.txt', MAN_TXT)
                print(MAN_T.format(m), file=self._data)
        # type: pod
        if (pkg.pl or
            pkg.pods):
            if pos < self._data.tell():
                print(file=self._data)

            pos = self._data.tell()
            for m in sorted(pkg.pl + pkg.pods):
                l = m if m.endswith('.pod') else m + '.pod'
                create_addendum(l[:-4] + '.1.txt', POD_TXT)
                print(POD_T.format(m, l), file=self._data)
        # check difference
        sha1 = hashlib.new('sha1', self._data.getvalue().encode()).hexdigest()
        if sha1 != self._sha1:
            notify('update', self.path)
            save(self.path, self._data.getvalue())


def path_for(*args):
    return os.path.normpath(os.path.join(os.path.dirname(__file__), *args))


def is_man(name):
    ext = os.path.splitext(name)[1][1:]
    return (ext.isdigit() and
            1 <= int(ext) <= 8)


def save(path, data):
    tmp = path + '.new'
    try:
        with open(tmp, 'w', encoding='utf-8') as fp:
            fp.write(data)
        os.rename(tmp, path)
    except Exception as e:
        print('ERROR:', e, file=sys.stderr)
        if os.path.exists(tmp):
            os.unlink(tmp)


def notify(action, path):
    print('{:>11}  {}'.format(action, path))


def split_portage(mans):
    eclass = []
    portage = []
    for f in mans:
        (eclass if '.eclass.' in f else portage).append(f)
    return portage, eclass


if __name__ == '__main__':
    sys.exit(main(sys.argv))
