defmodule Helpers do
  @env_folder Application.compile_env!(:distributed_logger, :event_logs_env_folder)

  @nodes_ports %{
    "node1" => 7001,
    "node2" => 7002,
    "node3" => 7003
  }
  def get_event_logs() do
    base_folder = "#{@env_folder}/nodes/#{node()}/data"

    case File.read("#{base_folder}/events.log") do
      {:ok, binary} ->
        String.split(binary, "\n")

      _ ->
        []
    end
  end

  defp args(node_name) do
    port = Map.get(@nodes_ports, node_name)

    [
      "-loader inet",
      "-hosts 127.0.0.1",
      "-setcookie #{:erlang.get_cookie()}",
      "-distributed_logger port #{port}",
      "-distributed_logger nodes [primary,node1,node2,node3]"
    ]
    |> Enum.reduce("", fn arg, acc -> "#{acc} #{arg}" end)
    |> to_charlist()
  end

  defp rpc(node, module, function, args) do
    :rpc.block_call(node, module, function, args)
  end

  defp add_code_paths(node) do
    rpc(node, :code, :add_paths, [:code.get_path()])
  end

  defp transfer_configuration(node) do
    for {app_name, _, _} <- Application.loaded_applications() do
      for {key, val} <- Application.get_all_env(app_name) do
        rpc(node, Application, :put_env, [app_name, key, val])
      end
    end
  end

  defp ensure_applications_started(node) do
    rpc(node, Application, :ensure_all_started, [:mix])
    rpc(node, Mix, :env, [Mix.env()])

    for {app_name, _, _} <- Application.loaded_applications() do
      rpc(node, Application, :ensure_all_started, [app_name])
    end
  end

  def spawn_node(node_name) do
    {:ok, node} =
      :slave.start(
        to_charlist("127.0.0.1"),
        String.to_atom(node_name),
        args(node_name)
      )

    add_code_paths(node)
    transfer_configuration(node)
    ensure_applications_started(node)

    connect_nodes(node)

    node
  end

  def restart_processes do
    Node.list([:this, :visible])
    |> Enum.each(fn node ->
      pid = rpc(node, Process, :whereis, [DistributedLogger])
      rpc(node, Process, :exit, [pid, :kill])
    end)

    :ok
  end

  defp connect_nodes(node) do
    Node.list([:this, :visible])
    |> Enum.each(fn other_node ->
      rpc(other_node, Node, :connect, [node])
    end)

    :ok
  end
end
