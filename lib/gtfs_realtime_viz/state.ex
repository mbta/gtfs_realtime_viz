defmodule GTFSRealtimeViz.State do
  @moduledoc false

  use GenServer

  alias GTFSRealtimeViz.Proto

  @type state :: %{optional(term) => [{String.t, [Proto.vehicle_position]}]}

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @spec init(:ok) :: {:ok, state}
  def init(:ok) do
    {:ok, %{vehicles: %{}, trip_updates: %{}}}
  end

  # client interface

  @spec new_data(GenServer.server, term, Proto.raw, String.t) :: :ok
  def new_data(pid \\ __MODULE__, group, raw, comment)
  def new_data(pid, group, raw, comment) do
    data =
      raw
      |> Proto.FeedMessage.decode
      |> Map.get(:entity)
    vehicles = Enum.map(data, & &1.vehicle) |> Enum.reject(& &1 == nil)
    trip_updates = Enum.map(data, & &1.trip_update) |> Enum.reject(& &1 == nil)

    if !Enum.empty?(vehicles) do
      GenServer.call(pid, {:vehicles, group, vehicles, comment})
    end
    if !Enum.empty?(trip_updates) do
      GenServer.call(pid, {:trip_updates, group, trip_updates, comment})
    end
  end

  @spec vehicles(GenServer.server, term) :: [{String.t, [Proto.vehicle_position]}]
  def vehicles(pid \\ __MODULE__, group)
  def vehicles(pid, group) do
    pid
    |> GenServer.call({:vehicles, group})
    |> Enum.reverse
  end

  def trip_updates(pid \\ __MODULE__, group)
  def trip_updates(pid, group) do
    pid
    |> GenServer.call({:trip_updates, group})
    |> Enum.reverse
  end

  # server callbacks

  def handle_call({:vehicles, group, vehicles, comment}, _from, state) do
    new_vehicles = update_in(state.vehicles, [Access.key(group, [])], fn prev_msgs ->
      max = max_archive()
      msgs = [{comment, vehicles} | prev_msgs]
      if max == :infinity do
        msgs
      else
        Enum.take(msgs, max)
      end
    end)

    {:reply, :ok, %{state | vehicles: new_vehicles}}
  end
  def handle_call({:vehicles, group}, _from, state) do
    case state.vehicles[group] do
      nil -> {:reply, [], state}
      vehicles -> {:reply, vehicles, state}
    end
  end

  def handle_call({:trip_updates, group, trip_updates, comment}, _from, state) do
    new_trip_updates = update_in(state.trip_updates, [Access.key(group, [])], fn prev_msgs ->
      max = max_archive()
      msgs = [{comment, trip_updates} | prev_msgs]
      if max == :infinity do
        msgs
      else
        Enum.take(msgs, max)
      end
    end)

    {:reply, :ok, %{state | trip_updates: new_trip_updates}}
  end
  def handle_call({:trip_updates, group}, _from, state) do
    {:reply, state.trip_updates[group] || [], state}
  end

  defp max_archive, do: Application.get_env(:gtfs_realtime_viz, :max_archive)
end
