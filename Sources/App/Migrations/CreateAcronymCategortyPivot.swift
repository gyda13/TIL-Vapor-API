//
//  File.swift
//  
//
//  Created by gyda almohaimeed on 23/07/1444 AH.
//

import Foundation
import Fluent



struct CreateAcronymCategortyPivot: Migration{
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("acronym-category-pivot")
            .id()
            .field("acronymID", .uuid, .required, .references("acronym", "id", onDelete: .cascade))
            .field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
            .create()
    }
    
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("acronym-category-pivot")
            .delete()
    }
}
