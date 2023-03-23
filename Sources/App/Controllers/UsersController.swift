//
//  File.swift
//  
//
//  Created by gyda almohaimeed on 22/07/1444 AH.
//

import Vapor


struct UsersController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        let usersRoutes = routes.grouped("api", "users")
        usersRoutes.get( use: getAllHandler)
        usersRoutes.post( use: creatHandler)
        usersRoutes.get(":userID", use: getHandler)
        usersRoutes.get(":userID", "acronym", use: getAcronymHnadler)
        usersRoutes.delete(":userID", use: deletHandler)
        
        let basicAuthMiddleware = User.authenticator()
        let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
      
        
    }
    
    
    func getAllHandler(_ req: Request) throws -> EventLoopFuture<[User.Public]> {
        User.query(on: req.db).all().convertToPublic()
    }
    
    func creatHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        let user = try req.content.decode(User.self)
        user.password = try Bcrypt.hash(user.password)
        return user.save(on: req.db).map {
            user.convertToPublic()
        }
    }
    
    func getHandler(_ req: Request) throws -> EventLoopFuture<User.Public> {
        User.find(req.parameters.get("userID"), on: req.db).unwrap(or: Abort(.notFound)).convertToPublic()
    }
    
    
    func getAcronymHnadler(_ req: Request) throws -> EventLoopFuture<[Acronym]> {
        User.find(req.parameters.get("userID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { user in
            user.$acronym.get(on: req.db)
        }
    }
    
    func deletHandler(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        User.find(req.parameters.get("userID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { user in
            user.delete(on: req.db).transform(to: .noContent)
        }
       }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<Token> {
        
        let user = try req.auth.require(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req.db).map {token}
    }
 
    
    
    //the middleware will take the username and password past the login rout find the user and authenticate them if the authientication failed 401 error appear
    
    
    
}

struct CreateUserData: Content {
    let name: String
    let username: String
    let password: String
}
