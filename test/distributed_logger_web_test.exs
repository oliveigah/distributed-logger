defmodule DistributedLogger.Web.Test do
  use ExUnit.Case

  import Helpers

  @routes %{
    "node1" => "localhost:7001/event",
    "node2" => "localhost:7002/event",
    "node3" => "localhost:7003/event"
  }

  @header [
    {"Content-Type", "text/html; charset=utf-8"},
    {"Accept", "text/html; charset=utf-8"}
  ]

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

  def write_to_node(node_name, event_data) do
    {:ok, _} =
      Map.get(@routes, node_name)
      |> HTTPoison.post(event_data, @header)
  end

  defp read_events_node(node) do
    :rpc.block_call(:"#{node}@127.0.0.1", DistributedLogger, :read_local, [0, 10])
  end

  test "http routes functions" do
    write_to_node("node1", "first event")
    write_to_node("node2", "second event")
    write_to_node("node3", "third event")
    write_to_node("node3", "fourth event")
    write_to_node("node2", "fifth event")
    write_to_node("node1", "sixth event")

    [first_1, second_1, third_1, fourth_1, fifth_1, sixth_1] = read_events_node("node1")
    [first_2, second_2, third_2, fourth_2, fifth_2, sixth_2] = read_events_node("node2")
    [first_3, second_3, third_3, fourth_3, fifth_3, sixth_3] = read_events_node("node3")

    assert {timestamp_first_1, "first event"} = handle_timestamp(first_1)
    assert {timestamp_first_2, "first event"} = handle_timestamp(first_2)
    assert {timestamp_first_3, "first event"} = handle_timestamp(first_3)

    ^timestamp_first_1 = ^timestamp_first_2 = timestamp_first_3

    assert {timestamp_second_1, "second event"} = handle_timestamp(second_1)
    assert {timestamp_second_2, "second event"} = handle_timestamp(second_2)
    assert {timestamp_second_3, "second event"} = handle_timestamp(second_3)

    ^timestamp_second_1 = ^timestamp_second_2 = timestamp_second_3

    assert {timestamp_third_1, "third event"} = handle_timestamp(third_1)
    assert {timestamp_third_2, "third event"} = handle_timestamp(third_2)
    assert {timestamp_third_3, "third event"} = handle_timestamp(third_3)

    ^timestamp_third_1 = ^timestamp_third_2 = timestamp_third_3

    assert {timestamp_fourth_1, "fourth event"} = handle_timestamp(fourth_1)
    assert {timestamp_fourth_2, "fourth event"} = handle_timestamp(fourth_2)
    assert {timestamp_fourth_3, "fourth event"} = handle_timestamp(fourth_3)

    ^timestamp_fourth_1 = ^timestamp_fourth_2 = timestamp_fourth_3

    assert {timestamp_fifth_1, "fifth event"} = handle_timestamp(fifth_1)
    assert {timestamp_fifth_2, "fifth event"} = handle_timestamp(fifth_2)
    assert {timestamp_fifth_3, "fifth event"} = handle_timestamp(fifth_3)

    ^timestamp_fifth_1 = ^timestamp_fifth_2 = timestamp_fifth_3

    assert {timestamp_sixth_1, "sixth event"} = handle_timestamp(sixth_1)
    assert {timestamp_sixth_2, "sixth event"} = handle_timestamp(sixth_2)
    assert {timestamp_sixth_3, "sixth event"} = handle_timestamp(sixth_3)

    ^timestamp_sixth_1 = ^timestamp_sixth_2 = timestamp_sixth_3
  end
end
