import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // "It works" page
    router.get { req in
        return try req.view().render("home")
    }
    
    // Says hello
    router.get("search") { req -> Future<View> in
        guard let searchTerm = req.query[String.self, at: "query"] else {
            throw Abort(.badRequest)
        }
        
        return try req.view().render("results", [
            "searchTerm": searchTerm
        ])
    }
    
}
