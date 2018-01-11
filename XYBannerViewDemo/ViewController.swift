//
//  ViewController.swift
//  XYBannerViewDemo
//
//  Created by user on 2018/1/8.
//  Copyright © 2018年 refrainC. All rights reserved.
//

import UIKit

class ViewController: UIViewController  {

    @IBOutlet var bannerView: XYBannerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let images = ["http://img3.3lian.com/2013/c1/36/d/81.jpg",
                      "http://img3.3lian.com/2013/c4/80/d/2.jpg"]
        
        bannerView.placeholderImage = UIImage.init(named: "placeholderimages")
        
        bannerView.setImageArray(imageArray: images)
        
        bannerView.setTime(time: 3.0)
        
        bannerView.startTime()
        
        bannerView.setPagePosition(position: .Default)

        bannerView.delegate = self
        
    }
    
    @IBAction func clearDiskCache(_ sender: Any) {
        
        XYBannerView.clearDiskCache()
        
    }
    
    
    
    
}

extension ViewController : XYBannerViewDelegate {
    
    func bannerView(selectIndex: Int) {
        
        print(selectIndex)
        
    }
    
}

