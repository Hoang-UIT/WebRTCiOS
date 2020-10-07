//
//  LoginViewController.swift
//  WebRTCiOSDemo
//
//  Created by hoangtp on 7/8/20.
//  Copyright © 2020 Rakumo. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var viewContentLogin: UIView!
    
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var nameTF: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        btnLogin.layer.cornerRadius = 5.0
        NotificationCenter.default.addObserver(self, selector: #selector(checkExist), name: NSNotification.Name("FCMToken"), object: nil)
        viewContentLogin.alpha = 0.0
    }
    @objc func checkExist() {
        RTCFireBaseServices.sharedInstance.checkExist { [weak self] (isExisted) in
            if isExisted {
                self?.viewContentLogin.alpha = 0.0
                RTCFireBaseServices.sharedInstance.createOrUpdateUser(isOnline: true, sdp: "")
                self?.presentViewController()
            } else {
                self?.viewContentLogin.alpha = 1.0
            }
        }
    }
    
    @IBAction func pressBtnLogin(_ sender: UIButton) {
        guard let name = nameTF.text, !name.isEmpty else {
            let alert = UIAlertController(title: "Warning", message: "User Name invalible", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        RTCFireBaseServices.sharedInstance.createOrUpdateUser(name: name, isOnline: true, sdp: "")
        presentViewController()
    }
    
    private func presentViewController() {
        var navi: UINavigationController?
        if #available(iOS 13.0, *) {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ViewController")
            navi = UINavigationController(rootViewController: viewController)
            navi?.modalPresentationStyle = .fullScreen
        } else {
            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController")
            navi = UINavigationController(rootViewController: viewController)
        }
        present(navi ?? UINavigationController(), animated: true, completion: nil)
    }
}

