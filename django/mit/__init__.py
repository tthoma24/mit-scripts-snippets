from django.contrib.auth.middleware import RemoteUserMiddleware

def zephyr(msg, clas='remit', instance='log', rcpt='adehnert',):
    import os
    os.system("zwrite -d -c '%s' -i '%s' '%s' -m '%s'" % (clas, instance, rcpt, msg, ))

class ScriptsRemoteUserMiddleware(RemoteUserMiddleware):
    header = 'SSL_CLIENT_S_DN_Email'
    
    def clean_username(username):
        zephyr(username)
        if '@' in username:
            name, domain = username.split('@')
            assert domain.upper() == 'MIT.EDU'
            return name
        else:
            return name

zephyr('Defined ScriptsRUM')
