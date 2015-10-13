//
//  WeechatDataType.swift
//  Pods
//
//  Created by Johan Lindskogen on 2015-09-06.
//
//

import Foundation

public class WeechatMessage {
    public var elements: [Dictionary<String, Any>]
    
    init() {
        elements = []
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

public class WeechatBufferLine: WeechatHdataType {
    public let date: NSDate
    public let message: String
    public let buffer: Int
    public let pointer: Int
    public let tags: [String?]
    
    init(dict: [String: Any]) {
        date = NSDate(timeIntervalSince1970: WeechatBuffer.stringToNSString(dict["date"]!).doubleValue)
        message = dict["message"] as! String
        buffer = dict["buffer"] as! Int
        pointer = dict["pointer"] as! Int
        if let tags_array = dict["tags_array"] as? [Any?] {
            tags = tags_array.map({ $0 as? String })
        } else {
            tags = []
        }
        
    }
    
    override public var description: String {
        return message
    }
}

public class WeechatBuffer: WeechatHdataType {
    let MAXLINE = 200
    
    public var notify: Int
    public var number: Int
    public var fullName: String?
    public var shortName: String?
    public var title: String?
    public var localVariables:[String: Any]
    public let pointer: Int
    
    public var lines: [WeechatBufferLine] = []
    public var nicks: [WeechatNick] = []
    
    let name = "name"
    
    init(dict: [String: Any]) {
        self.notify = dict["notify"] as! Int
        self.number = dict["number"] as! Int
        self.fullName = dict["full_name"] as? String
        self.shortName = dict["short_name"] as? String
        self.title = dict["title"] as? String
        self.pointer = dict["pointer"] as! Int
        self.localVariables = dict["local_variables"] as! Dictionary<String, Any>
    }
    
    override public var description: String {
        return "\(number).\(shortName) (\(notify)) \(title)"
    }
    
    public func hasLine(linePointer: Int) -> Bool {
        return lines.contains({$0.pointer == linePointer})
    }
    
    public func addLine(line: WeechatBufferLine) -> Bool {
        var addedLine = false
        if !hasLine(line.pointer) {
            lines.append(line)
            addedLine = true
        }
        return addedLine
    }
}

public class WeechatNick {
    
}

public class WeechatHdata: WeechatMessage, CustomStringConvertible {
    public let path: String
    public let pointer: Int
    
    public var description: String {
        let elems = elements.map({$0.description}).joinWithSeparator("\n")
        return "\(path){\n\(elems)\n}"
    }
    
    init(path: String, pointer: Int) {
        self.path = path
        self.pointer = pointer
    }
    
    func append(element: Dictionary<String, Any>) {
        elements.append(element)
    }
}


public enum WeechatTypeSize: Int {
    case Char    = 1
    case Int     = 4
}