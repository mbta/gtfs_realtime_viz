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
  EEx.function_from_file :defp, :gen_html, "lib/templates/viz.eex", [:assigns], [engine: Phoenix.HTML.Engine]
  EEx.function_from_file :defp, :render_diff, "lib/templates/diff.eex", [:assigns], [engine: Phoenix.HTML.Engine]
  EEx.function_from_file :defp, :render_single_file, "lib/templates/single_file.eex", [:assigns], [engine: Phoenix.HTML.Engine]

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
  Opts expects a map of %{"route_id" => [{"Stop name", "inbound_id", "outbound_id"}]
  """
  @spec visualize(term, %{String.t => [{String.t, String.t, String.t}]}) :: String.t
  def visualize(group, opts) do
    routes = Map.keys(opts)
    vehicle_archive = get_vehicle_archive(group, routes)
    [vehicle_archive: vehicle_archive, routes: opts, render_diff?: false]
    |> gen_html
    |> Phoenix.HTML.safe_to_string
  end

  def visualize_diff(group_1, group_2, opts) do
    routes = Map.keys(opts)
    archive_1 = get_vehicle_archive(group_1, routes)
    archive_2 = get_vehicle_archive(group_2, routes)
    [vehicle_archive: Enum.zip(archive_1, archive_2), routes: opts, render_diff?: true]
    |> gen_html()
    |> Phoenix.HTML.safe_to_string()
  end

  defp get_vehicle_archive(group, routes) do
    group
    |> State.vehicles
    |> vehicles_we_care_about(routes)
    |> vehicles_by_stop_id()
  end

  def vehicles_we_care_about(state, routes) do
    Enum.map(state,
      fn {descriptor, position_list} ->
        filtered_positions = position_list
        |> Enum.filter(fn position ->
          position.trip && position.trip.route_id in routes
        end)
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
    |> vehicles_with_status(status)
    |> Enum.map(& "#{ascii_train} (#{&1.vehicle && &1.vehicle.id})")
    |> Enum.join(",")
  end

  @spec trainify_diff([Proto.vehicle_position], [Proto.vehicle_position], Proto.vehicle_position_statuses, String.t, String.t) :: String.t
  defp trainify_diff(vehicles_base, vehicles_diff, status, ascii_train_base, ascii_train_diff) do
    base = vehicles_with_status(vehicles_base, status) |> Enum.map(& &1.vehicle && &1.vehicle.id)
    diff = vehicles_with_status(vehicles_diff, status) |> Enum.map(& &1.vehicle && &1.vehicle.id)

    unique_base = unique_trains(base, diff, ascii_train_base)
    unique_diff = unique_trains(diff, base, ascii_train_diff)

    [unique_base, unique_diff]
    |> List.flatten()
    |> Enum.map(&span_for_id/1)
    |> Enum.join(",")
  end

  defp span_for_id({ascii, id}) do
    "<span class=\"vehicle-#{id}\" onmouseover=\"highlight(#{id}, 'red')\" onmouseout=\"highlight(#{id}, 'black')\">#{ascii} (#{id})</span>"
  end

  # removes any vehicles that appear in given list
  defp unique_trains(vehicles_1, vehicles_2, ascii) do
    Enum.reject(vehicles_1, & &1 in vehicles_2) |> Enum.map(&{ascii, &1})
  end

  defp vehicles_with_status(vehicles, status) do
    Enum.filter(vehicles, & &1.current_status == status)
  end
end
