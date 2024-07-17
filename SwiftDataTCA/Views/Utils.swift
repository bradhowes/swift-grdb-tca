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

    var body: some View {
      VStack(alignment: .leading) {
        Text(movie.title)
          .font(.headline)
        HStack {
          ForEach(movie.actors) {
            Text($0.name)
              .lineLimit(1)
              .truncationMode(.middle)
          }
        }
      }
      .background(movie.favorite ? .blue : .clear)
    }
  }

  struct ActorView: View {
    let actor: Actor

    var body: some View {
      VStack(alignment: .leading) {
        Text(actor.name)
          .font(.headline)
        HStack {
          ForEach(actor.movies) {
            Text($0.title)
              .lineLimit(1)
              .truncationMode(.tail)
          }
        }
      }
    }
  }
}
