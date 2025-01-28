[![CI](https://github.com/bradhowes/swift-grdb-tca/actions/workflows/CI.yml/badge.svg)](https://github.com/bradhowes/swift-grdb-tca/actions/workflows/CI.yml)
[![COV](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bradhowes/54c92d8df32d9a1b64d945f2e76696f1/raw/swift-grdb-tca-coverage.json)](https://github.com/bradhowes/swift-grdb-tca/actions/workflows/CI.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-A31F34.svg)](https://opensource.org/licenses/MIT)

# Introduction

This is a simple app that uses SwiftUI for views, [The Composable Architecture v1.11.2
(TCA)](https://github.com/pointfreeco/swift-composable-architecture) framework for managing logic and state, and
[GRDB](https://github.com/groue/GRDB.swift) for backend storage. This was originally a branch of my
[SwiftDataTCA](https://github.com/bradhowes/SwiftDataTCA) app that I used for experimenting with SwiftData, but
switching the branches was a pain with Xcode, so a new repo it is.

The code here is using the `@SharedReader` feature described in [Point\*Free](https://pointfree.co) episodes about GRDB
-- a version of this macro can be found in the
[GRDBDemo](https://github.com/pointfreeco/swift-sharing/tree/main/Examples/GRDBDemo) app of their
[swift-sharing](https://github.com/pointfreeco/swift-sharing) package. Works pretty well!

# Overview

The code contains a top-level TCA "feature" (combination of a reducer and a SwiftUI view) called
[FromStateFeature](swiftui-grdb-tca/Views/FromState/FromStateFeature.swift). It shows a list of movies
and the names of the actors associated with the movie.

From this view you can:

* Add a new "random" movie
* Sort movies by title
* Search by title content
* Swipe to mark as a favorite
* Swipe to delete a movie
* Select a movie to "drill-down" to a list of actors. This view too supports "drilling-down" to see the actor's movies. This can
be done as much as you want, though unwinding gets to be a bit tiring.

Per TCA guidance, all UI activity lead to reducer actions that are performed in the feature's reducer logic, updating
internal feature state when necessary to cause a UI update.

## Drilling Down

The top-level views [FromStateView](SwiftDataTCA/Views/FromState/FromStateView.swift) and 
[FromQueryView](SwiftDataTCA/Views/FromQuery/FromQueryView.swift) start with a TCA `NavigationStack` view 
builder. The subsequent
`List` views define `NavigationLink` elements for each movie or actor in the view. These drive the transitions into
the next view, and record the path for the `Back` button to follow when moving back up.

The top-level reducers monitor the `path` actions and handle the selections made by the child views, 
[ActorMoviesView](SwiftDataTCA/Views/ActorMoviesFeature/ActorMoviesView.swift)
and
[MovieActorsView](SwiftDataTCA/Views/MovieActorsFeature/MovieActorsView.swift).
This is pretty much as what is documented on TCA's [Pushing Features onto the 
Stack](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/stackbasednavigation#Pushing-features-onto-the-stack)
page.

Each of the drill-down views can also change the favorite state of a movie, either via toolbar button in 
the `MovieActorsView` view, or via swiping in the `ActorMoviesView` view. When a parent view comes back into view, it 
updates to account for any possible changes made by a popped view.

## Previews

The SwiftUI previews operate pretty much like in the simulator or on a physical device.

## SwiftData Use

For the most part, SwiftData functionality is not found in the features. Instead, they use value types in the latest 
schema (v6) derived from the model reference types via their `valueType` attrribute. 
The value types have the `persistentModelID` attribute of 
the model that they are based on. The value types do not contain relationships like their
model counterparts. Instead they provide functions that return the relations as a collection of value types that are
ordered in a desired way.

The `Database` struct prvides an abstraction the the features use to interact with the SwiftData backend. It currently
offers 4 functions:

- fetchMovies -- return the collection of movies for a given SwiftData `FetchDescriptor`
- add -- create a new movie and add it to the database
- delete -- delete an existing movie
- save -- save to the database any changes that have been made to existing models

Per TCA guidance, there are live, test, and preview instances of this `Database` instance depending on the runtime 
environment. Since the differences are found in the underlying model context (which is also a dependency), the live
and test instances are basically the same, but with different `ModelContainer` and `ModelContext` instances.

## Schemas

Currently, there are 6 schemas defined by the application -- two were from the fork. There are migrations from one to 
the next. The migrations to v3 and v4 are complex migrations:

* v3 contains a new `sortableTitle` attribute on the Movie entity
* v4 contains a new `Actor` entity and establishes many-to-many relationship between it and `Movie` entity
* v5 contains the same models, but removes the `id` attribute that was populated with a UUID value
* v6 contains the same models but renames them to have a "Model" suffix. This was done to allow the names without 
"Model" to refer to the value type based on the model.

There are defined migrations from one schema to the next. The migrations have tests that validate the migration
behavior. This is one area that is not well documented in the current Swift Data documentation, and the migrations may
not be optimal, but they do appear to do the right thing.

## Tests

There are four sets of tests that exercise the code:

* old-school XCTest collection that exercises the TCA routing and other non-UI code
* new-school [Swift Testing](https://github.com/apple/swift-testing) style collections that for now replicate old-school
schema tests
* [snapshot tests](https://github.com/pointfreeco/swift-snapshot-testing) that run against the preview renders.
These tests run on GIthub but the comparison check is disabled -- the images generated with Xcode 16.0 likely will not 
match those generated by the older Xcode used in the integration pipeline.
* [UI tests](https://developer.apple.com/documentation/xctest/user_interface_tests) that attempt to exercise some flows
while running under the app in a simulator.

> [!NOTE]
> Due to how the in-memory SwiftData containers are implemented, tests that rely them cannot
> run in parallel mode. Doing so will result in random test failures and crashes.

## Original README

Below is the original contents of the "README" document found at the time of the fork.

```


```

# Movie App with SwiftData and PointFree Composable Architecture

This is a sample application that demonstrates the power of the PointFree Composable Architecture (TCA) in combination 
with Apple's SwiftData for data persistence.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction

This project is a demonstration of how to implement SwiftData and the PointFree Composable Architecture (TCA) in an iOS 
application. It provides a clear and concise example of how to integrate these two powerful tools to build efficient 
and maintainable iOS apps.

## Features

- **Sample Implementation**: The project is a simple implementation that highlights the integration of SwiftData for 
data persistence and TCA for a functional and predictable architecture.

- **SwiftData Integration**: SwiftData is used to illustrate the ease of data persistence in iOS applications, making 
it a valuable addition to your toolbox.

- **TCA Showcase**: The project demonstrates how TCA can be used to structure your app's architecture, making it easier 
to understand and manage the application's behavior and state.


## Getting Started

To get started with this project, follow these steps:

1. **Clone the Repository**:
2. **Open Xcode**:
3. **Build and Run**:
Build and run the project in Xcode to see the Movie app in action.

## Usage

You are encouraged to use this project as a reference to understand how to implement SwiftData and TCA in your own iOS 
applications. The sample code provided here can help you kickstart your projects and build efficient, maintainable apps.

## Contributing

If you'd like to contribute to this project, please follow the [CONTRIBUTING.md](CONTRIBUTING.md) guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
