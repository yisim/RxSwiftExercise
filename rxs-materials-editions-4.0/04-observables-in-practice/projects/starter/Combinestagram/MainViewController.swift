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
      _ = Observable.never().subscribe { event in
        print(event)
      }
    }

    example(of: "range") {
      _ = Observable<Int>
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
      _ = Observable<Int>
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
    
    example(of: "do") {
      let disposeBag = DisposeBag()
      Observable
        .never()
        .do(onNext: { _ in
          print("onNext")
        }, afterNext: { _ in
          print("afterNext")
        }, onError: { error in
          print("onError")
        }, afterError: { error in
          print("afterError")
        }, onCompleted: {
          print("onCompleted")
        }, afterCompleted: {
          print("afterCompleted")
        }, onSubscribe: {
          print("onSubscribe")
        }, onSubscribed: {
          print("onSubscribed")
        }, onDispose: {
          print("onDispose")
        })
        .subscribe { event in
          print(event)
        }
        .disposed(by: disposeBag)
    }
    
    example(of: "debug") {
      let disposeBag = DisposeBag()
      Observable
        .never()
        .debug("myDebug", trimOutput: true)
        .subscribe { event in
          print(event)
        }
        .disposed(by: disposeBag)
    }

    example(of: "PublishSubject") {
      let subject = PublishSubject<String>()
      subject.on(.next("Is anyone listening?"))
      let subcripitonOne = subject
        .subscribe { event in
          print(event)
        }
      subject.on(.next("1"))
      subject.onNext("2")
      let subscriptionTwo = subject
        .subscribe { event in
          print("2)",event.element ?? event)
        }
      subject.onNext("3")
      subcripitonOne.dispose()
      subject.onNext("4")

      subject.onCompleted()
      subject.onNext("5")
      subscriptionTwo.dispose()

      let disposeBag = DisposeBag()
      subject
        .subscribe { event in
          print("3)", event.element ?? event)
        }
        .disposed(by: disposeBag)
      subject.onNext("?")
    }

    func myprint<T: CustomStringConvertible>(label: String, event: Event<T>){
      print(label, (event.element ?? event.error) ?? event)
    }

    example(of: "BehaviorSubject") {
      enum MyError: Error {
        case anError
      }
      let subject = BehaviorSubject<String>(value: "initail value")
      let disposeBag = DisposeBag()
      subject.onNext("x")
      subject
        .subscribe { event in
          myprint(label: "1)", event: event)
        }
        .disposed(by: disposeBag)
      subject.onError(MyError.anError)
      subject
        .subscribe { event in
          myprint(label: "2)", event: event)
        }
        .disposed(by: disposeBag)
    }

    example(of: "ReplaySubject") {
      enum MyError: Error {
        case anError
      }
      let subject = ReplaySubject<String>.create(bufferSize: 2)
      let disposeBag = DisposeBag()
      subject.onNext("1")
      subject.onNext("2")
      subject.onNext("3")
      subject
        .subscribe {
          myprint(label: "1)", event: $0)
        }
        .disposed(by: disposeBag)
      subject
        .subscribe {
          myprint(label: "2)", event: $0)
        }
        .disposed(by: disposeBag)
      subject.onNext("4")
      subject.onError(MyError.anError)
//      subject.dispose()
      subject
        .subscribe {
          myprint(label: "3)", event: $0)
        }
        .disposed(by: disposeBag)
    }

    example(of: "PublishRelay") {
      let relay = PublishRelay<String>()
      let disposeBag = DisposeBag()
      relay.accept("knock, knock, anyone home?")
      relay
        .subscribe { event in
          myprint(label: "1)", event: event)
        }
        .disposed(by: disposeBag)
      relay.accept("1")
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
