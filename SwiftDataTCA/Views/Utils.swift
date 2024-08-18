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
      movie.actors(ordering: .forward)
        .map { $0.name }
        .formatted(.list(type: .and))
    }

    var body: some View {
      HStack(spacing: 8) {
        VStack(alignment: .leading) {
          Text(movie.name)
            .font(.headline)
            .foregroundStyle(movie.favorite ? .blue : .black)
          Text(actorNames)
            .font(.caption2)
        }
        Spacer()
        Image(systemName: "chevron.forward")
          .font(.footnote.bold())
          .foregroundColor(Color(UIColor.tertiaryLabel))
      }
    }
  }

  struct ActorView: View {
    let actor: Actor
    var movieTitles: String {
      actor.movies(ordering: .forward)
        .map { $0.name }
        .formatted(.list(type: .and))
    }

    var body: some View {
      HStack(spacing: 8) {
        VStack(alignment: .leading) {
          Text(actor.name)
            .font(.headline)
          Text(movieTitles)
            .font(.caption2)
        }
        Spacer()
        Image(systemName: "chevron.forward")
          .font(.footnote.bold())
          .foregroundColor(Color(UIColor.tertiaryLabel))
      }
    }
  }

  static func favoriteSwipeAction(_ movie: Movie, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Label("Favorite", systemImage: "star")
    }
    .tint(.blue)
  }

  static func deleteSwipeAction(_ movie: Movie, action: @escaping () -> Void) -> some View {
    Button(role: .destructive, action: action) {
      Label("Delete", systemImage: "trash")
    }
  }
}
