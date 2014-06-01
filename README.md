[SYSCONF](https://github.com/geonef/sysconf.base) profile "nef.cloud"
======================================================================

Sysconf is a tool that help sysadmins package and share system configurations
around simple "sysconf profiles" that depend on each other. Here is one of them.

This "nef.cloud" profile essentially provides **/usr/bin/nef-cloud**, a tool
that helps managing services (like HTTP, PHP, mailer or DB servers) which
are distributed around UNIX nodes.


You said cloud? Is it yet another complicated cloud manager?
------------------------------------------------------------
No!

As [SYSCONF](https://github.com/geonef/sysconf.base) is a simple yet powerful
way to organise and sync sysadmin work, it covers quite some needs already.

**nef-cloud** leverages SYSCONF by providing deployment logic through
static shell files in _/etc/nef.cloud_.


Example
-------
There is a complete an example with 2 services (HTTP CDN and Postfix mailer) in tree/usr/share/doc/examples/mycloud-3nodes-2service.

To make it shorter, suppose you need to setup a system named "mycloud" with 2 services:
* an HTTP CDN service to serve static files ; file can be added internally to the CDN
* a Postfix mail system with DKIM email signature done right, listening on SMTP port 25

The service should be replicated on 3 physical Debian nodes that we call "n1",
"n2", "n3" that communicate with each other through unsecure Internet.

Content of /etc/nef.cloud/mycloud/config:
```
NEF_CLOUD_NUMBER=1
NEF_CLOUD_NODES=(n1 n2 n3)
NEF_CLOUD_SYSCONF=mycloud-3nodes-2service
NEF_CLOUD_NODE_SERVICES=(host mx cdn)

# service-specific options
NEF_SERVICE_MX_DOMAIN=mydomain.net
NEF_SERVICE_CDN_DOMAIN=cdn.mydomain.net

# node-specific options
NEF_CLOUD_NODE_LVM_GROUP=lvmvg
NEF_CLOUD_NODE_PUBLIC_INTERFACE=eth0

NEF_CLOUD_NODE_INTERFACES=(CDN1)
NEF_CLOUD_NODE_INTERFACES_CDN1_INTERFACE=eth0:8
NEF_CLOUD_NODE_INTERFACES_CDN1_IP=199.21.178.42

NEF_CLOUD_NODE_TCP_FORWARDS=(CDNHTTP MXSMTP)

NEF_CLOUD_NODE_TCP_FORWARDS_CDNHTTP_DEST_IP=199.21.178.42 # INTERFACES_CDN1
NEF_CLOUD_NODE_TCP_FORWARDS_CDNHTTP_SOURCE_PORT=80
NEF_CLOUD_NODE_TCP_FORWARDS_CDNHTTP_TARGET_SERVICE=cdn
NEF_CLOUD_NODE_TCP_FORWARDS_CDNHTTP_TARGET_PORT=80

NEF_CLOUD_NODE_TCP_FORWARDS_MXSMTP_DEST_IP=199.21.178.42 # INTERFACES_CDN1
NEF_CLOUD_NODE_TCP_FORWARDS_MXSMTP_SOURCE_PORT=25
NEF_CLOUD_NODE_TCP_FORWARDS_MXSMTP_TARGET_SERVICE=mx
NEF_CLOUD_NODE_TCP_FORWARDS_MXSMTP_TARGET_PORT=25
```

Content of /etc/nef.cloud/mycloud/nodes/n1:
```
NEF_CLOUD_NODE_NUMBER=1
NEF_CLOUD_NODE_PUBLIC_IP=1.2.3.4
```

Content of /etc/nef.cloud/mycloud/nodes/n2:
```
NEF_CLOUD_NODE_NUMBER=2
NEF_CLOUD_NODE_PUBLIC_IP=1.2.3.5
```

Content of /etc/nef.cloud/mycloud/nodes/n3:
```
NEF_CLOUD_NODE_NUMBER=3
NEF_CLOUD_NODE_PUBLIC_IP=1.2.3.6
```

And tell the host that it is indeed the host for multiple services' LXC containers, by settings into /etc/nef.local/services (repeat the same on n2 and n3):
```
mycloud n1 host
```

That's all! Now, just run:
```
nef-cloud update services
```

The "host" service will setup the network this way:
* a virtual interface eth0:8 for IP 199.21.178.42
* a bridge "nc1x-1" up with IP 10.70.2.1/23
* GRE tunnels "nc1t-2" 10.69.2.8/30 (to n2) and "nc1t-3" 10.69.2.12/30 (to n3) with routing setup

As well as create or update 2 LXC containers:
* CDN service, with IP 10.70.2.11 (cdn is number 11 in /etc/nef.service/cdn)
* MX service, with IP 10.70.2.15 (mx is number 15 in /etc/nef.service/mx)


Project status
--------------
The whole thing is thought in such a way that configs and code be reused
as much as possible.

nef-cloud does few things instead of many, to keep it simple. Services in
/etc/nef.service let each domain be responsible for its own clustering, 
such as MongoDB's, CouchBase's, Elastic Search and so many others, that
should be configured by specific /etc/nef.service/name-of-service and
associated [SYSCONF](https://github.com/geonef/sysconf.base) profile.

First design and implementation by Jean-Francois Gigand, GEONF <jf@geonef.fr>,
in early 2014 and released as free software on GitHub a few months later.

If you're interested in using nef-cloud, feel free to contact me. Explain the
case and I'll tell you how nef-cloud can help you (or not !).
