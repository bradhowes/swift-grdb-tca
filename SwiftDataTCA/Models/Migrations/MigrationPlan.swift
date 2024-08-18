import Dependencies
import Foundation
import SwiftData

enum MigrationPlan: SchemaMigrationPlan {

  static var schemas: [any VersionedSchema.Type] {
    [
      SchemaV1.self,
      SchemaV2.self,
      SchemaV3.self,
      SchemaV4.self,
      SchemaV5.self,
      SchemaV6.self,
    ]
  }

  static var stages: [MigrationStage] {
    [
      .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self),
      StageV3.stage,
      StageV4.stage,
      StageV5.stage,
      StageV6.stage,
    ]
  }
}
