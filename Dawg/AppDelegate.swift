//
//  AppDelegate.swift
//  Dawg
//
//  Created by Daniel Büchele on 11/29/14.
//  Copyright (c) 2014 Daniel Büchele. All rights reserved.
//

import Cocoa
import WebKit
import Quartz

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate, NSWindowDelegate {
    
    @IBOutlet var window : NSWindow!
    var webView : WKWebView!
    @IBOutlet var view : NSView!
    @IBOutlet var loadingView : NSImageView!
    @IBOutlet var longLoading : NSTextField!
    @IBOutlet var reactivationMenuItem : NSMenuItem!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var timer : NSTimer!
    var activatedFromBackground = false
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        window.backgroundColor = NSColor.whiteColor()
        window.minSize = NSSize(width: 380,height: 376)
        window.makeMainWindow()
        window.makeKeyWindow()
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .Hidden
        window.delegate = self
        loadingView.layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        startLoading()
        
        #if DEBUG
            let path = NSBundle.mainBundle().objectForInfoDictionaryKey("PROJECT_DIR") as! String
            var source = String(contentsOfFile: path+"/server/dist/dawg.js", encoding: NSUTF8StringEncoding, error: nil)!+"init();"
        #else
            let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
            var jsurl = "https://raw.githubusercontent.com/martinblech/dawg/v" + version + "/server/dist/dawg.js"
            if (NSBundle.mainBundle().objectForInfoDictionaryKey("DawgJavaScriptURL") != nil) {
                jsurl = NSBundle.mainBundle().objectForInfoDictionaryKey("DawgJavaScriptURL") as! String
            }
            let source = "function getScript(url,success){ var script = document.createElement('script'); script.src = url; var head = document.getElementsByTagName('head')[0], done=false; script.onload = script.onreadystatechange = function(){ if (!done && (!this.readyState || this.readyState == 'loaded' || this.readyState == 'complete')) { done=true; success(); script.onload = script.onreadystatechange = null; head.removeChild(script); } }; head.appendChild(script); }" +
            "getScript('" + jsurl + "', function() {init();});"
        #endif
        
        var reactivationToggle : Bool? = NSUserDefaults.standardUserDefaults().objectForKey("reactivationToggle") as? Bool
        if (reactivationToggle != nil && reactivationToggle==true) {
            self.reactivationMenuItem.state = 1
        }
        
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(userScript)
        
        let handler = NotificationScriptMessageHandler()
        userContentController.addScriptMessageHandler(handler, name: "notification")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.preferences.plugInsEnabled = true
        #if DEBUG
            configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif
        
        webView = WKWebView(frame: self.view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.UIDelegate = self
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .allZeros, context: nil)
        
        // Layout
        view.addSubview(webView, positioned: NSWindowOrderingMode.Below, relativeTo: view);
        webView.autoresizingMask = NSAutoresizingMaskOptions.ViewWidthSizable | NSAutoresizingMaskOptions.ViewHeightSizable
        
        var s = NSProcessInfo.processInfo().arguments[0].componentsSeparatedByString("/")
        var st: String = s[s.count-4] as! String
        var url : String = "https://plus.google.com/hangouts"
        
        var req = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        // No need to set user agent
        // req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/600.3.17 (KHTML, like Gecko) Version/8.0.3 Safari/600.3.17", forHTTPHeaderField: "User-Agent")
        webView.loadRequest(req);
        
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if object as! NSObject == webView && keyPath == "estimatedProgress" {
            progressIndicator.doubleValue = webView.estimatedProgress
        }
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        
        if let url = navigationAction.request.URL {
            var isBlank = url.absoluteString == "about:blank"
            var inApp = false
            var isLogin = false
            var isLogout = false
            var isTalkGadget = false
            var isPlus = false
            var isNotificationsFrame = false
            var isClientChannel = false
            var isClientProxy = false
            var isInvalidation = false
            var isOauth = false
            var isPicker = false
            if let host = url.host, let path = url.path {
                inApp = host == "plus.google.com" && path.hasPrefix("/hangouts");
                isLogin = host.rangeOfString(".google.") != nil && (path.hasPrefix("/ServiceLogin") || path.hasPrefix("/CheckCookie") || path.hasPrefix("/accounts/SetSID"));
                isLogout = host == "accounts.google.com" && path.hasPrefix("/Logout") || host.rangeOfString(".google.") != nil && path.hasPrefix("/accounts/Logout2");
                isTalkGadget = host == "talkgadget.google.com"
                isPlus = host == "plus.google.com"
                isNotificationsFrame = host == "plus.google.com" && path.hasSuffix("/notifications/frame");
                isClientChannel = host.hasSuffix("client-channel.google.com");
                isClientProxy = host.hasPrefix("client") && host.hasSuffix(".google.com") && path.hasPrefix("/static/proxy");
                isInvalidation = host.hasSuffix(".google.com") && path.hasPrefix("/invalidation");
                isOauth = host == "accounts.google.com" && path.hasPrefix("/o/oauth");
                isPicker = host == "docs.google.com" && path.hasPrefix("/picker");
            }
            
            if inApp || isLogin || isLogout || isBlank || isTalkGadget || isPlus || isNotificationsFrame || isClientChannel || isClientProxy || isInvalidation || isOauth || isPicker {
                decisionHandler(.Allow)
            } else {
                if url.absoluteString == "https://plus.google.com/_/css-load-error/" {
                    println("Ignoring CSS load error")
                } else {
                    println("External url: \(url)")
                    NSWorkspace.sharedWorkspace().openURL(url)
                }
                decisionHandler(.Cancel)
            }
        } else {
            decisionHandler(.Cancel)
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: Selector("endLoading"), userInfo: nil, repeats: false)
    }
    
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    
    func applicationDidBecomeActive(aNotification: NSNotification) {
        NSApplication.sharedApplication().dockTile.badgeLabel = ""
        if (self.activatedFromBackground) {
            if (self.reactivationMenuItem.state == 1) {
                webView.evaluateJavaScript("reactivation()", completionHandler: nil);
            }
        } else {
            self.activatedFromBackground = true;
        }
        reopenWindow(self)
    }
    
    func applicationShouldOpenUntitledFile(sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationOpenUntitledFile(sender: NSApplication) -> Bool {
        reopenWindow(self)
        return true
    }
    
    
    @IBAction func reopenWindow(sender: AnyObject) {
        window.makeKeyAndOrderFront(self)
    }
    
    @IBAction func toggleReactivation(sender: AnyObject) {
        var i : NSMenuItem = sender as! NSMenuItem
        
        if (i.state == 0) {
            i.state = NSOnState
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "reactivationToggle")
        } else {
            i.state = NSOffState
            NSUserDefaults.standardUserDefaults().setObject(false, forKey: "reactivationToggle")
        }
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    var quicklookMediaURL: NSURL? {
        didSet {
            if quicklookMediaURL != nil {
                QLPreviewPanel.sharedPreviewPanel().makeKeyAndOrderFront(nil);
            }
        }
    }
    
    func endLoading() {
        timer.invalidate()
        loadingView.hidden = true
        progressIndicator.hidden = true
        longLoading.hidden = true
    }
    
    func startLoading() {
        loadingView.hidden = false
        progressIndicator.hidden = false
        longLoading.hidden = true
        timer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: Selector("longLoadingMessage"), userInfo: nil, repeats: false)
    }
    
    func longLoadingMessage() {
        if (!loadingView.hidden) {
            longLoading.hidden = false
        }
    }
    
    func statusBarItemClicked() {
        webView.evaluateJavaScript("reactivation()", completionHandler: nil);
        reopenWindow(self)
        NSApp.activateIgnoringOtherApps(true)
    }
    
    // MARK: Quicklook for Media
    
    var previewPanel: QLPreviewPanel?
    
    override func acceptsPreviewPanelControl(panel: QLPreviewPanel!) -> Bool {
        return true
    }
    
    override func beginPreviewPanelControl(panel: QLPreviewPanel!) {
        previewPanel = panel
        panel.delegate = self
        panel.dataSource = self
    }
    
    override func endPreviewPanelControl(panel: QLPreviewPanel!) {
        previewPanel = nil
    }
    
    func numberOfPreviewItemsInPreviewPanel(panel: QLPreviewPanel!) -> Int {
        return 1
    }
    
    func previewPanel(panel: QLPreviewPanel!, previewItemAtIndex index: Int) -> QLPreviewItem! {
        return WebPreviewItem(url: quicklookMediaURL!)
    }
    
    class WebPreviewItem : NSObject, QLPreviewItem {
        let previewItemURL: NSURL
        init(url: NSURL) {
            previewItemURL = url
        }
        
        let previewItemTitle: String = "Image"
        
    }
}


