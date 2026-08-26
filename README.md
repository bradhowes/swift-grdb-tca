[![CI][status]][ci]
[![COV][cov]][ci]
[![License: MIT][mit]][license]

# Introduction

This is a simple app that uses SwiftUI for views, [The Composable Architecture v1.26.1 (TCA)][1] framework for managing
logic and state, and [GRDB][2] for backend storage. This was originally a branch of my [SwiftDataTCA][3] app that I used
for experimenting with SwiftData, but switching the branches was a pain with Xcode, so a new repo it is.

![Demo GIF][demo]

The code here is using the `@SharedReader` feature described in [Point•Free episodes about SQLite and GRDB][12].

# Overview

The code contains a top-level TCA "feature" (combination of a reducer and a SwiftUI view) called [RootFeature][6].
It shows a list of movies and the names of the actors associated with the movie.

From this view you can:

* Add a new "random" movie
* Sort movies by title
* Search by title content
* Swipe to mark as a favorite
* Swipe to delete a movie
* Select a movie to "drill-down" to a list of actors. This view too supports "drilling-down" to see the actor's movies.
This can be done as much as you want, though unwinding gets to be a bit tiring.

Per TCA guidance, all UI activity lead to reducer actions that are performed in the feature's reducer logic, updating
internal feature state when necessary to cause a UI update.

## Drilling Down

The top-level view [RootView][7] starts with a TCA `NavigationStack` view builder. The subsequent `List` views define
`NavigationLink` elements for each movie or actor in the view. These drive the transitions into the next view, and
record the path for the `Back` button to follow when moving back up.

The top-level reducer in `RootFeature` monitors for `path` actions and handles the selections made by the child views,
[ActorMoviesView][8] and [MovieActorsView][9]. This is pretty much as what is documented on TCA's [Pushing Features onto
the Stack][10] page.

Each of the drill-down views can also change the favorite state of a movie, either via toolbar button in the
`MovieActorsView` view, or by swiping in the `ActorMoviesView` view. When a parent view comes back into view, it should
already show any changaes that were made in a child view.

The `ActorMoviesView` supports searching of movie titles, and the `MovieActorsView` supports searching of actor names.
Both of these (and the `RootView` as well) use the FTS5 SQLite plugin to perform full-text searching of content in the
movies and actors tables. Typing into the search field regenerates the SQL query that the views use to populate their
corresponding rows of actors and movies.

## Previews

The SwiftUI previews operate pretty much like in the simulator or on a physical device.

## GRDB Use

All GRDB activity is driven by activity in the feature reducers. Each state uses a `@SharedReader` property wrapper for
a container. This property is initialized with a GRDB query that will return a value for the container. When properties
change that affect the query, state activity will invoke `updateQuery` to update the `@SharedReader` query. This in turn
will cause the view to refresh when there are any updates.

The app communicates to its GRDB database by means of a DatabaseQueue instance that is available via the
`@Dependency(\.defaultDatabase)` attribute.

## Schemas

Unlike the SwiftDataTCA app, there is currently just 1 schema defined in the `Models` package in the file
[Schemav1.swift][11] file. The schema contains the GRDB Swift structs that map to SQL table definitions. Although this
is not as concise as the case with SwiftData, it is also much less mysterious -- properties and relationships are
spelled out in very readable form, and there is always the option to drop down into raw SQL if need be.

As mentioned above, the `movies` and `actors` tables have a related full-text search table. The GRDB intergration
creates the appropriate triggers to keep the full-text tables up-to-date when their source table changes.

## Tests

There are some...

[1]: https://github.com/pointfreeco/swift-composable-architecture
[2]: https://github.com/groue/GRDB.swift
[3]: https://github.com/bradhowes/SwiftDataTCA
[4]: https://github.com/pointfreeco/swift-sharing/tree/main/Examples/GRDBDemo
[5]: https://github.com/pointfreeco/swift-sharing
[6]: SwiftGRDBTCA/Views/Root/RootFeature.swift
[7]: SwiftGRDBTCA/Views/Root/RootView.swift
[8]: SwiftGRDBTCA/Views/ActorMoviesFeature/ActorMoviesView.swift
[9]: SwiftGRDBTCA/Views/MovieActorsFeature/MovieActorsView.swift
[10]: https://swiftpackageindex.com/pointfreeco/swift-composable-architecture/main/documentation/composablearchitecture/stackbasednavigation#Pushing-features-onto-the-stack
[11]: SwiftGRDBTCA/Packages/Sources/Models/SchemaV1.swift
[12]: https://www.pointfree.co/collections/sqlite

[demo]: media/demo.gif

[ci]: https://github.com/bradhowes/swift-grdb-tca/actions/workflows/CI.yml
[status]: https://github.com/bradhowes/swift-grdb-tca/actions/workflows/CI.yml/badge.svg
[cov]: https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bradhowes/b867d408459c766f8b95027edbcfd47d/raw/swift-grdb-tca-coverage.json
[mit]: https://img.shields.io/badge/License-MIT-A31F34.svg
[license]: https://opensource.org/licenses/MIT
