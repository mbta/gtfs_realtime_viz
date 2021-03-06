defmodule GTFSRealtimeVizTest do
  use ExUnit.Case

  alias GTFSRealtimeViz.Proto
  alias Test.DataHelpers

  test "when all vehicles have stop ids, does not have a no stop id section" do
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
              route_id: "route",
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

    GTFSRealtimeViz.new_message(:test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:test, %{routes: %{"route" => [{"stop", "this_is_the_stop_id", "outbound"}]}})

    refute viz =~ "No Stop ID:"
    assert viz =~ "this_is_the_vehicle_id"
  end

  test "when the prediction does not have a stop id, puts the vehicle in a separate location" do
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
              route_id: "route",
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
            stop_id: nil,
          }
        }
      ]
    }

    raw = Proto.FeedMessage.encode(data)

    GTFSRealtimeViz.new_message(:nil_test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:nil_test, %{routes: %{"route" => [{"stop", "this_is_the_stop_id", "outbound"}]}})

    assert viz =~ "No Stop ID:"
    assert viz =~ "this_is_the_vehicle_id"
  end

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
              route_id: "route",
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

    GTFSRealtimeViz.new_message(:test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:test, %{routes: %{"route" => [{"stop", "this_is_the_stop_id", "outbound"}]}})

    assert viz =~ "this is the test data"
    assert viz =~ "this_is_the_vehicle_id"
  end

  test "displays info about the stops given in for the route" do
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
              route_id: "Route",
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

    GTFSRealtimeViz.new_message(:test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:test, %{routes: %{"Route" => [{"First Stop", "this_is_the_stop_id", "124"}, {"Middle Stop", "125", "126"}, {"End Stop", "127", "128"}]}})

    assert viz =~ "this is the test data"
    assert viz =~ "this_is_the_vehicle_id"
    assert viz =~ "First Stop"
    assert viz =~ "Middle Stop"
    assert viz =~ "End Stop"
  end

  test "displays info about each route in the options" do
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

    GTFSRealtimeViz.new_message(:test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:test, %{routes: %{"First Route" => [{"FR Only Stop", "this_is_the_stop_id", "124"}], "Second Route" => [{"SR Only Stop", "125", "126"}]}})

    assert viz =~ "First Route"
    assert viz =~ "FR Only Stop"
    assert viz =~ "Second Route"
    assert viz =~ "SR Only Stop"
  end

  test "Only displays the given routes, even if there is data about other routes" do
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
              route_id: "First Route",
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
        },
        %Proto.FeedEntity{
          id: "124",
          is_deleted: false,
          vehicle: %Proto.VehiclePosition{
            trip: %Proto.TripDescriptor{
              trip_id: "secondary_trip_id",
              route_id: "other_route",
              direction_id: 0,
            },
            vehicle: %Proto.VehicleDescriptor{
              id: "different_vehicle",
              label: "different_vehicle_label",
            },
            position: %Proto.Position{
              latitude: 1.00,
              longitude: 1.00,
            },
            stop_id: "126",
          }
        }
      ]
    }

    raw = Proto.FeedMessage.encode(data)

    GTFSRealtimeViz.new_message(:test, raw, "this is the test data")
    viz = GTFSRealtimeViz.visualize(:test, %{routes: %{"First Route" => [{"FR Only Stop", "this_is_the_stop_id", "124"}]}})

    refute viz =~ "other_route"
    refute viz =~ "different_vehicle"
    assert viz =~ "this_is_the_vehicle_id"
  end

  describe "vehicles_we_care_about/2" do
    test "removes vehicle positions at stop ids we dont care about" do
      routes_we_care_about = ["First Route"]
      state = [{"this is the test data",
                DataHelpers.proto_for_vehicle_positions(["this_is_the_vehicle_id"], "First Route")
               },
              {"this is the test data",
                DataHelpers.proto_for_vehicle_positions(["this_is_the_vehicle_id"], "First Route")
              },
              {"this is the test data",
                [DataHelpers.proto_for_vehicle_positions(["this_is_the_vehicle_id"], "Other Route"),
                DataHelpers.proto_for_vehicle_positions(["different_vehicle"], "First Route")]
              |> List.flatten
              }
            ]

      expected = [{"this is the test data",
                    DataHelpers.proto_for_vehicle_positions(["this_is_the_vehicle_id"], "First Route")
                   },
                   {"this is the test data",
                      DataHelpers.proto_for_vehicle_positions(["this_is_the_vehicle_id"], "First Route")
                     },
                   {"this is the test data",
                      DataHelpers.proto_for_vehicle_positions(["different_vehicle"], "First Route")
                   }]


      assert GTFSRealtimeViz.vehicles_we_care_about(state, routes_we_care_about) == expected
    end
  end

  describe "visualize_diff/3" do
    test "Does not show repeats" do
      base_data = %Proto.FeedMessage{
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
                route_id: "Route",
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
      diff_data = %Proto.FeedMessage{
        header: %Proto.FeedHeader{
          gtfs_realtime_version: "1.0",
        },
        entity: [
          %Proto.FeedEntity{
            id: "456",
            is_deleted: false,
            vehicle: %Proto.VehiclePosition{
              trip: %Proto.TripDescriptor{
                trip_id: "this_is_the_trip_id",
                route_id: "Route",
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

      base_raw = Proto.FeedMessage.encode(base_data)
      diff_raw = Proto.FeedMessage.encode(diff_data)

      opts = %{routes: %{"Route" => [{"First Stop", "this_is_the_stop_id", "124"}, {"Middle Stop", "125", "126"}, {"End Stop", "127", "128"}]}}
      GTFSRealtimeViz.new_message(:test_bucket_base_1, base_raw, "this is the base data")
      GTFSRealtimeViz.new_message(:test_bucket_diff_1, diff_raw, "this is the diff data")
      viz = GTFSRealtimeViz.visualize_diff(:test_bucket_base_1, :test_bucket_diff_1, opts)
      File.write!("output.html", viz)

      refute viz =~ "this_is_the_vehicle_id"
    end

    test "Shows trains when they are at separate stops" do
      base_data = %Proto.FeedMessage{
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
              route_id: "Route",
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
      diff_data = %Proto.FeedMessage{
        header: %Proto.FeedHeader{
          gtfs_realtime_version: "1.0",
        },
      entity: [
        %Proto.FeedEntity{
          id: "456",
          is_deleted: false,
          vehicle: %Proto.VehiclePosition{
            trip: %Proto.TripDescriptor{
              trip_id: "this_is_the_trip_id",
              route_id: "Route",
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
            stop_id: "separate_stop_id",
          }
        }
      ]
    }

      base_raw = Proto.FeedMessage.encode(base_data)
      diff_raw = Proto.FeedMessage.encode(diff_data)

      opts = %{routes: %{"Route" => [{"First Stop", "this_is_the_stop_id", "124"}, {"Middle Stop", "125", "126"}, {"End Stop", "127", "128"}]}}
      GTFSRealtimeViz.new_message(:test_base, base_raw, "this is the base data")
      GTFSRealtimeViz.new_message(:test_diff, diff_raw, "this is the diff data")
      viz = GTFSRealtimeViz.visualize_diff(:test_base, :test_diff, opts)
      File.write!("test_output.html", viz)

      assert viz =~ "this_is_the_vehicle_label"
    end

    test "shows predictions if we have them" do
      base_data = %Proto.FeedMessage{
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
                route_id: "Route",
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
      base_trips = %Proto.FeedMessage{
        header: %Proto.FeedHeader{
          gtfs_realtime_version: "1.0",
        },
        entity: [
          %Proto.FeedEntity{
            id: "124",
            trip_update: %Proto.TripUpdate{
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
                route_id: "Route",
                direction_id: 0,
              },
              vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{
                id: "this_is_the_vehicle_id",
                label: "this_is_the_vehicle_label",
                license_plate: nil
              }
            }
          }
        ]
      }

      diff_data = %Proto.FeedMessage{
        header: %Proto.FeedHeader{
          gtfs_realtime_version: "1.0",
        },
        entity: [
          %Proto.FeedEntity{
            id: "456",
            is_deleted: false,
            vehicle: %Proto.VehiclePosition{
              trip: %Proto.TripDescriptor{
                trip_id: "this_is_the_trip_id",
                route_id: "Route",
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

      diff_trips = %Proto.FeedMessage{
        header: %Proto.FeedHeader{
          gtfs_realtime_version: "1.0",
        },
        entity: [
          %Proto.FeedEntity{
            id: "124",
            trip_update: %Proto.TripUpdate{
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
                route_id: "Route",
                direction_id: 0,
              },
              vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{
                id: "this_is_the_vehicle_id",
                label: "this_is_the_vehicle_label",
                license_plate: nil
              }
            }
          }
        ]
      }

      base_raw = Proto.FeedMessage.encode(base_data)
      base_trip_raw = Proto.FeedMessage.encode(base_trips)
      diff_raw = Proto.FeedMessage.encode(diff_data)
      diff_trip_raw = Proto.FeedMessage.encode(diff_trips)

      opts = %{timezone: "US/Eastern", routes: %{"Route" => [{"First Stop", "this_is_the_stop_id", "124"}, {"Middle Stop", "125", "126"}, {"End Stop", "127", "128"}]}}
      GTFSRealtimeViz.new_message(:test_bucket_base_2, base_raw, base_trip_raw, "this is the base data")
      GTFSRealtimeViz.new_message(:test_bucket_diff_2, diff_raw, diff_trip_raw, "this is the diff data")
      viz = GTFSRealtimeViz.visualize_diff(:test_bucket_base_2, :test_bucket_diff_2, opts)

      refute viz =~ "this_is_the_vehicle_id"
    end

    test "works when we dont have one to one trip updates with vehicle positions" do
      base_data = %Proto.FeedMessage{
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
                route_id: "Route",
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
      base_trips = %Proto.FeedMessage{
        header: %Proto.FeedHeader{
          gtfs_realtime_version: "1.0",
        },
        entity: [
          %Proto.FeedEntity{
            id: "124",
            trip_update: %Proto.TripUpdate{
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
                route_id: "Route",
                direction_id: 0,
              },
              vehicle: %GTFSRealtimeViz.Proto.VehicleDescriptor{
                id: "this_is_the_vehicle_id",
                label: "this_is_the_vehicle_label",
                license_plate: nil
              }
            }
          }
        ]
      }

      diff_data = %Proto.FeedMessage{
        header: %Proto.FeedHeader{
          gtfs_realtime_version: "1.0",
        },
        entity: [
          %Proto.FeedEntity{
            id: "456",
            is_deleted: false,
            vehicle: %Proto.VehiclePosition{
              trip: %Proto.TripDescriptor{
                trip_id: "this_is_the_trip_id",
                route_id: "Route",
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

      base_raw = Proto.FeedMessage.encode(base_data)
      base_trip_raw = Proto.FeedMessage.encode(base_trips)
      diff_raw = Proto.FeedMessage.encode(diff_data)

      routes = %{routes: %{"Route" => [{"First Stop", "this_is_the_stop_id", "124"}, {"Middle Stop", "125", "126"}, {"End Stop", "127", "128"}]}}
      GTFSRealtimeViz.new_message(:test_bucket_base_3, base_raw, "this is the base data")
      GTFSRealtimeViz.new_message(:test_bucket_base_3, base_trip_raw, "this is the base data")
      GTFSRealtimeViz.new_message(:test_bucket_diff_3, diff_raw, "this is the diff data")
      viz = GTFSRealtimeViz.visualize_diff(:test_bucket_base_3, :test_bucket_diff_3, routes)

      refute viz =~ "this_is_the_vehicle_id"
    end
  end

  describe "trips_we_care_about/2" do
    test "removes predictions on routes we dont care about" do
      routes_we_care_about = ["First Route"]
      state = [{"this is the test data",
                [DataHelpers.proto_for_trip_updates("First Route")]
               },
              {"this is the test data",
                [DataHelpers.proto_for_trip_updates("First Route")]
              },
              {"this is the test data",
                [
                  DataHelpers.proto_for_trip_updates("First Route"),
                  DataHelpers.proto_for_trip_updates("Other Route")
                ]
              |> List.flatten
              }
            ]

      expected = [{"this is the test data",
                    [DataHelpers.proto_for_trip_updates("First Route")],
                   },
                   {"this is the test data",
                    [DataHelpers.proto_for_trip_updates("First Route")],
                     },
                   {"this is the test data",
                    [DataHelpers.proto_for_trip_updates("First Route")],
                   }]

      assert GTFSRealtimeViz.trips_we_care_about(state, routes_we_care_about) == expected
    end
  end

  describe "sort_by_time/1" do
    test "sorts the time list by time" do
      time_list = [{"12345", {~D[2018-01-03], ~D[2018-01-03]}}, {"12345", {~D[2018-01-02], ~D[2018-01-02]}}, {"11111", {~D[2018-01-01], ~D[2018-01-01]}}, {"11112", {~D[2018-01-05], ~D[2018-01-05]}}]
      result = GTFSRealtimeViz.sort_by_time(time_list)
      assert List.first(result) == {"11111", {~D[2018-01-01], ~D[2018-01-01]}}
    end
  end

  describe "sort_time_diff/2" do
    test "sorts all predictions by time" do
      base_list = [{"12345", {~D[2018-01-03], ~D[2018-01-03]}}, {"12345", {~D[2018-01-02], ~D[2018-01-02]}}, {"11111", {~D[2018-01-01], ~D[2018-01-01]}}, {"11112", {~D[2018-01-05], ~D[2018-01-05]}}]
      diff_list = [{"54321", {~D[2018-02-03], ~D[2018-02-03]}}, {"15243", {~D[2018-02-02], ~D[2018-02-02]}}, {"22222", {~D[2018-02-01], ~D[2018-02-01]}}, {"21111", {~D[2018-02-05], ~D[2018-02-05]}}]

      result = GTFSRealtimeViz.sort_time_diff(base_list, diff_list)
      assert List.first(result) == {{"11111", {~D[2018-01-01], ~D[2018-01-01]}}, {"22222", {~D[2018-02-01], ~D[2018-02-01]}}}
    end

    test "always gives two results per environment if it has two or more" do
      base_list = [{"12345", {~D[2018-01-03], ~D[2018-01-03]}}, {"12345", {~D[2018-01-02], ~D[2018-01-02]}}, {"11111", {~D[2018-01-01], ~D[2018-01-01]}}, {"11112", {~D[2018-01-05], ~D[2018-01-05]}}]
      diff_list = [{"54321", {~D[2018-02-03], ~D[2018-02-03]}}]

      result = GTFSRealtimeViz.sort_time_diff(base_list, diff_list)
      assert result == [{{"11111", {~D[2018-01-01], ~D[2018-01-01]}}, {"54321", {~D[2018-02-03], ~D[2018-02-03]}}}, {{"12345", {~D[2018-01-02], ~D[2018-01-02]}}, nil}]
    end
  end
end
