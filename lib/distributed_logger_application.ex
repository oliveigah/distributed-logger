defmodule DistributedLogger.Application do
  @moduledoc false
  use Application

  def start(_, _) do
    DistributedLogger.System.start_link()
  end
end
