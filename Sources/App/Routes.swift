import Vapor

//All routes
public func routes(_ router: Router) throws {
    //Home screen, accessible without any additional URL parameters
    router.get { req -> EventLoopFuture<View> in
        let client = try req.client()

        //Get current Date
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)

        let months = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
        var dayIndex = months[month - 1] + day - 1

        //Modify leap year since no letter
        if (dayIndex == 59) {
            dayIndex = 60
        }

        guard let currentQuery = Query.init(currentDayAsInt: dayIndex).getSolrSearch() else {
            return try req.view().render("home")
        }

        return client.get(currentQuery  , headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            //flatMap unwraps the response and returns a SearchResult in the future
            .flatMap { response -> Future<SearchResult> in
                //Decode response into a SearchResult
                try response.content.decode(SearchResult.self)
            }
            //Take the SearchResult future (result), and try to render it
            .flatMap { results in
                //Render a view for the initial get request
                //results.leaf, pass a ResultPage
                var ltArr: [OIDTitle] = []

                for doc in results.response.docs {
                    guard let title = doc.title else { continue }
                    ltArr.append(OIDTitle(title: title, PID: doc.pid))
                }

                return try req.view().render("home", LODPageTitle(lettersIn: ltArr, numLetters: ltArr.count))
        }
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

    //Example url: http://localhost:8080/dynamicjson?rekl=28694,8172,13660&cpsca=132,64,84&islandora=1087,1093,1282,983
//Should return as String like staticjson, but I couldn't figure it output
//
    router.get("dynamicjson") { req -> Future<String> in
        let client = try req.client()
        let data = SavedID(reklQuery: req.query[String.self, at: "rekl"] ?? "", islandoraQuery: req.query[String.self, at: "islandora"] ?? "", cpscaQuery: req.query[String.self, at: "cpsca"] ?? "")
        let SavedLetters = IDArrays(SavedLetters: data)
        guard let encodedSearchTerm = SavedLetters.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest)
        }
        return client.get(encodedSearchTerm, headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1"), ("Authorization", "Basic Y2FzdGxlX2NvbXB1dGluZzo4PnoqPUw0QmU2TWlEP1FB")]))
            .flatMap { response -> Future<SearchResult> in
                try response.content.decode(SearchResult.self)
            }
            .map { result in
                var eventarray: [[String:Any]] = []
                //Go through each entry and add it to json output
                for entry in result.response.docs{
                    let test = JSONBuilder(entry: entry)
                    eventarray.append(test.events)
                }
                let text = ["headline":"Your Timeline", "text":"A Custom Morgan Letter Timeline"]
                let jsonDic : [String: Any] = ["title": text, "events": eventarray]
                let data = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
                let jsonString = String(data: data, encoding: String.Encoding.ascii)
                return jsonString ?? "Error"
        }
    }

    router.get("cart") { req -> Future<View> in
        let client = try req.client()
        let data = SavedID(reklQuery: try req.session()["rekl"] ?? "", islandoraQuery: try req.session()["islandora"] ?? "", cpscaQuery: try req.session()["cpsca"] ?? "")
        let SavedLetters = IDArrays(SavedLetters: data)
        guard let encodedSearchTerm = SavedLetters.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw Abort(.badRequest)
        }

        let currentQuery = Query.init(queryParameters: req.query, currentSearchURL: req.http.urlString)
        //Sends an HTTP GET request to URL
        //The headers are required in the HTTP request, parameter User-Agent has value
        //MorganApp/0.1
        return client.get(encodedSearchTerm, headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1"), ("Authorization", "Basic Y2FzdGxlX2NvbXB1dGluZzo4PnoqPUw0QmU2TWlEP1FB")]))
            //flatMap unwraps the response and returns a SearchResult in the future
            .flatMap { response -> Future<SearchResult> in
                //Decode response into a SearchResult
                try response.content.decode(SearchResult.self)
            }
            //Take the SearchResult future (result), and try to render it
            .flatMap { result in
                //Render a view for the initial get request
                //results.leaf, pass a ResultPage
                return try req.view().render("cart", ResultPage(query: currentQuery, searchResults: result.response.docs, numResults: result.response.numFound, start: result.response.start, page: 0))
        }
    }
    //Either need to consolidate with dynamicjson or pass parameters to html and
    //call dynamicjson from there
    router.get("manualtimeline") { req -> Future<View> in
        let data = SavedID(reklQuery: req.query[String.self, at: "rekl"] ?? "", islandoraQuery: req.query[String.self, at: "islandora"] ?? "", cpscaQuery: req.query[String.self, at: "cpsca"] ?? "")
        return try req.view().render("timelineview", data)
    }

    //Either need to consolidate with dynamicjson or pass parameters to html and
    //call dynamicjson from there
    router.get("timeline") { req -> Future<View> in
        let data = SavedID(reklQuery: try req.session()["rekl"] ?? "", islandoraQuery: try req.session()["islandora"] ?? "", cpscaQuery: try req.session()["cpsca"] ?? "")
        return try req.view().render("timelineview", data)
    }

        // create a route at GET /sessions/set/:name
    router.get("set", String.parameter) { req -> String in
        // get router param
        let name = try req.parameters.next(String.self)
        var current = "n/a"
        var id = "0"
        //Todo: Create a helper method to remove redundancy
        if name.hasPrefix("rekl") { // true
          id = name.components(separatedBy: ":")[1] ?? "0"
          current = try req.session()["rekl"] ?? "n/a"
          if current != "n/a"{
            try req.session()["rekl"] = current + "," + id
          }
          else{
            try req.session()["rekl"] = id
          }
        }
        else if name.hasPrefix("cpsca") {
          id = name.components(separatedBy: ":")[1] ?? "0"
          current = try req.session()["cpsca"] ?? "n/a"
          if current != "n/a"{
            try req.session()["cpsca"] = current + "," + id
          }
          else{
            try req.session()["cpsca"] = id
          }
        }
        else if name.hasPrefix("islandora") {
          id = name.components(separatedBy: ":")[1] ?? "0"
          current = try req.session()["islandora"] ?? "n/a"
          if current != "n/a"{
            try req.session()["islandora"] = current + "," + id
          }
          else{
            try req.session()["islandora"] = id
          }
        }
        // return the newly set name
        return current
    }

    // create a route at GET /sessions/del
    router.get("del", String.parameter) { req -> String in
        // destroy the session
        let name = try req.parameters.next(String.self)
        var current = "n/a"
        var id = "0"
        //Todo: Create a helper method to remove redundancy
        if name.hasPrefix("rekl") { // true
          id = name.components(separatedBy: ":")[1] ?? "0"
          print(id)
          current = try req.session()["rekl"] ?? "n/a"
          if current != "n/a"{
            let parsed = current.replacingOccurrences(of: id, with: "")
            try req.session()["rekl"] = parsed
          }
        }
        else if name.hasPrefix("cpsca") {
          id = name.components(separatedBy: ":")[1] ?? "0"
          current = try req.session()["cpsca"] ?? "n/a"
          if current != "n/a"{
            let parsed = current.replacingOccurrences(of: id, with: "")
            try req.session()["cpsca"] = parsed
          }
        }
        else if name.hasPrefix("islandora") {
          id = name.components(separatedBy: ":")[1] ?? "0"
          current = try req.session()["islandora"] ?? "n/a"
          if current != "n/a"{
            let parsed = current.replacingOccurrences(of: id, with: "")
            try req.session()["islandora"] = parsed
          }
        }
        return "done"
    }
}
