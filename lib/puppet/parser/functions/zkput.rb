require 'rubygems'
require 'zk'
require 'timeout'

module Puppet::Parser::Functions
    newfunction(:zkput, :type => :rvalue) do |args|
        path = args[0]
        data = args[1].to_s

        begin
            max_wait = lookupvar('zk_timeout').exists || 30
            Timeout.timeout max_wait do
                zk = ZK.new(lookupvar('zkserver')+':'+lookupvar('port'))
            end
        rescue Exception=>e
            # Fail catalog if zk is unavailable?
            raise Puppet::ParseError, "Timeout or error connecting to zookeeper
                server. Error was: #{e}"
            # Just return false if zk is unavailable?
            #return false
        end

        def fail(data)
          raise Puppet::ParseError, "Could not retreive at least [#{min}] servers
                from ZooKeeper at path [#{path}]. Returned data was: [#{servers}]."
        end

        begin
            # write the data at the path. The option :set will overwrite what's
            # there, and create all children nodes as necessary.
            zk.create(path, data, :or => :set)

        ensure
            zk.close!
        end


    end
end

