#!/usr/bin/env python

import sexpr
import os
import fcntl
import select
import sys
from abstfilter import AbstractConsumer

class Growler(AbstractConsumer):
    def __init__(self):
        return
    def feed(self, s):
        if s is None or type(s) is type(''): return
        print repr(s)
        d = dict([(ss[0], len(ss) > 2 and ss[2] or None) for ss in s])
        if d['tzcspew'] == 'message':
            zclass = d['class'].lower()
            zinstance = d['instance'].lower()
            zop = d['opcode'].lower()
            zsender = d['sender'].lower()
            zauth = d['auth'].lower() == 'yes'
            ztime = ':'.join(d['time'].split(' ')[3].split(':')[0:2])
            zmessage = d['message']
            id = '%s/\n%s/\n%s\n %s' % (zclass, zinstance, zsender, ztime)
            if zop == 'ping':
                header = '%s (%s)' % (id, zsender)
                message = '...'
            elif zop == 'nil':
                header = '%s (%s)' % (id, zmessage[0])
                message = '%s' % zmessage[1]
            else:
                return
            g = os.popen("growlnotify -a MacZephyr -n zephyr -d '%s' -t '%s'" % (id, header), 'w')
            g.write(message)
            g.close()
    def close(self):
        return

def main(argv):
    if len(argv) < 2:
        print """barn-growl v.0.0.1

Usage:
barn-growl USERNAME"""
        return 0

    username = argv[1]
    principal = username
    if principal.find("@") == -1:
        principal += '@ATHENA.MIT.EDU'
    bash = "/bin/bash -lc \"kdo %s ssh %s@linerva.mit.edu 'tzc -si'\" 2>/dev/null </dev/null" % (principal, username)
    p = os.popen(bash)
    r = sexpr.SExprReader(Growler())

    flags = fcntl.fcntl(p, fcntl.F_GETFL)
    fcntl.fcntl(p, fcntl.F_SETFL, flags | os.O_NONBLOCK)

    while 1:
        [i,o,e] = select.select([p], [], [], 5)
        if i: s = p.read(1024)
        else: s = ''

        if s != '':
            r.feed(s)
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
