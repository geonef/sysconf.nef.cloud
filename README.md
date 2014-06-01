[SYSCONF](https://github.com/geonef/sysconf.base) profile "nef.cloud"
======================================================================

Sysconf is a tool that help sysadmins package and share system configurations
around simple "sysconf profiles" that depend on each other. Here is one of them.

This "nef.cloud" profile essentially provides **/usr/bin/nef-cloud**, a tool
that helps managing services (like HTTP, PHP, mailer or DB servers) which
are distributed around UNIX nodes.


Yet another complicated cloud manager?
------------------------------------------------------------
**No!**

As [SYSCONF](https://github.com/geonef/sysconf.base) is a simple yet powerful
way to organise and sync sysadmin work, it covers quite some needs already.
It makes easy to reproduce services, but multiple-system management (LXC or VM)
and networking is still hard to manage.

**[nef-cloud](./tree/usr/bin/nef-cloud)** leverages SYSCONF by providing deployment logic through
static shell files in _/etc/nef.cloud_.

Compared to the Proxmox kind, nef-cloud does not integrate anything except
by setting a few simple shell definitions in /etc/nef.cloud that may be
cloud-related, node-related and service-related and organized pretty much
like the INI files philosophy.

The nef-cloud script would use a few of these definitions and call
service scripts lying into /etc/nef.service with the right definitions
depending on the node we're in, the cloud we're about and the service
that's being called.

**Think of it like the /etc/init.d/ scripts.**

**nef-cloud is an attempt to build most simple, low-level tool that guide and ease UNIX service replication across multiple nodes.**

Even single-node systems can benefit from the structuration it provides,
as well as the garantee to be able to replicate them easily whenever scaling is needed.


Example
-------
[Check out the complete example](./tree/usr/share/doc/nef.cloud/examples/mycloud-3nodes-2service)
with 2 services (HTTP CDN and Postfix mailer).

To make it shorter, suppose you need to setup a system named "mycloud" with 2 services:
* an HTTP CDN service to serve static files ; file can be added internally to the CDN
* a Postfix mail system with DKIM email signature done right, listening on SMTP port 25

The service should be replicated on 3 physical Debian nodes that we name _n1_,
_n2_, _n3_ that communicate with each other through unsecure Internet.

### What we need to write on node _n1_

#### /etc/nef.cloud/mycloud/config
```
NEF_CLOUD_NUMBER=1
NEF_CLOUD_NODES=(n1 n2 n3)
NEF_CLOUD_SYSCONF=mycloud
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

#### /etc/nef.cloud/mycloud/nodes/n1
```
NEF_CLOUD_NODE_NUMBER=1
NEF_CLOUD_NODE_PUBLIC_IP=1.2.3.4
```

#### /etc/nef.cloud/mycloud/nodes/n2
```
NEF_CLOUD_NODE_NUMBER=2
NEF_CLOUD_NODE_PUBLIC_IP=1.2.3.5
```

#### /etc/nef.cloud/mycloud/nodes/n3
```
NEF_CLOUD_NODE_NUMBER=3
NEF_CLOUD_NODE_PUBLIC_IP=1.2.3.6
```

#### /etc/nef.local/services
Needed to tell the host that it is indeed the node _n1_'s host that manage multiple services' LXC containers:
```
mycloud n1 host
```

### Now run the cloud
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

For IP addressing logic, see [NETWORKING.md](./NETWORKING.md).

### Start other nodes: n2 and n3
What we just wrote, except /etc/nef.local/services, needs to be shared across nodes.

Gather the files into a new, Git-versionned, sysconf profile:
```
# cd /sysconf && mkdir sysconf.my.mycloud
# echo my.mycloud >>deps # (so that "sysconf compile install update" integrate "my.mycloud")
# sysconf -c my.mycloud add /etc/nef.cloud/mycloud/config
# sysconf -c my.mycloud add /etc/nef.cloud/mycloud/nodes/n1
# sysconf -c my.mycloud add /etc/nef.cloud/mycloud/nodes/n2
# sysconf -c my.mycloud add /etc/nef.cloud/mycloud/nodes/n3
# cd my.mycloud
# git init .
# git add -A
# git commit -m "my new cloud"
# # create the remote repository on GitHub or elsewhere, then:
# git remote add origin ...
# git push -u origin master
```

Now, install [sysconf.base](https://github.com/geonef/sysconf.base) (if not already)
and your new _sysconf.my.mycloud_ profile on nodes n2 and n3, then run on both:
```
# nef-cloud update services
```

The 2 services CDN and MX should again, be created as LXC containers
and fully configured, networking included.

Check out /etc/hosts, you will see a list of all services on every nodes.
That would be :
```
# GENERATED BY SYSCONF

# /etc/hosts.d/generated.host.n1.mycloud.nef.hosts
# /etc/hosts-like content for cloud 'mycloud'

# NODE 'n1'
10.70.2.1 n1.mycloud.nef
10.70.2.11 cdn.n1.mycloud.nef
10.70.2.15 mx.n1.mycloud.nef

# NODE 'n2'
10.70.4.1 n2.mycloud.nef
10.70.4.11 cdn.n2.mycloud.nef
10.70.4.15 mx.n2.mycloud.nef

# NODE 'n3'
10.70.6.1 n3.mycloud.nef
10.70.6.11 cdn.n3.mycloud.nef
10.70.6.15 mx.n3.mycloud.nef
```

Ping any host, it should work whether from the local node bridge or across nodes through the GRE tunnel!


Project status
--------------
The whole thing is thought in such a way that configs and code be reused
as much as possible.

nef-cloud does few things instead of many, to keep it simple. Services in
/etc/nef.service let each domain be responsible for its own clustering, 
such as MongoDB's, CouchBase's, Elastic Search and so many others, that
should be configured by specific /etc/nef.service/name-of-service and
associated [SYSCONF](https://github.com/geonef/sysconf.base) profile.

First design and implementation by Jean-Francois Gigand, GEONEF <jf@geonef.fr>,
in early 2014 and released as free software on GitHub a few months later.

If you're interested in using nef-cloud, feel free to contact me. Explain the
case and I'll tell you how nef-cloud can help you (or not !).
