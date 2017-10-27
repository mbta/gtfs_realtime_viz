defmodule GTFSRealtimeViz do
  @moduledoc """
  Parses GTFS Realtime PB file and generates a nice visualization of it.

  $ iex -S mix
  iex(1)> "filename" |> File.read! |> GTFSRealtimeViz.FeedMessage.decode
  """

  use Protobuf, from: Path.expand("../config/gtfs-realtime.proto", __DIR__)

  require EEx
  EEx.function_from_file :def, :gen_html, "lib/viz.eex", [:assigns], [engine: Phoenix.HTML.Engine]

  def visualize(raw, filename) do
    data = GTFSRealtimeViz.FeedMessage.decode(raw) #TODO: handle failure
    vehicles = Enum.map(data.entity, & &1.vehicle) #TODO: handle if no entity, or not all vehicles

    content =
      [vehicles: vehicles]
      |> gen_html
      |> Phoenix.HTML.safe_to_string

    File.write!(filename, content)
  end
end
