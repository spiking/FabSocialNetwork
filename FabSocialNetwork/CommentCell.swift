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
import Async

class CommentCell: UITableViewCell {
    
    var blockUserTapAction: ((UITableViewCell) -> Void)?
    var usernameTapAction: ((UITableViewCell) -> Void)?
    var profileImgTapAction: ((UITableViewCell) -> Void)?
    
    private var _comment: Comment!
    private var _post: Post!
    private var _userRef: FIRDatabaseReference!
    private var _request: Request?
    
    var post: Post {
        return _post
    }
    
    var comment: Comment {
        return _comment
    }
    
    var request: Request? {
        return _request
    }
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var textLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let usernameTapped = UITapGestureRecognizer(target: self, action: #selector(CommentCell.usernameTapped(_:)))
        usernameTapped.numberOfTapsRequired = 1
        usernameLbl.addGestureRecognizer(usernameTapped)
        usernameLbl.userInteractionEnabled = true
        
        let profileImgTapped = UITapGestureRecognizer(target: self, action: #selector(CommentCell.profileImgTapped(_:)))
        profileImgTapped.numberOfTapsRequired = 1
        profileImg.addGestureRecognizer(profileImgTapped)
        profileImg.userInteractionEnabled = true
        
    }
    
    override func drawRect(rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func usernameTapped(sender: UITapGestureRecognizer) {
        
        self.usernameLbl.userInteractionEnabled = false
        self.usernameTapAction?(self)
        
        Async.background(after: 0.3) {
            self.usernameLbl.userInteractionEnabled = true
        }
    }
    
    func profileImgTapped(sender: UITapGestureRecognizer) {
        
        self.profileImg.userInteractionEnabled = false
        self.profileImgTapAction?(self)
        
        Async.background(after: 0.3) {
            self.profileImg.userInteractionEnabled = true
        }
    }
    
    func configureCell(comment: Comment) {
        
        self._comment = comment
        self._userRef = DataService.ds.REF_USERS.child(comment.userKey)
        self.textLbl.text = comment.commentText
        
        _userRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if let username = snapshot.value!["username"] as? String {
                self.usernameLbl.text = username.capitalizedString
            } else {
                self.usernameLbl.text = "Default Username"
            }
            
            if let profileUrl = snapshot.value!["imgUrl"] as? String {
                if let profImage = FeedVC.imageCache.objectForKey(profileUrl) as? UIImage {
                    self.profileImg.image = profImage
                } else {
                    self._request = Alamofire.request(.GET, profileUrl).validate(contentType: ["image/*"]).response(completionHandler: { (request, response, data, err) in
                        if err == nil {
                            let img = UIImage(data: data!)!
                            self.profileImg.image = img
                            FeedVC.imageCache.setObject(img, forKey: profileUrl)
                        }
                    })
                    
                }
            } else {
                self.profileImg.image = UIImage(named:"NoProfileImage.png")
            }
            
            }, withCancelBlock: { error in
                print(error.description)
        })

    }
}
