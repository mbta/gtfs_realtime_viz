# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :gtfs_realtime_viz, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:gtfs_realtime_viz, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

# e.g.
# config :gtfs_realtime_viz, :routes, %{
#   "Mattapan" => [
#     ["Ashmont", "70261", "70262"],
#     ["Cedar Grove", "70263", "70264"],
#     ["Butler", "70265", "70266"],
#     ["Milton", "70267", "70268"],
#     ["Central Ave", "70269", "70270"],
#     ["Valley Road", "70271", "70272"],
#     ["Capen St.", "70273", "70274"],
#     ["Mattapan", "70275", "70276"],
#   ]
# }
