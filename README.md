# GTFSRealtimeViz

This app visualizes the Vehicle Position data from a [GTFS Realtime](https://github.com/google/transit/tree/master/gtfs-realtime) protobuf file.

It lists all the vehicles in a table, and if configured with stop IDs and stop names, can display a simple ASCII art ladder diagram.

You can also feed it a series of protobuf files and page through the visualizations.

## Installation

This tool can be run either standalone or as a dependency of another project. To include it in another project, add it to your dependencies as follows:

```elixir
def deps do
  [
    {:gtfs_realtime_viz, "~> 0.3.0"},
  ]
end
```

To run it standalone, just clone this repository.

In both cases, run `mix deps.get` afterwards.

## Configuration

There are three configuration options.

The first two are `routes` and `timezone`, which will tell the tool to generate a simple ASCII art ladder diagram, and which time zone to display predictions in. `routes` is a map of all the routes you want ladders for, and a list of stations along that route in order. Each station is a list of three items: the station name you want displayed on the ladder, the stop ID for `direction_id == 0` and the stop ID for `direction_id == 1` at that station. Timezone is a string representing the time zone that should be used, ie: `"US/Eastern"`. This will be passed into visualize as the second argument.

For example:

``` ex
routes = %{
  "Mattapan" => [
    {"Ashmont", "70261", "70262"},
    {"Cedar Grove", "70263", "70264"},
    {"Butler", "70265", "70266"},
    {"Milton", "70267", "70268"},
    {"Central Ave", "70269", "70270"},
    {"Valley Road", "70271", "70272"},
    {"Capen St.", "70273", "70274"},
    {"Mattapan", "70275", "70276"},
  ]
}
timezone = "US/Eastern"

opts = %{routes: routes, timezone: timezone}

GTFSRealtimeViz.visualize(:prod, opts)
```

The second configuration option is `max_archive` and determines how many protobuf messages the app will store. The visualization generates static HTML that allows you to page through visualizations, so the page can grow quite large if you configure a large `max_archive`. For cases where you're not worried about running out of memory (say, experimenting or debugging locally), you can use `:infinity`. An example configuration might be:

``` ex
config :gtfs_realtime_viz, :max_archive, 5
```

## Use

This app runs a GenServer that stores protobuf data sent to it, and which can render the messages its received as HTML. Whether running standalone or within another application, the interface for interacting with the tool is the `GTFSRealtimeViz` module.

First you send raw protobuf data to it with `GTFSRealtimeViz.new_message/3`. The first argument specifies what type of data it is, if you want to send data, say, from multiple environments. The second argument is the protobuf data, and the third is a comment about that data. For example, if you have the data saved locally in a file, you might do:

```ex
iex> GTFSRealtimeViz.new_message(:prod, File.read!("/path/to/file.pb"), "This is my PB file")
```

Note that a GTFS Realtime message can have Vehicle Positions, Trip Updates, or Alerts. This tool currently only uses Vehicle Positions and will ignore anything else it's sent.

As you send multiple messages to the app, it will store them all, up to the configured `max_archive` per grouping, at which point it will evict older messages.

To generate HTML, run `GTFSRealtimeViz.visualize/1`. This will return a `String.t` of HTML. It's just a fragment (e.g., it lacks `<html>` tags and the like), but if you save it and open it in a browser, most browsers should display it just fine. Alternatively, if you're using this in another application, because it's just a fragment, you should be able to render the string within the frame of the other application.

If you just want a standalone file to open in a browser, you might run:

```ex
iex> File.write!("/path/to/file.html", GTFSRealtimeViz.visualize(:prod, %{routes: %{"Route" => [{"First stop", "123", "124"},  {"Second stop" , "125", "126"}]}, timezone: "US/Eastern"}))
```
