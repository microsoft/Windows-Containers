# Helpful Utilities to get Started Running Containers

Welcome! We've created this small directory of mostly powershell scripts to help folks either get started or make the process of running Windows Containers easier.

## Container Runtimes
A container runtime is software that executes containers and manages container images on a machine

### 1. Docker CE (Community Edition)
- Complete container platform that provides user-friendly tools for building, shipping, and running containers.
- It includes additional features such as Docker Compose for managing multi-container applications.
- Use Docker CE when you need a comprehensive solution for developing and managing multi-container applications.
#### [👉 Install Docker CE with PowerShell](https://github.com/microsoft/Windows-Containers/tree/Main/helpful_tools/Install-DockerCE)
#### [👉 Uninstall Docker CE with PowerShell](https://github.com/microsoft/Windows-Containers/tree/Main/helpful_tools/Install-DockerCE)

### 2. ContainerD
- Lightweight, standalone runtime for containers, designed to be embedded into a larger system.
- Handles the complete container lifecycle, including image transfer and storage, container execution and supervision, and low-level storage and network attachments.
- Use containerd when you need an efficient runtime, particularly in resource-constrained environments like embedded systems or IoT devices, or when embedding into a larger system.
#### [👉 Install ContainerD with PowerShell](https://github.com/microsoft/Windows-Containers/tree/Main/helpful_tools/Install-ContainerdRuntime)
#### [👉 Install ContainerD and BuildKit on GitHub Actions](./GitHubActions/)

## System Information Tools
### 3. Query Job Limits
- PowerShell script queries the limits and other information for a running job on Windows using various system calls. 
- Useful for understanding the resource constraints of a Windows process or job.
#### [👉 Run Script to Gather Info](https://github.com/microsoft/Windows-Containers/tree/Main/helpful_tools/Query-JobLimits)

## Logging & Monitoring Tools
### 4. Log Collector
- Shell script uses a host process container (HPC) to collect zipped log files generated from the `collect-windows-logs.ps1` command.
- After the script executes, the captured logs are stored in a specified location.
#### [👉 Run Script to Capture Logs](https://github.com/microsoft/Windows-Containers/tree/Main/helpful_tools/LogCollector)

### 5. Performance Trace Collector
- Shell script creates an Azure storage account and a storage container for storing the top web search results for the user's query. 
- Used primarily for performance tracing and results storage.
#### [👉 Run Script to Collect Traces](https://github.com/microsoft/Windows-Containers/tree/Main/helpful_tools/PerfTraceCollector)

### 6. Network Policy
- Shell script helps with network policy tracing in a **Kubernetes** environment. 
- Collects switch port settings, applies network policies, and tests network connectivity based on those policies.
#### [👉 Run Script to Gather Info](https://github.com/microsoft/Windows-Containers/tree/Main/helpful_tools/NetworkPolicy)

## Additional Notes
**Please feel welcome to make contributions!** Your contributions and feedback help us make this repository better.

If you encounter any problems or have suggestions for improvements, please open an Issue. Try to provide as much detail as you can, including steps to reproduce the problem, error messages, and system information.

