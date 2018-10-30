import Vapor

//All routes
public func routes(_ router: Router) throws {
    //Home screen, accessible without any additional URL parameters
    router.get { req in
        return try req.view().render("home")
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
        
        //Replaces all characters of searchTerm not in allowed characters with percent
        //Encoded characters. .urlQueryAllowed is the character set.
        guard let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest)
        }
        
        //Create URL for Islandora entries with encoded search title and description
        //Using SOLR search parameters
        //Returns maximum 10 documents (rows=10)
        //Excludes header
        let searchURL = "https://digital.lib.calpoly.edu/islandora/rest/v1/solr/RELS_EXT_hasModel_uri_t:bookCModel%20AND%20ancestors_ms:%22rekl:morgan-ms010%22%20AND%20(dc.title:" + encodedSearchTerm + "%20OR%20dc.description:" + encodedSearchTerm + ")?rows=15&omitHeader=true&wt=json"
        
        //Create a client to send a request.get()
        let client = try req.client()
        
        //Sends an HTTP GET request to URL
        //The headers are required in the HTTP request, parameter User-Agent has value
        //MorganApp/0.1
        return client.get(searchURL, headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            //flatMap unwraps the response and returns a SearchResult in the future
            .flatMap { response -> Future<SearchResult> in
                //Decode response into a SearchResult
                try response.content.decode(SearchResult.self)
            }
            //Take the SearchResult future (result), and try to render it
            .flatMap { result in
                //Render a view for the initial get request
                //results.leaf, pass a ResultPage
                return try req.view().render("results", ResultPage(searchTerm: searchTerm, searchResults: result.response.docs, numResults: result.response.numFound, start: result.response.start))
            }
    }
}
