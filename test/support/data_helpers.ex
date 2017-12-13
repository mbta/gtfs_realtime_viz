defmodule Test.DataHelpers do
  alias GTFSRealtimeViz.Proto

  def proto_for_vehicle_ids(vehicle_ids) do
    %Proto.FeedMessage{
      header: %Proto.FeedHeader{
        gtfs_realtime_version: "1.0",
      },
      entity: proto_for_feed_entity(vehicle_ids)
    }
    |> Proto.FeedMessage.encode
  end

  defp proto_for_feed_entity(vehicle_ids) do
    Enum.map(vehicle_ids, fn vehicle_id ->
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
  end

  def proto_for_vehicle_positions(vehicle_ids, route_id) do
    Enum.map(vehicle_ids, fn vehicle_id ->
        %Proto.VehiclePosition{
          trip: %Proto.TripDescriptor{
            trip_id: "this_is_the_trip_id",
            route_id: route_id,
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
    end)

  end

  def proto_for_trip_updates(route) do
    %Proto.TripUpdate{
      delay: nil,
      stop_time_update: [
        %GTFSRealtimeViz.Proto.TripUpdate.StopTimeUpdate{
          arrival: %GTFSRealtimeViz.Proto.TripUpdate.StopTimeEvent{
            delay: nil,
            time: 1512760579,
            uncertainty: nil
          },
          departure: %GTFSRealtimeViz.Proto.TripUpdate.StopTimeEvent{
            delay: nil,
            time: 1512760579,
            uncertainty: nil
          },
          schedule_relationship: :SCHEDULED,
          stop_id: "this_is_the_stop_id",
          stop_sequence: 280
        }
      ],
      timestamp: nil,
      trip: %Proto.TripDescriptor{
        trip_id: "this_is_the_trip_id",
        route_id: route,
        direction_id: 0,
      },
      vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{
        id: "this_is_the_vehicle_id",
        label: "this_is_the_vehicle_label",
        license_plate: nil
      }
    }
  end
end
