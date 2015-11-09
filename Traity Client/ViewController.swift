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

let traityKey = "tI0c1olhMQTJkJORLBM5yg"
let traitySecret = "DKHkMa5fMRvDcoqUZpEFamOy9z2kMlAO74FUw"
let userID = "cristian@crowdtransfer.com"



class ViewController: UIViewController {
    
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
        
        let sign = widget_signature(traityKey, secret: traitySecret, current_user_id: userID)
        let redirect_uri = "com.swapp.traityclient:/oauth2Callback"
        // 3 calculate final url
        let params = "?signature=\(sign)&success=\(redirect_uri)"
        
        print("https://traity.com/apps/connect\(params)")
        UIApplication.sharedApplication().openURL(NSURL(string: "https://traity.com/apps/connect\(params)")!)
        
        
        
        
        /// Mark: - NSURLSession Method
        //let authString = "\(traityKey):\(traitySecret)"
        //let authData = authString.dataUsingEncoding(NSUTF8StringEncoding)
        //let credentials = "Basic \(authData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength))"
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        //config.HTTPAdditionalHeaders = ["Authorization": credentials]
        let session = NSURLSession(configuration: config)
        
        let request = NSMutableURLRequest(urlString: "https://api.traity.com/oauth/token")
        request!.HTTPMethod = "POST"
        let dataString = "client_id=\(traityKey)&client_secret=\(traitySecret)&grant_type=client_credentials"
        let theData = dataString.dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: true)
        let task = session.uploadTaskWithRequest(request!, fromData: theData) { (data, response, error) -> Void in

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
            guard let token = jsonResult!.objectForKey("access_token") as? String else {
                print("Error Unwrapping"); return
            }
            
            //save token
            let storage = NSUserDefaults.standardUserDefaults()
            storage.setObject(token, forKey: "AccessToken")
        }
        task.resume()
    }
    
  
    @ IBAction func getReputation(sender: AnyObject) {
        let manager = SessionManager()
        
        manager.GET("/1.0/app-users/\(userID)", parameters: nil, success: { (task, response) -> Void in
            print(response)
            }, failure: { (task, response) -> Void in
                print(response)
                print("failed!")
        })
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
