# KubeCon 2023 Demo Bash Shell Scripts

These are the demo bash shell scripts presented in KubeCon 2023. For more information about this talk, visit: https://kccnceu2023.sched.com/event/1HyaA/making-legacy-modern-how-to-monitor-and-fine-tune-the-performance-of-your-windows-clusters-brandon-smith-howard-hao-microsoft

You can also view the talk on YouTube: https://www.youtube.com/watch?v=l5yWjocVOmY

This folder contains bash shell scripts that were tested in a WSL environment running on Windows 11:
1. `createcluster.sh`: creates an AKS cluster in Azure.
2. `createstorage.sh`: creates a storage account in Azure.
3. `downloadinstallazcopy.sh`: installs azcopy.exe to the target AKS node and azcopy to WSL.
4. `collecttraces.sh`: collects ETW traces for a customer scenario.

**Contributions are welcome!**