//
//  ViewController.swift
//  WebRTCiOSDemo
//
//  Created by hoangtp on 7/8/20.
//  Copyright © 2020 Rakumo. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var callers = [Caller]()
    private var user: Caller?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 100
        tableView.dataSource = self
        tableView.delegate = self
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
            if granted {
                print("permission granted")
            } else {
                print("permission denied")
            }
        }
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            //already authorized
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    //access allowed
                    print("access allowed")
                } else {
                    //access denied
                    print("access denied")
                }
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadData()
    }
    
    private func loadData() {
        callers.removeAll()
        tableView.reloadData()
        RTCFireBaseServices.sharedInstance.getListCaller { [weak self](callers) in
            self?.reloadData(callers)
            
        }
    }
    
    private func reloadData(_ callers: [Caller]) {
        if let token = RTCFireBaseServices.sharedInstance.token {
            self.callers.removeAll()
            for caller in callers {
                if caller.id?.elementsEqual(token) ?? false {
                    self.user = caller
                } else {
                    self.callers.append(caller)
                }
            }
            tableView.reloadData()
        }
    }
    
    @IBAction func readyToCallButtonAction(_ sender: UIButton) {
        goToMainViewController(caller: nil)
    }
    
    private func goToMainViewController(caller: Caller?) {
        let viewController: MainViewController?
        if #available(iOS 13.0, *) {
            viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MainViewController") as? MainViewController
            
        } else {
            viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as? MainViewController
        }
        viewController?.user = user
        if let caller = caller {
            viewController?.caller = caller
        }
        self.navigationController?.pushViewController(viewController ?? UIViewController(), animated: true)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return callers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CallerUITableViewCell", for: indexPath) as? CallerUITableViewCell else {
            return UITableViewCell()
        }
        let caller = callers[indexPath.row]
        cell.loadData(caller: caller)
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let caller = callers[indexPath.row]
        goToMainViewController(caller: caller)
    }
}

class CallerUITableViewCell: UITableViewCell {
    @IBOutlet weak var nameLable: UILabel!
    @IBOutlet weak var statusLable: UILabel!
    
    func loadData(caller: Caller) {
        nameLable.text = caller.name ?? ""
        if caller.isOnline ?? false {
            statusLable.text = "Online"
            statusLable.textColor = .green
        } else {
            statusLable.text = "Offline"
            statusLable.textColor = .red
        }
    }
}
