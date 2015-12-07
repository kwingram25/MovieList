//
//  MasterViewController.swift
//  MovieList
//
//  Created by Keith Ingram on 11/30/15.
//  Copyright © 2015 keithingram. All rights reserved.
//

import UIKit
import Alamofire
import SDWebImage

class MasterViewController: UICollectionViewController {

    let moviesPerPage : Int = 20
    let maxPage : Int = 10
    
    var detailViewController: DetailViewController? = nil
    var objects = [AnyObject]()
    
    struct MovieList {
        var currentPage : Int = 1
        var movies = NSMutableOrderedSet()
    }
    
    var currentListIndex : List = .NowPlaying
    
    var movieLists : [MovieList] = {
        var result = [MovieList]()
        for var i in 1...3 {
            result.append(MovieList())
        }
        return result
        
    }()
    
    var fetchingMovies = false
    
    var posterWidth : Int?
    
    let MovieListCellIdentifier = "MovieListCell"
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView!.allowsMultipleSelection = false
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        
        // Deselect cells on iPhone
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            for indexPath in collectionView!.indexPathsForVisibleItems() {
                collectionView!.cellForItemAtIndexPath(indexPath)?.selected = false
            }
            collectionView!.reloadData()
        }
        
        // Fetch first page
        fetchMovies()
        
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateLayout()

    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition(nil) { (context) -> Void in
            self.updateLayout()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Tab control
    
    
    @IBAction func didChangeTab(sender: UISegmentedControl) {
        
        currentListIndex = List(rawValue: sender.selectedSegmentIndex)!
        
        collectionView!.reloadData()
        
        if (movieLists[currentListIndex.rawValue].movies.count > 0) {
            collectionView!.scrollToItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0) , atScrollPosition: .Top , animated: false)
        }
        fetchMovies()
        
    }
    
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.collectionView?.indexPathsForSelectedItems()![0] {
                
                let movieInfo = movieLists[currentListIndex.rawValue].movies[indexPath.row] as! MovieInfo
                
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                controller.movieInfo = movieInfo
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    // MARK: - Helper functions
    
    func updateLayout() {
        let layout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        let isPhone = UIDevice.currentDevice().userInterfaceIdiom == .Phone
        
        // Default two posters per row
        var rowCount : CGFloat = 2.0
        
        // if Iphone, 3+ posters per row depending on height
        if isPhone  {
            rowCount = 3.0
            
            if UIApplication.sharedApplication().statusBarOrientation != UIInterfaceOrientation.Portrait {
                while ((view.bounds.size.width / rowCount) * 1.9 > view.frame.size.height * 0.75) {
                    rowCount += 1.0
                }
            }
        }
        
        // Collection view cell width
        let itemWidth = (view.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right - (layout.minimumInteritemSpacing*(rowCount-1))) / rowCount
        
        if posterWidth == nil {
            posterWidth = TheMovieDB.posterWidth( itemWidth )
        }
        
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.9)

        collectionView!.collectionViewLayout = layout
        
    }
    
    func fetchMovies() {
        
        let currentList = movieLists[currentListIndex.rawValue]
        
        // Do nothing if busy or loaded maximum
        if fetchingMovies || currentList.movies.count == moviesPerPage * currentList.currentPage || currentList.currentPage > maxPage {
            return
        }
        
        fetchingMovies = true
        
        let currentListPage = currentList.currentPage

        Alamofire.request(TheMovieDB.Router.MovieList(currentListIndex, currentListPage)).validate().responseJSON() {
            
            response in
                switch (response.result) {
                    case .Success(let JSON):
                        
                        // If success, append new movie infos & insert cells
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                            let movieInfos = ((JSON as! NSDictionary).valueForKey("results") as! [NSDictionary]).map{ MovieInfo(representation: $0) }
                            
                            let lastItem = currentList.movies.count

                            currentList.movies.addObjectsFromArray(movieInfos)
                            
                            let indexPaths = (lastItem..<currentList.movies.count).map{ NSIndexPath(forItem: $0, inSection: 0) }
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                self.collectionView!.insertItemsAtIndexPaths(indexPaths)
                            }
                            
                            self.fetchingMovies = false
                            self.movieLists[self.currentListIndex.rawValue].currentPage++
                        }
                        
                        break
                    
                    case .Failure(let error):

                        let alertController = UIAlertController(title: "Error", message: "\(error.localizedDescription) (Code \(error.code))", preferredStyle: UIAlertControllerStyle.Alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                        self.presentViewController(alertController, animated: true, completion: nil)
                        self.fetchingMovies = false
                        
                        break
                    
                }
        }
        
        
    }
    
    // MARK: - Collection view
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return movieLists[currentListIndex.rawValue].movies.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(MovieListCellIdentifier, forIndexPath: indexPath) as! MovieListCell
        
        cell.movieInfo = movieLists[currentListIndex.rawValue].movies[indexPath.row] as? MovieInfo
        cell.posterWidth = posterWidth
        
        cell.configure()
        
        return cell

    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath)! as! MovieListCell
        cell.backgroundColor = self.view.tintColor
        cell.titleLabel!.textColor = UIColor.whiteColor()
            
        // If portrait iPad, close left pane on select
        if let split = self.splitViewController {
            if UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.Portrait {
                split.toggleMasterView()
            }
        }
        
        performSegueWithIdentifier("showDetail", sender: nil)
        
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? MovieListCell {
            cell.backgroundColor = UIColor.whiteColor()
            cell.titleLabel!.textColor = UIColor.blackColor()
        }
    }
    
    //MARK: - Scroll view
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // Infinite scroll
        if scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8 {
            fetchMovies()
        }
        
        
    }

}

class MovieListCell: UICollectionViewCell {
    @IBOutlet var imageView : UIImageView?
    @IBOutlet var titleLabel : UILabel?
    
    var movieInfo : MovieInfo?
    var posterWidth : Int?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    // Set up views
    func configure() {
        titleLabel!.text = movieInfo!.title
        
        backgroundColor = selected ? tintColor : UIColor.whiteColor()
        titleLabel!.textColor = selected ? UIColor.whiteColor() : UIColor.blackColor()
        
        // Lazy load movie poster if available
        if movieInfo!.poster_path != nil {
            
            let posterURL = "\(TheMovieDB.Router.imageURLString)\(posterWidth ?? TheMovieDB.posterWidths[0])\(movieInfo!.poster_path ?? "")"
            
            imageView!.sd_setImageWithURL(NSURL(string: posterURL), placeholderImage: UIImage(named: "No Poster Available"), completed: nil)
            
        }
    }
    
}

extension UISplitViewController {
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem()
        UIApplication.sharedApplication().sendAction(barButtonItem.action, to: barButtonItem.target, from: nil, forEvent: nil)
    }
}
