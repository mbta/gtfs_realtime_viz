# Changelog

## 0.5.0

* Visualizer can now display predictions alongside the vehicle positions in the ladder view,
  if given a TripUpdates.pb file.

## 0.4.0

* Visualizer now uses the vehicle label instead of vehicle ID

## 0.3.0

* New function `visualize_diff/3` renders differences between two groups of protobuf files.

## 0.2.0

Adds filtering by route.

**Backwards Incompatible Changes**
* Ladder visualization is no longer configured by `config :realtime_gtfs_viz, :routes`, but is
  instead done at runtime as an argument passed to the `visualize/2` (previously `visualize/1`)
  function.
* Config of a route used to be a list of lists, now it's a list of tuples. E.g.,
  `"Route" => [["Station", 123, 234]]` is now `"Route" => [{"Station", 123, 234}]`.

## 0.1.1

Initial release!
