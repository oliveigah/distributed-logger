defmodule DistributedLogger.Application.Test do
  use ExUnit.Case

  import Helpers

  setup do
    File.rm_rf(Application.get_env(:distributed_logger, :event_logs_env_folder))

    restart_processes()

    :ok
  end

  setup_all %{} do
    spawn_node("node1")
    spawn_node("node2")
    spawn_node("node3")

    on_exit(fn ->
      Node.list()
      |> Enum.each(&:slave.stop/1)
    end)
  end

  test "cluster auto connection" do
    primary_cluster =
      Node.list([:this, :visible])
      |> Enum.sort()

    node1_cluster =
      :rpc.block_call(:"node1@127.0.0.1", Node, :list, [[:this, :visible]])
      |> Enum.sort()

    node2_cluster =
      :rpc.block_call(:"node2@127.0.0.1", Node, :list, [[:this, :visible]])
      |> Enum.sort()

    node3_cluster =
      :rpc.block_call(:"node3@127.0.0.1", Node, :list, [[:this, :visible]])
      |> Enum.sort()

    assert primary_cluster == node1_cluster
    assert node1_cluster == node2_cluster
    assert node2_cluster == node3_cluster
  end
end
