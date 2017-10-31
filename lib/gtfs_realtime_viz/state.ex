defmodule GTFSRealtimeViz.State do
  use GenServer

  alias GTFSRealtimeViz.Proto

  @type state :: [Proto.vehicle_position]

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
  def new_data(pid \\ __MODULE__, raw)
  def new_data(pid, raw) do
    vehicles =
      raw
      |> Proto.FeedMessage.decode
      |> Map.get(:entity)
      |> Enum.map(& &1.vehicle)

    GenServer.call(pid, {:vehicles, vehicles})
  end

  @spec vehicles(GenServer.server) :: [Proto.vehicle_position]
  def vehicles(pid \\ __MODULE__)
  def vehicles(pid) do
    GenServer.call(pid, :vehicles)
  end

  # server callbacks

  def handle_call({:vehicles, vehicles}, _from, _state) do
    {:reply, :ok, vehicles}
  end
  def handle_call(:vehicles, _from, state) do
    {:reply, state, state}
  end
end
