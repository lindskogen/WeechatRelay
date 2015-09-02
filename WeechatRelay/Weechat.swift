//
//  Weechat.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-19.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Foundation
import Cocoa
import CocoaAsyncSocket


public class Weechat: GCDAsyncSocketDelegate {
    
    private lazy var socket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
    
    private let TIMEOUT = 3600.0
    private let NO_TIMEOUT = -1.0
    
    private let TAG_INIT     = 0
    private let TAG_LINES    = 1
    private let TAG_BUFFER   = 2
    private let TAG_HOTLIST  = 3
    private let TAG_NICKLIST = 4
    private let TAG_EVENT    = 9
    
    private var incrementingTag = 0
    
    private let HEADER_LENGTH = 5
    
    public init(host: String, port: Int, password: String = "") throws {
        
        try socket.connectToHost(host, onPort: UInt16(port))
        
        writeString("init password=\(password),compression=OFF")
    }
    
    func writeString(string: String) {
        print(string)
        let commandString = "\(string)\n"
        socket.writeData(commandString.dataUsingEncoding(NSUTF8StringEncoding), withTimeout: NO_TIMEOUT, tag: incrementingTag++)
    }
    
    func queueReadMessage(length: Int, tag: Int) {
        print("queued:", length, tag)
        let len = UInt(length)
        
        socket.readDataToLength(len, withTimeout: NO_TIMEOUT, tag: tag)
    }
    
    func queueReadHeader(tag: Int) {
        queueReadMessage(HEADER_LENGTH, tag: tag + 100)
    }
    
    @objc public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        print(err)
    }
    
    @objc public func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        print("socket connected! \(host):\(port)")
    }
    
    @objc public func socket(sock: GCDAsyncSocket!, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        print("partially read \(partialLength) bytes")
    }
    
    @objc public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if tag > 100 {
            let (length, _) = WeechatParser(data: data).parseHeader()
            queueReadMessage(length, tag: tag - 100)
            
        } else {
            let msg = WeechatParser(data: data).parseBody()
            print(msg!)
            queueReadHeader(TAG_EVENT)
        }
    }
    
    public func getHotlist() {
        send_hdata("hotlist:gui_hotlist(*)")
        queueReadHeader(TAG_HOTLIST)
    }
    
    public func getBuffers() {
        writeString("buffer:gui_buffers(*) local_variables,notify,number,full_name,short_name,title\nsync")
        queueReadHeader(TAG_BUFFER)
    }
    
    func send_hdata(path: String, keys: String = "") {
        writeString("hdata \(path) \(keys)")
    }
    
    public func getLines() {
        send_hdata("buffer:gui_buffers/lines/first_line(*)/data", keys: "date,message")
        queueReadHeader(TAG_LINES)
    }
}

public struct WeechatHdataLine {
    let date: NSDate
    let message: String
}

public class WeechatStringFormatter {
    
    static let SET_COLOR = String(0x19)
    static let SET_ATTR =  String(0x1A)
    static let REM_ATTR =  String(0x1B)
    static let RESET =     String(0x1C)
    
    static let CONTROL_CHARS = SET_COLOR + SET_ATTR + REM_ATTR + RESET
    
    static public func format(unformatted: String) -> String {
        // var formatted = ""
        return ""
    }
}


