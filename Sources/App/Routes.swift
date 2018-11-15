import Vapor

//All routes
public func routes(_ router: Router) throws {
    //Home screen, accessible without any additional URL parameters
    router.get { req in
        return try req.view().render("home")
    }
    
    router.get("letter", String.parameter) { req -> Future<View> in
        let context = try req.parameters.next(String.self)
        //Create a client to send a request.get()
        let client = try req.client()
        //Sends an HTTP GET request to URL
        let searchURL = getChildrenURL(pid: context)
        
        return client.get(searchURL, headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1"), ("Authorization", "Basic Y2FzdGxlX2NvbXB1dGluZzo4PnoqPUw0QmU2TWlEP1FB")]))
            .flatMap { response -> Future<AncestorSearchResult> in
                return try response.content.decode(AncestorSearchResult.self)
        }
            .flatMap { result in
                var i = 0
                var pageArray: [PageInfo] = []
                for pageIn in result.response.docs {
                    pageArray.append(PageInfo(index1: i, PID1: pageIn.PID))
                    i = i + 1
                }
                return try req.view().render("letter", LetterPage(searchResults: result.response.numFound, searchData: pageArray, parent: context))
        }
    }

    
    //Adds new route, with search parameter.
    //Returns a view in the future
    router.get("search") { req -> Future<View> in
        //Attempt to obtain search term, otherwise abort
        //Receive the search term from the query
        //Request host/search?query=
        guard let searchTerm = req.query[String.self, at: "query"] else {
            throw Abort(.badRequest)
        }
        
        var page = req.query[Int.self, at: "page"] ?? 1
        if page < 1 {
            page = 1
        }
        
        let start = (page - 1) * 15
        
        //Replaces all characters of searchTerm not in allowed characters with percent
        //Encoded characters. .urlQueryAllowed is the character set.
        guard let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest)
        }
        
        //Create URL for Islandora entries with encoded search title and description
        //Using SOLR search parameters
        //Returns maximum 10 documents (rows=10)
        //Excludes header
        let searchURL = searchBookURL(item: encodedSearchTerm)
        
        //Create a client to send a request.get()
        let client = try req.client()
        
        //Sends an HTTP GET request to URL
        //The headers are required in the HTTP request, parameter User-Agent has value
        //MorganApp/0.1
        return client.get(searchURL, headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1"), ("Authorization", "Basic Y2FzdGxlX2NvbXB1dGluZzo4PnoqPUw0QmU2TWlEP1FB")]))
            //flatMap unwraps the response and returns a SearchResult in the future
            .flatMap { response -> Future<SearchResult> in
                //Decode response into a SearchResult
                try response.content.decode(SearchResult.self)
            }
            //Take the SearchResult future (result), and try to render it
            .flatMap { result in
                //Render a view for the initial get request
                //results.leaf, pass a ResultPage
                return try req.view().render("results", ResultPage(searchTerm: searchTerm, searchResults: result.response.docs, numResults: result.response.numFound, start: result.response.start, page: page))
        }
    }
}
