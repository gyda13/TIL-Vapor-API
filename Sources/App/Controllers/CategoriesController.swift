//
//  File.swift
//  
//
//  Created by gyda almohaimeed on 22/07/1444 AH.
//


import Vapor


struct CategoriesController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let categoriesRoutes = routes.grouped("api", "categories")
        categoriesRoutes.get( use: getAllHandler)
        categoriesRoutes.post( use: creatHandler)
        categoriesRoutes.get(":categoryID", use: getHandler)
        
        categoriesRoutes.get(":categoryID", "acronym", use: getAcronymsHandler)
      
        categoriesRoutes.delete(":categoryID", use: deletHandler)
    }
    
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Category]> {
        Category.query(on: req.db).all()
    }
    
    func creatHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        let category = try req.content.decode(Category.self)
        return category.save(on: req.db).map {
            category
        }
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Category> {
        Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound))
    }
    
    func getAcronymsHandler(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
        
        Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { category in category.$acronym.get(on: req.db)
            
        }
        
    }
    
    func deletHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { category in
            category.delete(on: req.db).transform(to: .noContent)
        }
       }
}
