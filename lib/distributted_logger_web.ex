defmodule DistributedLogger.Web do
  @moduledoc false
  use Plug.Router
  use Plug.ErrorHandler

  plug(:match)
  plug(:dispatch)

  def child_spec(_arg) do
    port = Application.fetch_env!(:distributed_logger, :port)
    IO.puts("Account HTTP server listening to: port #{port}")

    Plug.Adapters.Cowboy.child_spec(
      scheme: :http,
      options: [port: port],
      plug: __MODULE__
    )
  end

  defp send_http_response(_result, conn) do
    conn
    |> Plug.Conn.put_resp_content_type("charset=utf-8")
    |> Plug.Conn.send_resp(200, "ok")
  end

  post("event") do
    {:ok, event_data, conn} = Plug.Conn.read_body(conn)

    event_data
    |> DistributedLogger.write_global()
    |> send_http_response(conn)
  end
end
