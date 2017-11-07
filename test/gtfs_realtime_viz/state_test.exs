defmodule GTFSRealtimeViz.StateTest do
  use ExUnit.Case

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

    test "respects max_archive and :infinity", %{state_pid: pid} do
      old_max_archive = Application.get_env(:gtfs_realtime_viz, :max_archive)
      on_exit fn ->
        Application.put_env(:gtfs_realtime_viz, :max_archive, old_max_archive)
      end
      msg = Test.DataHelpers.proto_for_vehicle_ids(["veh_id"])

      Application.put_env(:gtfs_realtime_viz, :max_archive, 1)
      State.new_data(pid, :test2, msg, "msg")
      State.new_data(pid, :test2, msg, "msg")
      assert [_msg] = State.vehicles(pid, :test2)

      Application.put_env(:gtfs_realtime_viz, :max_archive, :infinity)
      State.new_data(pid, :test2, msg, "msg")
      State.new_data(pid, :test2, msg, "msg")
      assert [_1, _2, _3] = State.vehicles(pid, :test2)
    end
  end
end
