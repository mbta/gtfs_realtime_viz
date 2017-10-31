defmodule GTFSRealtimeViz.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gtfs_realtime_viz,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {GTFSRealtimeViz.Application, []}
    ]
  end

  defp deps do
    [
      {:exprotobuf, "~> 1.2.9"},
      {:phoenix_html, "~> 2.10.4"},
    ]
  end
end
