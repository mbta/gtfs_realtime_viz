# Changelog

## 0.10.0
 * Change in visualization:
   * Do not put trains that have no stop id in the route ladders.
   * Show the vehicle ids of trains with no stop id at the top of the page.

## 0.9.0
 * Change in  visualization:
  * Show next three predictions, rather than 2.

## 0.8.0
* Changes in visualization:
  * Include whether times are for arrival or departure
  * Include "minutes away" calculation
  * Re-arrange table to have transit->incoming->stopped go vertical

## 0.7.1
* If we don't provide routes to filter, we don't filter anything

## 0.7.0
* Uses vehicle label rather than ID in the diff view
* If a route has no stops configured, hide it from the ladder view

## 0.6.2
* Removes the dependency on trip id being the same between diffed environments so
  that earlier trips will correctly be shown even when trip ids do not match

## 0.6.1
* Fixes a bug where trips were sorted by trip_id instead of by vehicle arrival time

## 0.6.0

* Diff visualization hides predictions which are the same in both files.
* Diff visualization highlights all predictions for a trip on mouseover.
* Stop IDs that are the same in both directions are correctly distinguished.

## 0.5.0

* Visualizer can now display predictions alongside the vehicle positions in the ladder view,
  if given a TripUpdates.pb file.

**Backwards Incompatible Changes**
* Routes should now be passed in as part of an opts map in the form
  `%{routes: %{"Route Name" => [{station list}]}}`

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
