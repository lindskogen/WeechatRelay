//
//  Weechat.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-19.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Foundation

class Weechat {
    
    let connection:TCPClient
    
    init(socket : TCPClient) {
        connection = socket
    }
    
    func send(command : String) {
        connection.send(str: "\(command)\n")
    }
    
    func read(id : String? = nil) -> WeechatMessage? {
        let lengthByteLength = 4
        if let lengthData = readToData(lengthByteLength) {
            var length:UInt32 = 0
            lengthData.getBytes(&length, length: lengthByteLength)
            length = CFSwapInt32BigToHost(length)
            
            let messageByteLength = Int(length) - lengthByteLength
            
            if let messageData = readToData(messageByteLength) {
                return WeechatMessage(data: messageData, id: id)
            }
        }
        return nil
    }
    
    private func readToData(length : Int) -> NSData? {
        if let readBytes = connection.read(length) {
            return NSData(bytes: readBytes as [UInt8], length: length)
        } else {
            return nil
        }
    }
    
    func send_init(password : String = "", compression : CompressionType = .OFF) {
        send("init password=\(password),compression=\(compression)")
    }
    
    func send_test() {
        send("test")
        read()
    }
    
    func send_hdata(path : String) {
        send("hdata \(path)")
        read()
    }
}

enum CompressionType : String {
    case ZLIB = "zlib"
    case OFF = "off"
}


/*  ┌────────╥─────────────╥────╥────────┬──────────╥───────╥────────┬──────────┐
    │ length ║ compression ║ id ║ type 1 │ object 1 ║  ...  ║ type N │ object N │
    └────────╨─────────────╨────╨────────┴──────────╨───────╨────────┴──────────┘
     └──────┘ └───────────┘ └──┘ └──────┘ └────────┘         └──────┘ └────────┘
         4          1        ??      3        ??                 3        ??
     └────────────────────┘ └──────────────────────────────────────────────────┘
           header (5)                        compressed data (??)
     └─────────────────────────────────────────────────────────────────────────┘
                              'length' bytes                                    */

class WeechatMessage {
    
    var messageData:[Any] = []
    var count = 0
    
    init(data : NSData, id : String? = nil) {
        
        count = data.length
        
        let stream = NSInputStream(data: data)
        
        stream.open()
        
        let isCompressed = stream.readUInt8()
        
        count--
        
        assert(isCompressed == 0x00, "data should not be compressed")
        
        
        let idLength = stream.readInt()
        count -= 4
        // assert(idLength == id?.characters.count)
        if idLength != -1 {
            count -= idLength
            let idString = stream.readString(idLength)
            // TODO: Match idString with correct command id
        }
        
        WeechatMessageParser(stream: stream, withLength: count)
        print("stream ended")
        
        stream.close()

    }
    
}

class WeechatMessageParser {
    
    let stream: NSInputStream
    var count: Int
    
    
    init(stream: NSInputStream, withLength length: Int) {
        self.stream = stream
        self.count = length
        
        while count > 0 {
            readTypeAndObject()
        }
    }
    
    private func readObject(withType type: WeechatDataType) -> Any {
        var value : Any = "NULL"
        
        switch (type) {
        case .Char:
            value = stream.readChar()
            count--
            break
            
        case .String, .Buffer:
            value = readString()
            break
            
        case .Int:
            value = readInt()
            break
            
        case .Long, .Time:
            value = readLong()
            break
            
        case .Pointer:
            value = readPointer()
            break
            
        case .Array:
            value = readArray()
            break
        
            
        case .Hdata:
            let hd = readHdata()
            hd.elements.forEach(printMessage)
            value = hd
        }
        
        // print("\(type): \"\(value)\"")
        return value
        
    }
    
    private func printMessage(row: Dictionary<String, Any>) {
        print(row["message"]!)
    }
    
    private func readType() -> WeechatDataType {
        let type = readString(withLength: 3)
        
        return WeechatDataType(rawValue: type)!
    }
    
    private func readTypeAndObject() -> Any {
        let type = readType()
        
        return readObject(withType: type)
    }
    
    private func readInt() -> Int {
        count -= 4
        return stream.readInt()
    }
    
    private func readString(withLength length: Int) -> String {
        if length == 0 {
            return ""
        } else if length < 0 {
            return "NULL"
        }
        
        count -= length
        return stream.readString(length)
    }
    
    private func readString() -> String {
        let stringLength = readInt()
        
        return readString(withLength: stringLength)
    }
    
    private func readLong() -> String {
        let stringLength = Int(stream.readInt8())
        count--
        return readString(withLength: stringLength)
    }
    
    private func readPointer() -> String {
        let string = readLong()
        
        if string == "0" {
            return "NULL"
        } else {
            return string
        }
    }
    
    private func readArray() -> [Any] {
        let type = readType()
        let arrLength = readInt()
        var resultArray: [Any] = []
        
        if arrLength > 0 {
            for _ in 1...arrLength {
                resultArray.append(readObject(withType: type))
            }
            return resultArray
        } else {
            return []
        }
    }
    
    private func typeStringToTuple(typeString: String) -> (name: String, type: WeechatDataType) {
        let split = typeString.componentsSeparatedByString(":")
        return (split[0], WeechatDataType(rawValue: split[1])!)
    }
    
    private func readHdata() -> WeechatHdata {
        let path = readString()
        let pathElementCount = path.componentsSeparatedByString("/").count
        let keys = readString().componentsSeparatedByString(",").map(typeStringToTuple)
        let valueCount = readInt()
        
        let hData = WeechatHdata(path: path)
        var dict: [String: Any]
        var pPaths: [String]
        
        for _ in (1...valueCount) {
            dict = Dictionary<String, Any>()
            pPaths = []
            
            for _ in 1...pathElementCount {
                pPaths.append(readPointer())
            }
            dict["__path"] = pPaths
            
            for key in keys {
                dict[key.name] = readObject(withType: key.type)
            }
            hData.addElement(dict)
        }
        
        return hData
    }
}


enum WeechatDataType: String {
    case String  = "str"
    case Buffer  = "buf"
    case Char    = "chr"
    case Int     = "int"
    case Long    = "lon"
    case Time    = "tim"
    case Pointer = "ptr"
    case Array   = "arr"
    case Hdata   = "hda"
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
    
    func addElement(dict: Dictionary<String, Any>) {
        elements.append(dict)
    }
    
    
    
}



