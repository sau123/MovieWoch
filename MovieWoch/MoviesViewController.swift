//
//  MoviesViewController.swift
//  MovieWoch
//
//  Created by Saumeel Gajera on 7/13/16.
//  Copyright © 2016 walmart. All rights reserved.
//

import UIKit
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

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var networkErrorDescription: UILabel!
    @IBOutlet weak var networkErrorView: UIView!
    
    var movies : [NSDictionary]?
    var refreshControl : UIRefreshControl!
    var endpoint : String!
    
    func networkRequest(){
        
        
        if Reachability.isConnectedToNetwork() == false {
            print("not connected")
            networkErrorView.hidden = false
            tableView.hidden = true
            
            networkErrorDescription.sizeToFit()
            
            let alert = UIAlertView(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            //            var alert = UIAlertController(title: "No Internet Connection", message: "Make sure your device is connected to the internet.", preferredStyle: UIAlertControllerStyle.Alert)
            //            showViewController(alert, sender: networkErrorDescription )
            
            return
        }else{
            tableView.hidden = false
            networkErrorView.hidden = true
        }
        
//        hud.mode = MBProgressHUDModeAnnularDeterminate;
        
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
        
        tableView.dataSource = self
        tableView.delegate = self
        endpoint = "now_playing"
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshTableView", forControlEvents: .ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)

        networkRequest()
        
    }
    
    // on refresh, list changes from now_playing to top_rated movies
    func refreshTableView(){
        print("in refresh table view")
        endpoint = "top_rated"
        refreshControl.beginRefreshing()
        networkRequest()
        refreshControl.endRefreshing()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if let movies = movies{
            return movies.count
        }else{
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        let movie = movies![indexPath.row]
        let title = movie["title"] as! String
        let summary = movie["overview"] as! String
        let moviePath = movie["poster_path"] as! String
        
        cell.movieTitleLabel.text = title
        cell.movieSummaryLabel.text = summary
        cell.movieImage.setImageWithURL(NSURL(string: "https://image.tmdb.org/t/p/w342/\(moviePath)")!)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell!
        let indexPath = tableView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        
        let destinationController = segue.destinationViewController as! DetailedViewController
        
        destinationController.movie = movie
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
}
