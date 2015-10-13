//
//  WeechatMessageParser.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-26.
//  Copyright © 2015 Johan Lindskogen. All rights reserved.
//

import Foundation

public class WeechatData {
    
    let stream: NSInputStream
    var count: Int
    
    
    public init(data: NSData) {
        self.stream = NSInputStream(data: data)
        self.count = data.length
        
        self.stream.open()
    }
    
    
    
    private func readObject(withType type: WeechatDataType) -> Any? {
        var value: Any? = "NULL"
        
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
            break
            
        case .Htable:
            value = readHtable()
        }
        
        return value
        
    }
    
    public func printMessage(row: Dictionary<String, Any>) {
        debugPrint(row)
        let line = row["message"] as! String
        
        print(line)
        
    }
    
    public func readType() -> WeechatDataType {
        let type = readString(withLength: 3)!
        
        
        
        if let weetype = WeechatDataType(rawValue: type) {
            return weetype
        } else {
            fatalError("type \(type) is not supported")
        }
    }
    
    public func readInt() -> Int {
        count -= WeechatTypeSize.Int.rawValue
        return stream.readInt()
    }
    
    public func readUInt8() -> UInt8 {
        count -= WeechatTypeSize.Int.rawValue
        return stream.readUInt8()
    }
    
    public func readByte() -> UInt8 {
        count -= 1
        return stream.readUInt8()
    }
    
    public func readChar() -> Bool {
        count -= 1
        return stream.readChar()
    }
    
    public func readString(withLength length: Int) -> String? {
        if length == 0 {
            return ""
        } else if length < 0 {
            return nil
        }
        
        count -= length
        return stream.readString(length)
    }
    
    public func readString() -> String? {
        let stringLength = readInt()
        
        return readString(withLength: stringLength)
    }
    
    public func readLong() -> String {
        let stringLength = Int(stream.readInt8())
        count--
        return readString(withLength: stringLength)!
    }
    
    public func readPointer() -> Int {
        let string = readLong()
        if string == "\0" {
            return 0
        }
        return Int(string, radix: 16)!
    }
    
    public func readHdata() -> WeechatHdata {
        let path = readString()!
        let pathElementCount = path.componentsSeparatedByString("/").count
        let keys = readString()!.componentsSeparatedByString(",").map(typeStringToTuple)
        
        let valueCount = readInt()
        
        let hData = WeechatHdata(path: path, pointer: 0)
        var dict: [String: Any]
        
        for _ in (1...valueCount) {
            dict = Dictionary<String, Any>()
            
            var pointer = 0
            
            for _ in 1...pathElementCount {
                pointer = readPointer()
            }
            
            dict["pointer"] = pointer
            
            for key in keys {
                if let value = readObject(withType: key.type) {
                    dict[key.name] = value
                }
            }
            hData.append(dict)
        }
        
        return hData
    }
    
    public func readHtable() -> [String: Any] {
        let keyType = readType()
        let valueType = readType()
        
        let valueCount = readInt()
        
        var dict: [String: Any] = Dictionary<String, Any>()
        
        for _ in (1...valueCount) {
            let key = String(readObject(withType: keyType))
            
            dict[key] = readObject(withType: valueType)
        }
        return dict
    }
    
    public func readArray() -> [Any?] {
        let type = readType()
        let arrLength = readInt()
        var resultArray: [Any?] = []
        
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
    
}

public enum WeechatDataType: String {
    case String  = "str"
    case Buffer  = "buf"
    case Char    = "chr"
    case Int     = "int"
    case Long    = "lon"
    case Time    = "tim"
    case Pointer = "ptr"
    case Array   = "arr"
    case Hdata   = "hda"
    case Htable  = "htb"
}