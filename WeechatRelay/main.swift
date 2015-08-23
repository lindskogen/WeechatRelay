//
//  main.swift
//  WeechatRelay
//
//  Created by Johan Lindskogen on 2015-08-23.
//  Copyright © 2015 Lindskogen. All rights reserved.
//

let client = TCPClient(addr: "127.0.0.1", port: 9000)

let (success, _) = client.connect(timeout: 3600)

if success {
    let wc = Weechat(socket: client)
    wc.send_init()
    
    wc.send_hdata("buffer:gui_buffers(*)/lines/first_line(*)/data")
    // wc.send_test()
    // print(response)
    
}

