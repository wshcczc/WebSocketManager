//
//  WKWebSocket.swift
//  Wtb
//
//  Created by sorath on 2019/1/16.
//  Copyright © 2019 sorath. All rights reserved.
//

import UIKit
import Starscream

enum WKSocketMSGType:Int {
    case login = 0      //登录
    case signOut = 1    //登出
    case confirm = 2    //确认
    case syn = 4        //心跳包
}

//对Starscream的封装，包含了重新登陆的机制，重连的机制留给外部
class WKWebSocket:NSObject{
    var websocketUrl:String =  ""
    var socket:WebSocket
    
    var onConnect:(()->Void)?
    var onDisconnect:((Error?)->Void)?
    var onText:((String)->Void)?
    var onData:((Data)->Void)?
    
    
    init(url:String) {
        
        websocketUrl = url
        if let u = URL(string: url){
            socket = WebSocket(url:u )
            
        }else{
            socket = WebSocket(url:URL(string: url)! )
        }
        
        super.init()
        
        socket.delegate = self
    }
    
    
    func closeConnect(){
        socket.disconnect()
    }
    
    func connect(){
        socket.connect()
   
    }
    
    
    
}

//MARK: - 封装diaoyong
extension WKWebSocket{
    //重新连接后，再次重新登陆
    func socketLogin(){
        wkSocketWrite(type: .login)
    }
    
    //心跳包
    func socketHeartBeat(){
        wkSocketWrite(type: .syn)
    }
}


//MARK: - write
extension WKWebSocket{
    //统一格式调用
    func wkSocketWrite(type:WKSocketMSGType){
        AccountManager.getAccount().token = "h5_waykimain_5ccb28d4-89fc-481f-8deb-5856b744bd24"

        let token = AccountManager.getAccount().token
        
        if token.count>0{
            
            let map:[String:Any]
            if type != .syn{
                let msgUuid:String = UUIDTool.createRandomString(withKey: "132")
                let deviceId:String = UUIDTool.getUUIDInKeychain()
                map = ["msgType":type.rawValue,"msgUuid":msgUuid,"msgBody":["accessToken": token,
                                                                                "platform":"ios",
                                                                                "deviceId":deviceId,
                    ]] as [String : Any]
            }else{
                //心跳包
                map = ["msgType":type.rawValue] as [String : Any]
            }
           
            
            let j = String.getJSONStringFromDictionary(dictionary: map as NSDictionary)
            print("websocket is write ",j)
            socketWrite(string: j)
        }
    }
    
    func socketWrite(data:Data) {
        socket.write(data: data)
    }
    
    func socketWrite(string:String) {
        socket.write(string: string)
    }
    
    func socketWrite(ping:Data) {
        socket.write(ping: ping)
    }
    
    func socketWrite(pong:Data) {
        socket.write(pong: pong)
    }
}

extension WKWebSocket:WebSocketDelegate{
    func websocketDidConnect(socket: WebSocketClient){
        print("websocket is connected")
        if onConnect != nil {
            onConnect!()
        }
        
    }
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?){
        print("websocket is disconnected: \(error?.localizedDescription)")
        if onDisconnect != nil {
            onDisconnect!(error)
        }
        
    }
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String){
        print("got some text: \(text)")
        if onText != nil {
            onText!(text)
        }
    }
    func websocketDidReceiveData(socket: WebSocketClient, data: Data){
        print("got some data: \(data.count)")
        if onData != nil {
            onData!(data)
        }
    }
}

/*
 ### Wicc 客户端向服务端消息结构
 
 
 ##报文结构：
 | 字段名 | 类型 | 说明 |
 |-------|------|-----|
 |msgUuid|String|随机生成，确保每次向服务器发的消息的msgUuid唯一|
 |msgType|Int|消息类型，为整数值，详见下文|
 |msgBody|Object|消息体，不同的消息类型拥有不同的消息体结构|
 
 
 
 ##登录接口说明
 
 ##### 请求参数
 | 字段名 | 类型| 说明 |
 |-----|-----|-------|
 | platform | String | 应用平台，取android,ios,h5,pc|
 | deviceId | String | 设备唯一编码，如android的imei号，ios的deviceToken,h5，pc生成的唯一编码，原则上同一台设备，此值不变|
 | accessToken | String | 用户请求的token,在应用登录时取得 |
 
 
 
 ##消息确认包
 
 ##### 请求参数
 | 字段名 | 类型| 说明 |
 |-----|----- |-------|
 |msgUuid|String|需要确认的消息的UUID|
 | timestamp | Int64 | 时间戳,可选 |
 
 
 ## 心跳消息包
 
 ## 退出消息包
 
 
 
 ####消息类型
 | 类型编号 | 说明 |
 |---------|------|
 | 0 |登录消息|
 |1| 登出消息|
 |2| 确认消息|
 |4| 心跳消息|
 
 
 */
