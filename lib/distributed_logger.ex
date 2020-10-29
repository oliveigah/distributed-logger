defmodule DistributedLogger do
  @doc false
  use GenServer
  @env_folder Application.compile_env!(:distributed_logger, :event_logs_env_folder)
  @doc false
  def init(_) do
    base_folder = "#{@env_folder}nodes/#{node()}/data"

    File.mkdir_p!(base_folder)
    File.write("#{base_folder}/events.log", "", [:append])

    {:ok, File.stream!("#{base_folder}/events.log", [:append])}
  end

  @doc false
  def start_link(_ \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec write_global(String.t()) :: :ok
  @doc """
  Writes event data globally (all nodes)

  ## Examples
      iex> DistributedLogger.write_global("event data")
      iex> :ok
  """
  def write_global(event_data) do
    {_results, fail_nodes} =
      :rpc.multicall(
        Node.list([:this, :visible]),
        __MODULE__,
        :write_local,
        [parse_event_data(event_data)],
        :timer.seconds(5)
      )

    Enum.each(fail_nodes, &IO.puts("Write failed on node #{&1}"))

    :ok
  end

  @spec write_local(String.t()) :: :ok
  @doc """
  Writes event data locally (only this node)

  ## Examples
      iex> DistributedLogger.write_local("event data")
      iex> :ok
  """
  def write_local(event_data) do
    GenServer.call(__MODULE__, {:write_local, event_data})
  end

  @spec read_local(integer(), integer()) :: list(String.t())
  @doc """
  Read lines of the local log file.

  - 0 index based
  - border inclusive
  - is safe to use any integer as parameter

  ## Examples
      iex> DistributedLogger.write_local("event 0")
      iex> DistributedLogger.write_local("event 1")
      iex> DistributedLogger.write_local("event 2")
      iex> DistributedLogger.write_local("event 3")
      iex> DistributedLogger.read_local(1,2)
      iex> ["event 1", "event 2"]

      iex> DistributedLogger.read_local(1,10)
      iex> []

      iex> DistributedLogger.write_local("event 0")
      iex> DistributedLogger.write_local("event 1")
      iex> DistributedLogger.read_local(-57,454785)
      iex> ["event 0", "event 1"]
  """
  def read_local(initial_line, final_line) do
    GenServer.call(__MODULE__, {:read_local, initial_line, final_line})
  end

  @spec generate_consolidated_file(integer(), integer()) ::
          {:ok, String.t()} | {:error, String.t(), [atom]}
  @doc """
  Generated a consilidate event log file, which guarantee consistency along all nodes

  - Partial retrieves (initial line > 0 or final line < last line) may be inconsistent, but can be used for performance reasons
  - border inclusive
  - is safe to use any integer as parameter
  - To retrieve all file you just need to use 0 as initial line and a very big number as final line
  - The file is generated with a time stamp and inside the node's data folder
  - The file name is returned as second element of the tuple

  ## Examples
      iex> {:ok, _file_path} = DistributedLogger.generate_consolidated_file(0,100)
  """
  def generate_consolidated_file(initial_line, final_line) do
    :rpc.multicall(
      Node.list([:this, :visible]),
      __MODULE__,
      :read_local,
      [initial_line, final_line],
      :timer.seconds(5)
    )
    |> generate_file()
  end

  defp generate_file({[_h | _t] = nodes_results, []}) do
    file_path =
      nodes_results
      |> Stream.flat_map(fn x -> x end)
      |> Stream.uniq()
      |> Stream.map(fn event -> "#{event}\n" end)
      |> Enum.sort()
      |> write_to_consolidated_file()

    {:ok, file_path}
  end

  defp generate_file({_, [_h | _t] = fail_nodes}) do
    {:error, "Some nodes did not respond. Impossible to guarantee consistency", fail_nodes}
  end

  @doc false
  def handle_call({:write_local, event_data}, _from, file_stream) do
    ["#{event_data}", "\n"]
    |> Stream.into(file_stream)
    |> Stream.run()

    {:reply, :ok, file_stream}
  end

  def handle_call({:read_local, initial_line, final_line}, _from, file_stream) do
    lines_list =
      file_stream
      |> Stream.with_index()
      |> Stream.filter(fn {_line, index} -> initial_line <= index && final_line >= index end)
      |> Stream.map(fn {line, _} -> String.replace(line, "\n", "") end)
      |> Enum.to_list()

    {:reply, lines_list, file_stream}
  end

  defp parse_event_data(event_data) do
    timestamp = DateTime.to_unix(DateTime.utc_now())
    "#{timestamp} #{event_data}"
  end

  defp write_to_consolidated_file(data) do
    base_folder = "#{@env_folder}nodes/#{node()}/data"
    timestamp = DateTime.to_unix(DateTime.utc_now())
    file_path = "#{base_folder}/#{timestamp}-consolidated-events.log"

    File.mkdir_p!(base_folder)
    File.write(file_path, "", [:append])

    strm = File.stream!(file_path, [:append])

    data
    |> Stream.into(strm)
    |> Stream.run()

    file_path
  end
end
