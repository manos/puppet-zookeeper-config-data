require 'rubygems'
require 'zk'

module Puppet::Parser::Functions
    newfunction(:zkget, :type => :rvalue) do |args|
        path = args[0]
        min = args[1].to_i
        if args.length > 2
            type = args[2].to_s
        else
            type = 'data'
        end

        begin
            zk = ZK.new(lookupvar('zk_server')+':'+lookupvar('zk_port'))
        rescue Exception=>e
            # Fail catalog if zk is unavailable?
            raise Puppet::ParseError, "Timeout or error connecting to zookeeper server. Error was: #{e}"
            # Just return false if zk is unavailable?
            #return false
        end

        def fail(data)
          raise Puppet::ParseError, "Could not retreive at least [#{min}] servers from ZooKeeper at path [#{path}]. Returned data was: [#{servers}]."
        end

        begin
            # you can either implement cache (in case zk is unavailable),
            # or just fail catalog compilation so puppet can't make any changes.
            # Stopping the puppet run is good enough for me.

            if type == 'data'
                begin
                    data = zk.get(path).first
                rescue ZK::Exceptions::NoNode
                    #NoNode? return empty string
                    data = String.new
                end
            elsif type == 'children'
                begin
                    data= zk.children(path)
                rescue ZK::Exceptions::NoNode
                    #NoNode? return empty string
                    data = String.new
                end
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

