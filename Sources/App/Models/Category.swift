//
//  File.swift
//  
//
//  Created by gyda almohaimeed on 22/07/1444 AH.
//


import Fluent
import Vapor


final class Category: Model {
    
    static let schema = "categories"
    
    @ID
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: AcronymCategoryPivot.self, from: \.$category, to: \.$acronym)
    var acronym: [Acronym]
    
    
    init() {
        
    }
    
    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
   
  
      
}


extension Category: Content {}

