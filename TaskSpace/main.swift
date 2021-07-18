//
//  main.swift
//  TaskSpace
//
//  Created by Hoyoun Song on 2021/06/09.
//

import Foundation

let arguments = CommandLine.arguments

if !Database._init(forceRoot: nil) {
    print("Failed to prepare for base environment.")
}

if !Database.verify(key: "default_setup") || !Database.getData(key: "default_setup").elementsEqual("done") {
    if !Database.addKey(key: Database.key_selected, data: "default") {
        print("ERROR: Failed setting key data for default container initialization.")
        exit(9)
    }
    if !Database.addContainer(name: "default") {
        print("ERROR: Failed initializing default container.")
        exit(9)
    }
    let returnedSentence = Database.updateDesktop()
    if !returnedSentence.elementsEqual("Update was successful.") {
        print("ERROR: \(returnedSentence)")
        exit(9)
    }
    if !NSSwiftUtils.doesTheFileExist(at: Database.containersPath + "default") {
        print("ERROR: Default space initialization was not successful.")
        exit(9)
    }
    if !Database.addKey(key: "default_setup", data: "done") {
        print("ERROR: Failed writing default container setup key.")
        exit(9)
    }
    print("Default container initialized.")
}

if arguments.count < 2 {
    print("Verbs        Parameters         Descriptions")
    print("list                            List all the available workspace containers")
    print("add          [container name]   Create an empty workspace container")
    print("delete       [container name]   Delete specified workspace container")
    print("sync         [container name]   Sync current desktop content with the specified workspace container")
    print("switch-nsync [container name]   Switch to specified workspace container without syncing")
    print("switch       [container name]   Switch to specified workspace container")
    print("current                         Shows which workspace container is in use")
    print("setroot      [path]             Set container root location to given path (Type default to set to default)")
    print("root                            Shows the root path of library")
    exit(0)
}

if arguments[1].elementsEqual("help") {
    print("Verbs        Parameters         Descriptions")
    print("list                            List all the available workspace containers")
    print("add          [container name]   Create an empty workspace container")
    print("delete       [container name]   Delete specified workspace container")
    print("sync         [container name]   Sync current desktop content with the specified workspace container")
    print("switch-nsync [container name]   Switch to specified workspace container without syncing")
    print("switch       [container name]   Switch to specified workspace container")
    print("current                         Shows which workspace container is in use")
    print("setroot      [path]             Set container root location to given path (Type default to set to default)")
    print("root                            Shows the root path of library")
}else if arguments[1].elementsEqual("list") {
    print("Containers you have: ")
    NSSwiftUtils.executeShellScript("ls", "-1", Database.containersPath)
}else if arguments.count == 3 && arguments[1].elementsEqual("add") {
    print("Adding workspace container: \(arguments[2])")
    if !Database.addContainer(name: arguments[2]) {
        print("You already have a workspace with that name. Please choose another one.")
        exit(9)
    }else{
        print("Workspace container \(arguments[2]) is added.")
    }
}else if arguments.count == 3 && arguments[1].elementsEqual("delete") {
    if arguments[2].elementsEqual("default") {
        print("You are not allowed to delete default workspace.")
        exit(9)
    }else if Database.getData(key: Database.key_selected).elementsEqual(arguments[2]) {
        print("Please select another workspace first, then delete.")
        exit(9)
    }
    print("Deleting workspace container: \(arguments[2])")
    if !Database.removeContainer(name: arguments[2]) {
        print("Failed removing workspace container.")
        exit(9)
    }else{
        print("Workspace container \(arguments[2]) is removed.")
    }
}else if arguments[1].elementsEqual("sync") {
    if arguments.count == 2 {
        let currentWorkspace = Database.getData(key: Database.key_selected)
        print("Syncing workspace container: \(currentWorkspace)")
        if !Database.isContainerAvailable(name: currentWorkspace) {
            print("There is no such workspace container: \(currentWorkspace)")
            exit(9)
        }else{
            let returned = Database.updateDesktop()
            if returned.elementsEqual("Update was successful.") {
                print("Workspace container \(currentWorkspace) is up-to-date.")
            }else{
                print(returned)
                exit(9)
            }
        }
    }else{
        print("Syncing workspace container: \(arguments[2])")
        if !Database.isContainerAvailable(name: arguments[2]) {
            print("There is no such workspace container: \(arguments[2])")
            exit(9)
        }else{
            let originallySelected = Database.getData(key: Database.key_selected)
            if !Database.addKey(key: Database.key_selected, data: arguments[2]) {
                print("Failed setting temporary key for target workspace container.")
                exit(9)
            }
            let returned = Database.updateDesktop()
            if !Database.addKey(key: Database.key_selected, data: originallySelected) {
                print("Failed restoring key for original workspace container.")
                exit(9)
            }
            if returned.elementsEqual("Update was successful.") {
                print("Workspace container \(arguments[2]) is up-to-date.")
            }else{
                print(returned)
                exit(9)
            }
        }
    }
}else if arguments.count == 3 && arguments[1].elementsEqual("switch") || arguments[1].elementsEqual("switch-nsync") {
    print("Switching to workspace container: \(arguments[2])")
    if !Database.isContainerAvailable(name: arguments[2]) {
        print("There is no such workspace container: \(arguments[2])")
        exit(9)
    }else{
        let returned = Database.selectAsDesktop(container: arguments[2], doSync: !arguments[1].elementsEqual("switch-nsync"))
        if returned.elementsEqual("Swap successful.") {
            print("Switched to workspace container: \(arguments[2])")
        }else{
            print(returned)
            exit(9)
        }
    }
}else if arguments[1].elementsEqual("current") {
    print("You are currently using: \(Database.getData(key: Database.key_selected))")
}else if arguments[1].elementsEqual("force-restart") {
    Database.removeKey(key: Database.key_inProcess)
}else if arguments[1].elementsEqual("root") {
    print("Current Root: \(Database.databaseLocation)")
    if Database.databaseLocation.elementsEqual(Database.originalDatabaseLocation) {
        print("(Default)")
    }else{
        print("(Customized)")
    }
}else if arguments.count == 3 && arguments[1].elementsEqual("setroot") {
    var path = arguments[2]
    if !arguments[2].hasSuffix("/") {
        path = arguments[2] + "/"
    }
    
    
    
    if arguments[2].contains("default") {
        print("Resetting root location!")
        path = Database.originalDatabaseLocation
    }
    
    
    if NSSwiftUtils.createDirectoryWithParentsDirectories(to: path) && NSSwiftUtils.doesTheFileExist(at: path) {
        print("Setting root location to: \(path)")
        print("Syncing containers...")
        // SAME COMMAND FROM SYNC
        
        
        let currentWorkspace = Database.getData(key: Database.key_selected)
        if !Database.isContainerAvailable(name: currentWorkspace) {
            print("There is no such workspace container: \(currentWorkspace)")
            exit(9)
        }else{
            let returned = Database.updateDesktop()
            if returned.elementsEqual("Update was successful.") {
                print("Workspace container \(currentWorkspace) is up-to-date.")
            }else{
                print(returned)
                exit(9)
            }
        }
        
        
        
        // END OF SYNC
        if !Database.addKey(key: Database.key_root_emu, data: path) {
            print("Failed to write emulated root configuration.")
            exit(9)
        }
        let originalContainerPath = Database.containersPath
        let originalConfigPath = Database.keydataStore
        let originalLogsPath = Database.logs
        print("Updating inner structure...")
        if !Database._init(forceRoot: Database.originalDatabaseLocation) {
            print("Update failed.")
            exit(9)
        }
        print("Migrating taskspace containers...")
        if (NSSwiftUtils.executeShellScript("cp", "-r", originalContainerPath, Database.containersPath) != 0) {
            print("Taskspace migration failed. Please copy all contents from \(originalContainerPath)   to   \(Database.containersPath)")
            exit(9)
        }
        
        print("Migrating configurations...")
        if (NSSwiftUtils.executeShellScript("cp", "-r", originalConfigPath, Database.keydataStore) != 0) {
            print("Taskspace configurations migration failed. Please copy all contents from \(originalConfigPath)   to   \(Database.keydataStore)")
            exit(9)
        }
        
        print("Migrating logs...")
        if (NSSwiftUtils.executeShellScript("cp", "-r", originalLogsPath, Database.logs) != 0) {
            print("Taskspace configurations migration failed. Please copy all contents from \(originalLogsPath)   to   \(Database.logs)")
            exit(9)
        }
        
        print("Task finished.")
    }else{
        print("Failed to set root location to \(path)")
        exit(9)
    }
}else {
    print("No such verb with matching parameter: \(arguments[1])")
    exit(9)
}

exit(0)
