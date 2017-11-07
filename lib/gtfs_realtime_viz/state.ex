defmodule GTFSRealtimeViz.State do
  use GenServer

  alias GTFSRealtimeViz.Proto

  @type state :: %{optional(term) => [{String.t, [Proto.vehicle_position]}]}

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @spec init(:ok) :: {:ok, state}
  def init(:ok) do
    {:ok, %{}}
  end

  # client interface

  @spec new_data(GenServer.server, term, Proto.raw, String.t) :: :ok
  def new_data(pid \\ __MODULE__, group, raw, comment)
  def new_data(pid, group, raw, comment) do
    vehicles =
      raw
      |> Proto.FeedMessage.decode
      |> Map.get(:entity)
      |> Enum.map(& &1.vehicle)

    GenServer.call(pid, {:vehicles, group, vehicles, comment})
  end

  @spec vehicles(GenServer.server, term) :: [{String.t, [Proto.vehicle_position]}]
  def vehicles(pid \\ __MODULE__, group)
  def vehicles(pid, group) do
    pid
    |> GenServer.call({:vehicles, group})
    |> Enum.reverse
  end

  # server callbacks

  def handle_call({:vehicles, group, vehicles, comment}, _from, state) do
    new_state = update_in(state, [Access.key(group, [])], fn prev_msgs ->
      Enum.take([{comment, vehicles} | prev_msgs], max_archive())
    end)

    {:reply, :ok, new_state}
  end
  def handle_call({:vehicles, group}, _from, state) do
    {:reply, state[group], state}
  end

  defp max_archive, do: Application.get_env(:gtfs_realtime_viz, :max_archive)
end
