POSHChef
========

## Overview

POSHChef has been built as a native chef client on Windows using PowerShell.  Although support for Windows platforms in Chef is continually expanding the way it is implemented means that developers and system administrators need to understand Ruby in order to correctly write recipes and cookbooks.  In addition it is not easy to test any PowerShell code that has been written as it is passed to a Chef recource, which is running under Ruby, and then it is executed using a call to 'powershell.exe'.

So POSHChef was developed.  It had 3 main goals:

 - Must be interoperable with Chef and community cookbooks
 - Use PowerShell as the main language so that testing can be achieved through tools such as Pester
 - Utilise Microsoft Desired State Configuration (DSC) to configure machines

POSHChef is installed as a module and has a depdendency on another module called 'Logging'.  This latter module is used to log messages to different providers (such as Screen, Log Files, Event Viewer).

## Installation

This is to be deployed as a module.  Copy the contents of the repository to the following location:

    C:\Windows\System32\WindowsPowerShell\v1.0\Modules\POSHChef

Note:  This is currently the location for the module, but it may change in the future to fit in with the additional module locations that Microsoft Provides in Windows.

## More Information

Please refer to the [Wiki](http://github.com/POSHChef/POSHChef/wiki) for more detailed installation information and further information.

## Acknowledgements

This project makes use of the following open source projects:

- [7-Zip](http://www.7-zip.org/)
- [BouncyCastle](http://www.bouncycastle.org/csharp/)
