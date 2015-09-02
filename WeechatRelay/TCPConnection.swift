//
//  TCPConnection.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-23.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

public class TCPConnection: GCDAsyncSocketDelegate {
    
    public init(host: String, port: Int) {
        let asyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        
        do {
            try asyncSocket.connectToHost(host, onPort: UInt16(port))
        } catch {
            
        }
        
    }
    
    @objc public func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        
    }
    
    @objc public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        
    }
    
}
