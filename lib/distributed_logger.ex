defmodule DistributedLogger do
  use GenServer
  @env_folder Application.compile_env!(:distributed_logger, :event_logs_env_folder)
  def init(_) do
    connect_to_cluster()

    base_folder = "#{@env_folder}nodes/#{node()}/data"

    File.mkdir_p!(base_folder)
    {:ok, File.stream!("#{base_folder}/events.log", [:append])}
  end

  defp connect_to_cluster() do
  end

  def start_link(_ \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def write_global(event_data) do
    :erpc.multicall(
      Node.list([:this, :visible]),
      __MODULE__,
      :write_local,
      [parse_event_data(event_data)],
      :timer.seconds(5)
    )
  end

  def write_local(event_data) do
    GenServer.call(__MODULE__, {:write_local, event_data})
  end

  def handle_call({:write_local, event_data}, _from, file_stream) do
    ["#{event_data}", "\n"]
    |> Stream.into(file_stream)
    |> Stream.run()

    {:reply, :ok, file_stream}
  end

  def parse_event_data(event_data) do
    timestamp = DateTime.to_unix(DateTime.utc_now())
    "#{timestamp} #{event_data}"
  end
end
