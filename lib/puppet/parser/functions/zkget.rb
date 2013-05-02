require 'thread'
require 'zk'
require 'timeout'

module Puppet::Parser::Functions
    newfunction(:zkget, :type => :rvalue) do |args|
        path = args[0]
        min = args[1].to_i
        if args.len > 2
            type = args[2].to_s
        else
            type = 'data'
        end

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
            # you can either implement cache (in case zk is unavailable),
            # or just fail catalog compilation so puppet can't make any changes.
            # Stopping the puppet run is good enough for me.

            if type == 'data'
                data = zk.get(path)
            elsif type == 'children'
                data= zk.children(path)
            else
                raise Puppet::ParseError, "Unknown type of get: #{type}"
            end

            if data.kind_of?(Array)
                # we got an array? now, make sure we got enough, or fail.
                if not data.count >= min
                    fail(data)
                end
                return data
            else
                # we got a string, return it has a 1-element array
                if min == 1 and not data.nil?
                    return [data]
                else
                    return false
                end
            end

        ensure
            zk.close!
        end
    end
end

