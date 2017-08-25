//
//  TalkDatabase.swift
//  TestFile
//
//  Created by Jongwhan Lee on 26/07/2017.
//  Copyright © 2017 leejw51. All rights reserved.
//

// in production stage
// I'll use REALM DB or sqlite
// for persistency..
// comment by jongwhan lee

import Foundation
class TalkDatabase {
    var table = [String:Any]()
    static var sharedInstance:TalkDatabase?
    
    func initialize() {
        TalkDatabase.sharedInstance = self
        
        loadDB()
    }
    
    func makeTest() {
        print("Make Test")
        var messages = [ [String:String] ]()
        for i in 1...10 {
            var newone = [String:String]()
            newone["Right"] = "true"
            newone["Say"] = "Say=\(i)"
            messages.append(newone)
        }
        table["James"] = messages
        table["Mary"] = messages
        table["Robot"] = messages
    }
    
    func save(filename:String) {
        print("Save=",filename)
        let jsonObject = table
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions())         
            try jsonData.write(to: URL(fileURLWithPath: filename))
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func load(filename:String) {
        print("Load=", filename)
        do {            
            let data = try Data(contentsOf: URL(fileURLWithPath:filename))
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            self.table = json as! [String:Any]
            print(self.table)
        }
        catch {
             print(error.localizedDescription)
        }
        
      }
    
    func saveDB() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let p = documentsPath + "/talk.json"
        print("Save Path=", p)
        save(filename:p)
    }
    
    func loadDB() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let p = documentsPath + "/talk.json"
        print("Load Path=", p)
        load(filename:p)
    }
    
    func addUser(user:String) {
        if nil == self.table[user]  {
            self.table[user] = [ [String:String] ]()
        }
    }
    // in swift
    // array, dictionary are structs, so they are values 
    // comment by jongwhan lee
    func addPost(user:String, text:String) {
        addUser(user:user)
        var newone = [String:String]()
        newone["Right"] = "true"
        newone["Say"] =  text
        var messages : [ [String:String] ] = self.table[user] as! [ [String:String] ]
        messages.append(newone)
        self.table[user] = messages
        saveDB()
    }
    
    func addReply(user:String, text:String) {
        addUser(user:user)
        var newone = [String:String]()
        newone["Right"] = "false"
        newone["Say"] =  text
        var messages : [ [String:String] ] = self.table[user] as! [ [String:String] ]
        messages.append(newone)
        self.table[user] = messages
        saveDB()
    }

}
