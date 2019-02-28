import Vapor

final class SavedID: Codable {
    let reklQuery: String
    let islandoraQuery: String
    let cpscaQuery: String

    init(reklQuery: String, islandoraQuery: String, cpscaQuery: String) {
        self.reklQuery = reklQuery
        self.islandoraQuery = islandoraQuery
        self.cpscaQuery = cpscaQuery
    }
}

final class IDArrays: Codable {
    let reklArray: [String]
    let islandoraArray: [String]
    let cpscaArray: [String]
    let url: String
    init(SavedLetters: SavedID, restrictLength: Bool = true) {
        self.reklArray = SavedLetters.reklQuery.components(separatedBy: ",")
        self.islandoraArray = SavedLetters.islandoraQuery.components(separatedBy: ",")
        self.cpscaArray = SavedLetters.cpscaQuery.components(separatedBy: ",")
        var queryingURL = "https://digital.lib.calpoly.edu/islandora/rest/v1/solr/"
        for identifier in self.reklArray{
            queryingURL.append("PID:\"rekl:" + identifier + "\"")
            queryingURL.append(" OR ")
        }
        for identifier in self.islandoraArray{
            queryingURL.append("PID:\"islandora:" + identifier + "\"")
            queryingURL.append(" OR ")
        }
        for identifier in self.cpscaArray{
            queryingURL.append("PID:\"cpsca:" + identifier + "\"")
            queryingURL.append(" OR ")
        }
        var truncated = queryingURL.prefix(queryingURL.count - 4)
        
        if(restrictLength) {
            truncated += "?rows=15&omitHeader=true&wt=json&start=0"
        } else {
            truncated += "?omitHeader=true&wt=json"
        }
        
        self.url = String(truncated)
    }
}

final class JSONBuilder {
  let date : String
  var datearray : [String]
  let description : String
  let title : String
  let children : [String]?
  let url : String
  let start_date : [String: Any]
  let titleanddescription : [String: Any]
  let media: [String: Any]
  let events: [String: Any]


  //print(children)
  init(entry: docArray){
    self.date = entry.date ?? ""
    self.datearray = date.components(separatedBy: "-")
    self.description = entry.description ?? ""
    self.title = entry.title ?? ""
    self.children = entry.children
    if self.children?.isEmpty == false {
        self.url = "https://digital.lib.calpoly.edu/islandora/object/" + self.children![0] + "/datastream/JPG/view"
    }
    else{
      self.url = "https://digital.lib.calpoly.edu/islandora/rest/v1/object/" + entry.pid + "/datastream/TN"
    }
    while self.datearray.count < 3 {
        self.datearray.append("")
    }
    if self.datearray[2].contains("/"){
      self.datearray[2] = self.datearray[2].components(separatedBy: "/")[0]
    }
    self.start_date = ["year": self.datearray[0], "month": self.datearray[1], "day": self.datearray[2]]
    self.titleanddescription = ["headline": "<a href=" + "\"letter\\" + entry.pid + "\"" + ">" + self.title + "</p>","text": self.description]
    self.media = ["url" : self.url, "thumbnail" : self.url]
    self.events = ["start_date": self.start_date, "text": self.titleanddescription, "media" : self.media]
  }
}
