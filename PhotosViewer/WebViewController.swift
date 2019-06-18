//
//  WebViewController.swift
//  PhotosViewer
//
//  Created by Nathan Taylor on 6/16/19.
//  Copyright © 2019 Nathan Taylor. All rights reserved.
//

import Foundation
import WebKit

class WebViewController : UIViewController {
    func load(url: URL) -> WKNavigation? {
        self.loadViewIfNeeded()
        return webView?.load(URLRequest(url: url))
    }
    
    var webView: WKWebView?
    
    override func loadView() {
        super.loadView()
        
        let subview = WKWebView(frame: .zero)
        self.view.addSubview(subview)

        self.webView = subview
        self.view.setNeedsLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView?.frame = self.view.bounds
    }
}


