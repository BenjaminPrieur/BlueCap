//
//  UITableViewControllerExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/27/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

extension UITableViewController {
    
    func updateWhenActive() {
        if UIApplication.sharedApplication().applicationState == .Active {
            self.tableView.reloadData()
        }
    }
    
    func styleNavigationBar() {
        let font = UIFont(name:"Thonburi", size:20.0)
        var titleAttributes : [NSObject:AnyObject]
        if var defaultTitleAttributes = UINavigationBar.appearance().titleTextAttributes {
            titleAttributes = defaultTitleAttributes
        } else {
            titleAttributes = [NSObject:AnyObject]()
        }
        titleAttributes[NSFontAttributeName] = font
        self.navigationController?.navigationBar.titleTextAttributes = titleAttributes
    }
    
    func styleUIBarButton(button:UIBarButtonItem) {
        let font = UIFont(name:"Thonburi", size:16.0)
        var titleAttributes : [NSObject:AnyObject]
        if var defaultitleAttributes = button.titleTextAttributesForState(UIControlState.Normal) {
            titleAttributes = defaultitleAttributes
        } else {
            titleAttributes = [NSObject:AnyObject]()
        }
        titleAttributes[NSFontAttributeName] = font
        button.setTitleTextAttributes(titleAttributes, forState:UIControlState.Normal)
    }
}
