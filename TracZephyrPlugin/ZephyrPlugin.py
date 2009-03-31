from trac.core import *
from trac.ticket import ITicketChangeListener
import subprocess
import textwrap

class ZephyrPlugin(Component):
    implements(ITicketChangeListener)
    
    def zwrite(self, id, message):
        zclass = self.config.get('ZephyrPlugin', 'class')
        if zclass == '':
            return
        p = subprocess.Popen(['zwrite', '-q', '-l', '-d',
                              '-c', zclass,
                              '-i', 'trac-#%s' % id],
                             stdin=subprocess.PIPE)
        p.stdin.write("\n".join(textwrap.wrap(message)).encode('utf-8', 'replace'))
        p.stdin.close()
        p.wait()
    
    def ticket_created(self, ticket):
        message = "%s filed a new ticket:\n%s\n\n%s" % (ticket['reporter'], ticket['summary'], ticket['description'][:255])
        self.zwrite(ticket.id, message)
    
    def ticket_changed(self, ticket, comment, author, old_values):
        if old_values.has_key('status'):
            if ticket['status'] == 'closed':
                message = "%s closed ticket as %s\n(%s)" % (author, ticket['resolution'], ticket['summary'])
            else:
                message = "%s set status to %s\n(%s)" % (author, ticket['status'], ticket['summary'])
        else:
            message = "%s updated this ticket\n(%s)" % (author, ticket['summary'])
        self.zwrite(ticket.id, message)
    
    def ticket_deleted(self, ticket):
        pass
