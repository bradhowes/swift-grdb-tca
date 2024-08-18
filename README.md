[![CI](https://github.com/bradhowes/SwiftDataTCA/actions/workflows/CI.yml/badge.svg)](https://github.com/bradhowes/SwiftDataTCA/actions/workflows/CI.yml)
[![COV](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bradhowes/54c92d8df32d9a1b64d945f2e76696f1/raw/SwiftDataTCA-coverage.json)](https://github.com/bradhowes/SwiftDataTCA/actions/workflows/CI.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-A31F34.svg)](https://opensource.org/licenses/MIT)

# Introduction

This is a fork of the [SwiftDataTCA](https://github.com/SouzaRodrigo61/SwiftDataTCA) repo by 
[Rodrigo Santos de Souza](https://github.com/SouzaRodrigo61) that I've used to explore how best to incorporate 
[SwiftData](https://developer.apple.com/documentation/swiftdata) into an application written using 
[The Composable Architecture v1.11.2 (TCA)](https://github.com/pointfreeco/swift-composable-architecture) library and tools.
My changes were done in Xcode 16.0 Beta using Swift 6 with _Complete Concurrency Checking_ enabled.

# Overview

The code contains two top-level TCA "features" (combination of a reducer and a SwiftUI view):

* [FromStateFeature](SwiftDataTCA/Views/FromState/FromStateFeature.swift) -- the list of movies to show and work with 
comes from a SwiftData query done in the feature
* [FromQueryFeature](SwiftDataTCA/Views/FromQuery/FromQueryFeature.swift) -- the list of movies to show and work with 
comes from a `@Query` macro in the SwiftUI view

Both features contain the same interface functionality, including:

* Adding a new "random" movie
* Sorting movies by title
* Searching by title content
* Swiping to mark as a favorite
* Swiping to delete a movie
* Selecting a movie to "drill-down" to a list of actors. This view too supports "drilling-down" to see the actor's movies.

Per TCA guidance, all UI activity lead to reducer actions that are performed in the feature's reducer logic, updating
internal feature state when necessary to cause a UI update.

The two features are quite similar and there is some duplication of code, but this was done to make the features 
self-contained.

## Drilling Down

The top-level views [FromStateView](SwiftDataTCA/Views/FromState/FromStateView.swift) and 
[FromQueryView](SwiftDataTCA/Views/FromQuery/FromQueryView.swift) start with a TCA `NavigationStack` view 
builder. The subsequent
`List` views define a `selection` attribute that toggles a private state in the view (not reflected in the store). When
this view state value changes, there is an `onChange` block that runs which sends an action to the store that indicates 
what item was tapped. 

The top-level reducers monitor the `path` actions and handle the selections made by the child views, 
[ActorMoviesView](SwiftDataTCA/Views/ActorMoviesFeature/ActorMoviesView.swift)
and
[MovieActorsView](SwiftDataTCA/Views/MovieActorsFeature/MovieActorsView.swift).
Note that this is a tad more verbose than that documented on TCA's [Pushing Features onto the 
Stack](https://pointfreeco.github.io/swift-composable-architecture/main/documentation/composablearchitecture/stackbasednavigation#Pushing-features-onto-the-stack)
page where the list item is a button which sends the action into the reducer, but IMO it better utilizes the SwiftUI
view hierarchy.

Each of the drill-down views can also change the favorite state of a movie, either via toolbar button in 
the `MovieActorsView` view, or via swiping in the `ActorMoviesView` view.

## Previews

The SwiftUI previews operate pretty much like in the simulator or on a physical device.

## SwiftData Use

For the most part, SwiftData functionality is not found in the features. Instead, they use value types derived from 
the model reference types via their `valueType` attrribute. The value types have the `persistentModelID` attribute of 
the model that they are based on. The value types do not contain relationships like their
model counterparts. Instead they provide functions that return the relations as a collection of value types that are
ordered in a desired way.

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

There are two sets of tests: old-school XCTest collection that works with TCA and the brand new 
[Swift Testing](https://github.com/apple/swift-testing) style collection that does not yet work well with TCA testing
functions and macros (as of TCA v1.11.12).

Most of the code is covered with unit tests. There are also [snapshot
tests](https://github.com/pointfreeco/swift-snapshot-testing) that run against the preview renders. These tests run on
GIthub but the comparison check is disabled -- the images generated with Xcode 16.0 Beta likely will not match those
generated by the older Xcode used in the integration pipeline.

## Original README

Below is the original contents of the "README" document found at the time of the fork.




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
