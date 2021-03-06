//
//  ShowUserPostVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-28.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import JSSAlertView

class ShowUserPostVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var post: Post!

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsetsMake(-8, 0, 0, 0)
        
        loadiPhoneTypeRowHeight()
        tableView.rowHeight = UITableViewAutomaticDimension
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)

        title = "POST"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SEGUE_COMMENTSVC {
            if let commentsVC = segue.destinationViewController as? CommentsVC {
                if let post = sender as? Post {
                    commentsVC.post = post
                }
            }
        }
    }
    
    func loadiPhoneTypeRowHeight() {
        switch iphoneType {
        case "4":
            tableView.estimatedRowHeight = 400
        case "5":
            tableView.estimatedRowHeight = 425
        case "6":
            tableView.estimatedRowHeight = 450
        case "6+":
            tableView.estimatedRowHeight = 550
        default:
            tableView.estimatedRowHeight = 550
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        if post.imageUrl == nil || post.imageUrl == "" {
            return 110 + heightForView(post.postDescription, width: screenWidth - 24)
            
        } else {
            return tableView.estimatedRowHeight + heightForView(post.postDescription, width: screenWidth - 24)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            
            // Cancel request if user scrolls
            cell.request?.cancel()
            var img: UIImage?
            
            // Load post image from local cache
            if let url = post.imageUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(post, img: img)
            
            // Push comment segue which will be executed when tapped
            cell.commentTapAction = { (cell) in
                self.performSegueWithIdentifier(SEGUE_COMMENTSVC, sender: self.post)
            }
            
            cell.reportTapAction = { (cell) in
                self.reportAlert()
            }
            
            cell.layoutIfNeeded()
            
            return cell
            
        } else {
            return PostCell()
        }
    }
    
    func reportAlert() {
        let alertview = JSSAlertView().show(self, title: "Report", text: "Do you want to report this post for containing objectionable content? \n", buttonText: "Yes", cancelButtonText: "No", color: UIColorFromHex(0xe64c3c, alpha: 1))
        alertview.setTextTheme(.Light)
        alertview.addAction(reportAnswerYes)
        alertview.addCancelAction(reportAnswerNo)
    }
    
    func reportAnswerYes() {
        reportUserPost(self.post.postKey)
    }
    
    func reportAnswerNo() {
        // Do nothing
    }
}
