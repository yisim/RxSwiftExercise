/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import RxSwift
import RxRelay

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

  override func viewDidLoad() {
    super.viewDidLoad()

    actionAdd()

  }
  
  @IBAction func actionClear() {

  }

  @IBAction func actionSave() {

  }

  @IBAction func actionAdd() {

    example(of: "never") {
      Observable.never().subscribe { event in
        print(event)
      }
    }

    example(of: "range") {
      Observable<Int>
        .range(start: 1, count: 10)
        .subscribe(onNext: { i in
          let n = Double(i)

          let fibonacci = Int(
            ((pow(1.61803, n) - pow(0.61803, n)) /
              2.23606).rounded()
          )

          print(fibonacci)
        })
    }

    example(of: "dispose") {
      let observable = Observable.of("a", "b", "c")
      let subscription = observable.subscribe { event in
        print(event)
      }
      subscription.dispose()
    }

    example(of: "disposeBag") {
      let disposeBag = DisposeBag()
      let observable = Observable.of("a", "b", "c")
      let subscription = observable.subscribe { event in
        print(event)
      }
      subscription.disposed(by: disposeBag)
    }

    example(of: "creat") {
      enum MyError: Error {
        case anError
      }
      Observable<Int>
        .create { observer in
          observer.on(.next(1))
          observer.onNext(3)
//          observer.onError(MyError.anError)
//          observer.onCompleted()
          observer.on(.next(2))
          return Disposables.create()
        }
        .subscribe {
          print($0)
        }
          onError: { print($0)
        } onCompleted: {
          print("completed")
        } onDisposed: {
          print("disposed")
        }
//        .disposed(by: DisposeBag())

    }

    example(of: "deferred") {
      let disposeBag = DisposeBag()
      var flip = false
      let observable = Observable<Int>.deferred {
        flip.toggle()
        if flip {
          return Observable.of(1,2,3)
        } else {
          return Observable.of(4,5,6)
        }
      }

      for _ in 0...3 {
        observable
          .subscribe(
            onNext: { print($0) },
            onCompleted: { print("completed") },
            onDisposed: { print("disposed") }
          )
          .disposed(by: disposeBag)
      }
    }

    example(of: "traits") {
      Single<Int>.create { observer in
        observer(.success(1))
        return Disposables.create()
      }
      .subscribe { element in
        print(element)
      } onError: { error in
        print(error)
      }
      .disposed(by: DisposeBag())

    }

    example(of: "single") {

      let disposeBag = DisposeBag()

      enum FileReadError: Error {
        case fileNotfound
        case unreadable
        case encodingFaild
      }

      func loadText(from name: String) -> Single<String> {
        return Single<String>
          .create { single in
            let disposable = Disposables.create()
            guard let path = Bundle.main.path(forResource: name, ofType: "") else {
              single(.error(FileReadError.fileNotfound))
              return disposable
            }
            guard let data = FileManager.default.contents(atPath: path) else {
              single(.error(FileReadError.unreadable))
              return disposable
            }
            guard let contents = String(data: data, encoding: .utf8) else {
              single(.error(FileReadError.encodingFaild))
              return disposable
            }
            single(.success(contents))
            return disposable
          }
      }

      loadText(from: "Podfile")
        .subscribe {
          print($0)
        } onError: {
          print($0)
        }.disposed(by: disposeBag)

    }

    example(of: "Challenge 1: Perform side effects") {
      Observable
        .never()
        .subscribe { event in
          print(event)
        }
        .disposed(by: DisposeBag())
    }

  }

  func showMessage(_ title: String, description: String? = nil) {
    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
    present(alert, animated: true, completion: nil)
  }
}


extension MainViewController {
  public func example(of description: String, action: () -> Void) {
    print("\n---Example","\(description)","---")
    action()
  }
}
