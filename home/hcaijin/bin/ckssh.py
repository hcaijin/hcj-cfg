#!/usr/bin/python
import socket,sys
sk = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sk.settimeout(1)
try:
    sk.connect((sys.argv[1],int(sys.argv[2])))
    print 'ok'
except Exception:
    print 'no'
sk.close()
