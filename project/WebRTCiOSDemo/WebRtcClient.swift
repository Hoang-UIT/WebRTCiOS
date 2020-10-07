//
//  WebRtcClient.swift
//  WebRTCiOSDemo
//
//  Created by hoangtp on 7/8/20.
//  Copyright © 2020 Rakumo. All rights reserved.
//

import Foundation
import WebRTC

protocol WebRtcClientDelegate: class {
    func connectionState(_ connectionState: RTCIceConnectionState)
    func onLocalStream(_ localMediaStream: RTCMediaStream?)
    func onRemoteStream(_ remoteMediaStream: RTCMediaStream?)
}

class WebRtcClient: NSObject {
    
    private var factory: RTCPeerConnectionFactory?
    private var mediaConstraints :RTCMediaConstraints?
    private var peer: RTCPeerConnection?
    private var localMediaStream: RTCMediaStream?
    private var remoteMediaStream: RTCMediaStream?
    private var audioSource: RTCAudioSource?
    private var videoSource: RTCVideoSource?
    private var videoCapturer: RTCCameraVideoCapturer?
    
    var user: Caller?
    var caller: Caller?
    
    weak var delegate: WebRtcClientDelegate?
    
    override init() {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        RTCPeerConnectionFactory.initialize()
        factory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
        factory?.setOptions(RTCPeerConnectionFactoryOptions())
        
        mediaConstraints = RTCMediaConstraints(mandatoryConstraints: [kRTCMediaConstraintsOfferToReceiveAudio:kRTCMediaConstraintsValueTrue, kRTCMediaConstraintsOfferToReceiveVideo:kRTCMediaConstraintsValueTrue], optionalConstraints: ["DtlsSrtpKeyAgreement":kRTCMediaConstraintsValueTrue])
    }
    
    func start() {
        peer = Peer()
        createMediaStream()
        if let caller = caller {
            createAnswer(caller)
        } else {
            createOffer()
        }
    }
    
    func close() {
        
    }
    
    private func defaultICEServer() -> [RTCIceServer] {
        
        var iceServers = [RTCIceServer]()
        let stunServ = RTCIceServer(urlStrings: ["stun:stun1.l.google.com:19302"])
        iceServers.append(stunServ)
        
        let turnServ = RTCIceServer(urlStrings: ["turn:numb.viagenie.ca"], username:  "webrtc@live.com", credential: "muazkh")
        iceServers.append(turnServ)
        return iceServers
    }
    
    private func createMediaStream() {
        localMediaStream = factory?.mediaStream(withStreamId: "ARDAMS")
        
        if let audioTrack = createAudioTrack() {
            audioTrack.isEnabled = true
            localMediaStream?.addAudioTrack(audioTrack)
        }
        
        if let videoTrack = createVideoTrack() {
            videoTrack.isEnabled = true
            localMediaStream?.addVideoTrack(videoTrack)
        }
        
        if let localMediaStream = localMediaStream {
            peer?.add(localMediaStream)
            delegate?.onLocalStream(localMediaStream)
        }
    }
    
    private func createAudioTrack() -> RTCAudioTrack? {
        guard let audioSource = factory?.audioSource(with: RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio" : "true"], optionalConstraints: nil)) else {
            return nil
        }
        self.audioSource = audioSource
        let audioTrack = factory?.audioTrack(with: audioSource, trackId: "ARDAMSa0")
        return audioTrack
    }
    
    private func createVideoTrack() -> RTCVideoTrack? {
        guard let videoSource = factory?.videoSource() else {
            return nil
        }
        self.videoSource = videoSource
        
        let devices = RTCCameraVideoCapturer.captureDevices()
        if let frontCamera = (devices.first {$0.position == .front}),
            let format = RTCCameraVideoCapturer.supportedFormats(for: frontCamera).last,
            let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate {
            let intFps = Int(fps)
            
            videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
            if #available(iOS 13.0, *) {
                videoCapturer?.captureSession.connections.first?.isVideoMirrored = true
            } else {
                // Fallback on earlier versions
                
            }
            videoCapturer?.startCapture(with: frontCamera, format: format, fps: intFps)
            let videoTrack = factory?.videoTrack(with: videoSource, trackId: "ARDAMSv0")
            
            return videoTrack
        }
        
        //        if let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
        //
        //            // choose highest res
        //            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
        //                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
        //                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
        //                return width1 < width2
        //            }).last,
        //
        //            // choose highest fps
        //            let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) {
        //
        //
        //            videoCapturer?.startCapture(with: frontCamera, format: format, fps: Int(fps.maxFrameRate))
        //
        //
        //        }
        return nil
    }
    
    private func Peer() -> RTCPeerConnection? {
        let rtcConfiguration = RTCConfiguration()
        rtcConfiguration.iceServers = defaultICEServer()
        rtcConfiguration.tcpCandidatePolicy = .disabled
        rtcConfiguration.bundlePolicy = .maxBundle
        rtcConfiguration.rtcpMuxPolicy = .require
        rtcConfiguration.continualGatheringPolicy = .gatherContinually
        rtcConfiguration.keyType = .ECDSA
        
        guard let mediaConstraints = mediaConstraints else {
            return nil
        }
        return factory?.peerConnection(with: rtcConfiguration, constraints: mediaConstraints, delegate: self)
    }
    
    private func createOffer() {
        guard let mediaConstraints = mediaConstraints else {
            return
        }
        peer?.offer(for: mediaConstraints, completionHandler: { [ weak self] (sessionDesciption, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let sessionDesciption = sessionDesciption else {
                return
            }
            self?.handleSdpGenerated(sessionDesciption)
        })
    }
    
    func createAnswer(_ caller: Caller) {
        if let callerId = caller.id {
            RTCFireBaseServices.sharedInstance.callTo(callerId: callerId)
        }
        guard let sdp = caller.sdp else {
            return
        }
        peer?.setRemoteDescription(RTCSessionDescription(type: .offer, sdp: sdp), completionHandler: { [weak self] (error) in
            if (error != nil) {
                print(error.debugDescription)
            } else {
                guard let mediaConstraints = self?.mediaConstraints else {
                    return
                }
                self?.peer?.answer(for: mediaConstraints, completionHandler: { (sessionDescription, error) in
                    if error != nil {
                        print(error.debugDescription)
                    } else {
                        guard let sessionDescription = sessionDescription else {
                            return
                        }
                        self?.handleSdpGenerated(sessionDescription)
                    }
                })
            }
        })
        for item in caller.candidates {
            guard let sdp = item.id,
                let sdpMLineIndex = item.label,
                let sdpMid = item.candidate else {
                    return
            }
            let candidate = RTCIceCandidate(sdp: sdp, sdpMLineIndex: Int32(sdpMLineIndex), sdpMid: sdpMid)
            self.peer?.add(candidate)
        }
    }
    
    func handleAnswerRecieve(_ sdp: String?, _ candidate: Candidate?) {
        if let sdp = sdp {
            let sessionDescription = RTCSessionDescription(type: .answer, sdp: sdp)
            peer?.setRemoteDescription(sessionDescription, completionHandler: { (error) in
                if error != nil {
                    print(error.debugDescription)
                }
            })
        }
        if let candidate = candidate {
            guard let sdp = candidate.id,
                let sdpMLineIndex = candidate.label,
                let sdpMid = candidate.candidate else {
                    return
            }
            self.peer?.add(RTCIceCandidate(sdp: sdp, sdpMLineIndex: Int32(sdpMLineIndex), sdpMid: sdpMid))
        }
    }
    
    private func handleSdpGenerated(_ sessionDescription: RTCSessionDescription) {
        RTCFireBaseServices.sharedInstance.createOrUpdateUser(sdp: sessionDescription.sdp)
        self.peer?.setLocalDescription(sessionDescription, completionHandler: { (error) in
            if error != nil {
                print(error.debugDescription)
            }
        })
    }
}

extension WebRtcClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        remoteMediaStream = stream
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        delegate?.connectionState(newState)
        switch newState {
        case .new:
            print("new")
        case .checking:
            print("checking")
        case .connected:
            print("connected")
            delegate?.onRemoteStream(remoteMediaStream)
        case .completed:
            print("completed")
        case .failed:
            print("failed")
        case .disconnected:
            print("disconnected")
        case .closed:
            print("closed")
        case .count:
            print("count")
        @unknown default:
            print("UNKNOWN")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let candidate = Candidate(id: candidate.sdp, label: Int(candidate.sdpMLineIndex), candidate: candidate.sdpMid ?? "")
        user?.candidates.append(candidate)
        RTCFireBaseServices.sharedInstance.updateCandidate(user?.candidates.count ?? 0, candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
}
