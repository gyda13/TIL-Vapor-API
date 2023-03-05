import Fluent
import Vapor

func routes(_ app: Application) throws {
   
    let acronymController = AcronymController()
    try app.register(collection: acronymController)
    
    
    let usersController = UsersController()
    try app.register(collection: usersController)

    let categoriesController = CategoriesController()
    try app.register(collection: categoriesController)

    
    let websiteCotroller = WebsiteController()
    try app.register(collection: websiteCotroller)
}
