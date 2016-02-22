Facter.add("zk_server") do
    setcode do
        'zookeeper.example.com'
    end
end
Facter.add("zk_port") do
    setcode do
        '2181'
    end
end
