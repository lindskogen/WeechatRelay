//
//  WeechatMessageParser.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-26.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Foundation

class WeechatMessageParser {
    
    let stream: NSInputStream
    var count: Int
    let id: String?
    
    
    init(data: NSData, id: String? = nil) {
        self.stream = NSInputStream(data: data)
        self.count = data.length
        self.id = id
        
    }
    
    func parse() -> WeechatHdata? {
        
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
        
        if readType() != .Hdata {
            fatalError("type should be Hdata")
        }
        
        let hd = readHdata()
        
        print("stream ended")
        
        stream.close()
        
        return hd
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
            break
            
        case .Htable:
            value = readHtable()
        }
        
        // print("\(type): \"\(value)\"")
        return value
        
    }
    
    private func printMessage(row: Dictionary<String, Any>) {
        debugPrint(row)
        let line = row["message"] as! String
        
        print(line)
        
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
    
    private func readHtable() -> [String: Any] {
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
        debugPrint(split[1])
        return (split[0], WeechatDataType(rawValue: split[1])!)
    }
    
    private func readHdata() -> WeechatHdata {
        let path = readString()
        let pathElementCount = path.componentsSeparatedByString("/").count
        let keys = readString().componentsSeparatedByString(",").map(typeStringToTuple)
        
        debugPrint(keys)
        
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
            hData.append(dict)
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
    case Htable  = "htb"
}