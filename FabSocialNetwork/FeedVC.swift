//
//  FeedVC.swift
//  FabSocialNetwork
//
//  Created by Adam Thuvesen on 2016-06-05.
//  Copyright © 2016 Adam Thuvesen. All rights reserved.
//

import UIKit
import Firebase
import Alamofire
import SCLAlertView
import MobileCoreServices
import EZLoadingActivity


class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var posts = [Post]()
    static var imageCache = NSCache() // Static since single instance (global)
    var imagePicker: UIImagePickerController!
    var imageSelected = false
    var noConnectionAlerts = 0
    var typeOfLogin = ""
    var placeHolderText = "Anything you would like to share?"
    var refreshControl: UIRefreshControl!
    
    @IBOutlet weak var postViewHeight: NSLayoutConstraint!
    @IBOutlet weak var postView: MaterialView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postTextViewHeight: NSLayoutConstraint!
    @IBOutlet weak var postTextView: MaterialTextView!
    @IBOutlet weak var imageSelector: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(FeedVC.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl) // not required when using UITableViewController
        
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        
        postTextView.delegate = self
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.navigationBar.tintColor = UIColor.blackColor()
        
        tableView.estimatedRowHeight = 500
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FeedVC.dismisskeyboard))
        view.addGestureRecognizer(tap)
        
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.setImage(UIImage(named: "profile2.png"), forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(FeedVC.profileBtnPressed), forControlEvents: UIControlEvents.TouchUpInside)
        button.frame = CGRectMake(0, 0, 40, 40)
        let barButton = UIBarButtonItem(customView: button)
        self.navigationItem.rightBarButtonItem = barButton
        
        loginMessage()
        
        self.title = "FAB NETWORK"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
        
        if isConnectedToNetwork() {
            print("Connected!")
            EZLoadingActivity.show("Loading...", disableUI: false)
        }
        
        // NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(FeedVC.isConnected), userInfo: nil, repeats: true)
        
        loadProfileData()
        
        print("User logged in as \(typeOfLogin)")
        
        initObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        if postTextView.text == "" || postTextView.text == placeHolderText {
            postTextView.text = placeHolderText
            postTextView.textColor = UIColor.lightGrayColor()
        } else {
            postTextView.textColor = UIColor.blackColor()
        }
    }
    
    func initObservers() {
        
        // Observe changes in Firebase, update instantly
        DataService.ds.REF_POSTS.observeEventType(.Value, withBlock: { snapshot in
            self.posts = []
            
            if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshot {
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                        
                    }
                }
            }
            
            EZLoadingActivity.hide()
            self.tableView.reloadData()
        })
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            
            // Cancel request if user scrolls
            cell.request?.cancel()
            let post = posts[indexPath.row]
            var img: UIImage?
            
            // Load post image from local cache
            if let url = post.imageUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage
            }
            
            cell.configureCell(post, img: img)
            
            // Push comment segue which will be executed when tapped
            cell.commentsTapAction = { (cell) in
                self.performSegueWithIdentifier("CommentsVC", sender: post)
            }
            
            return cell
            
        } else {
            return PostCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = posts[indexPath.row]
        
        let textLength = post.postDescription.characters.count
        
        print(textLength)
        
        
        if post.imageUrl == nil || post.imageUrl == "" {
            
            // Temp solution, not working properly. Need dynamic fix.
            
            if textLength < 75 {
                return 200
            } else if textLength < 100 {
                return 225
            } else if textLength < 125 {
                return 250
            } else if textLength < 150 {
                return 275
            } else if textLength < 175 {
                return 300
            } else if textLength < 200 {
                return 325
            } else {
                return 350
            }
            
        } else {
            return tableView.estimatedRowHeight
        }
    }
    
    func refresh(sender:AnyObject) {
        
        if isConnectedToNetwork() {
            tableView.reloadData()
            refreshControl.endRefreshing()
        } else {
            refreshControl.endRefreshing()
            infoAlert("No Internet Connection", subTitle: "\nPlease connect to a network and try again.")
        }
    }
    
    func profileBtnPressed() {
        dismisskeyboard()
        self.performSegueWithIdentifier("ProfileVC", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        dismisskeyboard()
        
        if segue.identifier == "CommentsVC" {
            if let commentsVC = segue.destinationViewController as? CommentsVC {
                if let post = sender as? Post {
                    commentsVC.post = post
                }
            }
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelector.image = image
        imageSelected = true
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelector.image = UIImage(named: "camera")
        imageSelected = false
    }
    
    func dismisskeyboard() {
        view.endEditing(true)
    }
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        postTextView.textColor = UIColor.blackColor()
        
        if postTextView.text == placeHolderText {
            postTextView.text = ""
        }
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        
        if postTextView.text == "" {
            postTextView.text = placeHolderText
            postTextView.textColor = UIColor.lightGrayColor()
        }
        
        view.removeConstraint(postViewHeight)
        view.removeConstraint(postTextViewHeight)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        postViewHeight = NSLayoutConstraint(item: postView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 161)
        postTextViewHeight = NSLayoutConstraint(item: postTextView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: 89)
        
        view.addConstraint(postViewHeight)
        view.addConstraint(postTextViewHeight)
    }
    
    func loginMessage() {
        if typeOfLogin == "OldAccount" {
            successAlert("Welcome back", subTitle: "\nYou have successfully been logged in!")
        } else if typeOfLogin == "NewAccount" {
            successAlert("Welcome", subTitle: "\nA new account has successfully been created!")
        } else {
            // Do nothing
        }
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "No Posts"
        } else {
            str = "No Internet Connection"
        }
        
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        var str = ""
        if isConnectedToNetwork() {
            str = "It looks like there are no posts. If you like, add one above."
        } else {
            str = "Please connect to a network and the feed will load automatically."
        }
        let attrs = [NSFontAttributeName: UIFont.preferredFontForTextStyle(UIFontTextStyleBody)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        var imgName = ""
        if isConnectedToNetwork() {
            imgName = "write_15"
        } else {
            imgName = "network_20"
        }
        
        return UIImage(named: imgName)
    }
    
    func postToFireBase(imgUrl: String?) {
        
        var post: Dictionary<String, AnyObject> = [
            "description": postTextView.text!,
            "likes": 0,
            "user" : NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) as! String
        ]
        
        if imgUrl != nil {
            post["imageUrl"] = imgUrl!
        } else {
            post["imageUrl"] = ""
        }
        
        // Add post to firebase
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        imageSelected = false
        
        postTextView.text = placeHolderText
        postTextView.textColor = UIColor.lightGrayColor()
        imageSelector.image = UIImage(named: "camera")
        
        EZLoadingActivity.Settings.SuccessText = "Uploded"
        EZLoadingActivity.hide(success: true, animated: true)
        
        tableView.reloadData()
    }
    
    // If app has been reinstalled, must fetch user data from firebase 
    
    func loadProfileData() {
        
        if NSUserDefaults.standardUserDefaults().objectForKey("profileUrl") == nil  || NSUserDefaults.standardUserDefaults().objectForKey("username") == nil {
            print("Profile url or username is nil, load from firebase")
            
            DataService.ds.REF_USER_CURRENT.observeEventType(.Value, withBlock: { snapshot in
                
                if let snapshot = snapshot.children.allObjects as? [FDataSnapshot] {
                    
                    for snap in snapshot {
                        
                        if snap.key == "imgUrl" {
                            let profileUrl = snap.value
                            NSUserDefaults.standardUserDefaults().setValue(profileUrl, forKey: "profileUrl")
                            print("Added prof url \(profileUrl)")
                        }
                        
                        if snap.key == "username" {
                            let username = snap.value
                            NSUserDefaults.standardUserDefaults().setValue(username, forKey: "username")
                            print("Added username \(username)")
                        }
                        
                        print("Nothing to add!")
                        
                    }
                }
            })
        } else {
            print("Profile data is up to date")
        }
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
        imagePicker.allowsEditing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    
    @IBAction func makePost(sender: AnyObject) {
        
        print("Post!")
        dismisskeyboard()
        
        let profileUrl = NSUserDefaults.standardUserDefaults().valueForKey("profileUrl") as? String
        let username = NSUserDefaults.standardUserDefaults().valueForKey("username") as? String
        
        if profileUrl == nil || username == nil {
            infoAlert("Action not allowed", subTitle: "\nPlease add a profile image and username before posting.")
            return;
        }
        
        if !isConnectedToNetwork() {
            infoAlert("No Internet Connection", subTitle: "\nTo make a post please connect to a network.")
            return
        }
        
        if let txt = postTextView.text where txt != "" && postTextView.text != placeHolderText {
            
            EZLoadingActivity.show("Uploading...", disableUI: false)
            
            if let img = imageSelector.image where imageSelected == true {
                
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                
                // Convert to JPG & compress 70 %
                let imgData = UIImageJPEGRepresentation(img, 0.3)!
                
                // Convert Imageshack API key to data format
                let keyData = "12DJKPSU5fc3afbd01b1630cc718cae3043220f3".dataUsingEncoding(NSUTF8StringEncoding)!
                
                // Convert JSON to data format
                let keyJson = "json".dataUsingEncoding(NSUTF8StringEncoding)!
                
                // Upload post image with ImageShack
                Alamofire.upload(.POST, url, multipartFormData: { MultipartFormData in
                    
                    MultipartFormData.appendBodyPart(data: keyData, name: "key")
                    MultipartFormData.appendBodyPart(data: imgData, name: "fileupload", fileName: "image", mimeType: "image/jpg")
                    MultipartFormData.appendBodyPart(data: keyJson, name: "format")
                    
                    }, encodingCompletion: { encodingResult in
                        switch encodingResult {
                            
                        case .Success(let upload, _, _):
                            upload.responseJSON(completionHandler: { response in
                                
                                if let info = response.result.value as? Dictionary<String,AnyObject> {
                                    if let links = info["links"] as? Dictionary<String,AnyObject> {
                                        if let imageLink = links["image_link"] as? String {
                                            print("LINK: \(imageLink)")
                                            self.postToFireBase(imageLink)
                                        }
                                        
                                    }
                                    
                                }
                                
                            })
                            
                        case.Failure(let error):
                            print(error)
                        }
                        
                })
                
            } else {
                self.postToFireBase(nil)
            }
            
        } else {
            infoAlert("No description", subTitle: "\nPlease add a description before posting.")
        }
    }
}
