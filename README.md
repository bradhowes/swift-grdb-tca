# Note about Fork

This is a fork of the [SwiftDataTCA](https://github.com/SouzaRodrigo61/SwiftDataTCA) repo by 
[Rodrigo Santos de Souza](https://github.com/SouzaRodrigo61) that I've used to explore how best to incorporate SwiftData
in TCA (v1.11.2). My changes were done in Xcode 16.0 Beta using Swift 6 and complete concurrency checking enabled.

The code contains two TCA "features" (combination of a reducer and a SwiftUI view):

* FromState -- the list of movies to show and work with comes from a query done in the feature
* FromQuery -- the list of movies to show and work with comes from a `Query` in the SwiftUI view

Both SwiftUI views the same functionality, including:

* adding a new "random" movie
* sorting movies by title
* sorting movies by UUID
* searching by title content
* swiping to mark as a favorite
* swiping to delete a movie

Per TCA guidance, all UI activity lead to reducer actions that are performed in the feature's reducer logic, updating
internal feature state when necessary to cause a UI update.

The two features are quite similar and there is some duplication of code, but this was done to make the features 
self-contained.

![](https://github.com/bradhowes/SwiftDataTCA/blob/main/FromState.gif?raw=true)
![](https://github.com/bradhowes/SwiftDataTCA/blob/main/FromQuery.gif?raw=true)

Below is the original contents of the "README" document found at the time of the fork.

# Movie App with SwiftData and PointFree Composable Architecture

This is a sample application that demonstrates the power of the PointFree Composable Architecture (TCA) in combination with Apple's SwiftData for data persistence.

## Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Introduction

This project is a demonstration of how to implement SwiftData and the PointFree Composable Architecture (TCA) in an iOS application. It provides a clear and concise example of how to integrate these two powerful tools to build efficient and maintainable iOS apps.

## Features

- **Sample Implementation**: The project is a simple implementation that highlights the integration of SwiftData for data persistence and TCA for a functional and predictable architecture.

- **SwiftData Integration**: SwiftData is used to illustrate the ease of data persistence in iOS applications, making it a valuable addition to your toolbox.

- **TCA Showcase**: The project demonstrates how TCA can be used to structure your app's architecture, making it easier to understand and manage the application's behavior and state.


## Getting Started

To get started with this project, follow these steps:

1. **Clone the Repository**:
2. **Open Xcode**:
3. **Build and Run**:
Build and run the project in Xcode to see the Movie app in action.

## Usage

You are encouraged to use this project as a reference to understand how to implement SwiftData and TCA in your own iOS applications. The sample code provided here can help you kickstart your projects and build efficient, maintainable apps.


## Contributing

If you'd like to contribute to this project, please follow the [CONTRIBUTING.md](CONTRIBUTING.md) guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
