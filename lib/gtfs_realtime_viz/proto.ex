defmodule GTFSRealtimeViz.Proto do
  use Protobuf, from: Path.expand("../../config/gtfs-realtime.proto", __DIR__)

  alias GTFSRealtimeViz.Proto

  @type raw :: bitstring

  @type feed_message :: %Proto.FeedMessage{
    header: feed_header,
    entity: [feed_entity],
  }

  @type feed_header :: %Proto.FeedHeader{
    gtfs_realtime_version: String.t,
    incrementality: nil | :FULL_DATASET | :DIFFERENTIAL,
    timestamp: nil | integer,
  }

  @type feed_entity :: %Proto.FeedEntity{
    id: String.t,
    is_deleted: boolean,
    trip_update: nil | trip_update,
    vehicle: nil | vehicle_position,
    alert: nil | alert,
  }

  @type trip_update :: %Proto.TripUpdate{
    trip: trip_descriptor,
    vehicle: nil | vehicle_descriptor,
    stop_time_update: [trip_update_stop_time_update],
    timestamp: nil | integer,
    delay: nil | integer,
  }

  @type trip_update_stop_time_event :: %Proto.TripUpdate.StopTimeEvent{
    delay: nil | integer,
    time: nil | integer,
    uncertainty: nil | integer,
  }

  @type trip_update_stop_time_update :: %Proto.TripUpdate.StopTimeUpdate{
    stop_sequence: nil | integer,
    stop_id: nil | String.t,
    arrival: nil | trip_update_stop_time_event,
    departure: nil | trip_update_stop_time_event,
    schedule_relationship: nil | :SCHEDULED | :SKIPPED | :NO_DATA
  }

  @type vehicle_position :: %Proto.VehiclePosition{
    trip: nil | trip_descriptor,
    vehicle: nil | vehicle_descriptor,
    position: nil | position,
    current_stop_sequence: nil | integer,
    stop_id: nil | String.t,
    current_status: nil | :INCOMING_AT | :STOPPED_AT | :IN_TRANSIT_TO,
    timestamp: nil | integer,
    congestion_level: nil | :UNKNOWN_CONGESTION_LEVEL | :RUNNING_SMOOTHLY | :STOP_AND_GO | :CONGESTION | :SEVERE_CONGESTION,
    occupancy_status: nil | :EMPTY | :MANY_SEATS_AVAILABLE | :FEW_SEATS_AVAILABLE | :STANDING_ROOM_ONLY | :CRUSHED_STANDING_ROOM_ONLY | :FULL | :NOT_ACCEPTING_PASSENGERS,
  }

  @type alert :: %Proto.Alert{
    active_period: [time_range],
    informed_entity: [entity_selector],
    cause: nil | :UNKNOWN_CAUSE | :OTHER_CAUSE | :TECHNICAL_PROBLEM | :STRIKE | :DEMONSTRATION | :ACCIDENT | :HOLIDAY | :WEATHER | :MAINTENANCE | :CONSTRUCTION | :POLICE_ACTIVITY | :MEDICAL_EMERGENCY,
    effect: nil | :NO_SERVICE | :REDUCED_SERVICE | :SIGNIFICANT_DELAYS | :DETOUR | :ADDITIONAL_SERVICE | :OTHER_EFFECT | :UNKNOWN_EFFECT | :STOP_MOVED,
    url: nil | translated_string,
    header_text: nil | translated_string,
    description_text: nil | translated_string,
  }

  @type time_range :: %Proto.TimeRange{
    start: nil | integer,
    end: nil | integer,
  }

  @type position :: %Proto.Position{
    latitude: float,
    longitude: float,
    bearing: nil | float,
    odometer: nil | float,
    speed: nil | float,
  }

  @type trip_descriptor :: %Proto.TripDescriptor{
    trip_id: nil | String.t,
    route_id: nil | String.t,
    direction_id: nil | integer,
    start_time: nil | String.t,
    start_date: nil | String.t,
    schedule_relationship: nil | :SCHEDULED | :ADDED | :UNSCHEDULED | :CANCELED,
  }

  @type vehicle_descriptor :: %Proto.VehicleDescriptor{
    id: nil | String.t,
    label: nil | String.t,
    license_plate: nil | String.t,
  }

  @type entity_selector :: %Proto.EntitySelector{
    agency_id: nil | String.t,
    route_id: nil | String.t,
    route_type: nil | integer,
    trip: nil | trip_descriptor,
    stop_id: nil | String.t,
  }

  @type translated_string :: %Proto.TranslatedString{
    translation: [translated_string_translation],
  }

  @type translated_string_translation :: %Proto.TranslatedString.Translation{
    text: String.t,
    language: nil | String.t,
  }
end
