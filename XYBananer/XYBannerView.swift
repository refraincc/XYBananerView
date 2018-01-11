//
//  XYBannerView.swift
//  XYBannerViewDemo
//
//  Created by user on 2018/1/8.
//  Copyright © 2018年 refrainC. All rights reserved.
//

import UIKit

enum PageControlPosition {
    case Default
    case Hide
    case TopCenter
    case BottomLeft
    case BottomCenter
    case BottomRight
}

protocol XYBannerViewDelegate: class {
    
    func bannerView(selectIndex: Int)
    
}

class XYBannerView: UIView {

    weak var delegate : XYBannerViewDelegate?
    
    public var autoCache : Bool = true
    
    public var placeholderImage : UIImage?
    
    fileprivate var imageArray : Array<String> = Array()
    
    fileprivate var time : TimeInterval = 3.0
    
    fileprivate var pagePosition : PageControlPosition = .Default
    
    fileprivate var currentIndex : Int = 0
    
    fileprivate var nextIndex : Int = 1
    
    fileprivate var timer : Timer?
    
    fileprivate var images : Array<Any> = Array()
    
    
    fileprivate lazy var scrollView : UIScrollView = {
       
        let scrollView = UIScrollView()
        scrollView.scrollsToTop = false
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.addSubview(currentImageView)
        scrollView.addSubview(otherImageView)
        return scrollView
    }()
    
    fileprivate lazy var currentImageView : UIImageView = {
       
        let currentImageView = UIImageView()
        currentImageView.clipsToBounds = true
        return currentImageView
    }()
    
    fileprivate lazy var otherImageView : UIImageView = {
        
        let otherImageView = UIImageView()
        otherImageView.clipsToBounds = true
        return otherImageView
    }()
    
    lazy var pageControl : UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.isUserInteractionEnabled = false
        return pageControl
    }()
    
    fileprivate var pageImageSize : CGSize = CGSize.zero
    
    fileprivate var margin : CGFloat = 5.0
    
    fileprivate lazy var queue : OperationQueue = OperationQueue()
    
    fileprivate lazy var cachePath : String! = {
       
        var cachePath : String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!
        cachePath.append("/XYBannerImageCache")
        
        return cachePath
        
    }()


    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        
        initSubViews()
        initCachePath()
    }
    
    override func awakeFromNib() {
        initSubViews()
        initCachePath()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        
        super.init(coder: aDecoder)!
    }
    

    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.frame = self.bounds
        
        
        
        let width = bounds.size.width
        let height = bounds.size.height
        if images.count > 1 {
            
            scrollView.contentSize = CGSize.init(width: width * 5, height: 0)
            scrollView.contentOffset = CGPoint(x : width * 2, y : 0)
            currentImageView.frame = CGRect.init(x: width * 2, y: 0, width: width, height: height)
            
            startTime()
            
        } else {
            
            scrollView.contentSize = CGSize.zero
            scrollView.contentOffset = CGPoint.zero
            currentImageView.frame = CGRect.init(x: 0, y: 0, width: width, height: height)
            
            stopTimer()
            
        }
        
    }
}


extension XYBannerView {
    
    fileprivate func initSubViews(){
        
        self.addSubview(scrollView)
        self.addSubview(pageControl)
        
        
        let tap : UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapClick))
        scrollView.addGestureRecognizer(tap)
        
    }
    
    
    fileprivate func initCachePath(){
        
        var isDir : ObjCBool = ObjCBool.init(false)
        let isExists = FileManager.default.fileExists(atPath: cachePath, isDirectory: &isDir)
        
        if !isExists || !isDir.boolValue {
            
            try! FileManager.default.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
            
        }
    }
    
    fileprivate func downloadImage(index : Int) {
        
        
        
        let imageStr = imageArray[index] as NSString
        
        let imageName = imageStr.replacingOccurrences(of: "/", with: "")
        
        let path = "file://" + cachePath + "/" + imageName
        
        print(path)
        
        let pathUrl = URL.init(string: path)
        
        if autoCache {
            let data = try? Data.init(contentsOf: pathUrl!)
            
            if data != nil {
                
                let image : UIImage = UIImage.init(data: data!)!
                
                
                images[index] = image
                
                if currentIndex == index {
                    
                    currentImageView.image = image;
                    
                }
                return
                
            }
        }
        
        weak var weakSelf = self
        // 下载图片
        let download =  BlockOperation.init {
            
            if weakSelf?.currentIndex == index  || weakSelf?.placeholderImage != nil{
                
                weakSelf?.currentImageView.image = weakSelf?.placeholderImage
                
            }

            
            let urlStr = weakSelf?.imageArray[index]
            
            guard let requestURL = URL.init(string: urlStr!) else{
                
                return
            }
            
            let data = try! Data.init(contentsOf: requestURL)
            
            
            let image : UIImage = UIImage.init(data: data)!
            
        
            weakSelf?.images[index] = image
            
            if weakSelf?.currentIndex == index {
                
                DispatchQueue.main.async {
                    weakSelf?.currentImageView.image = image
                }
            }
            
            if weakSelf?.autoCache == true{
                
                try! data.write(to: pathUrl!, options: .atomicWrite)
                
            }
        }
        queue.addOperation(download)
    }
    
    
    
    fileprivate func changeToNext() {
        
        currentImageView.image = otherImageView.image
        scrollView.contentOffset = CGPoint.init(x: xy_width * 2, y: 0)
        scrollView.layoutSubviews()
        currentIndex = nextIndex
        pageControl.currentPage = currentIndex
        
    }
    
}

// MARK: - 对外暴露的方法
extension XYBannerView {
    public func setImageArray(imageArray : Array<String>){
        
        guard imageArray.count >= 1 else {
            return
        }
        
        self.imageArray = imageArray
        
        for index in 0...imageArray.count - 1 {
            
            let obj = imageArray[index]
            
            images.append(obj)

            downloadImage(index: index)
            
        }
        
        pageControl.numberOfPages = imageArray.count
        
        layoutSubviews()
        
        setPagePosition(position: .Default)
        
    }
    
    
    
    public func setPagePosition(position : PageControlPosition) {
        
        pagePosition = position;
        
        if position == .Hide || images.count == 1{
            pageControl.isHidden = true
            return;
        }
        
        var size = CGSize.zero
        
        if pageImageSize.width == 0 {
            size = pageControl.size(forNumberOfPages: pageControl.numberOfPages)
            size.height = 8.0
        }else{
            size = CGSize.init(width: pageImageSize.width * (CGFloat)(pageControl.numberOfPages) * 2.0 - 1.0, height: pageImageSize.height)
        }
        
        pageControl.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
        
        let centerY = xy_height - size.height * 0.5 - margin
        
        let pointY = xy_height - size.height - margin
        
        if position == .Default || position == .BottomCenter {
            pageControl.center = CGPoint.init(x: xy_width * 0.5, y: centerY)
        }else if position == .TopCenter {
            pageControl.center = CGPoint.init(x: xy_width * 0.5, y: size.height * 0.5 + margin)
        }else if position == .BottomLeft {
            pageControl.frame = CGRect.init(x: margin, y: pointY, width: size.width, height: size.height)
        }else{
            pageControl.frame = CGRect.init(x: xy_width - margin - size.width, y: pointY, width: size.width, height: size.height)
        }
        
    }
    
    public func setTime(time : TimeInterval) {
        self.time = time
        
        startTime()
        
    }
    
    public func setPageControler(image:  UIImage, currentImage: UIImage) {
        if image.isEqual(nil) || currentImage.isEqual(nil){
            return
        }
        pageImageSize = image.size
        pageControl.setValue(image, forKey: "_pageImage")
        pageControl.setValue(currentImage, forKey: "_currentImage")
    }
    
    public func startTime() {
        
        guard images.count > 1 else {
            return
        }
        
        if timer != nil {
            stopTimer()
        }
        
        let timeF = time < 1 ? 1 : time
        
        timer = Timer.init(timeInterval: timeF, target: self, selector: #selector(nextPage), userInfo: nil, repeats: true)
        
        RunLoop.current.add(timer!, forMode: .commonModes)
    }
    
    public func stopTimer() {
        
        timer?.invalidate()
        timer = nil
        
    }
    
    @objc fileprivate func nextPage() {
        
        scrollView.setContentOffset(CGPoint.init(x: self.bounds.size.width * 3, y: 0), animated: true)
        
        
    }
    
    @objc fileprivate func tapClick() {
        
        delegate?.bannerView(selectIndex: currentIndex)
        
        
    }
    
    class func clearDiskCache() {
        
        var cachePath : String = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last!
        cachePath.append("/XYBannerImageCache")
        
        let contents = try! FileManager.default.contentsOfDirectory(atPath: cachePath)
        
        for fileName in contents {
            
            let filePath = cachePath.appending("/" + fileName)
            
           try! FileManager.default.removeItem(atPath: filePath)
        }
    }
}


// MARK: - UIScrollViewDelegate
extension XYBannerView : UIScrollViewDelegate {
    
    fileprivate func changeCurrentPageWithOffset(offsetX : CGFloat) {
        
        let width = bounds.width
        
        if offsetX < width * 1.5{
            
            var index : Int = currentIndex - 1
            
            if index < 0{
                index = images.count - 1
                pageControl.currentPage = index
            }else if offsetX > width * 2.5 {
                pageControl.currentPage = (currentIndex + 1) / images.count
            }else {
                pageControl.currentPage = currentIndex
            }
        }
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !__CGSizeEqualToSize(CGSize.zero, scrollView.contentSize) else {
            return
        }
        
        let offsetX = scrollView.contentOffset.x
        
        changeCurrentPageWithOffset(offsetX: offsetX)
        
        if offsetX < xy_width * 2{//右
            otherImageView.frame = CGRect.init(x: xy_width, y: 0, width: xy_width, height: xy_height)
            
            nextIndex = currentIndex - 1
            if nextIndex < 0 {
                nextIndex = images.count - 1
            }
            otherImageView.image = images[nextIndex] as? UIImage
            
            if offsetX <= xy_width {
                changeToNext()
            }
        }else if offsetX > xy_width * 2{ //左
            otherImageView.frame = CGRect.init(x:currentImageView.frame.maxX , y: 0, width: xy_width, height: xy_height)
            nextIndex = (currentIndex + 1) % images.count
            otherImageView.image = images[nextIndex] as? UIImage
            
            if offsetX >= xy_width * 3 {
                changeToNext()
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopTimer()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        startTime()
    }
    
}


extension UIView {
    var xy_width : CGFloat {
        return bounds.size.width
    }
    var xy_height : CGFloat {
        return bounds.size.height
    }
}


