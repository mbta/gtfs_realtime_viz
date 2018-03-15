defmodule GTFSRealtimeViz.Mixfile do
  use Mix.Project

  @version "0.7.1"

  def project do
    [
      app: :gtfs_realtime_viz,
      version: @version,
      elixir: "~> 1.0",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      source_url: "https://github.com/mbta/gtfs_realtime_viz"
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
      {:ex_doc, "~> 0.16", only: [:dev], runtime: false},
      {:exprotobuf, "~> 1.0"},
      {:phoenix_html, "~> 2.0"},
      {:timex, "~> 3.1"}
    ]
  end

  defp env do
    [
      max_archive: 5,
      routes: %{},
    ]
  end

  defp description do
    "Visualizer for GTFS Realtime protocol buffer files"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mbta/gtfs_realtime_viz"},
      maintainers: ["Gabe Durazo <gabe@durazo.us>", "John Kohler <kohlerjohnp@gmail.com>", "Alex Sghia-Hughes", "Dave Maltzan <dmaltzan@gmail.com>"]
    ]
  end
end
