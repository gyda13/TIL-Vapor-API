//
//  File.swift
//  
//
//  Created by gyda almohaimeed on 22/07/1444 AH.
//

import Fluent


struct CreateCategory: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .id()
            .field("name", .string ,.required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("categories").delete()
    }
}
