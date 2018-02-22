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
    State.single_pb(group, raw, comment)
  end

  def new_message(group, vehicle_positions, trip_updates, comment) do
    State.new_data(group, vehicle_positions, trip_updates, comment)
  end

  @doc """
  Renders the received protobuf files and comments into an HTML fragment that can either
  be opened directly in a browser or embedded within the HTML layout of another app.
  """
  @spec visualize(term, route_opts) :: String.t
  def visualize(group, opts) do
    routes = Map.keys(opts[:routes])
    display_routes = opts[:routes] |> Enum.reject(fn {_key, val} -> val == [] end) |> Map.new
    vehicle_archive = get_vehicle_archive(group, routes)
    trip_update_archive = get_trip_update_archive(group, routes, opts[:timezone])
    [trip_update_archive: trip_update_archive, vehicle_archive: vehicle_archive, routes: display_routes, render_diff?: false]
    |> gen_html
    |> Phoenix.HTML.safe_to_string
  end

  @doc """
  Renders an HTML fragment that displays the vehicle differences
  between two pb files.
  """
  @spec visualize_diff(term, term, route_opts) :: String.t
  def visualize_diff(group_1, group_2, opts) do
    routes = Map.keys(opts[:routes])
    vehicle_archive_1 = get_vehicle_archive(group_1, routes)
    trip_archive_1 = get_trip_update_archive(group_1, routes, opts[:timezone])
    vehicle_archive_2 = get_vehicle_archive(group_2, routes)
    trip_archive_2 = get_trip_update_archive(group_2, routes, opts[:timezone])

    [trip_update_archive: Enum.zip(trip_archive_1, trip_archive_2), vehicle_archive: Enum.zip(vehicle_archive_1, vehicle_archive_2), routes: opts[:routes], render_diff?: true]
    |> gen_html()
    |> Phoenix.HTML.safe_to_string()
  end

  defp get_trip_update_archive(group, routes, timezone) do
    group
    |> State.trip_updates
    |> trips_we_care_about(routes)
    |> trip_updates_by_stop_direction_id(timezone)
  end

  def trips_we_care_about(state, routes) do
    Enum.map(state,
      fn {descriptor, update_list} ->
        filtered_positions = update_list
        |> Enum.filter(fn trip_update ->
          trip_update.trip.route_id in routes
        end)
        {descriptor, filtered_positions}
      end)
  end

  defp trip_updates_by_stop_direction_id(state, timezone) do
    Enum.map(state, fn {_descriptor, trip_updates} ->
      trip_updates
      |> Enum.flat_map(fn trip_update ->
        trip_update.stop_time_update
        |> Enum.reduce(%{}, fn stop_update, stop_update_acc ->
          if stop_update.arrival && stop_update.arrival.time do
            Map.put(stop_update_acc, {stop_update.stop_id, trip_update.trip.direction_id}, {trip_update.trip.trip_id, stop_update.arrival.time})
          else
            stop_update_acc
          end
        end)
      end)
    end)
    |> Enum.map(fn predictions ->
      Enum.reduce(predictions, %{}, fn {stop_id, {trip_id, time}}, acc ->
        Map.update(acc, stop_id, [{trip_id, timestamp(time, timezone)}], fn timestamps -> timestamps ++ [{trip_id, timestamp(time, timezone)}] end)
      end)
    end)
  end

  defp timestamp(diff_time, timezone) do
    diff_datetime = diff_time
                    |> DateTime.from_unix!()
                    |> Timex.Timezone.convert(timezone)
    diff_datetime
  end

  defp get_vehicle_archive(group, routes) do
    group
    |> State.vehicles
    |> vehicles_we_care_about(routes)
    |> vehicles_by_stop_direction_id()
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

  @spec vehicles_by_stop_direction_id([{String.t, [Proto.vehicle_position]}]) :: [{String.t, %{required(String.t) => [Proto.vehicle_position]}}]
  defp vehicles_by_stop_direction_id(state) do
    Enum.map(state, fn {comment, vehicles} ->
      vehicles_by_stop = Enum.reduce(vehicles, %{}, fn v, acc ->
        update_in acc, [{v.stop_id, v.trip.direction_id}], fn vs ->
          [v | (vs || [])]
        end
      end)

      {comment, vehicles_by_stop}
    end)
  end

  @spec format_times([{String.t, DateTime.t}] | nil) :: [Phoenix.HTML.Safe.t]
  def format_times(nil) do
    []
  end
  def format_times(time_list) do
    time_list
    |> sort_by_time()
    |> Enum.take(2)
    |> Enum.map(&format_time/1)
  end

  def sort_by_time(time_list) do
    Enum.sort(time_list, &time_list_sorter/2)
  end

  defp time_list_sorter({_, time1}, {_, time2}) do
    Timex.before?(time1, time2)
  end

  defp format_time({_, nil}) do
    nil
  end
  defp format_time({trip_id, time}) do
    ascii = Timex.format!(time, "{h24}:{m}:{s}")
    span_for_id({ascii, trip_id})
  end

  @spec format_time_diff(time_list, time_list) :: [{time_output, time_output}]
  when time_list: {String.t, DateTime.t} | nil, time_output: Phoenix.HTML.Safe.t | nil
  def format_time_diff(base_list, nil) do
    for format <- format_times(base_list) do
      {format, nil}
    end
  end
  def format_time_diff(nil, diff_list) do
    for format <- format_times(diff_list) do
      {nil, format}
    end
  end
  def format_time_diff(base_list, diff_list) do
    for {{base_trip, base_prediction}, {diff_trip, diff_prediction}} <- sort_time_diff(base_list, diff_list) do
      {format_time({base_trip, base_prediction}), format_time({diff_trip, diff_prediction})}
    end
  end

  def sort_time_diff(base_list, diff_list) do
    for {base, diff} <- zip_pad(sort_by_time(base_list), sort_by_time(diff_list), 2, [])  do
      {base, diff}
    end
  end

  defp zip_pad(base_list, diff_list, count, acc)
  defp zip_pad([], [], _, acc), do: Enum.reverse(acc)
  defp zip_pad(_, _, 0, acc), do: Enum.reverse(acc)
  defp zip_pad([], [head | tail], count, acc), do: zip_pad([], tail, count - 1, [{nil, head} | acc])
  defp zip_pad([head | tail], [], count, acc), do: zip_pad(tail, [], count - 1, [{head, nil} | acc])
  defp zip_pad([base_head | base_tail], [diff_head | diff_tail], count, acc), do: zip_pad(base_tail, diff_tail, count - 1, [{base_head, diff_head} | acc])

  @spec trainify([Proto.vehicle_position], Proto.vehicle_position_statuses, String.t) :: iodata
  defp trainify(vehicles, status, ascii_train) do
    vehicles
    |> vehicles_with_status(status)
    |> Enum.map(fn status ->
      label =
        if status.vehicle do
          status.vehicle.label || ""
        else
          ""
        end
      [ascii_train, " ", label]
    end)
    |> Enum.intersperse(",")
  end

  @spec label_or_id(Proto.vehicle_position) :: String.t
  defp label_or_id(%{label: label, id: id}) when label in [nil, ""] do
    id
  end
  defp label_or_id(%{label: label}) do
    label
  end

  @spec trainify_diff([Proto.vehicle_position], [Proto.vehicle_position], Proto.vehicle_position_statuses, String.t, String.t) :: Phoenix.HTML.Safe.t
  defp trainify_diff(vehicles_base, vehicles_diff, status, ascii_train_base, ascii_train_diff) do
    base = vehicles_with_status(vehicles_base, status) |> Enum.map(& &1.vehicle && label_or_id(&1.vehicle))
    diff = vehicles_with_status(vehicles_diff, status) |> Enum.map(& &1.vehicle && label_or_id(&1.vehicle))

    unique_base = unique_trains(base, diff, ascii_train_base)
    unique_diff = unique_trains(diff, base, ascii_train_diff)

    [unique_base, unique_diff]
    |> List.flatten()
    |> Enum.map(&span_for_id/1)
    |> Enum.intersperse(",")
  end

  defp span_for_id({ascii, id}) do
    tag_opts = [class: "vehicle-#{id}", onmouseover: "highlight('#{id}', 'red')", onmouseout: "highlight('#{id}', 'black')"]
    :span
    |> Phoenix.HTML.Tag.content_tag([ascii, "(", id, ")"], tag_opts)
  end

  # removes any vehicles that appear in given list
  defp unique_trains(vehicles_1, vehicles_2, ascii) do
    Enum.reject(vehicles_1, & &1 in vehicles_2) |> Enum.map(&{ascii, &1})
  end

  defp vehicles_with_status(vehicles, status) do
    Enum.filter(vehicles, & &1.current_status == status)
  end
end
