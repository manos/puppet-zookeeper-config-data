**Current status: development, testing. Not ready for use.**



---



Using puppet-zookeeper
----------------------

Functions available in puppet, provided by this module:
```puppet
zkget('/path', 1, 'data') # returns data at path, with min=1 values returned.
                          # optional 3rd arg is either 'data' or 'children', to
                          # fetch either the data at `path`, or an array of its children
zkput('/path', 'stuff')   # writes the string 'stuff' at path. Will create znodes
                          # in path if required (mkdir -p), and overwrites any data at path
```

To use these functions, you *must* have defined two variables in the current scope:
$zk_server
$zk_port

These functions store zk data as persistent, non-sequential, and overwrites any
existing data at the specified node.

An Example
----------

For example, say you want to store haproxy backend server configuration information
in zookeeper, and use it in the puppet module that sets up the server. (the data
is written by other classes, that use the haproxy module)

This is a great use case! Nodes should be able to register themselves, and the
haproxy class shouldn't know anything about the class (server list) that's called it.

In an haproxy::register class, you take the parameters you need. Say, ip and port.
```puppet
define haproxy::register($ip, $port) { $site_name = $name }
```

Remember, parser functions run on the puppet master (so it needs access to your
zookeeper server). But arguments to zkget and zkput are parsed in the catalog
compilations *for* a host, so $::hostname, $::fqdn, etc are valid to use.

Put that information in zookeeper:
```puppet
include zk_puppet
zkput("/puppet/services/haproxy/${site_name}/${::hostname}", $::hostname)
zkput("/puppet/services/haproxy/${site_name}/${::hostname}/ip", $::ipaddr)
zkput("/puppet/services/haproxy/${site_name}/${::hostname}/port", $port)
```

Now that the data is written to zookeeper, the haproxy class can use it to
construct its config. You'll want to call a define from ::register, with the site
name

in haproxy::backend, for example
```puppet
$servers = zkget("/puppet/services/haproxy/${site_name}", 0, 'children')
```

$servers is now an array, containing a list of servers. But you'll need to get
parameters stored as znode data in zk. Since there is no iteration in puppet,
and inline templates can only return strings, you'll need an intermediary define
to call.

So call haproxy::backend::server_line { $servers: site_name => $site_name }, and in it,
get the parameters you expect, and write the server line in your config (using concat)!
```puppet
include zk_puppet
$server    = $name
$ip   = zkget("/puppet/services/haproxy/${site_name}/${server}/ip", 1)
$port = zkget("/puppet/services/haproxy/${site_name}/${server}/port", 1)
```

The 2nd argument is min values. If the ip or port returned nothing from zookeeper, 
compilation would fail.
```puppet
concat::fragment { $service_name:
    target  => $conf,
    content => "    server ${name} ${ip}:${port} check inter $inter rise $rise fall $fall port $port maxconn $maxconn\n",
    order   => 7,
}
```
NB: if either ip or port were missing from zk, they would be set to false (we didn't
specify min or max args). So check before using.

