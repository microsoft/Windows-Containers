# KubeCon 2023 Demo Bash Shell Scripts

These are the demo bash shell scripts presented in KubeCon 2023. For more information about this talk, visit: https://kccnceu2023.sched.com/event/1HyaA/making-legacy-modern-how-to-monitor-and-fine-tune-the-performance-of-your-windows-clusters-brandon-smith-howard-hao-microsoft

You can also view the talk on YouTube: https://www.youtube.com/watch?v=l5yWjocVOmY

This folder contains bash shell scripts that were tested in a WSL environment running on Windows 11. The scripts include:

1. collectlog.ps1: A PowerShell script that calls c:\k\debug\collect-windows-logs.ps1 and copies the output zip file to d:\perf\latestdebuglog.zip.
2. collectlogs.sh: A script that performs the following actions:
    1). Creates a host process container.
    2).Calls collectlog.ps1.
    3).Uploads d:\perf\latestdebuglog.zip to Azure storage using Azcopy.exe.
    4). Downloads latestdebuglog.zip from Azure storage to the collectlogs.sh folder under .\results\latestdebuglog.zip.

The purpose of these scripts is to reduce the manual steps involved in the investigation log collection process. To run the script, simply execute the following command in your WSL windows: bash -x collectlogs.sh. Please make sure that collectlog.ps1 is also located in the same folder as collectlogs.sh.

**Contributions are welcome!**