//
//  WeechatMessageParser.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-26.
//  Copyright © 2015 Johan Lindskogen. All rights reserved.
//

import Foundation

class WeechatMessage {
    
}

class WeechatParser {
    
    let stream: NSInputStream
    var count: Int
    let tag: Int
    
    
    init(data: NSData, tag: Int) {
        self.stream = NSInputStream(data: data)
        self.count = data.length
        self.tag = tag
        
    }
    
    func parseHeader() -> (length: Int, compressed: Bool) {
        
        stream.open()
        let length = readInt()
        let compressed = readByte() == 0x01
        stream.close()
        
        print(length, compressed)
        
        return (length - 5, compressed)
    }
    
    func parseBody() -> WeechatMessage? {
        
        stream.open()
        let actualId = readString()
        if actualId.hasPrefix("_") {
            print(actualId)
        }
        
        let type = readType()
        if  type != .Hdata {
            fatalError("type should be Hdata, was (\(type))")
        }
        let hdata = readHdata()
        stream.close()
        
        return hdata
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
        
        
        
        if let weetype = WeechatDataType(rawValue: type) {
            return weetype
        } else {
            fatalError("type \(type) is not supported")
        }
    }
    
    private func readTypeAndObject() -> Any {
        let type = readType()
        
        return readObject(withType: type)
    }
    
    private func readInt() -> Int {
        count -= WeechatTypeSize.Int.rawValue
        return stream.readInt()
    }
    
    private func readByte() -> UInt8 {
        count -= 1
        return stream.readUInt8()
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
        
        if string == "\0" {
            return "NULL"
        } else {
            return "0x\(string)"
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
            hData.append(processHdataType(dict))
        }
        
        return hData
    }
    
    private func processHdataType(dict: Dictionary<String, Any>) -> WeechatHdataType {
        switch tag {
            case TAG_LINES:
                return WeechatHdataLine(dict: dict)
            case TAG_BUFFER:
                return WeechatHdataBuffer(dict: dict)
            break
            case TAG_HOTLIST:
            break
            case TAG_NICKLIST:
            break
        default: break
            
        }
        debugPrint(dict)
        return WeechatHdataType()
    }
}

public class WeechatHdataType: CustomStringConvertible {
    public var description: String {
        fatalError("fail, description must be overridden")
    }
    static func stringToNSString(string: Any) -> NSString {
        return string as! NSString
    }
}

public class WeechatHdataLine: WeechatHdataType {
    let date: NSDate
    let message: String
    let buffer: String
    
    init(dict: Dictionary<String, Any>) {
        date = NSDate(timeIntervalSince1970: WeechatHdataBuffer.stringToNSString(dict["date"]).doubleValue)
        message = dict["message"] as! String
        buffer = dict["buffer"] as! String
    }
    
    override public var description: String {
        return "\(date): \(message)"
    }
}

public class WeechatHdataBuffer: WeechatHdataType {
    let notify: Int
    let number: Int
    let fullName: String
    let shortName: String
    let title: String
    let lines: String
    let localVariables:[String: Any]
    
    let name = "name"
    
    init(dict: Dictionary<String, Any>) {
        debugPrint(dict)
        notify = dict["notify"] as! Int
        number = dict["number"] as! Int
        lines = dict["lines"] as! String
        fullName = dict["full_name"] as! String
        shortName = dict["short_name"] as! String
        title = dict["title"] as! String
        localVariables = dict["local_variables"] as! Dictionary<String, Any>
    }
    
    override public var description: String {
        return "\(number).\(localVariables[name]!) (\(notify)) \(title) "
    }
}


class WeechatHdata: WeechatMessage, CustomStringConvertible {
    let path: String
    var elements: [WeechatHdataType] = []
    
    var description: String {
        let elems = "\n".join(elements.map({$0.description}))
        return "\(path){\n\(elems)\n}"
    }
    
    init(path: String) {
        self.path = path
    }
    
    func append(element: WeechatHdataType) {
        elements.append(element)
    }
}


enum WeechatTypeSize: Int {
    case Char    = 1
    case Int     = 4
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