import Config

config :distributed_logger, event_logs_env_folder: "./persist/dev/"
config :distributed_logger, port: 5555
config :distributed_logger, environment: :dev
