//
//  SimpleValidationViewController.swift
//  RxSwiftExercise
//
//  Created by 邹婉玉 on 2021/8/21.
//

import UIKit
import RxSwift
import RxCocoa

private let minimalUsernameLength = 5
private let minimalPasswordLength = 5

class SimpleValidationViewController: ViewController {
    
    @IBOutlet weak var usernameOutlet: UITextField!
    @IBOutlet weak var usernameVaildOutlet: UILabel!
    
    @IBOutlet weak var passwordOutlet: UITextField!
    @IBOutlet weak var passwordVaildOutlet: UILabel!
    
    @IBOutlet weak var doSomethingOutlet: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameVaildOutlet.text = "Username has to be at least \(minimalUsernameLength) charactors"
        passwordVaildOutlet.text = "Password has to be at least \(minimalPasswordLength) charactors"
        
        let usernameVaild = usernameOutlet.rx.text.orEmpty.map
        {
            $0.count > minimalUsernameLength
        }.share(replay: 1)
        let passwordVaild = passwordOutlet.rx.text.orEmpty.map {
            $0.count > minimalPasswordLength
        }.share(replay: 1)
        let everythingVaild = Observable.combineLatest(usernameVaild, passwordVaild) { $0 && $1 }.share(replay: 1)
        
        usernameVaild
            .bind(to: usernameVaildOutlet.rx.isHidden)
            .disposed(by: disposeBag)
        passwordVaild
            .bind(to: passwordVaildOutlet.rx.isHidden)
            .disposed(by: disposeBag)
        
        usernameVaild.bind(to: passwordOutlet.rx.isUserInteractionEnabled).disposed(by: disposeBag)
        
        everythingVaild.bind(to: doSomethingOutlet.rx.isEnabled).disposed(by: disposeBag)
        
        doSomethingOutlet.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.showAlert()
        }).disposed(by: disposeBag)
    }
    
    func showAlert() {
        let alert = UIAlertController(
            title: "tap tap",
            message: "successfully!!!",
            preferredStyle: .alert
        )
        let defaultAction = UIAlertAction(
            title: "ok",
            style: .default) { _ in
        }
        alert.addAction(defaultAction)
        present(alert, animated: true, completion: nil)
    }

}
