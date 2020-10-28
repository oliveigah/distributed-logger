defmodule DistributedLoggerApplicationTest do
  use ExUnit.Case

  test "cluster auto connection" do
    Helpers.spawn_node("node1")
    Helpers.spawn_node("node2")
    Helpers.spawn_node("node3")

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

    Enum.each(Node.list(), &:slave.stop/1)
  end
end
