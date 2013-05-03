#
# This is probably a bad place to age out data (at puppet catalog compilation),
# but here it is.
#
# zkdel('/path', 86400) will delete the znode at path, if data hasn't changed in
# 86400 seconds.
#
require 'rubygems'
require 'zk'

module Puppet::Parser::Functions
    newfunction(:zkdel) do |args|
        path = args[0]
        mtime = args[1].to_s

        begin
            zk = ZK.new(lookupvar('zk_server')+':'+lookupvar('zk_port'))
        rescue Exception=>e
            # Fail catalog if zk is unavailable?
            raise Puppet::ParseError, "Timeout or error connecting to zookeeper server. Error was: #{e}"
            # Just return false if zk is unavailable?
            #return false
        end

        begin

            node = zk.stat(path)

            if stat.mtime.to_i < Time.now.to_i - mtime
                zk.delete(path, :ignore => [:no_node,:not_empty])
            end

        ensure
            zk.close!
        end

    end
end

