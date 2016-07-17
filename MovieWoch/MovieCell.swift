//
//  MovieCell.swift
//  MovieWoch
//
//  Created by Saumeel Gajera on 7/14/16.
//  Copyright © 2016 walmart. All rights reserved.
//

import UIKit

class MovieCell: UITableViewCell {

    @IBOutlet weak var movieTitleLabel: UILabel!
    @IBOutlet weak var movieSummaryLabel: UILabel!
    @IBOutlet weak var movieImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        movieTitleLabel.sizeToFit()
//        movieSummaryLabel.sizeToFit()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
