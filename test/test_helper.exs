:net_kernel.start([:"primary@127.0.0.1"])

# Allow spawned nodes to fetch all code from this node
:erl_boot_server.start([])

{:ok, ipv4} = :inet.parse_ipv4_address(to_charlist("127.0.0.1"))
:erl_boot_server.add_slave(ipv4)

ExUnit.start()
