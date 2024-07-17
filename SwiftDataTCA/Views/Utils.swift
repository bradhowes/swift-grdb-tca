import SwiftUI

enum Utils {
  static func pickerView(title: String, binding: Binding<SortOrder?>) -> some View {
    Picker(title, selection: binding) {
      Text(title + " ↑").tag(SortOrder?.some(.forward))
      Text(title + " ↓").tag(SortOrder?.some(.reverse))
      Text(title + " ⊝").tag(SortOrder?.none)
    }.pickerStyle(.automatic)
  }

  struct MovieView: View {
    let movie: Movie
    var actorNames: String {
      movie.actors
        .map { $0.name }
        .formatted(.list(type: .and))
    }

    var body: some View {
      VStack(alignment: .leading) {
        Text(movie.title)
          .font(.headline)
        Text(actorNames)
          .font(.caption2)
      }
      .background(movie.favorite ? .blue : .clear)
    }
  }

  struct ActorView: View {
    let actor: Actor
    var movieTitles: String {
      actor.movies
        .map { $0.title }
        .formatted(.list(type: .and))
    }

    var body: some View {
      VStack(alignment: .leading) {
        Text(actor.name)
          .font(.headline)
        Text(movieTitles)
          .font(.caption2)
      }
    }
  }
}
