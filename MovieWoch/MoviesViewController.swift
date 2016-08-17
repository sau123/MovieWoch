//
//  MoviesViewController.swift
//  MovieWoch
//
//  Created by Saumeel Gajera on 7/13/16.
//  Copyright © 2016 walmart. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import AFNetworking
import MBProgressHUD
import SVProgressHUD
import UIAlertView_Blocks


public class Reachability{
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
}

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var networkErrorDescription: UILabel!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    var movies : [NSDictionary]?
    var filteredMovies : [NSDictionary] = []
    var searchActive : Bool = false
    
    var refreshControl : UIRefreshControl!
    var endpoint : String!
    
    @IBAction func onSegmentControlTapped(sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        if index == 0{
            collectionView.hidden = true
            tableView.hidden = false
        }else{
            collectionView.hidden = false
            tableView.hidden = true
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        print("start")
        let arr = self.movies!
        let filteredMovies = arr.filter{
            ($0["title"] as! String).containsString(searchText)
        }
        
        if filteredMovies.count == 0{
            searchActive = false
        }else{
            searchActive = true
        }
        self.filteredMovies = filteredMovies
        print("count of filtered moives : \(filteredMovies.count)")
        //        print("filtered Movies :\(filteredMovies)")
        self.tableView.reloadData()
        self.collectionView.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searchActive{
            return filteredMovies.count
        }else{
            if let movies = movies{
                return movies.count
            }else{
                return 0
            }
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        print("index row : \(indexPath.row)")
        let gridCell = collectionView.dequeueReusableCellWithReuseIdentifier("GridViewCell", forIndexPath: indexPath) as! GridViewCell
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.grayColor()
        gridCell.selectedBackgroundView = backgroundView
        
        let movie : NSDictionary
        
        if searchActive {
            movie = filteredMovies[indexPath.row]
        } else {
            movie = movies![indexPath.row]
        }
        
        let title = movie["title"] as! String
        let moviePath = movie["poster_path"] as! String
        
        gridCell.gridMovieTitle.text = title
        gridCell.gridMovieImage.setImageWithURL(NSURL(string: "https://image.tmdb.org/t/p/w342/\(moviePath)")!)
        
        return gridCell
    }
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }
    
    func networkRequest(){
        
        if Reachability.isConnectedToNetwork() == false {
            print("not connected")
            networkErrorView.hidden = false
            tableView.hidden = true
            
            networkErrorDescription.sizeToFit()
            
//            let alert = UIAlertView(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", delegate: nil, cancelButtonTitle: "OK")
//            alert.show()
            let alert = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", preferredStyle: UIAlertControllerStyle.Alert)
            presentViewController(alert, animated: true, completion: nil)
            return
        }else{
            tableView.hidden = false
            networkErrorView.hidden = true
        }
        
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.Dark)
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Gradient)
        SVProgressHUD.setBackgroundColor(UIColor.whiteColor())
        
        SVProgressHUD.show()
        SVProgressHUD.showWithStatus("Loading Movies..")
        
        // Do any additional setup after loading the view.
        
        let api_key = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(api_key)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: {
            (dataOrNil, response, error) in
            if let data = dataOrNil {
                if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSDictionary{
                    //                    NSLog("response \(responseDictionary)")
                    
                    self.movies = (responseDictionary["results"] as! [NSDictionary])
                    self.tableView.reloadData()
                    self.collectionView.reloadData()
                    let delay = NSTimeInterval.init(2)
                    print("delay : \(delay)")
                    
                    SVProgressHUD.dismissWithDelay(delay)
                }
            }
        });
        task.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        tableView.dataSource = self
        tableView.delegate = self
        
        collectionView.hidden = true
        
        searchBar.delegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshTableView", forControlEvents: .ValueChanged)
        
        refreshControl.beginRefreshing()
        networkRequest()
        tableView.insertSubview(refreshControl, atIndex: 0)
        refreshControl.endRefreshing()
        
        
    }
    
    // on refresh, list changes from now_playing to top_rated movies
    func refreshTableView(){
        print("in refresh table view")
        
        refreshControl.beginRefreshing()
        networkRequest()
        refreshControl.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if searchActive{
            return filteredMovies.count
        }else{
            if let movies = movies{
                return movies.count
            }else{
                return 0
            }
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        //        cell.selectionStyle = UITableViewCellSelectionStyle.
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.blackColor()
        cell.selectedBackgroundView = backgroundView
        
        let movie : NSDictionary
        if searchActive {
            movie = filteredMovies[indexPath.row]
        } else {
            movie = movies![indexPath.row]
        }
        
        let title = movie["title"] as! String
        let summary = movie["overview"] as! String
        let moviePath = movie["poster_path"] as! String
        
        cell.movieTitleLabel.text = title
        cell.movieSummaryLabel.text = summary
        
        
        let imageHttpString = "https://image.tmdb.org/t/p/w45/\(moviePath)"
        let smallImageRequest = NSURLRequest(URL: NSURL(string: imageHttpString)!)
        
        let imageHttpString1 = "https://image.tmdb.org/t/p/original/\(moviePath)"
        let largeImageRequest = NSURLRequest(URL: NSURL(string: imageHttpString1)!)
        
        cell.movieImage.setImageWithURLRequest(
            smallImageRequest,
            placeholderImage: nil,
            success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                
                // smallImageResponse will be nil if the smallImage is already available
                // in cache (might want to do something smarter in that case).
                print("smallimagerequest : \(smallImageRequest)")
                print("smallimageresponse : \(smallImageResponse)")
                print("small Image : \(smallImage)")
                
                
                // logic 
                /*
                    if small image is in cache, large image will also be in cache
                    if small image in not in cache, large image will also not be in cache.
                 
                    always displaying the large image, just that first time, it gets displayed with animation, second time it just gets displayed.
                */
                if smallImageResponse != nil {
                    cell.movieImage.alpha = 0.0
                    cell.movieImage.image = smallImage;
                
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                    
                        cell.movieImage.alpha = 1.0
                    
                        }, completion: { (sucess) -> Void in
                        
                            // The AFNetworking ImageView Category only allows one request to be sent at a time
                            // per ImageView. This code must be in the completion block.
                        
                            cell.movieImage.setImageWithURLRequest(
                                largeImageRequest,
                                placeholderImage: smallImage,
                                success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                    
                                        cell.movieImage.image = largeImage;
                                
                                },
                                failure: { (request, response, error) -> Void in
                                    // do something for the failure condition of the large image request
                                    // possibly setting the ImageView's image to a default image
                            })
                    })
                }else{
                    print ("small image was cached!")
                    cell.movieImage.setImageWithURLRequest(
                        largeImageRequest,
                        placeholderImage: smallImage,
                        success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                            print("large image in cache, mostly !!!")
                            cell.movieImage.image = largeImage;
                            
                        },
                        failure: { (request, response, error) -> Void in
                            // do something for the failure condition of the large image request
                            // possibly setting the ImageView's image to a default image
                    })
                

                }
        
            },
            failure: { (request, response, error) -> Void in
                // do something for the failure condition
                // possibly try to get the large image
        })
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let indexPath : NSIndexPath!
        
        if (segue.identifier == "listViewSegue"){
            print("segue of table view")
            let cell = sender as! UITableViewCell!
            indexPath = tableView.indexPathForCell(cell)
        }else{
            print("segue of grid view")
            let cell = sender as! UICollectionViewCell!
            indexPath = collectionView.indexPathForCell(cell)
        }
        
        var movie : NSDictionary!
        if searchActive{
            movie = filteredMovies[indexPath!.row]
        }else{
            movie = movies![indexPath!.row]
        }
        let destinationController = segue.destinationViewController as! DetailedViewController
        destinationController.movie = movie
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
}
