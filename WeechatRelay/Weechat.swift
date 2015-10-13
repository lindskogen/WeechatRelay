//
//  Weechat.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-19.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import BBSZLib

public class Weechat: GCDAsyncSocketDelegate {
    
    private lazy var socket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
    
    private let TIMEOUT = 3600.0
    private let NO_TIMEOUT = -1.0
    
    private var messageHandlers: [String: [WeechatMessageHandler]] = Dictionary()
    private var queuedReads = 0
    
    private var incrementingTag = 1
    private let headerTag = 0
    
    private let HEADER_LENGTH = 4
    
    public init(host: String, port: Int, password: String = "") throws {
        
        try socket.connectToHost(host, onPort: UInt16(port))
        print("connecting to \(host):\(UInt16(port))")
        
        writeString("init password=\(password),compression=zlib", id: .INIT)
        queueReadHeader()
    }
    
    public func addHandler(event: String, handler: WeechatMessageHandler) {
        
        if var handlers = messageHandlers[event] {
            handlers.append(handler)
        } else {
            messageHandlers[event] = [handler]
        }
    }
    
    func writeString(string: String, id: WeechatTagConstant) {
        // print(string)
        let commandString = "(\(id.rawValue))\(string)\n"
        socket.writeData(commandString.dataUsingEncoding(NSUTF8StringEncoding), withTimeout: NO_TIMEOUT, tag: headerTag)
    }
    
    func queueReadMessage(length: Int, tag: Int) {
    
        queuedReads++
        
        print("queued: len(\(length))")
        let len = UInt(length)
        
        socket.readDataToLength(len, withTimeout: NO_TIMEOUT, tag: tag)
    }
    
    func queueReadHeader() {
        queueReadMessage(HEADER_LENGTH, tag: headerTag)
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
        
        queuedReads--
        
        if tag == headerTag {
            let weechatData = WeechatData(data: data)
            
            let length = readHeader(weechatData)
            
            queueReadMessage(length - HEADER_LENGTH, tag: 1)
        } else {
            readBody(data, tag: tag)
        }
        
        print("queuedReads", queuedReads)
        
        if queuedReads == 0 {
            queueReadHeader()
        }
    }
    
    private func readHeader(data: WeechatData) -> Int {
        let lengthOfMessage = data.readInt()
        
        return lengthOfMessage
    }
    
    private func decompressData(data: NSData) -> NSData {
        do {
            return try data.bbs_dataByInflating()
        } catch {
            return data
        }
    }
    
    private func dataIsCompressed(data: WeechatData) -> Bool {
        return data.readChar()
    }
    
    private func readBody(data: NSData, tag: Int) {
        
        let isCompressedData = WeechatData(data: data.subdataWithRange(NSMakeRange(0, 1)))
        var uncompressedData = data.subdataWithRange(NSMakeRange(1, data.length - 1))
        
        if dataIsCompressed(isCompressedData) {
            uncompressedData = decompressData(uncompressedData)
        }
        
        let weechatData = WeechatData(data: uncompressedData)
        
        
        guard let id = weechatData.readString() else { fatalError("id not defined") }
        
        print(id)
        
        if let handlers = messageHandlers[id] where handlers.count > 0 {
            handlers.forEach({ (handler) in
                handler.handleMessage(weechatData, id: id)
            })
        } else {
            fatalError("no handler for (\(id))")
        }
    }
    
    private func printData(data: NSData) {
        debugPrint(String(data: data, encoding: NSUTF8StringEncoding))
    }
    
    public func getHotlist() {
        send_hdata("hotlist:gui_hotlist(*)", tag: .HOTLIST)
    }
    
    public func getBuffers() {
        send_hdata("buffer:gui_buffers(*) local_variables,lines,notify,number,full_name,short_name,title", tag: .BUFFER)
    }
    
    public func send_input(buffer: String, data: String) {
        writeString("input \(buffer) \(data)", id: .INPUT)
    }
    
    func send_hdata(path: String, tag: WeechatTagConstant) {
        writeString("hdata \(path)", id: tag)
    }
    
    public func getLines(num: Int) {
        send_hdata("buffer:gui_buffers(*)/lines/last_line(-\(num))/data", tag: .LINES)
    }
}

// https://weechat.org/files/doc/stable/weechat_plugin_api.en.html#hdata

public enum WeechatTagConstant: String {
    case INPUT    = "input"
    case HEADER   = "header"
    case INIT     = "init"
    case LINES    = "lines"
    case BUFFER   = "buffer"
    case HOTLIST  = "hotlist"
    case NICKLIST = "nicklist"
    case EVENT    = "event"
}

