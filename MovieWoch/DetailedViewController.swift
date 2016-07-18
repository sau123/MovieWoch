//
//  DetailedViewController.swift
//  MovieWoch
//
//  Created by Saumeel Gajera on 7/16/16.
//  Copyright © 2016 walmart. All rights reserved.
//

import UIKit

class DetailedViewController: UIViewController {
    @IBOutlet weak var detailedImageView: UIImageView!
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var movieSummary: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    
    
    var movie: NSDictionary!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setting scrollview's width and height.
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)
        
        let title = movie["title"] as! String
        let summary = movie["overview"] as! String
        let moviePath = movie["poster_path"] as! String
        
        movieTitle.text = title
        movieSummary.text = summary
        movieSummary.sizeToFit()
        
        detailedImageView.setImageWithURL(NSURL(string: "https://image.tmdb.org/t/p/w342/\(moviePath)")!)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
