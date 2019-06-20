//
//  PhotoDetailViewController.swift
//  PhotosViewer
//
//  Created by Nathan Taylor on 6/17/19.
//  Copyright © 2019 Nathan Taylor. All rights reserved.
//

import UIKit

class PhotoDetailCell : UICollectionViewCell {
    static let preferredSize = CGSize(width: 340.0, height: 340.0)
    
    let imageView = UIImageView(frame: .zero)
    let spinner = UIActivityIndicatorView(style: .white)
    
    var photo: PhotoManager.Photo? {
        didSet {
        }
    }
    
    override func layoutSubviews() {
        imageView.frame = self.bounds
        spinner.frame = self.bounds
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        spinner.hidesWhenStopped = true
        
        imageView.clipsToBounds = true
        imageView.backgroundColor = .darkGray
        
        self.backgroundColor = .white
        self.addSubview(imageView)
        self.addSubview(spinner)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class PhotosDetailViewController: UICollectionViewController, UICollectionViewDataSourcePrefetching {
    
    private let photoCellReuseIdentifier = "PhotoCell"
    
    let photoManager: PhotoManager
    let imageCache = NSCache<PhotoManager.Photo, UIImage>()
    var tasks = Dictionary<PhotoManager.Photo, URLSessionTask>()
    
    
    init(photoManager: PhotoManager, index: Int = 0) {
        self.photoManager = photoManager
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: PhotoDetailCell.preferredSize.width, height: PhotoDetailCell.preferredSize.height)
        flowLayout.sectionInset = UIEdgeInsets(top: 120.0, left: 40.0, bottom: 320.0, right: 40.0)
        flowLayout.minimumLineSpacing = 20.0
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.scrollDirection = .vertical
        flowLayout.sectionInsetReference = .fromSafeArea
        flowLayout.scrollDirection = .horizontal
        
        super.init(collectionViewLayout: flowLayout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.photoManager = PhotoManager(configuration: URLSessionConfiguration.default)
        super.init(coder: aDecoder)
    }
    
    override func loadView() {
        super.loadView()
        
        self.collectionView.backgroundColor = .white
        self.collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: photoCellReuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.prefetchDataSource = self
        self.collectionView.isPagingEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        photoManager.loadPhotos { (photos, error) in
            guard error == nil else {
                // Should probably logout here
                return
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    
    func loadImage(at indexPath:IndexPath, completion: ((UIImage?) -> Void)? = nil) {
        let photo = photoManager.photos[indexPath.item]
        let task = photoManager.loadImage(for: photo, size: .standard, completion: { (image) in
            guard let image = image else { return }
            self.imageCache.setObject(image, forKey: photo)
            self.tasks[photo] = nil
            
            if let handler = completion {
                handler(image)
            }
        })
        self.tasks[photo] = task
    }
    
    func cancelLoad(at indexPath:IndexPath) {
        let photo = photoManager.photos[indexPath.item]
        if let task = tasks[photo] {
            task.cancel()
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoManager.photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellReuseIdentifier, for: indexPath) as! PhotoCell
        let photos = photoManager.photos
        
        let photo = photos[indexPath.item]
        cell.photo = photo
        
        if let image = imageCache.object(forKey: photo) {
            cell.imageView.image = image
        } else {
            cell.spinner.startAnimating()
            self.loadImage(at: indexPath) { (image) in
                DispatchQueue.main.async {
                    if self.collectionView.indexPath(for: cell) == indexPath {
                        cell.imageView.image = image
                        cell.spinner.stopAnimating()
                    }
                }
            }
        }
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    // MARK: - UICollectionViewPrefetchDelegate
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for ip in indexPaths {
            loadImage(at: ip)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for ip in indexPaths {
            cancelLoad(at: ip)
        }
    }
    
    //  MARK: - UIScrollViewDelegate
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}

