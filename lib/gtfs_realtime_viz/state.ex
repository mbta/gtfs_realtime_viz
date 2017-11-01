defmodule GTFSRealtimeViz.State do
  use GenServer

  alias GTFSRealtimeViz.Proto

  @max_archive Application.get_env(:gtfs_realtime_viz, :max_archive)

  @type state :: [{String.t, [Proto.vehicle_position]}]

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @spec init(:ok) :: {:ok, state}
  def init(:ok) do
    {:ok, []}
  end

  # client interface

  @spec new_data(GenServer.server, Proto.raw) :: :ok
  def new_data(pid \\ __MODULE__, raw, comment)
  def new_data(pid, raw, comment) do
    vehicles =
      raw
      |> Proto.FeedMessage.decode
      |> Map.get(:entity)
      |> Enum.map(& &1.vehicle)

    GenServer.call(pid, {:vehicles, vehicles, comment})
  end

  @spec vehicles(GenServer.server) :: [Proto.vehicle_position]
  def vehicles(pid \\ __MODULE__)
  def vehicles(pid) do
    GenServer.call(pid, :vehicles)
  end

  # server callbacks

  def handle_call({:vehicles, vehicles, comment}, _from, state) do
    new_state = Enum.take([{comment, vehicles} | state], @max_archive)
    {:reply, :ok, new_state}
  end
  def handle_call(:vehicles, _from, state) do
    {:reply, state, state}
  end
end
