defmodule GTFSRealtimeViz do
  use Protobuf, from: Path.expand("../config/gtfs-realtime.proto", __DIR__)
  @moduledoc """
  Parses GTFS Realtime PB file and generates a nice visualization of it.

  $ iex -S mix
  iex(1)> "filename" |> File.read! |> GTFSRealtimeViz.FeedMessage.decode
  """
end
