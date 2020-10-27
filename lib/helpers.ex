defmodule Helpers do
  @env_folder Application.compile_env!(:logger, :event_logs_env_folder)
  def get_event_logs() do
    base_folder = "#{@env_folder}/nodes/#{node()}/data"

    case File.read("#{base_folder}/events.log") do
      {:ok, binary} ->
        String.split(binary, "\n")

      _ ->
        []
    end
  end

  defp inet_loader_args do
    to_charlist("-loader inet -hosts 127.0.0.1 -setcookie #{:erlang.get_cookie()}")
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
      :slave.start(to_charlist("127.0.0.1"), String.to_atom(node_name), inet_loader_args())

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
