//
//  AccountManager.swift
//  PhotosViewer
//
//  Created by Nathan Taylor on 6/16/19.
//  Copyright © 2019 Nathan Taylor. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class Account : NSObject {
    let token : String
    
    init(token: String) {
        self.token = token
    }
    
    var sessionConfiguration : URLSessionConfiguration? {
        let config = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        config.httpAdditionalHeaders = [ "Authorization" : token ]
        return config
    }
}

protocol AccountManagerDelegate : NSObject {
    func accountManager(_ accountManager: AccountManager, didLogin account: Account)
    func accountManagerDidLogout(_ accountManager: AccountManager)
}

class AccountManager : NSObject, WKNavigationDelegate {
    // MARK: - Pubrlic
    weak var delegate: AccountManagerDelegate?
    @IBOutlet var navigationController: UINavigationController?
    var accountViewController: WebViewController? {
        return navigationController?.viewControllers[0] as? WebViewController
    }
    
    var currentAccount: Account? {
        get {
            var account: Account? = nil
            os_unfair_lock_lock(&_lock)
            account = _account
            os_unfair_lock_unlock(&_lock)
            return account
        }
        set {
            var oldValue: Account?
            
            os_unfair_lock_lock(&_lock)
            oldValue = _account
            _account = newValue
            os_unfair_lock_unlock(&_lock)
            
            if oldValue != newValue {
                if let account = newValue {
                    delegate?.accountManager(self, didLogin: account)
                }
                else {
                    delegate?.accountManagerDidLogout(self)
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        login()
    }
    
    @IBAction func login() {
        let viewController = self.accountViewController
        viewController?.title = "Log In"
        viewController?.navigationItem.hidesBackButton = true
        
        viewController?.loadViewIfNeeded()
        viewController?.webView?.navigationDelegate = self
        loginNavigation = viewController?.load(url: loginURL)
    }
    
    @IBAction func logout() {
        let viewController = self.accountViewController
        viewController?.title = "Logged Out"
        viewController?.navigationItem.hidesBackButton = true

        let rightItem = UIBarButtonItem(title: "Log In", style: .done, target: self, action: #selector(AccountManager.login))
        viewController?.navigationItem.rightBarButtonItem = rightItem
        
        viewController?.loadViewIfNeeded()
        viewController?.webView?.navigationDelegate = self
        logoutNavigation = viewController?.load(url: logoutURL)
    }
    
    @IBAction func showPhotos(account: Account) {
        guard let config = account.sessionConfiguration else { return }
        
        let viewController = PhotosViewController(photoManager: PhotoManager(configuration: config))
        viewController.title = "Photos"
        viewController.navigationItem.hidesBackButton = true
        
        let rightItem = UIBarButtonItem(title: "Log Out", style: .done, target: self, action: #selector(AccountManager.logout))
        viewController.navigationItem.rightBarButtonItem = rightItem
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(viewController, animated: true)

    }

    // MARK: - Private
    private let clientID = "5khm2intordkd1jjr7rbborbfj"
    private let redirectURL = "https://www.23andme.com/"
    private let loginHost = "insta23prod.auth.us-west-2.amazoncognito.com"
    private let loginPath = "/login"
    private let logoutPath = "/logout"
    
    private var _lock = os_unfair_lock_s()
    private var _account: Account? = nil
    
    private var loginNavigation: WKNavigation?
    private var logoutNavigation: WKNavigation?
    
    private var loginURL: URL {
        let components = NSURLComponents()
        components.scheme = "https"
        components.host = loginHost
        components.path = loginPath
        components.queryItems = [ URLQueryItem(name: "response_type", value: "token"), URLQueryItem(name: "client_id", value: clientID), URLQueryItem(name: "redirect_uri", value: redirectURL)]
        
        return components.url!
    }
    
    private var logoutURL: URL {
        let components = NSURLComponents()
        components.scheme = "https"
        components.host = loginHost
        components.path = logoutPath
        components.queryItems = [ URLQueryItem(name: "response_type", value: "token"), URLQueryItem(name: "client_id", value: clientID), URLQueryItem(name: "logout_uri", value: redirectURL)]
        
        return components.url!
    }
    
    private func token(from fragment: String) -> String? {
        var token: String?
        let fragments = fragment.components(separatedBy: "&")
        for fragment in fragments {
            let pair = fragment.components(separatedBy: "=")
            if pair.count == 2 && pair[0] == "id_token" {
                token = pair[1]
                break
            }
        }
        return token
    }
    
    // MARK: - WebViewControllerDelegateProtocol
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var result: WKNavigationActionPolicy = .allow
        if let url = navigationAction.request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let host = components.host, host == "www.23andme.com" {
            
            if let fragment = components.fragment, let token = token(from: fragment) {
                let account = Account(token: token)
                currentAccount = account
                result = .cancel
                
                DispatchQueue.main.async {
                    self.showPhotos(account: account)
                }
            }
        }
        decisionHandler(result)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if navigation == logoutNavigation {
            currentAccount = nil
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }

}
