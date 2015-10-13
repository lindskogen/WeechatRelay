//
//  File.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-09-06.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Foundation

public protocol WeechatMessageHandler {
    func handleMessage(data: WeechatData, id: String)
}

public protocol WeechatMessageHandlerDelegate {
    func didUpdateData()
}

public class WeechatLineManager: WeechatMessageHandler {
    
    let bufferManager: WeechatBufferManager
    public var delegate: WeechatMessageHandlerDelegate?
    
    public init(bufferManager: WeechatBufferManager) {
        self.bufferManager = bufferManager
    }
    
    public func handleMessage(data: WeechatData, id: String) {
        _ = data.readType()
        let hdata = data.readHdata()
        for elem in hdata.elements {
            let line = WeechatBufferLine(dict: elem)
            bufferManager.findByPointer(line.buffer)?.addLine(line)
        }
        delegate?.didUpdateData()
    }
}

public class WeechatBufferManager: WeechatMessageHandler {
    public var buffers: [Int: WeechatBuffer] = Dictionary<Int, WeechatBuffer>()
    public var delegate: WeechatMessageHandlerDelegate?
    
    public init() {}
    
    public func findByPointer(pointer: Int) -> WeechatBuffer? {
        return buffers[pointer]
    }
    
    public func handleMessage(data: WeechatData, id: String) {
        _ = data.readType()
        let hdata = data.readHdata()
        for elem in hdata.elements {
            let buffer = WeechatBuffer(dict: elem)
            buffers[buffer.pointer] = buffer
        }
        delegate?.didUpdateData()
    }
}


