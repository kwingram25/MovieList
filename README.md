# MovieList

Simple universal iOS 8+ app that interacts with the public [TheMovieDB.org](http://www.themoviedb.org) api \([reference](http://docs.themoviedb.apiary.io/)\). The master controller displays a collecion view of movies from three public lists. Selecting one displays the movie's basic info in the detail view. App uses Auto Layout to adapt to device and screen size, and has been tested on iPhone 6 and above. Uses Alamofire/AFNetworking/Reachability to query for lists and fetch specific movie details, SDWebImage for lazy loading posters, and SwiftDate for date handling. 
