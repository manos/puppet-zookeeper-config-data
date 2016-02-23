#
# This is probably a bad place to age out data (at puppet catalog compilation),
# but here it is.
#
require 'rubygems'
require 'zk'

module Puppet::Parser::Functions
    newfunction(:zkdel) do |args|
        path = args[0]
        mtime = args[1].to_i
        if args.length > 2
            parent_path = args[2]
            min_nodes = args[3].to_i
        else
            parent_path = nil
        end

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

            if ! parent_path.nil?
                parent_node = zk.stat(path)
                if not parent_node.numChildren - 1 < min_nodes
                    return false
                end
            end

            if node.mtime.to_i < (Time.now.to_i * 1000) - mtime
                begin
                    zk.delete(path, :ignore => :no_node)
                rescue ZK::Exceptions::NotEmpty
                    # it has children. What to do? Should probably traverse the tree,
                    # and recursively delete all nodes. For now, delete all kids and try again.
                    kids = zk.children(path)
                    for kid in kids
                        zk.delete(path+'/'+kid, :ignore => [:no_node,:not_empty])
                        zk.delete(path, :ignore => :no_node)
                    end
                end
            else
                return false
            end

        ensure
            zk.close!
        end
    end
end

