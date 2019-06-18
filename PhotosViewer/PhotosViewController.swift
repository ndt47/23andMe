//
//  ViewController.swift
//  PhotosViewer
//
//  Created by Nathan Taylor on 6/16/19.
//  Copyright © 2019 Nathan Taylor. All rights reserved.
//

import UIKit

class PhotoCell : UICollectionViewCell {
    var imageView = UIImageView(frame: .zero)
    var spinner = UIActivityIndicatorView(style: .gray)
    
    var photo: PhotoManager.Photo? = nil
    
    override func layoutSubviews() {
        imageView.frame = self.bounds
        spinner.frame = self.bounds
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        spinner.hidesWhenStopped = true
        
        self.backgroundColor = .white
        self.addSubview(imageView)
        self.addSubview(spinner)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}


class PhotosViewController: UICollectionViewController {
    
    private let photoCellReuseIdentifier = "PhotoCell"
    
    let photoManager: PhotoManager
    
    init(photoManager: PhotoManager) {
        self.photoManager = photoManager
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 150.0, height: 150.0)
        flowLayout.sectionInset = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        flowLayout.minimumLineSpacing = 8.0
        flowLayout.minimumInteritemSpacing = 8.0
        flowLayout.scrollDirection = .vertical
        flowLayout.sectionInsetReference = .fromSafeArea

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
    
    // MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoManager.photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCellReuseIdentifier, for: indexPath) as! PhotoCell
        let photos = photoManager.photos
        
        let photo = photos[indexPath.item]
        cell.photo = photo
        cell.spinner.startAnimating()
        
        let _ = photoManager.loadImage(for: photo, size: .thumbnail, completion: { (image) in
            DispatchQueue.main.async {
                if self.collectionView.indexPath(for: cell) == indexPath {
                    cell.imageView.image = image
                    cell.spinner.stopAnimating()
                }
            }
        })
        
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
    
}

