//
//  File.swift
//  
//
//  Created by gyda almohaimeed on 22/07/1444 AH.
//

import Fluent


struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .id()
            .field("name", .string ,.required)
            .field("username", .string ,.required)
            .field("password", .string ,.required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("user").delete()
    }
}
