import Vapor

//All routes
public func routes(_ router: Router) throws {
    //Home screen, accessible without any additional URL parameters
    router.get { req in
        return try req.view().render("home")
    }
    
    router.get("letter", String.parameter) { req -> Future<View> in
        let letterPID = try req.parameters.next(String.self)
        let client = try req.client()
        let letterURL = getLetterURL(pid: letterPID)
        
        let searchResultRequest = client.get(letterURL, headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            .flatMap { firstResponse -> Future<SearchResult> in
                return try firstResponse.content.decode(SearchResult.self)
        }
        
        let ocrDataRequest = client.get("https://digital.lib.calpoly.edu/islandora/object/" + letterPID + "/datastream/OCR_BOOK", headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            .flatMap { secondResponse -> Future<Data> in
                return secondResponse.http.body.consumeData(on: req)
        }
        
        return flatMap(searchResultRequest, ocrDataRequest) { (result: SearchResult, ocrData: Data) in
                guard let letter = result.response.docs.first else {
                    throw Abort(.badRequest)
                }
            
                let ocrText = String(data: ocrData, encoding: .utf8) ?? "invalid encoding"
                return try req.view().render("letter", LetterPage(title: letter.title, children: letter.children, ocrText: ocrText, numPages: letter.children?.count, metadata: letter))
        }
    }

    router.get("help") { req -> Future<View> in
        return try req.view().render("help")
    }
    
    router.get("about") { req -> Future<View> in
        return try req.view().render("about")
    }
    
    router.get("explore") { req -> Future<View> in
        return try req.view().render("explore")
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
        let searchURL = searchBookURL(encodedSearchTerm: encodedSearchTerm, start: start)
        
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
