
Invoke-Expression "c:\k\debug\collect-windows-logs.ps1"
$latestZipFile = Get-ChildItem -Path "C:" -Filter *.zip -Recurse | Sort-Object CreationTime -Descending | Select-Object -First 1
Copy-Item $latestZipFile.FullName d:\perf\latestdebuglog.zip


