//
//  File.swift
//  Traity Client
//
//  Created by Cristian Duguet on 11/4/15.
//  Copyright © 2015 Cristian Duguet. All rights reserved.
//


import UIKit
import AFNetworking
import SwiftHTTP


class SessionManager : AFHTTPSessionManager {
    
    init(baseURL url: NSURL!) {
        super.init(baseURL: url, sessionConfiguration: nil)
        requestSerializer = AFJSONRequestSerializer();
        responseSerializer = AFJSONResponseSerializer();
    }

    convenience init() {
        let path = NSBundle.mainBundle().pathForResource("Settings", ofType: "plist")
        //let host = NSDictionary(contentsOfFile: path!)?.objectForKey("API Host") as! String
        let host = "https://api.traity.com"
        
        self.init(baseURL:NSURL(string: host))
    }
    
    override func dataTaskWithRequest(request: NSURLRequest, completionHandler: ((NSURLResponse, AnyObject?, NSError?) -> Void)?) -> NSURLSessionDataTask {
        let req = request as! NSMutableURLRequest
        let storage = NSUserDefaults.standardUserDefaults()
        if let accessToken = storage.objectForKey("AccessToken") as? String {
            req.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }
        return super.dataTaskWithRequest(req, completionHandler: completionHandler)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
