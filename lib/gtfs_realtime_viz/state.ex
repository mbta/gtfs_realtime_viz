defmodule GTFSRealtimeViz.State do
  use GenServer

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @spec init(:ok) :: [GTFSRealtimeViz.Proto]
  def init(:ok) do
    {:ok, []}
  end

  # client interface

  def new_data(pid \\ __MODULE__, raw) do
    vehicles =
      raw
      |> GTFSRealtimeViz.Proto.FeedMessage.decode
      |> Map.get(:entity)
      |> Enum.map(& &1.vehicle)

    GenServer.call(pid, {:vehicles, vehicles})
  end

  def vehicles(pid \\ __MODULE__) do
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
