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

  @routes Application.get_env(:gtfs_realtime_viz, :routes)

  @spec new_message(Proto.raw, String.t) :: :ok
  def new_message(raw, comment) do
    State.new_data(raw, comment)
  end

  @spec visualize() :: String.t
  def visualize do
    [vehicle_archive: vehicles_by_stop_id(), routes: @routes]
    |> gen_html
    |> Phoenix.HTML.safe_to_string
  end

  @spec vehicles_by_stop_id() :: [{String.t, %{required(String.t) => [Proto.vehicle_position]}}]
  defp vehicles_by_stop_id do
    Enum.map(State.vehicles(), fn {comment, vehicles} ->
      vehicles_by_stop = Enum.reduce(vehicles, %{}, fn v, acc ->
        update_in acc, [v.stop_id], fn vs ->
          [v | (vs || [])]
        end
      end)

      {comment, vehicles_by_stop}
    end)
  end

  @spec trainify([Proto.vehicle_position], Proto.vehicle_position_statuses, String.t) :: String.t
  def trainify(vehicles, status, ascii_train) do
    vehicles
    |> Enum.filter(& &1.current_status == status)
    |> Enum.map(& "#{ascii_train} (#{&1.vehicle && &1.vehicle.id})")
    |> Enum.join(",")
  end
end
