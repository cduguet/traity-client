//
//  ViewController.swift
//  Traity Client
//
//  Created by Cristian Duguet on 11/2/15.
//  Copyright © 2015 Cristian Duguet. All rights reserved.
//

import UIKit
import AFOAuth2Manager
import JWT
import Foundation

let traityKey = "tI0c1olhMQTJkJORLBM5yg"
let traitySecret = "DKHkMa5fMRvDcoqUZpEFamOy9z2kMlAO74FUw"
let userID = "duguet@gmail.com"
let userIsTraity = true
let accountIcons = [    "facebook"     : "icon-facebook",
                        "twitter"      : "icon-twitter",
                        "google"       : "icon-google-plus",
                        "linkedin"     : "icon-linkedin",
                        "airbnb"       : "icon-airbnb",
                        "uber"         : "icon-uber",
                        "ebay"         : "icon-ebay",
                        "amazon"       : "icon-amazon",
                        "instagram"    : "icon-instagram",
                        "paypal"       : "icon-paypal",
                        "angelist"     : "icon-angelist",
                        "couchsurfing" : "icon-couchsurfing",
                        "passport"     : "icon-passport",
                        "smsleft"      : "icon-sms"]

let accountNames = [    "facebook"      :   "Facebook"      ,
                        "twitter"       :   "Twitter"       ,
                        "google"        :   "Google Plus"   ,
                        "linkedin"      :   "LinkedIn"      ,
                        "airbnb"        :   "Airbnb"        ,
                        "uber"          :   "Uber"          ,
                        "ebay"          :   "Ebay"          ,
                        "amazon"        :   "Amazon"        ,
                        "instagram"     :   "Instagram"     ,
                        "paypal"        :   "PayPal"        ,
                        "angelist"      :   "Angelist"      ,
                        "couchsurfing"  :   "Couchsurfing"  ,
                        "passport"      :   "Passport"      ,
                        "smsleft"       :   "SMS"           ]

struct traityReview {
    var provider: String
    var author: String
    var picture: String?
    var text : String
    var date: NSDate
}


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet var profilePicture: UIImageView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var tableView: UITableView!
    
    let actions = ["Upload Passport", "Connect to Facebook"];
    var connectedAccounts: [String] =  []
    
    
    var isObserved = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func widget_signature(key: String, secret: String, current_user_id: String, options: [String:AnyObject] = [:]) -> String {
        var payload = options as Dictionary
        payload["time"] = (Int(NSDate().timeIntervalSince1970))
        payload["current_user_id"] = current_user_id
        
        let signature = ["key": key, "payload": JWT.encode(payload, algorithm: .HS256(secret))]
        return JWT.encode(signature, algorithm: .None)
    }
    
    @IBAction func authenticate(sender: AnyObject) {
        
        
        // Mark: - Get Access Key if there is no access key saved.
        // NSURLSession Method
        let storage = NSUserDefaults.standardUserDefaults()
        
        if let _ = storage.valueForKey("AccessToken") {}
        else { getAccessToken() }
        //if let expiringDate = storage.valueForKey("TokenExpirationDate"), let refreshToken = storage.valueForKey("RefreshToken") as? String {
            //if date is expired
            //if expiringDate.compare(NSDate()) == NSComparisonResult.OrderedDescending {
                //getAccessToken(true, refreshToken: refreshToken)
            //} else { getAccessToken() }
        //}
        //else { getAccessToken() }
        
        
        //Mark: -Connect local user to Traity User
        //If the User has not already connected his account to Traity.
        if !userIsTraity {
            let sign = widget_signature(traityKey, secret: traitySecret, current_user_id: userID)
            let redirect_uri = "com.swapp.traityclient:/oauth2Callback"
            // calculate final url
            let params = "?signature=\(sign)&success=\(redirect_uri)"
            UIApplication.sharedApplication().openURL(NSURL(string: "https://traity.com/apps/connect\(params)")!)
        } else {
            getReputation()
        }
        
        //Mark: -get user reputation
        if !isObserved {
            let _ = NSNotificationCenter.defaultCenter().addObserverForName(
                "AGAppLaunchedWithURLNotification",
                object: nil,
                queue: nil,
                usingBlock: { (notification: NSNotification!) -> Void in
                    self.getReputation()
            })
            isObserved = true
        }
    }
    
    
    func getReputation() {
        let manager = SessionManager()
        
        manager.GET("/1.0/app-users/\(userID)", parameters: nil, success: { (task, response) -> Void in
            print(response)

            let picAddress = response["picture"] as? String ?? ""
            
            //Async
            self.profilePicture.downloadedFrom(link: picAddress, contentMode: UIViewContentMode.ScaleAspectFit)
            
            let h = response["verified"] as! [String]
            
            for account in h {
                if let _ = accountNames[account] {
                    self.connectedAccounts.append(account)
                }
            }
            print("number of connected profiles now is \(self.connectedAccounts.count)")
            self.tableView.reloadData()
            
            }, failure: { (task, response) -> Void in
                //print(response)
                print("Failed to get reputation.")
                // FIXME: Check if the error is the lack of Token
                self.getAccessToken()
        })
        
        
        manager.GET("/1.0/app-users/\(userID)/reviews", parameters: nil, success: { (task, response) -> Void in
        
            if let h = response["other"]! {
                print(h)
            }
            
            }, failure: { (task, response) -> Void in
                //print(response)
                print("Failed to get reviews.")
        })
        
        
    }
    
    func getAccessToken(refresh: Bool = false, refreshToken: String = "") {
    
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let request = NSMutableURLRequest(URL: NSURL(string: "https://api.traity.com/oauth/token")!)
//        let request = NSMutableURLRequest(urlString: "https://api.traity.com/oauth/token")
        request.HTTPMethod = "POST"
        
        var dataString = "client_id=\(traityKey)&client_secret=\(traitySecret)&grant_type=client_credentials"
        if refresh {
            // FIXME: not working
            print("refreshing token")
            dataString = "client_id=\(traityKey)&client_secret=\(traitySecret)&refresh_token=\(refreshToken)&grant_type=refresh_token"
        }
        
        let theData = dataString.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
        let task = session.uploadTaskWithRequest(request, fromData: theData) { (data, response, error) -> Void in
            
            // verify data return
            guard (error == nil ) else { print("There is an error in the request"); return }
            guard (data != nil) else { print("error catching data"); return }
            
            //process return
            let jsonResult : AnyObject?
            do {
                jsonResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers)
            } catch { print("Error parsing JSON") ; return }
            guard jsonResult != nil else { print("No results returned. Could not save to memory."); return }
            
            //process token
            print(jsonResult)
            guard let token = jsonResult!.objectForKey("access_token") as? String else {
                print("Error Unwrapping"); return
            }
            //save token
            let storage = NSUserDefaults.standardUserDefaults()
            storage.setObject(token, forKey: "AccessToken")

            if let expirationSeconds =  jsonResult!.objectForKey("expires_in") as? Double {
                let tokenExpirationDate = NSDate(timeIntervalSinceNow: expirationSeconds)
                storage.setObject(tokenExpirationDate, forKey: "TokenExpirationDate")
            }
            if let refreshToken =  jsonResult!.objectForKey("refresh_token") as? String {
                storage.setObject(refreshToken, forKey: "RefreshToken")
            }
        }
        task.resume()
    }
    
    func uploadPassport(source: UIImagePickerControllerSourceType =  .Camera) {
        var image = UIImagePickerController()
        image.delegate = self
        image.sourceType = source
        image.allowsEditing = false
        
        self.presentViewController(image, animated: true, completion: nil)
    }
    
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        print("image selected")
        var image2 = image
        
        if image.size.width > 1000 {
            image2 = Images.resizeImage(image, width: 1000)!
        }
        let imageData = UIImagePNGRepresentation(image2)
        
        //Encoding
        let base64String = imageData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        //print(base64String)
        let param = ["passport": base64String]
        
        let manager = SessionManager()
        
        manager.PUT("/1.0/app-users/\(userID)/passport", parameters: param, success: { (task, response) -> Void in
            print(response)
            
            }, failure: { (task, response) -> Void in
                print(response)
                print("Failed to upload passport.")
        })
        
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    ///MARK :- ViewController Methods
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    ///MARK: -Table Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("actionsCell")!
            cell.textLabel!.text  = actions[indexPath.row]
            return cell

        case 1:
            let cell : ConnectedAccountsCell = self.tableView.dequeueReusableCellWithIdentifier("connectedAccountsCell")! as! ConnectedAccountsCell

            cell.accountTitle!.text  = accountNames[connectedAccounts[indexPath.row]]!
            cell.accountIcon.image = UIImage(named: accountIcons[connectedAccounts[indexPath.row]]!)
            return cell
            
        default:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("connectedProfilesCell")!
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return actions.count
        case 1:
            return connectedAccounts.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Actions"
        case 1:
            return "Verified Profiles"
        default:
            return ""
        }
    }
    
    
    //select cells
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                print("upload Passport")
                let actionSheet =  UIAlertController(title: "Upload Passport", message: "", preferredStyle: .ActionSheet)
                actionSheet.addAction(UIAlertAction(title: "Take Photo", style: .Default, handler: { (action) -> Void in
                    self.uploadPassport(UIImagePickerControllerSourceType.Camera)
                }))
                actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .Default, handler: { (action) -> Void in
                    self.uploadPassport(UIImagePickerControllerSourceType.PhotoLibrary)
                }))
                self.presentViewController(actionSheet, animated: true, completion: nil)
                break
            case 1:
                print("Connect to Facebook")
                break
            default:
                break
            }
            break
        case 1:
            break
        default:
            break
        }
    }
}



/// Mark: - Extension Download images

extension UIImageView {
    func downloadedFrom(link link:String, contentMode mode: UIViewContentMode) {
        guard
            let url = NSURL(string: link)
            else {return}
        contentMode = mode
        NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, _, error) -> Void in
            guard
                let data = data where error == nil,
                let image = UIImage(data: data)
                else { return }
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.image = image
            }
        }).resume()
    }
}
