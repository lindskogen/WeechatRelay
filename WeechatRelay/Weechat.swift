//
//  Weechat.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-19.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Foundation
import Cocoa

public class Weechat {
    
    let connection:TCPClient
    
    public init(socket : TCPClient) {
        connection = socket
    }
    
    func send(command : String) {
        connection.send(str: "\(command)\n")
    }
    
    func readHdata(id : String? = nil) -> WeechatHdata? {
        let lengthByteLength = 4
        if let lengthData = readToData(lengthByteLength) {
            var length:UInt32 = 0
            lengthData.getBytes(&length, length: lengthByteLength)
            length = CFSwapInt32BigToHost(length)
            
            let messageByteLength = Int(length) - lengthByteLength
            
            if let messageData = readToData(messageByteLength) {
                return WeechatMessageParser(data: messageData, id: id).parse()
            }
        }
        return nil
    }
    
    func readWeechatLines() -> [WeechatLine]? {
        if let lines: [[String: Any]] = readHdata()?.toDicts() {
            return lines.map({ (date: $0["date"] as! NSString, message: $0["message"] as! String) })
                .map({
                WeechatLine(
                    date: NSDate(timeIntervalSince1970: $0.date.doubleValue),
                    message: $0.message
                )
            })
        } else {
            return nil
        }
    }
    
    private func readToData(length : Int) -> NSData? {
        if let readBytes = connection.read(length) {
            return NSData(bytes: readBytes as [UInt8], length: length)
        } else {
            return nil
        }
    }
    
    public func send_init(password : String = "", compression : CompressionType = .OFF) {
        send("init password=\(password),compression=\(compression)")
    }
    
    func send_test() {
        send("hotlist:gui_hotlist(*)")
        readHdata()
    }
    
    public func getHotlist() {
        send_hdata("hotlist:gui_hotlist(*)")
        let hdata = readHdata()
        print(hdata)
    }
    
    public func getBuffers() {
        send_hdata("buffer:gui_buffers(*) local_variables,notify,number,full_name,short_name,title")
        let hdata = readHdata()
        print(hdata)
    }
    
    public func send_hdata(path : String) {
        send("hdata \(path)")
        // read()
    }
    
    public func getLines() -> [WeechatLine] {
        send_hdata("buffer:gui_buffers(*)/lines/first_line(*)/data date,message")
        return readWeechatLines()!
    }
}

public struct WeechatLine {
    let date: NSDate
    let message: String
}

public enum CompressionType : String {
    case ZLIB = "zlib"
    case OFF = "off"
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

class WeechatHdata : CustomStringConvertible {
    let path: String
    var elements: [[String: Any]] = []
    
    var description: String {
        let elems = ", ".join(elements.map({$0.description}))
        return "\(path) {\(elems)}"
    }
    
    init(path: String) {
        self.path = path
    }
    
    func append(dict: Dictionary<String, Any>) {
        elements.append(dict)
    }
    
    func toDicts() -> [[String: Any]] {
        return elements
    }
    
}



