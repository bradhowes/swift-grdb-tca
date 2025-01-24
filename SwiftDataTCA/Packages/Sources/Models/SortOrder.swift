import Foundation
import GRDB


extension SortOrder {

  public func by(_ column: Column) -> SQLOrdering {
    switch self {
    case .forward: return column.collating(.localizedCaseInsensitiveCompare).asc
    case .reverse: return column.collating(.localizedCaseInsensitiveCompare).desc
    }
  }
}

