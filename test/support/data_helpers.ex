defmodule Test.DataHelpers do
  alias GTFSRealtimeViz.Proto

  def proto_for_vehicle_ids(vehicle_ids) do
    %Proto.FeedMessage{
      header: %Proto.FeedHeader{
        gtfs_realtime_version: "1.0",
      },
      entity: Enum.map(vehicle_ids, fn vehicle_id ->
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
              id: vehicle_id,
              label: "this_is_the_vehicle_label",
            },
            position: %Proto.Position{
              latitude: 0.00,
              longitude: 0.00,
            },
            stop_id: "this_is_the_stop_id",
          }
        }
      end)
    }
    |> Proto.FeedMessage.encode
  end
end
