defmodule Helpers do
  @env_folder Application.compile_env!(:logger, :event_logs_env_folder)
  def get_event_logs() do
    base_folder = "#{@env_folder}/nodes/#{node()}/data"

    File.read!("#{base_folder}/events.log")
    |> String.split("\n")
  end
end
