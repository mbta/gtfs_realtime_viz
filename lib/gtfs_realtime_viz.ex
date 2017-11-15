defmodule GTFSRealtimeViz do
  @moduledoc """
  GTFSRealtimeViz is an OTP app that can be run by itself or as part of another
  application. You can send it protobuf VehiclePositions.pb files, in sequence,
  and then output them as an HTML fragment, to either open in a browser or embed
  in another view.

  Example usage as stand alone:

  ```
  $ iex -S mix
  iex(1)> proto = File.read!("filename.pb")
  iex(2)> GTFSRealtimeViz.new_message(:prod, proto, "first protobuf file")
  iex(3)> File.write!("output.html", GTFSRealtimeViz.visualize(:prod))
  ```
  """

  alias GTFSRealtimeViz.State
  alias GTFSRealtimeViz.Proto

  require EEx
  EEx.function_from_file :defp, :gen_html, "lib/viz.eex", [:assigns], [engine: Phoenix.HTML.Engine]

  @doc """
  Send protobuf files to the app's GenServer. The app can handle a series of files,
  belonging to different groupings (e.g., test, dev, and prod). When sending the file,
  you must also provide a comment (perhaps a time stamp or other information about the
  file), which will be displayed along with the visualization.
  """
  @spec new_message(term, Proto.raw, String.t) :: :ok
  def new_message(group, raw, comment) do
    State.new_data(group, raw, comment)
  end

  @doc """
  Renders the received protobuf files and comments into an HTML fragment that can either
  be opened directly in a browser or embedded within the HTML layout of another app.
  """
  @spec visualize(term, %{String.t => [[String.t]]}) :: String.t
  def visualize(group, opts) do
    all_locations = locations_we_care_about(opts)
    vehicles_we_care_about = group
                             |> State.vehicles
                             |> vehicles_we_care_about(all_locations)

    [vehicle_archive: vehicles_by_stop_id(vehicles_we_care_about), routes: opts]
    |> gen_html
    |> Phoenix.HTML.safe_to_string
  end

  def locations_we_care_about(opts) do
    opts
    |> Enum.flat_map(fn {_, stop} -> stop end)
    |> Enum.flat_map(fn stop -> stop end)
  end

  def vehicles_we_care_about(state, locations_we_care_about) do
    Enum.map(state,
      fn {descriptor, position_list} ->
        filtered_positions = position_list
        |> Enum.filter(fn position -> position.stop_id in locations_we_care_about end)
        {descriptor, filtered_positions}
      end)
  end

  @spec vehicles_by_stop_id([{String.t, [Proto.vehicle_position]}]) :: [{String.t, %{required(String.t) => [Proto.vehicle_position]}}]
  defp vehicles_by_stop_id(state) do
    Enum.map(state, fn {comment, vehicles} ->
      vehicles_by_stop = Enum.reduce(vehicles, %{}, fn v, acc ->
        update_in acc, [v.stop_id], fn vs ->
          [v | (vs || [])]
        end
      end)

      {comment, vehicles_by_stop}
    end)
  end

  @spec trainify([Proto.vehicle_position], Proto.vehicle_position_statuses, String.t) :: String.t
  defp trainify(vehicles, status, ascii_train) do
    vehicles
    |> Enum.filter(& &1.current_status == status)
    |> Enum.map(& "#{ascii_train} (#{&1.vehicle && &1.vehicle.id})")
    |> Enum.join(",")
  end

  defp routes, do: Application.get_env(:gtfs_realtime_viz, :routes)
end
