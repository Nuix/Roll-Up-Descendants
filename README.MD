
Roll Up Descendants
================

![Last tested in Nuix 7.4](https://img.shields.io/badge/Nuix-7.4-green.svg)

View the GitHub project [here](https://github.com/Nuix/Roll-Up-Descendants) or download the latest release [here](https://github.com/Nuix/Roll-Up-Descendants/releases).

# Overview

**Written By:** Jason Wells

# Overview

Similar to (not exactly the same as) the processing setting `Hide immaterial items (text rolled up to parent)` this script is able to take the text of descendants items and append them to the selected ancestor item.  Items which are rolled up in this way can then be excluded, tagged or deleted by the script depending on settings.

# Getting Started

## Setup

Begin by downloading the latest release.  Extract the contents of the archive into your Nuix scripts directory.  In Windows the script directory is likely going to be either of the following:

- `%appdata%\Nuix\Scripts` - User level script directory
- `%programdata%\Nuix\Scripts` - System level script directory

## Settings

| Setting | Description |
|---------|-------------|
| **Text Separator** | Determines what text (if any) will be used to separate the descendant text appended to the ancestor item.  Supports `\n` for newlines (and `\r\n`) and `\t` for tab as well as any other text you wish to include. |
| **Don't Append Empty Text from Descendants** | When checked the script will not append descendant text which is empty or contains only whitespace characters. |
| **Only Roll Up Immaterial Children and Their Descendants** | When checked, rolled up descendants will be located by getting the immaterial children of a selected ancestor item and their descendants.  When not checked ALL descendants of each selected ancestor item will be rolled up. |
| **Backup Selected Item Text** | When checked, the text of each selected item will be backed up into the specified directory. |
| **Text Backup Directory** | When **Backup Selected Item Text** is checked, this setting determines the root directory to which the text will be backed up to. |
| **Exclude Rolled Up Descendants** | When selected, items which are rolled up will be excluded afterwards. |
| **Exclusion Name** | When **Exclude Rolled Up Descendants** is selected, this setting determines the name of the exclusion rolled up items will be added to. |
| **Tag Rolled Up Descendants** | When selected, items which are rolled up will be tagged afterwards. |
| **Tag Name** | When **Tag Rolled Up Descendants** is selected, this setting determines the name of the tag to be applied. |
| **Delete Rolled Up Descendants** | When selected, items which are rolled up will be deleted from the case afterwards! |

## Additional Notes

### Aborting
This script supports aborting early.  When aborting the script will process no further work, but anything that has already been done remains (nothing is reverted back).

### File System Stored Text
When Nuix is started with arguments along the lines of:
```
-Dnuix.storage.stores.useFileSystemTextStore=true
-Dnuix.storage.stores.fileSystemTextStoreLocation="c:\temp\FSTextStore"
```

The item text stored on the file system will be updated along with the text of the item if Nuix reports that the item is stored and returns a path to the text on the file system (see [Text.isStored](https://download.nuix.com/releases/desktop/stable/docs/en/scripting/api/nuix/Text.html#isStored--) and [Text.getStoredPath](https://download.nuix.com/releases/desktop/stable/docs/en/scripting/api/nuix/Text.html#getStoredPath--)).

# License

```
Copyright 2018 Nuix

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
