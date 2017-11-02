defmodule GTFSRealtimeVizTest do
  use ExUnit.Case

  alias GTFSRealtimeViz.Proto

  test "visualizes a file" do
    data = %Proto.FeedMessage{
      header: %Proto.FeedHeader{
        gtfs_realtime_version: "1.0",
      },
      entity: [
        %Proto.FeedEntity{
          id: "123",
          is_deleted: false,
          vehicle: %Proto.VehiclePosition{
            trip: %Proto.TripDescriptor{
              trip_id: "this_is_the_trip_id",
              route_id: "this_is_the_route_id",
              direction_id: 0,
            },
            vehicle: %Proto.VehicleDescriptor{
              id: "this_is_the_vehicle_id",
              label: "this_is_the_vehicle_label",
            },
            position: %Proto.Position{
              latitude: 0.00,
              longitude: 0.00,
            },
            stop_id: "this_is_the_stop_id",
          }
        }
      ]
    }

    raw = Proto.FeedMessage.encode(data)

    GTFSRealtimeViz.new_message(raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize()

    assert viz =~ "this is the test data"
    assert viz =~ "this_is_the_vehicle_id"
  end
end
