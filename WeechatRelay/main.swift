//
//  main.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-23.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

import Cocoa

do {
    let wc = try Weechat(host: "127.0.0.1", port: 9000)
    
    // wc.getLines()
    wc.getBuffers()
    // wc.getHotlist()
    
    NSRunLoop.mainRunLoop().run()
} catch {
    fatalError("ERRROR")
}
