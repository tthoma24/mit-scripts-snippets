#!/usr/bin/env python

"""
Subscribes to zephyr via tzc and sends messages to notification drivers (growl or libnotify).
"""

import sexpr
import os
import subprocess
import fcntl
import select
import sys
from abstfilter import AbstractConsumer
import optparse

class Notifier(AbstractConsumer):
    def __init__(self, usegrowl, usenotify, useprint):
        self.usegrowl = usegrowl
        self.usenotify = usenotify
        if usenotify:
            import pynotify
            pynotify.init("Zephyr")
            self.pings = {}
            self.pynotify = pynotify
        self.useprint = useprint
        return
    def feed(self, s):
        if s is None or type(s) is type(''): return
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
                header = '%s (%s)' % (id, len(zmessage) > 0 and zmessage[0] or zsender)
                message = '%s' % (len(zmessage) > 1 and zmessage[1] or '')
            else:
                return
            if self.useprint:
                print (id, header)
                print message
            if self.usegrowl:
                growlnotify = ['growlnotify', '-a', 'MacZephyr', '-n', 'zephyr', '-d', id, '-t', header]
                g = subprocess.Popen(growlnotify, stdin=subprocess.PIPE)
                g.stdin.write(message)
                g.stdin.close()
            if self.usenotify:
                if id in self.pings:
                    self.pings[id].close()
                self.pings[id] = self.pynotify.Notification(header, message)
                self.pings[id].show()
    def close(self):
        return

def main(argv):
    parser = optparse.OptionParser(usage = '%prog [-s "username@machine"] (--growl | --notify | --print)',
            description = __doc__.strip())
    parser.add_option('-s', '--ssh',
            type = 'string',
            default = None,
            dest = 'ssh',
            help = 'optional remote host to run tzc')
    parser.add_option('-g', '--growl',
            action = 'store_true',
            default = False,
            dest = 'growl',
            help = 'use growlnotify for output')
    parser.add_option('-n', '--notify',
            action = 'store_true',
            default = False,
            dest = 'notify',
            help = 'use notify-send for output')
    parser.add_option('-p', '--print',
            action = 'store_true',
            default = False,
            dest = 'useprint',
            help = 'use stdout for output')
    opts, args = parser.parse_args()

    usegrowl = opts.growl
    usenotify = opts.notify
    useprint = opts.useprint
    if not usegrowl and not usenotify and not useprint:
        parser.print_help(sys.stderr)
        return 1
    ssh = opts.ssh

    if ssh is None:
        retval = subprocess.call(['which', 'tzc'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if retval:
            print 'tzc not in path.  Please add -s username@machine to specify remote host.'
            return 1

    if ssh is not None:
        command = "ssh -K %s 'tzc -si'" % ssh
    else:
        command = "tzc -si"
    p = os.popen(command)
    r = sexpr.SExprReader(Notifier(usegrowl, usenotify, useprint))

    flags = fcntl.fcntl(p, fcntl.F_GETFL)
    fcntl.fcntl(p, fcntl.F_SETFL, flags | os.O_NONBLOCK)

    try:
        while 1:
            [i,o,e] = select.select([p], [], [], 5)
            if i: s = p.read(1024)
            else: s = ''

            if s != '':
                r.feed(s)
    except KeyboardInterrupt:
        pass
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
