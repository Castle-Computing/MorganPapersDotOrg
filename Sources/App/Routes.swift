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
            return try req.view().render("letter", LetterPage(title: letter.title, children: letter.children, ocrText: ocrText, numPages: letter.children?.count, metadata: letter, pid: letterPID))
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

    //Example url: http://localhost:8080/dynamicjson?rekl=28694,8172,13660&cpsca=132,64,84&islandora=1087,1093,1282,983
    //Should return as String like staticjson, but I couldn't figure it output
    //
    router.get("dynamicjson") { req -> Future<String> in
        let client = try req.client()
        let reklQuery = req.query[String.self, at: "rekl"] ?? ""
        let reklArray = reklQuery.components(separatedBy: ",")
        let islandoraQuery = req.query[String.self, at: "islandora"] ?? ""
        let islandoraArray = islandoraQuery.components(separatedBy: ",")
        let cpscaQuery = req.query[String.self, at: "cpsca"] ?? ""
        let cpscaArray = cpscaQuery.components(separatedBy: ",")
        var queryingURL = "https://digital.lib.calpoly.edu/islandora/rest/v1/solr/"
        for identifier in reklArray{
            queryingURL.append("PID:\"rekl:" + identifier + "\"")
            queryingURL.append(" OR ")
        }
        for identifier in islandoraArray{
            queryingURL.append("PID:\"islandora:" + identifier + "\"")
            queryingURL.append(" OR ")
        }
        for identifier in cpscaArray{
            queryingURL.append("PID:\"cpsca:" + identifier + "\"")
            queryingURL.append(" OR ")
        }

        var truncated = queryingURL.prefix(queryingURL.count - 4)
        truncated += "?rows=15&omitHeader=true&wt=json&start=0"
        guard let encodedSearchTerm = truncated.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
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
                    let date = entry.date ?? ""
                    var datearray = date.components(separatedBy: "-")
                    let description = entry.description ?? ""
                    let title = entry.title ?? ""
                    let children = entry.children
                    //print(children)
                    var url = "https://digital.lib.calpoly.edu/islandora/rest/v1/object/" + entry.pid + "/datastream/TN"
                    if children?.isEmpty == false {
                        url = "https://digital.lib.calpoly.edu/islandora/object/" + children![0] + "/datastream/JPG/view"
                    }
                    if date == "" {
                        datearray.append("")
                    }
                    let start_date : [String: Any] = ["year": datearray[0], "month": datearray[1], "day": datearray[2]]
                    let titleanddescription : [String: Any] = ["headline": "<a href=" + "\"letter\\" + entry.pid + "\"" + ">" + title + "</p>","text": description]
                    let media = ["url" : url]
                    let events : [String: Any] = ["start_date": start_date, "text": titleanddescription, "media" : media]
                    eventarray.append(events)
                }
                let text = ["headline":"Your Timeline", "text":"A Custom Morgan Letter Timeline"]
                let jsonDic : [String: Any] = ["title": text, "events": eventarray]
                let data = try JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted)
                let jsonString = String(data: data, encoding: String.Encoding.ascii)
                return jsonString ?? "Error"
        }
    }

    //Either need to consolidate with dynamicjson or pass parameters to html and
    //call dynamicjson from there
    router.get("manualtimeline") { req -> Future<View> in
        let reklQuery = req.query[String.self, at: "rekl"] ?? ""
        let islandoraQuery = req.query[String.self, at: "islandora"] ?? ""
        let cpscaQuery = req.query[String.self, at: "cpsca"] ?? ""
        let data = ["rekl": reklQuery, "islandora": islandoraQuery, "cpsca": cpscaQuery]
        return try req.view().render("timelineview", data)
    }

    //Either need to consolidate with dynamicjson or pass parameters to html and
    //call dynamicjson from there
    router.get("timeline") { req -> Future<View> in
        let reklQuery = try req.session()["rekl"] ?? "n/a"
        let islandoraQuery = try req.session()["islandora"] ?? "n/a"
        let cpscaQuery = try req.session()["cpsca"] ?? "n/a"
        let data = ["rekl": reklQuery, "islandora": islandoraQuery, "cpsca": cpscaQuery]
        return try req.view().render("timelineview", data)
    }

    //Adds new route, with search parameter.
    //Returns a view in the future
    router.get("search") { req -> Future<View> in
        //Attempt to obtain search term, otherwise abort
        //Receive Querythe search term from the query
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
        print(searchURL)
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

    // create a route at GET /sessions/set/:name
    router.get("set", String.parameter) { req -> String in
        // get router param
        let name = try req.parameters.next(String.self)
        var current = "n/a"
        var id = "0"
        //Todo: Create a helper method to remove redundancy
        if name.hasPrefix("rekl") { // true
          id = name.components(separatedBy: ":")[1] ?? "0"
          print(id)
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
          print(id)
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
          print(id)
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
          print(id)
          current = try req.session()["cpsca"] ?? "n/a"
          if current != "n/a"{
            let parsed = current.replacingOccurrences(of: id, with: "")
            try req.session()["cpsca"] = parsed
          }
        }
        else if name.hasPrefix("islandora") {
          id = name.components(separatedBy: ":")[1] ?? "0"
          print(id)
          current = try req.session()["islandora"] ?? "n/a"
          if current != "n/a"{
            let parsed = current.replacingOccurrences(of: id, with: "")
            try req.session()["islandora"] = parsed
          }
        }
        return "done"
    }
}
