//
//  NSInputStream_Extensions.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-19.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Foundation

extension NSInputStream {
    
    func readUInt8() -> UInt8 {
        var buffer : UInt8 = 0
        let bytesRead = self.read(&buffer, maxLength: 1)
        assert(bytesRead >= 0, "stream not open?")
        
        return buffer
    }
    
    func readInt8() -> Int8 {
        return Int8(bitPattern: readUInt8())
    }
    
    func readInt32() -> Int32 {
        var buffer : UInt32 = 0
        buffer += UInt32(readUInt8()) << (3 * 8)
        buffer += UInt32(readUInt8()) << (2 * 8)
        buffer += UInt32(readUInt8()) << 8
        buffer += UInt32(readUInt8())
        
        return Int32(bitPattern: buffer)
    }

    
    func readInt() -> Int {
        return Int(readInt32())
    }
    
    func readChar() -> Bool {
        return readUInt8() == 1
    }
    
    func readString(length: Int) -> String {
        var buffer = [UInt8]()
        var utf8 = UTF8()
        var resultString = ""
        
        assert(length > 0, "length is \(length)")
        
        for _ in 1...length {
            buffer.append(readUInt8())
        }
        var generator = buffer.generate()
        var finished = false
        
        repeat {
            let result = utf8.decode(&generator)
            
            switch result {
            case .Result(let char):
                resultString.append(char)
                break
            default:
                finished = true
            }
        } while !finished
        
        
        return resultString
    }

}
