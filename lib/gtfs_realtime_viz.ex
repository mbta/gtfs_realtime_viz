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
  iex(3)> File.write!("output.html", GTFSRealtimeViz.visualize(:prod, %{}))
  ```
  """

  alias GTFSRealtimeViz.State
  alias GTFSRealtimeViz.Proto

  @type route_opts :: %{String.t => [{String.t, String.t, String.t}]}

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
  """
  @spec visualize(term, route_opts) :: String.t
  def visualize(group, opts) do
    routes = Map.keys(opts)
    vehicle_archive = get_vehicle_archive(group, routes)
    trip_update_archive = get_trip_update_archive(group, routes)
    [trip_update_archive: trip_update_archive, vehicle_archive: vehicle_archive, routes: opts, render_diff?: false]
    |> gen_html
    |> Phoenix.HTML.safe_to_string
  end

  @doc """
  Renders an HTML fragment that displays the vehicle differences
  between two pb files.
  """
  @spec visualize_diff(term, term, route_opts) :: String.t
  def visualize_diff(group_1, group_2, opts) do
    routes = Map.keys(opts)
    vehicle_archive_1 = get_vehicle_archive(group_1, routes)
    trip_archive_1 = get_trip_update_archive(group_1, routes)
    vehicle_archive_2 = get_vehicle_archive(group_2, routes)
    trip_archive_2 = get_trip_update_archive(group_2, routes)
    trip_archive = archive_trips(trip_archive_1, trip_archive_2)

    [trip_update_archive: trip_archive, vehicle_archive: Enum.zip(vehicle_archive_1, vehicle_archive_2), routes: opts, render_diff?: true]
    |> gen_html()
    |> Phoenix.HTML.safe_to_string()
  end

  defp archive_trips(trip_set_1, trip_set_2) do
    archived = Enum.reduce(trip_set_1, %{}, fn {key, value}, acc ->
      Map.put(acc, key, {value, trip_set_2[key]})
    end)
    archived = Enum.reduce(trip_set_2, archived, fn {key, value}, acc ->
      Map.put(acc, key, {trip_set_1[key], value})
    end)
  end

  defp get_trip_update_archive(group, routes) do
    group
    |> State.trip_updates
    |> trips_we_care_about(routes)
    |> trip_updates_by_stop_id
  end

  def trips_we_care_about(state, routes) do
    Enum.map(state,
      fn {descriptor, update_list} ->
        filtered_positions = update_list
        |> Enum.filter(fn trip_update ->
          trip_update.trip && trip_update.trip.route_id in routes
        end)
        {descriptor, filtered_positions}
      end)
  end

  defp trip_updates_by_stop_id(state) do
    Enum.flat_map(state, fn {_descriptor, trip_updates} ->
      trip_updates
      |> Enum.flat_map(fn trip_update ->
        trip_update.stop_time_update
        |> Enum.reduce(%{}, fn stop_update, stop_update_acc ->
          if stop_update.arrival do
            Map.put(stop_update_acc, stop_update.stop_id, stop_update.arrival.time)
          else
            stop_update_acc
          end
        end)
      end)
    end)
    |> Enum.reduce(%{}, fn {stop_id, time}, acc ->
      Map.put(acc, stop_id, ([acc[stop_id], time_from_now(time)] |> List.flatten |> Enum.reject(& &1 == nil)))
    end)
  end

  def extract_trips(nil) do
    {nil, nil}
  end
  def extract_trips({first, second}) do
    {first, second}
  end

  defp time_from_now(current_time \\ DateTime.utc_now, diff_time) do
    {:ok, diff_datetime} = DateTime.from_unix(diff_time)
    DateTime.diff(diff_datetime, current_time, :second)
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

  @spec format_times([String.t] | nil) :: [String.t]
  def format_times(nil) do
    []
  end
  def format_times(time_list) do
    time_list
    |> Enum.sort()
    |> Enum.take(2)
    |> Enum.map(& "#{&1} seconds")
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
    tag_opts = [class: "vehicle-#{id}", onmouseover: "highlight(#{id}, 'red')", onmouseout: "highlight(#{id}, 'black')"]
    :span
    |> Phoenix.HTML.Tag.content_tag("#{ascii} (#{id})", tag_opts)
    |> Phoenix.HTML.safe_to_string()
  end

  # removes any vehicles that appear in given list
  defp unique_trains(vehicles_1, vehicles_2, ascii) do
    Enum.reject(vehicles_1, & &1 in vehicles_2) |> Enum.map(&{ascii, &1})
  end

  defp vehicles_with_status(vehicles, status) do
    Enum.filter(vehicles, & &1.current_status == status)
  end
end
