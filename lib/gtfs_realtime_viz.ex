defmodule GTFSRealtimeViz do
  @moduledoc """
  Parses GTFS Realtime PB file and generates a nice visualization of it.

  $ iex -S mix
  iex(1)> "filename.pb" |> File.read! |> GTFSRealtimeViz.new_message
  iex(2)> GTFSRealtimeViz.visualize("output.html")
  """

  alias GTFSRealtimeViz.State

  require EEx
  EEx.function_from_file :def, :gen_html, "lib/viz.eex", [:assigns], [engine: Phoenix.HTML.Engine]

  def new_message(raw) do
    State.new_data(raw)
  end

  def visualize(filename) do
    routes = Application.get_env(:gtfs_realtime_viz, :routes)

    content =
      [vehicles: vehicles_by_stop_id(), routes: routes]
      |> gen_html
      |> Phoenix.HTML.safe_to_string

    File.write!(filename, content)
  end

  defp vehicles_by_stop_id do
    Enum.reduce(State.vehicles(), %{}, fn v, acc -> Map.put(acc, v.stop_id, v) end)
  end
end
