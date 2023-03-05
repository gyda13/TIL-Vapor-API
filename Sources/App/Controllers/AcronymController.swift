//
//  File.swift
//  
//
//  Created by gyda almohaimeed on 22/07/1444 AH.
//

import Vapor
import Fluent


struct AcronymController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let acronymRoutes = routes.grouped("api", "acronym")
        acronymRoutes.get( use: getAllHandler)
        acronymRoutes.get(":acronymID", use: getHandler)
      
        // get the user info from acronymID
        acronymRoutes.get(":acronymID", "user", use: getUserHnadler)
    
        acronymRoutes.get(":acronymID", "categories", use: getCatogriesHandler)

        acronymRoutes.get("search", use: searchHandler)
        
        
        let tokenAuthMiddleware = Token.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let tokenAuthGroup = acronymRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post( use: creatHandler)
        tokenAuthGroup.delete(":acronymID", use: deletHandler)
        tokenAuthGroup.put(":acronymID", use: updateHandler)
        tokenAuthGroup.post(":acronymID", "categories", ":categoryID", use: addCategoriesHandler)
    }
    
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
        Acronym.query(on: req.db).all()
    }
    
    func creatHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
        let data = try req.content.decode(CreateAcronymData.self)
        let user = try req.auth.require(User.self)
        let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
        return acronym.save(on: req.db).map{
            acronym
        }
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound))
    }
    
    
    func deletHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
            acronym.delete(on: req.db).transform(to: .noContent)
        }
       }
        
    func updateHandler(_ req: Request) throws -> EventLoopFuture<Acronym> {
        let updateAcronym = try req.content.decode(CreateAcronymData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
            acronym.short = updateAcronym.short
            acronym.long = updateAcronym.long
            acronym.$user.id = userID
            return acronym.save(on: req.db).map {
                acronym
            }
            
        }
    }
    
    func getUserHnadler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
            acronym.$user.get(on: req.db).convertToPublic()
        }
    }
    
    
    func getCatogriesHandler(_ req: Request) throws -> EventLoopFuture<[Category]> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
            acronym.$categories.get(on: req.db)
        }
    }
    
    
    
      func addCategoriesHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
          let acronymQuery = Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound))
          let categoryQuery = Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound))
          return acronymQuery.and(categoryQuery).flatMap { acronym, category in
              acronym.$categories.attach(category, on: req.db).transform(to: .created)
          }
      }
   
    
    
    func searchHandler(_ req: Request) throws ->
    EventLoopFuture<[Acronym]> {
        
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        return Acronym.query(on: req.db).group(.or) { or in
            or.filter(\.$short == searchTerm)
            or.filter(\.$long == searchTerm)
        }.all()
        
    }
    
    
}

struct CreateAcronymData: Content {
    let short: String
    let long: String
}
