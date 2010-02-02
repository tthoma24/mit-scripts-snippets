from django.contrib.auth.middleware import RemoteUserMiddleware
from django.contrib.auth.backends import RemoteUserBackend
from django.contrib import auth

def zephyr(msg, clas='remit', instance='log', rcpt='adehnert',):
    import os
    os.system("zwrite -d -c '%s' -i '%s' '%s' -m '%s'" % (clas, instance, rcpt, msg, ))

class ScriptsRemoteUserMiddleware(RemoteUserMiddleware):
    header = 'SSL_CLIENT_S_DN_Email'

class ScriptsRemoteUserBackend(RemoteUserBackend):
    def clean_username(self, username, ):
        if '@' in username:
            name, domain = username.split('@')
            assert domain.upper() == 'MIT.EDU'
            return name
        else:
            return username
