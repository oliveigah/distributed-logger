defmodule DistributedLoggerTest do
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

      File.rm_rf(Application.get_env(:distributed_logger, :event_logs_env_folder))
    end)
  end

  defp write_on_node_local(node, data) do
    :rpc.block_call(:"#{node}@127.0.0.1", DistributedLogger, :write_local, [data])
  end

  defp write_on_node_global(node, data) do
    :rpc.block_call(:"#{node}@127.0.0.1", DistributedLogger, :write_global, [data])
  end

  defp read_events_node(node) do
    :rpc.block_call(:"#{node}@127.0.0.1", DistributedLogger, :read_local, [0, 10])
  end

  test "should write events in order" do
    write_on_node_local("node1", "first event")
    write_on_node_local("node1", "second event")
    write_on_node_local("node1", "third event")
    write_on_node_local("node1", "fourth event")

    [first, second, third, fourth] = read_events_node("node1")

    assert first == "first event"
    assert second == "second event"
    assert third == "third event"
    assert fourth == "fourth event"
  end

  test "should write only inside node" do
    write_on_node_local("node1", "first event")
    write_on_node_local("node3", "second event")

    [first] = read_events_node("node1")
    [second] = read_events_node("node3")

    assert first == "first event"
    assert second == "second event"

    assert read_events_node("node2") == []
  end

  test "should write with timestamp on all nodes in order" do
    write_on_node_global("node1", "first event")
    write_on_node_global("node2", "second event")
    write_on_node_global("node3", "third event")
    write_on_node_global("node3", "fourth event")
    write_on_node_global("node2", "fifth event")
    write_on_node_global("node1", "sixth event")

    [first1, second1, third1, fourth1, fifth1, sixth1] = read_events_node("node1")
    [first2, second2, third2, fourth2, fifth2, sixth2] = read_events_node("node2")
    [first3, second3, third3, fourth3, fifth3, sixth3] = read_events_node("node3")

    assert {timestamp_first_1, "first event"} = handle_timestamp(first1)
    assert {timestamp_first_2, "first event"} = handle_timestamp(first2)
    assert {timestamp_first_3, "first event"} = handle_timestamp(first3)
    assert ^timestamp_first_1 = ^timestamp_first_2 = timestamp_first_3

    assert {timestamp_second_1, "second event"} = handle_timestamp(second1)
    assert {timestamp_second_2, "second event"} = handle_timestamp(second2)
    assert {timestamp_second_3, "second event"} = handle_timestamp(second3)
    assert ^timestamp_second_1 = ^timestamp_second_2 = timestamp_second_3

    assert {timestamp_third_1, "third event"} = handle_timestamp(third1)
    assert {timestamp_third_2, "third event"} = handle_timestamp(third2)
    assert {timestamp_third_3, "third event"} = handle_timestamp(third3)
    assert ^timestamp_third_1 = ^timestamp_third_2 = timestamp_third_3

    assert {timestamp_fourth_1, "fourth event"} = handle_timestamp(fourth1)
    assert {timestamp_fourth_2, "fourth event"} = handle_timestamp(fourth2)
    assert {timestamp_fourth_3, "fourth event"} = handle_timestamp(fourth3)
    assert ^timestamp_fourth_1 = ^timestamp_fourth_2 = timestamp_fourth_3

    assert {timestamp_fifth_1, "fifth event"} = handle_timestamp(fifth1)
    assert {timestamp_fifth_2, "fifth event"} = handle_timestamp(fifth2)
    assert {timestamp_fifth_3, "fifth event"} = handle_timestamp(fifth3)
    assert ^timestamp_fifth_1 = ^timestamp_fifth_2 = timestamp_fifth_3

    assert {timestamp_sixth_1, "sixth event"} = handle_timestamp(sixth1)
    assert {timestamp_sixth_2, "sixth event"} = handle_timestamp(sixth2)
    assert {timestamp_sixth_3, "sixth event"} = handle_timestamp(sixth3)
    assert ^timestamp_sixth_1 = ^timestamp_sixth_2 = timestamp_sixth_3
  end
end
