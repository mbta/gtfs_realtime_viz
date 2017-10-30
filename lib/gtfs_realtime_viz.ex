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
    content =
      [vehicles: State.vehicles()]
      |> gen_html
      |> Phoenix.HTML.safe_to_string

    File.write!(filename, content)
  end
end
