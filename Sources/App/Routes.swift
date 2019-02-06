import Vapor

//All routes
public func routes(_ router: Router) throws {
    //Home screen, accessible without any additional URL parameters
    router.get { req -> EventLoopFuture<View> in
        //Get current Date
        let now = Date()
        let months = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M"
        let month = dateFormatter.string(from: now)
        dateFormatter.dateFormat = "d"
        let day = dateFormatter.string(from: now)
        var index = months[Int(month)! - 1] + Int(day)! - 1
        
        //Read from file
        let fileURL = URL.init(fileURLWithPath: DirectoryConfig.detect().workDir + "/Resources/LetterDates.txt")
        let fileData = try String.init(contentsOf: fileURL)
        var lines: [String] = []
        fileData.enumerateLines { line, _ in
            lines.append(line)
        }
        
        
        //Modify leap year since no letter
        if (index == 59) {
            index = 60
        }
        
        //Split line into array
        let letterArr = lines[index].components(separatedBy: ", ")
        var letters: LODPageTitle
        
        //Try JSON
        let fileURL2 = URL.init(fileURLWithPath: DirectoryConfig.detect().workDir + "/Resources/LetterDates.json")
        let data = try Data(contentsOf: fileURL2, options: .mappedIfSafe)
        do {
            let object: [String: AnyObject] = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject as! [String : AnyObject]
            let today = object[String(index)] as! [[String : AnyObject]]
            var ltArr: [OIDTitle] = []
            for item in today {
                print ("PID: ", item["PID"]!, "title: ", item["title"]!)
                ltArr.append(OIDTitle(title: item["title"] as! String, PID: item["PID"] as! String))
            }
            letters = LODPageTitle(lettersIn: ltArr, numLetters: ltArr.count)
            for item in letters.letters! {
                print ("PID: ", item.PID, "title: ", item.title)
            }
            print (letters.numLetters)
            return try req.view().render("home", letters)
        } catch {
            // Handle Error
        }
        //Render home
        return try req.view().render("home", LODPage(lettersIn: letterArr, numLetters: letterArr.count))
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
        
        let relatedItemsRequest = client.get("https://digital.lib.calpoly.edu/islandora/object/" + letterPID + "/datastream/RELATED_OBJECTS", headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            .flatMap { secondResponse -> Future<Data> in
                return secondResponse.http.body.consumeData(on: req)
        }
        
        return flatMap(searchResultRequest, ocrDataRequest, relatedItemsRequest) { (result: SearchResult, ocrData: Data, relatedItems: Data) in
            guard let letter = result.response.docs.first else {
                throw Abort(.badRequest)
            }
        
            var ocrText: String? = String(data: ocrData, encoding: .utf8)
            if (ocrText?.isEmpty ?? false) || ocrText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false { ocrText = nil }
            
            var relatedItemsText: String? = String(data: relatedItems, encoding: .utf8)
            if (relatedItemsText?.isEmpty ?? false) || relatedItemsText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false { relatedItemsText = nil }
            
            
            var relatedItems = [relatedItem]()
            
            if let unformatedRelatedItems = relatedItemsText?.split(separator: "\n") {
                for item in unformatedRelatedItems {
                    var split = item.components(separatedBy: ",")
                    guard (split.count >= 2) else { continue }
                    
                    relatedItems.append(relatedItem.init(id: split.remove(at: 0), title: split.joined(separator: ",")))
                }
            }
            
            return try req.view().render("letter", LetterPage(title: letter.title, children: letter.children, ocrText: ocrText, numPages: letter.children?.count, metadata: letter, relatedItems: relatedItems))
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
        
        let currentQuery = Query.init(queryParameters: req.query, currentSearchURL: req.http.urlString)
        
        var page = req.query[Int.self, at: "page"] ?? 1
        if page < 1 {
            page = 1
        }
        
        let start = (page - 1) * 15
        
        //Create URL for Islandora entries with encoded search title and description
        //Using SOLR search parameters
        //Returns maximum 10 documents (rows=10)
        //Excludes header
        //let searchURL = searchBookURL(encodedSearchTerm: encodedSearchTerm, start: start)
        let searchURL = currentQuery.getSolrSearch(start: start)!
        
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
                return try req.view().render("results", ResultPage(query: currentQuery, searchResults: result.response.docs, numResults: result.response.numFound, start: result.response.start, page: page))
        }
    }
}
