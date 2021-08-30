//
//  UIViewController+Alert.swift
//  Combinestagram
//
//  Created by 邹婉玉 on 2021/8/29.
//  Copyright © 2021 Underplot ltd. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {
  
  func showAlert(_ title: String, description: String? = nil) -> Completable {
    return Completable
      .create { [weak self] observer in
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
          observer(.completed)
        }))
        self?.present(alert, animated: true, completion: nil)
        return Disposables.create { [weak self] in
          self?.dismiss(animated: true, completion: nil)
        }
      }
  }
  
}
