//
//  Caller.swift
//  WebRTCiOSDemo
//
//  Created by hoangtp on 7/8/20.
//  Copyright © 2020 Rakumo. All rights reserved.
//

import Foundation

class Caller: NSObject {
    var id: String?
    var name: String?
    var isOnline: Bool?
    var sdp: String?
    var candidates = [Candidate]()
    
    init(_ id: String? = nil, _ name: String? = nil, _ isOnline: Bool? = nil) {
        super.init()
        self.id = id
        self.name = name
        self.isOnline = isOnline
    }
}

class Candidate: NSObject {
    var id: String?
    var label: Int?
    var candidate: String?
    
    init(id: String, label: Int, candidate: String) {
        super.init()
        self.id = id
        self.label = label
        self.candidate = candidate
    }
    
    func convertToDictionary() -> [String: Any] {
        var dic = [String: Any]()
        dic["id"] = id
        dic["label"] = label
        dic["candidate"] = candidate
        return dic
    }
}
