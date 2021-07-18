//
//  Database.swift
//  TaskSpace
//
//  Created by Hoyoun Song on 2021/06/09.
//

import Foundation
public class Database {
    
    public static let originalDatabaseLocation = NSSwiftUtils.getHomeDirectory() + "Library/Taskspace/";
    
    public static var databaseLocation = NSSwiftUtils.getHomeDirectory() + "Library/Taskspace/";
    public static var containersPath = databaseLocation + "containers/";
    public static var keydataStore = databaseLocation + "keys/";
    public static var buffer_switch = databaseLocation + "buffer_switch";
    public static var buffer_update = databaseLocation + "buffer_update";
    public static var logs = databaseLocation + "logs/";
    
    public static let key_selected = "selected";
    public static let key_inProcess = "process";
    public static let key_root_emu = "root_emu";
    
    public static func _init(forceRoot: String?) -> Bool {
        if forceRoot != nil {
            var root = forceRoot
            if !forceRoot!.replacingOccurrences(of: "\n", with: "").hasSuffix("/") {
                root = forceRoot! + "/"
            }
            databaseLocation = root!
            containersPath = databaseLocation + "containers/";
            keydataStore = databaseLocation + "keys/";
            buffer_switch = databaseLocation + "buffer_switch";
            buffer_update = databaseLocation + "buffer_update";
            logs = databaseLocation + "logs/";
        }else if verify(key: key_root_emu) && !getData(key: key_root_emu).replacingOccurrences(of: "\n", with: "").elementsEqual("") {
            databaseLocation = getData(key: key_root_emu)
            containersPath = databaseLocation + "containers/";
            keydataStore = databaseLocation + "keys/";
            buffer_switch = databaseLocation + "buffer_switch";
            buffer_update = databaseLocation + "buffer_update";
            logs = databaseLocation + "logs/";
        }
        
        if !(NSSwiftUtils.doesTheFileExist(at: containersPath)
            && NSSwiftUtils.doesTheFileExist(at: logs)
                && NSSwiftUtils.doesTheFileExist(at: keydataStore)) {
            
            return NSSwiftUtils.createDirectoryWithParentsDirectories(to: containersPath)
            && NSSwiftUtils.createDirectoryWithParentsDirectories(to: logs)
            && NSSwiftUtils.createDirectoryWithParentsDirectories(to: keydataStore)
        }
        return true
    }
    
    public static func verify(key: String) -> Bool {
        return NSSwiftUtils.isFile(at: keydataStore + key);
    }
    
    public static func isContainerAvailable(name: String) -> Bool {
        return NSSwiftUtils.doesTheFileExist(at: containersPath + name)
    }
    
    public static func getData(key: String) -> String {
        if verify(key: key) {
            return NSSwiftUtils.readContents(of: keydataStore + key).replacingOccurrences(of: "\n", with: "")
        }
        return "undefined";
    }
    
    public static func addKey(key: String, data: String) -> Bool {
        return (NSSwiftUtils.executeShellScript("/bin/sh", "-c", "echo \(data) > \(keydataStore + key)") == 0)
    }
    
    
    public static func removeKey(key: String) -> Bool {
        return NSSwiftUtils.deleteFile(at: keydataStore + key)
    }
    
    public static func addContainer(name: String) -> Bool {
        if isContainerAvailable(name: name) {
            return false
        }
        return NSSwiftUtils.createDirectoryWithParentsDirectories(to: containersPath + name)
    }
    
    public static func removeContainer(name: String) -> Bool {
        if isContainerAvailable(name: name) {
            return (NSSwiftUtils.removeDirectory(at: containersPath + name, ignoreSubContents: true) == 0)
        }
        return false
    }
    
    public static func updateDesktop() -> String {
        let selectedDatabase = getData(key: key_selected)
        let desktop = NSSwiftUtils.getHomeDirectory() + "Desktop"
        
        while verify(key: key_inProcess) && !getData(key: key_inProcess).elementsEqual("update") {
            sleep(1)
        }
        if !addKey(key: key_inProcess, data: "update") {
            return "Unable to prepare environment to update."
        }
        if (NSSwiftUtils.executeShellScript("cp", "-r", desktop, buffer_update) != 0) {
            return "Failed to transfer contents to buffer."
        }
        if (NSSwiftUtils.removeDirectory(at: containersPath + selectedDatabase, ignoreSubContents: true) != 0) {
            return "Failed to clear previous container. Content is preserved in buffer."
        }
        if (NSSwiftUtils.executeShellScript("mv", buffer_update, containersPath + selectedDatabase + "/") != 0) {
            return "Failed to transfer contents from buffer to container. Content is preserved in buffer."
        }
        if !removeKey(key: key_inProcess) {
            return "Failed to remove process flag. Content is successfully transfered to container."
        }
        return "Update was successful."
    }
    
    public static func selectAsDesktop(container: String, doSync: Bool) -> String {
        
        let desktop = NSSwiftUtils.getHomeDirectory() + "Desktop"
        if verify(key: key_inProcess) {
            return "Unable to swap now - Process is running: \(getData(key: key_inProcess))"
        }
        
        if doSync {
            let outputFromUpdate = updateDesktop()
            if !outputFromUpdate.elementsEqual("Update was successful.") {
                return "[UPDATE ERROR] " + outputFromUpdate
            }
        }else{
            print("[Intentional - User] Previously selected workspace container is not updated.")
        }
        
        if !addKey(key: key_inProcess, data: "swapto_\(container)") {
            return "Failed to prepare environment to swap."
        }
        NSSwiftUtils.executeShellScript("/bin/sh", "-c", "rm -rf \"\(desktop)\"/*")
        removeKey(key: key_selected)
        if !addKey(key: key_selected, data: container) {
            return "Failed to set selected key."
        }
        if !NSSwiftUtils.createDirectoryWithParentsDirectories(to: desktop) {
            return "Failed to create desktop environment."
        }
        if (NSSwiftUtils.executeShellScript("cp", "-r", containersPath + container + "/", desktop) != 0) {
            return "Failed to update desktop environment."
        }
        if !removeKey(key: key_inProcess) {
            return "Failed to clear process information."
        }
        return "Swap successful."
    }
}
