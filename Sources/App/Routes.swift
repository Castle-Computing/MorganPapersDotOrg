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
        
        guard let encodedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest)
        }
        
        let searchURL = "https://digital.lib.calpoly.edu/islandora/rest/v1/solr/ancestors_ms:%22rekl:morgan-ms010%22%20AND%20(dc.title:" + encodedSearchTerm + "%20OR%20dc.description:" +  encodedSearchTerm + ")?rows=10&omitHeader=true&wt=json"
        
        let client = try req.client()
        
        return client.get(searchURL, headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            .flatMap { response -> Future<SearchResult> in
                try response.content.decode(SearchResult.self)
            }
            .flatMap { result in
                //debugPrint(result.response.docs)
                return try req.view().render("results", ResultPageStruct(searchTerm: searchTerm, searchResults: result.response.docs, numResults: result.response.numFound, start: result.response.start))
            }
    }
    
    struct ResultPageStruct: Codable {
        let searchTerm: String
        let searchResults: [docArray]
        let numberOfResults: Int
        let start: Int
        
        init(searchTerm: String, searchResults: [docArray], numResults: Int, start: Int) {
            self.searchTerm = searchTerm
            self.searchResults = searchResults
            self.numberOfResults = numResults
            self.start = start
        }
    }
    
    struct SearchResult: Codable {
        let response: searchResponse
    }
    
    struct searchResponse: Codable {
        let numFound: Int
        let start: Int
        let docs: [docArray]
    }
    
    struct docArray: Codable {
        var titleArray: [String]?
        var title: String?
        
        var authorArray: [String]?
        var author: String?
        
        var descriptionArray: [String]?
        var description: String?
        
        var pid: String
        
        enum CodingKeys: String, CodingKey {
            case titleArray = "dc.title"
            case title = "title"
            case authorArray = "dc.contributor"
            case author = "author"
            case descriptionArray = "dc.description"
            case description = "description"
            case pid = "PID"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            titleArray = try container.decode([String].self, forKey: .titleArray)
            title = titleArray![0]
            
            let reklPid = try container.decode(String.self, forKey: .pid)
            pid = String(reklPid.split(separator: ":")[1])
            
            do {
                authorArray = try container.decode([String].self, forKey: .authorArray)
                author = authorArray![0]
            } catch {
                debugPrint("No contributor listed.")
            }
            
            do {
                descriptionArray = try container.decode([String].self, forKey: .descriptionArray)
                description = descriptionArray![0]
            } catch {
                debugPrint("No description listed.")
            }
        }
    }
}
