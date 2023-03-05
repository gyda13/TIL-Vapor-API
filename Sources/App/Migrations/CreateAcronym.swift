//
//  File.swift
//  
//
//  Created by gyda almohaimeed on 22/07/1444 AH.
//

import Fluent


struct CreateAcronym: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("acronym")
            .id()
            .field("short", .string ,.required)
            .field("long", .string ,.required)
            .field("userID", .uuid, .required, .references("users", "id"))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("acronym").delete()
    }
}
