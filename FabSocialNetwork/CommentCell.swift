//
//  CommentCell.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-09.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Alamofire
import Firebase

class CommentCell: UITableViewCell {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var textLbl: UILabel!
    
    private var _comment: Comment!
    private var _post: Post!
    private var _userRef: Firebase!
    
    var request: Request?
    
    var post: Post {
        return _post
    }
    
    var comment: Comment {
        return _comment
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func drawRect(rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(comment: Comment) {
        print("Configure comment cell")
        self._comment = comment
        
        print("\(comment.userKey)")
        
        self._userRef = DataService.ds.REF_USERS.childByAppendingPath(comment.userKey)
        self.textLbl.text = comment.commentText
        
        _userRef.observeEventType(.Value, withBlock: { snapshot in
            print(snapshot.value)
            
            if let username = snapshot.value["username"] as? String {
                self.usernameLbl.text = username
            } else {
                self.usernameLbl.text = "Default Username"
            }
            
            if let profileUrl = snapshot.value["imgUrl"] as? String {
                
                print(profileUrl)
                
                // Not in cache, download and add to cache
                self.request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                    if err == nil {
                        let img = UIImage(data: data!)!
                        self.profileImg.image = img
                        FeedVC.imageCache.setObject(img, forKey: profileUrl)
                    }
                })
            } else {
                print("No profile img")
                self.profileImg.hidden = true
            }
            
            
            }, withCancelBlock: { error in
                print(error.description)
        })

        print("Configure cell, text entered: \(comment.commentText)")
        
    }
}