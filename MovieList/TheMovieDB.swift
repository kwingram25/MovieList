//
//  TheMovieDB.swift
//  MovieList
//
//  Created by Keith Ingram on 11/30/15.
//  Copyright © 2015 keithingram. All rights reserved.
//

import Foundation
import Alamofire
import SwiftDate

//  List of tabs
enum List : Int {
    case NowPlaying = 0
    case ComingSoon = 1
    case TopRated = 2
}

struct TheMovieDB {
    
    // MARK : - API Request Router
    enum Router: URLRequestConvertible {
        static let baseURLString = "http://api.themoviedb.org/3"
        static let apiKey = "5ee9d156b4fe056b1a65f0600a3dbdaf"
        
        case MovieList(List, Int)       // /movies/now_playing, /movies/upcoming, /movies/top_rated
        case MovieInfo(Int)             // /movie/{id}?append_to_response=credits
        
        var URLRequest: NSMutableURLRequest {
            let (path, parameters) : (String, [String : AnyObject]) = {
                switch self {
                    
                //  Retrieves list of movies w/basic info for each
                case .MovieList (let tab, let page):
                    
                    var component : String
                    switch(tab) {
                        case .NowPlaying:
                            component = "now_playing"
                            break
                        case .ComingSoon:
                            component = "upcoming"
                            break
                        case .TopRated:
                            component = "top_rated"
                            break
                    }
                    
                    let params = ["api_key": Router.apiKey, "page": "\(page)", "lang": "en"]
                    return ("/movie/\(component)", params)
                
                //  Retrieves detailed info for specific movie w/ID, cast, crew, genres
                case .MovieInfo(let movieID):
                    let params = ["api_key": Router.apiKey, "id": "\(movieID)", "append_to_response": "credits"]
                    return ("/movie/\(movieID)", params)
                }
            }()
            
            let URL = NSURL(string: Router.baseURLString)
            let URLRequest = NSURLRequest(URL: URL!.URLByAppendingPathComponent(path))
            let encoding = Alamofire.ParameterEncoding.URL
            
            return encoding.encode(URLRequest, parameters: parameters).0
        }
    }
    
    static let imageURLString = "http://image.tmdb.org/t/p/w"
    
    //  Available TMDB poster sizes
    static let posterWidths : [Int] = [92, 154, 185, 342, 500, 780]
    
    //  Returns the smallest poster size that is larger than the given image width
    static func posterWidth(width : CGFloat) -> Int {
        
        var posterWidth : Int = posterWidths[0]
        let scale = UIScreen.mainScreen().scale
        for i in 0..<posterWidths.count {
            if Int(width*scale) > posterWidths[i] {
                posterWidth = posterWidths[i+1]
            }
        }
        return posterWidth
    }
    
}

//  Representation of movie information JSON returned
class MovieInfo : NSObject {
    let id : Int
    
    var title : String?
    var release_date : NSDate?
    var overview : String?
    var genres : [String]?
    
    var directors : [String]?
    var writers : [String]?
    var cast : [String]?
    
    var poster_path : String?
    
    init(representation: AnyObject) {
        self.id = representation.valueForKeyPath("id") as! Int
        
        self.title = representation.valueForKeyPath("title") as? String
        self.release_date = (representation.valueForKeyPath("release_date") as? String)?.toDate(DateFormat.Custom("yyyy-MM-dd"))
        
        self.overview = representation.valueForKeyPath("overview") as? String
        self.poster_path = representation.valueForKeyPath("poster_path") as? String

    }
    
}