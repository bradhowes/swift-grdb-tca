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
    let movie: MovieModel
    var actorNames: String {
      Support.sortedActors(for: movie, order: .forward)
        .map { $0.name }
        .formatted(.list(type: .and))
    }

    var body: some View {
      HStack(spacing: 8) {
        VStack(alignment: .leading) {
          Text(movie.title)
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
    let actor: ActorModel
    var movieTitles: String {
      Support.sortedMovies(for: actor, order: .forward)
        .map { $0.title }
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

  static func favoriteSwipeAction(_ movie: MovieModel, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Label("Favorite", systemImage: "star")
    }
    .tint(.blue)
  }

  static func deleteSwipeAction(_ movie: MovieModel, action: @escaping () -> Void) -> some View {
    Button(role: .destructive, action: action) {
      Label("Delete", systemImage: "trash")
    }
  }
}
