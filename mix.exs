defmodule GTFSRealtimeViz.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gtfs_realtime_viz,
      version: "0.1.0",
      elixir: "~> 1.0",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {GTFSRealtimeViz.Application, []},
      env: env(),
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 0.0", only: [:dev], runtime: false},
      {:exprotobuf, "~> 1.0"},
      {:phoenix_html, "~> 2.0"},
    ]
  end

  defp env do
    [
      max_archive: 5,
      routes: %{},
    ]
  end
end
