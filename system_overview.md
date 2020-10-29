# System Overview

## Running the system

### Requirements

- Elixir 1.11.1
- Erlang OTP 23

### Testing

1 - Inside terminal, go to the project's folder

2 - `mix deps.get`

3 - `bash ./scripts/test.sh`

4 - Good to go! :)

After the first run of the `test.sh` you can run the tests normally using `mix test`

### Running

You have 2 ways to run the system:

1 - Interactive shell in which you can add a custom number of servers and interact with the system in real time via IEX

2 - `bash ./scripts/run.sh` script inside the project's folder to start 3 fully connected nodes running on the ports 5555, 5556 and 5557

### IEX

If you want to run the system via iex you can run the following command (#{xxx} must be replaced):

`iex --name #{name}@127.0.0.1 --erl "-distributed_logger port #{http_port} -distributed_logger nodes #{nodes_to_connect}" -S mix`

There are 3 values you need to replace here, lets break it down:

- #{name}: Node's name (eg: node1)

- #{http_port}: HTTP port that the node will listem (eg: 5556)

- #{node_to_connect}: List of node's names that this node will connect on initialization (eg: [node2, node3])

After running this command you already have a fully functional instance of the system and you can add nodes by running this command on other terminals, just change the node name and port, and if you want to connect them pass the node name using nodes_to_connect.

For instance if you want 3 nodes connected you must run on 3 different terminals the following commands (in order):

- `iex --name node1@127.0.0.1 --erl "-distributed_logger port 5555 -distributed_logger nodes" -S mix`

- `iex --name node2@127.0.0.1 --erl "-distributed_logger port 5556 -distributed_logger nodes [node1]" -S mix`

- `iex --name node3@127.0.0.1 --erl "-distributed_logger port 5557 -distributed_logger nodes [node1,node2]" -S mix`

With this you have a cluster with 3 fully connected nodes. Each one listening on different ports and saving event data on different files.

### Shell Script

If you dont want to run with iex you can run the shell script inside the project's folder using `bash ./scripts/run.sh` that will start a cluster with 3 nodes as daemons. Which you can kill using the `kill.sh` script with sudo privileges.

## Interacting

To interact with the system you can go either by terminal (only if you have chosen the IEX approach on the previous section) using the `DistributedLogger` module or using http requests (avaiable for both, IEX and shell script) to the listening ports of the nodes.

### IEX

Via terminal you have 3 main functions to interact with:

`DistributedLogger.write_global/1`: Receives event data (eg: "This is event 1") it's save the event data globally

`DistributedLogger.write_local/1` : Receives event data (eg: "This is event 1") it's save the event data locally

`DistributedLogger.read_local/2` : Receives initial line and final line, returning a list containing all the lines requested from the local file

The docs for all these functions can be accessed via terminal running the `h` command. (eg: `h DistributedLogger.write_global/1`)

### HTTP

Alternatively you can run interact using a http request such as:

`curl -X POST -H "Content-Type: text/plain" --data "This is event 1" http://127.0.0.1:5555/event`

`curl -X POST -H "Content-Type: text/plain" --data "This is event 2" http://127.0.0.1:5556/event`

`curl -X POST -H "Content-Type: text/plain" --data "This is event 3" http://127.0.0.1:5557/event`

A post to the `/event` route is equivalent to run `DistributedLogger.write_global/1` inside some terminal, actually the route just call this same function.

### Log Files

If you want to see the logs that are being generated you can check inside the persist folder:

`project/persist/dev/nodes/#{node}/data/event.log`

Each event is in one line and the unix timestamp is added to the data

## System Overview

WIP

![](./assets/exdocs_assets/node-diagram.png)
![](./assets/exdocs_assets/cluster-diagram.png)

## Distributed Logger

WIP

## Design Choices

WIP
