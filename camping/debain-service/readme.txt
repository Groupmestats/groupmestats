To setup the camping server as a debian service:

1.  Copy camping-server to /etc/init.d/
2.  Edit camping-server.default.example for your environment
3.  Rename camping-server.default.example to camping-server, and move it to /etc/defaults

You can start the server with:
service camping-server start

You can stop the server with:
service camping-server stop
