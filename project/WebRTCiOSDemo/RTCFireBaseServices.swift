//
//  RTCFireBaseServices.swift
//  WebRTCiOSDemo
//
//  Created by hoangtp on 7/8/20.
//  Copyright © 2020 Rakumo. All rights reserved.
//

import Foundation
import Firebase

class RTCFireBaseServices: NSObject {
    static let sharedInstance = RTCFireBaseServices()
    
    var ref: DatabaseReference!
    var token: String?
    
    private override init() {
    }
    
    func checkExist(completionHandler:((Bool)->())?) {
        guard let token = token else {
            completionHandler?(false)
            return
        }
        ref = Database.database().reference(withPath: "root/users/")
        ref.observeSingleEvent(of: .value) { (data) in
            if let dic = data.value as? [String : Any] {
                if dic.keys.contains(token) {
                    completionHandler?(true)
                } else {
                    completionHandler?(false)
                }
            } else {
                completionHandler?(false)
            }
        }
    }
    
    func createOrUpdateUser(name: String? = nil, isOnline: Bool? = nil, sdp: String? = nil, candidates: [Candidate]? = nil, caller: String? = nil) {
        guard let token = token else {
            return
        }
        ref = Database.database().reference(withPath: "root/users/\(token)")
        var info: [String: Any] = [:]
        info["token"] = token
        if let name = name {
            info["name"] = name
        }
        if let isOnline = isOnline {
            info["isOnline"] = isOnline
        }
        if let sdp = sdp {
            info["sdp"] = sdp
        }
        if let candidates = candidates {
            var dic = [String: Any]()
            for index in 0..<candidates.count {
                dic["\(index)"] = candidates[index].convertToDictionary()
            }
            info["candidates"] = dic
        } else {
            info["candidates"] = [:]
        }
        if let caller = caller {
            info["caller"] = caller
        }
        ref.updateChildValues(info)
    }
    
    func updateCandidate(_ index: Int, _ candidate: Candidate) {
        guard let token = token else {
                   return
               }
        ref = Database.database().reference(withPath: "root/users/\(token)/candidates/")
        let dic = ["\(index)": candidate.convertToDictionary()]
        ref.updateChildValues(dic)
    }
    
    func getListCaller(_ completionHanlder:(([Caller])->())?) {
        ref = Database.database().reference(withPath: "root/users/")
        ref.observe(.value, with: { (data) in
            var callers = [Caller]()
            if let dic = data.value as? [String: Any] {
                for (_,value) in dic {
                    if let _dic = value as? [String: Any] {
                        let caller = RTCFireBaseServices.sharedInstance.parseDataCaller(_dic)
                        callers.append(caller)
                    }
                }
            }
            completionHanlder?(callers)
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func callTo(callerId: String) {
        guard let token = token else {
            return
        }
        let info: [String: Any] = ["caller": token]
        ref = Database.database().reference(withPath: "root/users/\(callerId)")
        ref.updateChildValues(info)
    }
    
    func listenCallFrom(callBack:((_ callerId: String)->())?) {
        guard let token = token else {
            return
        }
        ref = Database.database().reference(withPath: "root/users/\(token)//caller")
        ref.observe(.value) { (data) in
            if let callerId = data.value as? String {
                callBack?(callerId)
            }
        }
    }
    
    func getDataSdpCaller(token: String, CompletionHandler:((String)->())?) {
        ref = Database.database().reference(withPath: "root/users/\(token)/sdp/")
        ref.observe(.value) { (data) in
            if let value = data.value as? String, !value.isEmpty {
                CompletionHandler?(value)
            }
        }
    }
    func getDataCandidatesCaller(token: String, CompletionHandler:((Candidate)->())?)  {
        ref = Database.database().reference(withPath: "root/users/\(token)/candidates/")
        ref.observe(.childAdded) { (data) in
            if let dic = data.value as? [String: Any] {
                if let id = dic["id"] as? String,
                    let label = dic["label"] as? Int,
                    let candidateStr = dic["candidate"] as? String{
                    let candidate = Candidate(id: id, label: label, candidate: candidateStr)
                    CompletionHandler?(candidate)
                }
            }
        }
    }
    
    func parseDataCaller(_ dic: [String : Any]) -> Caller {
        let caller = Caller()
        caller.id = dic["token"] as? String
        caller.name = dic["name"] as? String
        caller.isOnline = dic["isOnline"] as? Bool
        caller.sdp = dic["sdp"] as? String
        if let candidates = dic["candidates"] as? [[String : Any]] {
            for _dic in candidates {
                if let id = _dic["id"] as? String,
                    let label = _dic["label"] as? Int,
                    let candidateStr = _dic["candidate"] as? String{
                    let candidate = Candidate(id: id, label: label, candidate: candidateStr)
                    caller.candidates.append(candidate)
                }
            }
        }
        return caller
    }
}
