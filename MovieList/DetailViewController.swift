//
//  DetailViewController.swift
//  MovieList
//
//  Created by Keith Ingram on 11/30/15.
//  Copyright © 2015 keithingram. All rights reserved.
//

import UIKit
import Alamofire
import SwiftDate

class DetailViewController: UIViewController {

    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var posterImageView: UIImageView!
    
    @IBOutlet weak var movieTitleLabel: UILabel!
    @IBOutlet weak var genresLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var directorsLabel: UILabel!
    @IBOutlet weak var writersLabel: UILabel!
    @IBOutlet weak var starringLabel: UILabel!
    
    var dataFetching : Bool = false
    var dataFetched : Bool = false
    var viewConfigured : Bool = false
    
    var movieInfo: MovieInfo? {
        didSet {
            self.fetchMovieInfo()
        }
    }
    
    // MARK: - Life cycle
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Edge cases
        if scrollView.hidden == true && movieInfo != nil {
            activityIndicatorView.startAnimating()
            if !dataFetching {
                fetchMovieInfo()
            }
        }
        else {
            if (dataFetched && !viewConfigured) {
                configureView()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Fetch movie data

    func fetchMovieInfo() {
        
        dataFetching = true

        if let movieInfo = self.movieInfo {
            
            activityIndicatorView?.startAnimating()
            Alamofire.request(TheMovieDB.Router.MovieInfo(movieInfo.id)).validate().responseJSON() {
                
                response in
                
                self.dataFetching = false
                
                switch (response.result) {
                case .Success(let JSON):
                    
                    // If success, update movieInfo with cast/crew/genres
                    
                    self.movieInfo!.directors = ((JSON as! NSDictionary).valueForKeyPath("credits.crew") as! [NSDictionary]).filter({ ($0["job"] as! String) == "Director" }).map{ $0["name"] as! String }
                    self.movieInfo!.writers = ((JSON as! NSDictionary).valueForKeyPath("credits.crew") as! [NSDictionary]).filter({ ($0["department"] as! String) == "Writing" }).map{ $0["name"] as! String }
                    self.movieInfo!.cast = ((JSON as! NSDictionary).valueForKeyPath("credits.cast") as! [NSDictionary]).filter({ ($0["order"] as! Int) < 3 }).map{ $0["name"] as! String }
                    self.movieInfo!.genres = ((JSON as! NSDictionary).valueForKey("genres") as! [NSDictionary]).map{ $0["name"] as! String }
                    
                    self.dataFetched = true
                    
                    self.configureView()

                    break
                    
                case .Failure(let error):
                    let alertController = UIAlertController(title: "Error", message: "\(error.localizedDescription) (Code \(error.code))", preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                    self.activityIndicatorView.stopAnimating()
                    break
                    
                }
            }
        }
    }
    
    // Set up views, load poster
    func configureView() {
        
        if let movieInfo = self.movieInfo {
            movieTitleLabel?.text = movieInfo.title ?? ""
            releaseDateLabel?.text = movieInfo.release_date != nil ? movieInfo.release_date!.toString(DateFormat.Custom("MMM d, YYYY")) : "N/A"
            overviewLabel?.text = movieInfo.overview ?? "–"
            
            if movieInfo.genres?.count > 0 {
                genresLabel?.text = movieInfo.genres?.joinWithSeparator(", ")
            }
            
            if movieInfo.directors?.count > 0 {
                directorsLabel?.text = movieInfo.directors?.joinWithSeparator(", ")
            }
            if movieInfo.writers?.count > 0 {
                writersLabel?.text = movieInfo.writers?.joinWithSeparator(", ")
            }
            if movieInfo.cast?.count > 0 {
                starringLabel?.text = movieInfo.cast?.joinWithSeparator(", ")
            }
            
            if posterImageView != nil {
                let posterWidth = TheMovieDB.posterWidth( posterImageView.frame.size.width ?? 342.0)
                let posterURL = "\(TheMovieDB.imageURLString)\(posterWidth)\(movieInfo.poster_path ?? "")"
                
                posterImageView?.sd_setImageWithURL(NSURL(string: posterURL), placeholderImage: UIImage(named: "No Poster Available"), completed: nil)
            }
            
            activityIndicatorView?.stopAnimating()
            scrollView?.hidden = false
            
            viewConfigured = true

        }
    }

}

