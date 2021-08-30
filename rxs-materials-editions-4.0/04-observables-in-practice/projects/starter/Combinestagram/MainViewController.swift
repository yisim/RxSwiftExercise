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
  
  private let bag = DisposeBag()
  private let imags = BehaviorRelay<[UIImage]>(value: [])
  private var imageCache = [Int]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let newImages = imags.share()
    
    newImages
      .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
      .subscribe(onNext: { [weak imagePreview] photos in
        imagePreview?.image = photos.collage(size: imagePreview?.frame.size ?? CGSize.zero)
      })
      .disposed(by: bag)
    
    newImages
      .subscribe(onNext: { [weak self] photos in
        self?.updateUI(photos: photos)
      })
      .disposed(by: bag)
    
    test5()
    
  }
  
  @IBAction func actionClear() {
    imags.accept([])
    imageCache = []
  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }

    PhotoWriter
      .save(image)
      .asSingle()
      .subscribe { [weak self] id in
        self?.showMessage("Saved with id: \(id)")
        self?.actionClear()
      } onError: { [weak self] error in
        self?.showMessage("Error", description: error.localizedDescription)
      }
      .disposed(by: bag)

  }

  @IBAction func actionAdd() {
    let photoViewController: PhotosViewController
    if #available(iOS 13.0, *) {
      photoViewController = storyboard!.instantiateViewController(identifier: "PhotosViewController") as! PhotosViewController
    } else {
      photoViewController = PhotosViewController()
    }
    let newPhotos = photoViewController.selectedPhotos
      .share()
    newPhotos
      .takeWhile({[weak self] newImage in
        let count = self?.imags.value.count ?? 0
        return count < 6
      })
      .filter({ newImage in
        newImage.size.width > newImage.size.height
      })
      .filter({ [weak self] newImage in
        let len = newImage.pngData()?.count ?? 0
        guard self?.imageCache.contains(len) == false else {
          return false
        }
        self?.imageCache.append(len)
        return true
      })
      .subscribe(
        onNext: { [weak self] newImage in
          guard let images = self?.imags else { return }
          images.accept(images.value + [newImage])
        }, onDisposed: {
          print("Completed photos selection")
        })
      .disposed(by: bag)
    navigationController!.pushViewController(photoViewController, animated: true)
    
    newPhotos
      .ignoreElements()
      .subscribe { [weak self] in
        self?.updateNavigationIcon()
      } onError: { error in
        print(error)
      }
      .disposed(by: bag)

  }
  
  private func updateNavigationIcon() {
    let icon =
      imagePreview
      .image?
      .scaled(CGSize(width: 22, height: 22))
      .withRenderingMode(.alwaysOriginal)
    
    navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: icon, style: .done, target: nil, action: nil)
    
  }
  
  private func updateUI(photos: [UIImage]) {
    buttonClear.isEnabled = photos.count > 0
    buttonSave.isEnabled = photos.count > 0 && (photos.count % 2 == 0)
    itemAdd.isEnabled = photos.count < 6
    title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
  }

  func showMessage(_ title: String, description: String? = nil) {
    showAlert(title, description: description)
      .subscribe {
        print("dismiss")
      } onError: { error in
        print(error)
      }
      .disposed(by: bag)

  }
}

extension MainViewController {
  public func example(of description: String, action: () -> Void) {
    print("\n---Example","\(description)","---")
    action()
  }
}

extension MainViewController {
  func test() {
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
    
    example(of: "BehaviorRelay") {
      let relay = BehaviorRelay<String>(value: "Initial value")
      let disposeBag = DisposeBag()
      relay.accept("New initial value")
      relay
        .subscribe {
          myprint(label: "1)", event: $0)
        }
        .disposed(by: disposeBag)
      relay.accept("1")
      relay
        .subscribe {
          myprint(label: "2)", event: $0)
        }
        .disposed(by: disposeBag)
      relay.accept("2")
      print(relay.value)
    }
    
    let cards = [
      ("🂡", 11), ("🂢", 2), ("🂣", 3), ("🂤", 4), ("🂥", 5), ("🂦", 6), ("🂧", 7), ("🂨", 8), ("🂩", 9), ("🂪", 10), ("🂫", 10), ("🂭", 10), ("🂮", 10),
      ("🂱", 11), ("🂲", 2), ("🂳", 3), ("🂴", 4), ("🂵", 5), ("🂶", 6), ("🂷", 7), ("🂸", 8), ("🂹", 9), ("🂺", 10), ("🂻", 10), ("🂽", 10), ("🂾", 10),
      ("🃁", 11), ("🃂", 2), ("🃃", 3), ("🃄", 4), ("🃅", 5), ("🃆", 6), ("🃇", 7), ("🃈", 8), ("🃉", 9), ("🃊", 10), ("🃋", 10), ("🃍", 10), ("🃎", 10),
      ("🃑", 11), ("🃒", 2), ("🃓", 3), ("🃔", 4), ("🃕", 5), ("🃖", 6), ("🃗", 7), ("🃘", 8), ("🃙", 9), ("🃚", 10), ("🃛", 10), ("🃝", 10), ("🃞", 10)
    ]
    
    func cardString(for hand: [(String, Int)]) -> String {
      return hand.map { $0.0 }.joined(separator: "")
    }
    
    func points(for hand: [(String, Int)]) -> Int {
      return hand.map { $0.1 }.reduce(0, +)
    }
    
    enum HandError: Error {
      case busted(points: Int)
    }
    
    example(of: "Challenge 1: Create a blackjack card dealer using a publish subject") {
      let disposeBag = DisposeBag()
      
      let dealtHand = PublishSubject<[(String, Int)]>()
      
      func deal(_ cardCount: UInt) {
        var deck = cards
        var cardsRemaining = deck.count
        var hand = [(String, Int)]()
        
        for _ in 0..<cardCount {
          let randomIndex = Int.random(in: 0..<cardsRemaining)
          hand.append(deck[randomIndex])
          deck.remove(at: randomIndex)
          cardsRemaining -= 1
        }
        
        // Add code to update dealtHand here
        let points = points(for: hand)
        if points >= 21 {
          dealtHand.onError(HandError.busted(points: points))
        } else {
          dealtHand.onNext(hand)
        }
      }
      
      // Add subscription to dealtHand here
      dealtHand
        .subscribe {
          print(cardString(for: $0), "for", points(for: $0), "points")
        } onError: {
          print($0)
        }
        .disposed(by: disposeBag)
      
      deal(3)
    }
    
    example(of: "Challenge 2: Observe and check user session state using a behavior relay") {
      
    }
  }
}

extension MainViewController {
  func test2() {
    example(of: "IgnoreElement") {
      let strikes = PublishSubject<String>()
      
      let disposeBag = DisposeBag()
      strikes.onNext("0")
      strikes
        .ignoreElements()
        .subscribe {
          print($0)
          print("You are out!")
        }
        .disposed(by: disposeBag)
      
      strikes.onNext("1")
      strikes.onNext("2")
      strikes.onNext("3")
      strikes.onCompleted()
    }
    
    example(of: "ElementAt") {
      let strikes = PublishSubject<String>()
      
      let disposeBag = DisposeBag()
      strikes
        .elementAt(1)
        .subscribe {
          print($0)
          print("You are out!")
        }
        .disposed(by: disposeBag)
      
      strikes.onNext("1")
      strikes.onNext("2")
      strikes.onNext("3")
      strikes.onCompleted()
    }
    
    example(of: "filter") {
      let disposeBag = DisposeBag()
      
      Observable<Int>.of(10, 3, 5, 6, 8, 70)
        .filter { $0 > 3 }
        .subscribe(onNext: {
          print($0)
        })
        .disposed(by: disposeBag)
      
    }
    
    example(of: "skip") {
      let disposeBag = DisposeBag()
      
      Observable
        .of("A", "B", "C", "D", "E")
        .skip(3)
        .subscribe(onNext: {
          print($0)
        })
        .disposed(by: disposeBag)
      
    }
    
    example(of: "skipWhile") {
      let disposeBag = DisposeBag()
      
      Observable
        .of(1, 2, 3, 2, 4)
        .skipWhile { $0.isMultiple(of: 2) }
        .subscribe(onNext: {
          print($0)
        })
        .disposed(by: disposeBag)
      
    }
    
    example(of: "skipUntile") {
      let disposeBag = DisposeBag()
      
      let subject = PublishSubject<String>()
      let trigger = PublishSubject<String>()
      subject
        .skipUntil(trigger)
        .subscribe {
          print($0)
        }
        .disposed(by: disposeBag)
      subject.onNext("1")
      subject.onNext("2")
      subject.onNext("3")
      trigger.onNext("A")
      subject.onNext("4")
      trigger.onNext("B")
      trigger.onCompleted()
      subject.onNext("5")
      
    }
    
    example(of: "take") {
      let disposeBag = DisposeBag()
      
      Observable
        .of(1,2,3,4,5,6,7,8)
        .take(3)
        .subscribe {
          print($0)
        }
        .disposed(by: disposeBag)
      
    }
    
    example(of: "takeWhile") {
      let disposeBag = DisposeBag()
      
      Observable
        .of(2, 2, 4, 4, 6, 6)
        .enumerated()
        .takeWhile { index, integer in
          integer.isMultiple(of: 2) && index < 3
        }
        .map( \.element )
        .subscribe {
          print($0)
        }
        .disposed(by: disposeBag)
      
    }
    
    example(of: "takeUntil") {
      let disposebag = DisposeBag()
      
      Observable
        .of(1,2,3,4,5,6)
        .takeUntil(.exclusive) {
          $0.isMultiple(of: 4)
        }
        .subscribe({
          print($0)
        })
        .disposed(by: disposebag)
    }
    
    example(of: "take until trigger") {
      let disposeBag = DisposeBag()
      
      let subject = PublishSubject<String>()
      let trigger = PublishSubject<String>()
      
      subject
        .takeUntil(trigger)
        .subscribe({
          print($0)
        })
        .disposed(by: disposeBag)
      subject.onNext("1")
      subject.onNext("2")
      subject.onNext("3")
      trigger.onNext("A")
      subject.onNext("4")
      subject.onNext("5")
      
    }
    
    example(of: "distinctUntilChange") {
      let disposeBag = DisposeBag()
      
      Observable
        .of("A", "A", "B", "B", "A")
        .distinctUntilChanged()
        .subscribe({
          print($0)
        })
        .disposed(by: disposeBag)
      
    }
    
    example(of: "distinctUntilChange(_:)") {
      let disposeBag = DisposeBag()
      
      let fomatter = NumberFormatter()
      fomatter.numberStyle = .spellOut
      
      Observable<NSNumber>
        .of(110, 20, 200, 210, 310)
        .distinctUntilChanged({ a, b in
          guard let aWords = fomatter.string(from: a)?.components(separatedBy: " "),
                let bWords = fomatter.string(from: b)?.components(separatedBy: " ") else {
            return false
          }
          var containsMatch = false
          for aWord in aWords  where bWords.contains(aWord) {
            containsMatch = true
          }
          return containsMatch
        })
        .subscribe({
          print($0)
        })
        .disposed(by: disposeBag)
      
    }
    
    example(of: "Challenge 1") {
      let disposeBag = DisposeBag()
      
      let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Shai",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott"
      ]
      
      func phoneNumber(from inputs: [Int]) -> String {
        var phone = inputs.map(String.init).joined()
        
        phone.insert("-", at: phone.index(
                      phone.startIndex,
                      offsetBy: 3)
        )
        
        phone.insert("-", at: phone.index(
                      phone.startIndex,
                      offsetBy: 7)
        )
        
        return phone
      }
      
      let input = PublishSubject<Int>()
      
      // Add your code here
      input
        .skipWhile({ $0 == 0 })
        .filter({ $0 < 10 })
        .take(10)
        .toArray()
        .subscribe {
          let phone = phoneNumber(from: $0)
          if let contact = contacts[phone] {
            print("Dailing \(contact) \(phone)...")
          } else {
            print("Contact not found")
          }
        } onError: { error in
          print(error)
        }
        .disposed(by: disposeBag)

      input.onNext(0)
      input.onNext(603)
      
      input.onNext(2)
      input.onNext(1)
      
      // Confirm that 7 results in "Contact not found",
      // and then change to 2 and confirm that Shai is found
      input.onNext(2)
      
      "5551212".forEach {
        if let number = (Int("\($0)")) {
          input.onNext(number)
        }
      }
      
      input.onNext(9)
    }
  }
}

extension MainViewController {
  func test3() {
    example(of: "share") {
      let disposeBag = DisposeBag()
      var start = 0
      func getStartNumber() -> Int {
        start += 1
        return start
      }
      let numbers = Observable<Int>.create { observer in
        let start = getStartNumber()
        observer.onNext(start)
        observer.onNext(start+1)
        observer.onNext(start+2)
        observer.onCompleted()
        return Disposables.create()
      }.share()
      
      numbers
        .subscribe(
          onNext: { el in
            print("element [\(el)]")
          },
          onCompleted: {
            print("-------------")
          }
        )
        .disposed(by: disposeBag)
      
      numbers
        .subscribe(
          onNext: { el in
            print("element [\(el)]")
          },
          onCompleted: {
            print("-------------")
          }
        )
        .disposed(by: disposeBag)
    }
  }
}

extension MainViewController {
  func test4() {
    example(of: "toArray") {
      let bag = DisposeBag()
      
      Observable
        .of("A", "B", "C", "D", "E")
        .toArray()
        .subscribe {
          print($0)
        } onError: { error in
          print(error)
        }
        .disposed(by: bag)
    }
    
    example(of: "map") {
      let bag = DisposeBag()
      
      let formatter = NumberFormatter()
      formatter.numberStyle = .spellOut
      
      Observable<Int>
        .of(124, 23, 33)
        .map {
          formatter.string(for: $0) ?? ""
        }
        .subscribe(onNext: {
          print($0)
        })
        .disposed(by: bag)
    }
    
    example(of: "enumerated and map") {
      let bag = DisposeBag()
      
      Observable<Int>
        .of(1, 2, 3, 4, 5, 6)
        .enumerated()
        .map({ index, element in
          index > 2 ? element * 2 : element
        })
        .subscribe(onNext: {
          print($0)
        })
        .disposed(by: bag)
    }
    
    example(of: "compactMap") {
      let bag = DisposeBag()
      
      Observable
        .of("To", "be", nil, "or", nil, "not", "to", "be")
        .compactMap{ $0 }
        .toArray()
        .map{
          $0.joined(separator: " ")
        }
        .subscribe {
          print($0)
        } onError: { error in
          print(error)
        }
        .disposed(by: bag)
      
    }
    
    example(of: "Transforming inner observables") {
      struct Student {
        let score: BehaviorSubject<Int>
      }
      
      let bag = DisposeBag()
      
      let laura = Student(score: BehaviorSubject(value: 80))
      let charlotte = Student(score: BehaviorSubject(value: 90))
      
      let student = PublishSubject<Student>()
      
      student
        .flatMap {
          $0.score
        }
        .subscribe(onNext: {
          print($0)
        })
        .disposed(by: bag)
      
      student.onNext(laura)
      laura.score.onNext(98)
      student.onNext(charlotte)
      charlotte.score.onNext(100)
      
    }
    
    example(of: "flatMapLatest") {
      struct Student {
        let score: BehaviorSubject<Int>
      }
      
      let bag = DisposeBag()
      
      let laura = Student(score: BehaviorSubject(value: 80))
      let charlotte = Student(score: BehaviorSubject(value: 90))
      
      let student = PublishSubject<Student>()
      
      student
        .flatMapLatest {
          $0.score
        }
        .subscribe(onNext: {
          print($0)
        })
        .disposed(by: bag)
      
      student.onNext(laura)
      student.onNext(charlotte)
      laura.score.onNext(98)
      charlotte.score.onNext(100)
      
    }
    
    example(of: "materialize an dematerialize") {
      let bag = DisposeBag()
      
      struct Student {
        let score: BehaviorSubject<Int>
      }
      
      enum MyError: Error {
        case anError
      }
      
      let laura = Student(score: BehaviorSubject(value: 80))
      let charlotte = Student(score: BehaviorSubject(value: 90))
      
      let student = BehaviorSubject(value: laura)
      
      let studentScore = student
        .flatMapLatest {
          $0.score.materialize()
          //          $0.score
        }
      
//      studentScore.subscribe(onNext: {
//        print($0)
//      })
//      .disposed(by: bag)
      
      studentScore
        .filter {
          guard $0.error == nil else {
            print("here, an error", $0.error!)
            return false
          }
          return true
        }
        .dematerialize()
        .subscribe(onNext: {
          print($0)
        })
        .disposed(by: bag)
      
      laura.score.onNext(81)
      laura.score.onNext(82)
      laura.score.onError(MyError.anError)
      laura.score.onNext(83)
      student.onNext(charlotte)
      charlotte.score.onNext(91)
      laura.score.onNext(84)
      
      
      
    }
    
    
  }
}

extension MainViewController {

  func test5() {
    let contacts = [
      "603-555-1212": "Florent",
      "212-555-1212": "Shai",
      "408-555-1212": "Marin",
      "617-555-1212": "Scott"
    ]

    func phoneNumber(from inputs: [Int]) -> String {
      var phone = inputs.map(String.init).joined()

      phone.insert("-", at: phone.index(
        phone.startIndex,
        offsetBy: 3)
      )

      phone.insert("-", at: phone.index(
        phone.startIndex,
        offsetBy: 7)
      )

      return phone
    }

    example(of: "phone") {
      let disposeBag = DisposeBag()

      let input = PublishSubject<Int>()

      input
        .skipWhile {
          $0 == 0
        }
        .filter {
          $0 < 10
        }
        .take(10)
        .toArray()
        .subscribe {
          let phone = phoneNumber(from: $0)
          if let contact = contacts[phone] {
            print("Dialing \(contact) (\(phone))...")
          } else {
            print("Contact not found")
          }

        } onError: { error in
          print(error)
        }
        .disposed(by: disposeBag)

      input.onNext(0)
      input.onNext(603)

      input.onNext(2)
      input.onNext(1)

      // Confirm that 7 results in "Contact not found",
      // and then change to 2 and confirm that Shai is found
      input.onNext(2)

      "5551212".forEach {
        if let number = (Int("\($0)")) {
          input.onNext(number)
        }
      }

      input.onNext(9)
    }
  }
}

extension ObservableType {
  
  /**
   Takes a sequence of optional elements and returns a sequence of non-optional elements, filtering out any nil values.
   - returns: An observable sequence of non-optional elements
   */
  
  public func unwrap<T>() -> Observable<T> where Element == T? {
    return self.filter { $0 != nil }.map { $0! }
  }
}
