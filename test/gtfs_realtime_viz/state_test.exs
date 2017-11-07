defmodule GTFSRealtimeViz.StateTest do
  use ExUnit.Case, async: true

  alias GTFSRealtimeViz.State

  setup_all do
    {:ok, pid} = State.start_link(name: :test)
    %{state_pid: pid}
  end

  describe "adds and retrieves data" do
    test "retrieves data in order that it was added", %{state_pid: pid} do
      raw1 = Test.DataHelpers.proto_for_vehicle_ids(["veh_id_1"])
      raw2 = Test.DataHelpers.proto_for_vehicle_ids(["veh_id_2"])

      State.new_data(pid, :test1, raw1, "1st msg")
      State.new_data(pid, :test1, raw2, "2nd msg")

      assert [{"1st msg", _}, {"2nd msg", _}] = State.vehicles(pid, :test1)
    end
  end
end
