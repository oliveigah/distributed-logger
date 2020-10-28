defmodule DistributedLogger.Application do
  @moduledoc false
  use Application

  def start(_, _) do
    Application.get_env(:distributed_logger, :nodes, [])
    |> Enum.each(&Node.connect(:"#{&1}@127.0.0.1"))

    DistributedLogger.System.start_link()
  end
end
