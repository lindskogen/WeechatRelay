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
    
    func readUnicodeScalar() -> UnicodeScalar {
        return UnicodeScalar(readUInt8())
    }
    
    func readChar() -> Character {
        return Character(UnicodeScalar(readUInt8()))
    }
    
    func readString(length: Int) -> String {
        var resultString = String()
        
        assert(length > 0, "length is \(length)")
        
        for _ in 1...length {
            resultString.append(readUnicodeScalar())
        }
        return resultString
    }

}