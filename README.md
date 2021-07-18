# taskspace-bin
 Manage your Mac Desktop as a container!


**PLEASE USE RELEASE VERSION**
The taskspace library migration is not supported in the release version, but the code is available. However, the migration code is too unstable, therefore you have a chance of loosing your data. Please use the release version which is more stable.



**WARNING: If you are using iCloud Desktop & Document sync, you may use excessive network transmission. Unless you don't have limit & have small files in your desktop directory or don't care the excessive use of network transmission, please do not use this software. Also, you are not recommended if you work on large files / too many small files on your desktop. Swapping large or numerous files takes long time, and consumes SSD lifespan. I am not responsible for any side effects coming from this sowftware.**



### Basic Descriptions

1. This software holds the desktop files as a container.
2. The container is stored in ~/Library/TaskSpace/containers/
3. You may switch the desktop files as you want.



### Available Commands:

- list: List all the available workspace containers
- add [container name]: Create an empty workspace container
- delete [container name]: Delete specified workspace container
- sync [container name]: Sync current desktop content with the specified workspace container
- switch-nsync [container name]: Switch to specified workspace container without syncing
- switch [container name]: Switch to specified workspace container
- current: Shows which workspace container is in use
