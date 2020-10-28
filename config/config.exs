import Config

config :distributed_logger, nodes: []

import_config("#{Mix.env()}.exs")
