defmodule DistributedLogger.System do
  @moduledoc false
  def start_link() do
    Supervisor.start_link(
      [DistributedLogger],
      strategy: :one_for_one,
      name: __MODULE__
    )
  end
end