require 'thread'
require 'zk'



    # you can either implement cache (in case zk is unavailable), or just fail
    # catalog compilation. Stopping the puppet run is good enough for me.

class Events
    def initialize
        @zk = ZK.new
        @path = '/puppet'
    end

    def run
        # start with clean data
        begin
            @zk.delete('/puppet/test1')
            @zk.delete('/puppet/test2')
            @zk.delete('/puppet')
        rescue ZK::Exceptions::NoNode
        end

        @zk.create('/puppet', 'puppet', :or => :set)
        @zk.create('/puppet/test1', 'test1', :or => :set)
        @zk.create('/puppet/test1', 'whee!', :or => :set)
        @zk.create('/puppet/test2', 'test2', :or => :set)
        puts @zk.children(@path)
        puts @zk.get(@path).first
        puts @zk.get('/puppet/test1').first

    ensure
        @zk.close!
    end
end

Events.new.run

