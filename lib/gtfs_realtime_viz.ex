defmodule GTFSRealtimeViz do
  @moduledoc """
  Parses GTFS Realtime PB file and generates a nice visualization of it.

  $ iex -S mix
  iex(1)> "filename.pb" |> File.read! |> GTFSRealtimeViz.new_message
  iex(2)> GTFSRealtimeViz.visualize("output.html")
  """

  alias GTFSRealtimeViz.State
  alias GTFSRealtimeViz.Proto

  require EEx
  EEx.function_from_file :def, :gen_html, "lib/viz.eex", [:assigns], [engine: Phoenix.HTML.Engine]

  @spec new_message(Proto.raw) :: :ok
  def new_message(raw) do
    State.new_data(raw)
  end

  @spec visualize() :: String.t
  def visualize do
    routes = Application.get_env(:gtfs_realtime_viz, :routes)

    [vehicles: vehicles_by_stop_id(), routes: routes]
    |> gen_html
    |> Phoenix.HTML.safe_to_string
  end

  @spec vehicles_by_stop_id() :: %{required(String.t) => Proto.vehicle_position}
  defp vehicles_by_stop_id do
    Enum.reduce(State.vehicles(), %{}, fn v, acc -> Map.put(acc, v.stop_id, v) end)
  end
end
