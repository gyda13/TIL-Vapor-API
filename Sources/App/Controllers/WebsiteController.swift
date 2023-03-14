//
//  File.swift
//  
//
//  Created by gyda almohaimeed on 13/08/1444 AH.
//
import Vapor

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let authSessionsRoutes = routes.grouped(User.sessionAuthenticator())
        authSessionsRoutes.get(use: indexHandler)
        authSessionsRoutes.get("acronym", ":acronymID", use: acronymHandler)
        authSessionsRoutes.get("users", ":userID", use: userHandler)
        authSessionsRoutes.get("users", use: allUsersHandler)
        authSessionsRoutes.get("categories", ":categoryID", use: categoryHandler)
        authSessionsRoutes.get("categories", use: allCategoriesHandler)
        authSessionsRoutes.get("login", use: loginHandler)
       
        let credentialsAuthRoutes = authSessionsRoutes.grouped(User.credentialsAuthenticator())
        credentialsAuthRoutes.post("login", use: loginPostHandler)
        
        let protectRoutes = authSessionsRoutes.grouped(User.redirectMiddleware(path: "/login"))
        protectRoutes.get("acronym", "create", use: createAcronymHandler)
        protectRoutes.post("acronym", "create", use: createAcronymPostHandler)
        protectRoutes.get("acronym", ":acronymID","edit", use: editAcronymHandler)
        protectRoutes.post("acronym", ":acronymID","edit", use: editAcronymPostHandler)
        protectRoutes.post("acronym", ":acronymID", "delete", use: deleteAcronymPostHandler)
        
    }
    
    func indexHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Acronym.query(on: req.db).all().flatMap { acronyms in
            let context = IndexContext(title: "Homepage", acronyms: acronyms)
            return req.view.render("index", context)
        }
    }
    
    func acronymHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
            let userFuture = acronym.$user.get(on: req.db)
            let categoriesFuture = acronym.$categories.get(on: req.db)
            return userFuture.and(categoriesFuture).flatMap { user, categories in
                let context = AcronymContext(title: acronym.long, acronym: acronym, user: user, categories: categories)
                return req.view.render("acronym", context)
            }
        }
    }
    
    func userHandler(_ req: Request) throws -> EventLoopFuture<View> {
        User.find(req.parameters.get("userID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { user in
            user.$acronym.get(on: req.db).flatMap { acronyms in
                let context = UserContext(title: user.name, user: user, acronyms: acronyms)
                return req.view.render("user", context)
            }
        }
    }
    
    func allUsersHandler(_ req: Request) throws -> EventLoopFuture<View> {
        User.query(on: req.db).all().flatMap { users in
            let context = AllUsersContext(title: "All Users", users: users)
            return req.view.render("allUsers", context)
        }
    }
    
    func categoryHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { category in
            category.$acronym.get(on: req.db).flatMap { acronyms in
                let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
                return req.view.render("category", context)
            }
        }
    }
    
    func allCategoriesHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Category.query(on: req.db).all().flatMap { categories in
            let context = AllCategoriesContext(title: "All Categories", categories: categories)
            return req.view.render("allCategories", context)
        }
    }
    
    func createAcronymHandler(_ req: Request) throws -> EventLoopFuture<View> {

            let context = CreateAcronymContext(title: "Create an Acronym")
            return req.view.render("createAcronym", context)
        
    }
    
    func createAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(CreateAcronymData.self)
        let user = try req.auth.require(User.self)
        let acronym = try Acronym(short: data.short, long: data.long, userID: user.requireID())
        return acronym.save(on: req.db).flatMapThrowing {
            let id = try acronym.requireID()
            return req.redirect(to: "/acronym/\(id)")
            
        }
    }
    
    func editAcronymHandler(_ req: Request) throws -> EventLoopFuture<View> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
           
                let context = EditAcronymContext(title: "Edit Acronym", acronym: acronym)
                return req.view.render("createAcronym", context)
            
            
        }
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(CreateAcronymData.self)
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        return Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
            acronym.short = data.short
            acronym.long = data.long
            acronym.$user.id = userID
            return acronym.save(on: req.db).flatMapThrowing {
                let id = try acronym.requireID()
                return req.redirect(to: "/acronym/\(id)")
                
            }
        }
        
    }
    
    func deleteAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
         Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap
        { acronym in
            acronym.delete(on: req.db).transform(to: req.redirect(to: "/"))
        }
    }
    
    func loginHandler(_ req: Request) throws -> EventLoopFuture<View> {
        let context = LoginContext(title: "Log In")
        return req.view.render("login", context)
    
    }
    
    func loginPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        if req.auth.has(User.self) {
            return req.eventLoop.future(req.redirect(to: "/"))
        } else {
            return req.view.render("login", LoginContext(title: "Log In")).encodeResponse(for: req)
        }
    }
    
}

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
    let categories: [Category]
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let acronyms: [Acronym]
}

struct AllCategoriesContext: Encodable {
    let title: String
    let categories: [Category]
}

struct CreateAcronymContext: Encodable{
    let title: String
    
}

struct EditAcronymContext: Encodable{
    let title: String
    let acronym: Acronym
    let editing = true
    
}


struct LoginContext: Encodable{
    let title: String
    
}

