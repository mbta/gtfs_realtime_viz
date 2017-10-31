defmodule GTFSRealtimeViz.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      GTFSRealtimeViz.State,
    ]

    opts = [strategy: :one_for_one, name: GTFSRealtimeViz.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
