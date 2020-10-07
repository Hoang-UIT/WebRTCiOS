//
//  MainViewController.swift
//  WebRTCiOSDemo
//
//  Created by hoangtp on 7/9/20.
//  Copyright © 2020 Rakumo. All rights reserved.
//

import UIKit
import WebRTC

class MainViewController: UIViewController {
    
    @IBOutlet weak var stateLabel: UILabel!
    
    @IBOutlet weak var localStreamView: UIView!
    
    @IBOutlet weak var remoteStreamView: UIView!
    
    private var localRender = RTCMTLVideoView()
    private var remoteRender = RTCMTLVideoView()
    
    var client: WebRtcClient?
    var user: Caller?
    var caller:Caller?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        localRender.videoContentMode = .scaleAspectFill
        localRender.translatesAutoresizingMaskIntoConstraints = false
        self.localStreamView.addSubview(localRender)
        
        // align localRender from the left and right
        self.localStreamView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view": localRender]))
        
        // align localRender from the top and bottom
        self.localStreamView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view": localRender]))
        
        remoteRender.videoContentMode = .scaleAspectFill
        remoteRender.translatesAutoresizingMaskIntoConstraints = false
        self.remoteStreamView.addSubview(remoteRender)
 
        // align localRender from the left and right
        self.remoteStreamView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view": remoteRender]));
        
        // align localRender from the top and bottom
        self.remoteStreamView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: ["view": remoteRender]));
        
        RTCFireBaseServices.sharedInstance.listenCallFrom { [weak self] (callerId) in
            self?.handleCallerIdRecieve(callerId)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        client = WebRtcClient()
        client?.user = user
        client?.caller = caller
        client?.delegate = self
        client?.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        RTCFireBaseServices.sharedInstance.createOrUpdateUser(sdp: "", caller: "")
    }
    
    func handleCallerIdRecieve(_ callerId: String) {
        RTCFireBaseServices.sharedInstance.getDataSdpCaller(token: callerId) { [weak self] (sdp) in
            self?.client?.handleAnswerRecieve(sdp, nil)
        }
        RTCFireBaseServices.sharedInstance.getDataCandidatesCaller(token: callerId) { [weak self] (candidate) in
            self?.client?.handleAnswerRecieve(nil, candidate)
        }
    }
    
    
    @IBAction func cancelButtonAction(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension MainViewController: WebRtcClientDelegate {
    func connectionState(_ connectionState: RTCIceConnectionState) {
        DispatchQueue.main.async {
            switch connectionState {
            case .new:
                self.stateLabel.text = "NEW"
            case .checking:
                self.stateLabel.text = "CHECKING"
            case .connected:
                self.stateLabel.text = "CONNECTED"
            case .completed:
                self.stateLabel.text = "COMPLETED"
            case .failed:
                self.stateLabel.text = "FAILED"
            case .disconnected:
                self.stateLabel.text = "DISCONNECTED"
                self.navigationController?.popViewController(animated: true)
            case .closed:
                self.stateLabel.text = "CLOSED"
            case .count:
                self.stateLabel.text = "COUNT"
            @unknown default:
                self.stateLabel.text = "UNKNOWN"
            }
        }
    }
    func onLocalStream(_ localMediaStream: RTCMediaStream?) {
        if let videoTrack = localMediaStream?.videoTracks.first {
            videoTrack.isEnabled = true
            videoTrack.add(localRender)
        }
    }
    
    func onRemoteStream(_ remoteMediaStream: RTCMediaStream?) {
        if let videoTrack = remoteMediaStream?.videoTracks[0] {
            videoTrack.isEnabled = true
            videoTrack.add(remoteRender)
        }
    }
}
