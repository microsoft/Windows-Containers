############################################################
# Script to query the job limits inside a process-isolated container
############################################################
<#
    .NOTES
        Copyright (c) Microsoft Corporation.  All rights reserved.

        Use of this sample source code is subject to the terms of the Microsoft
        license agreement under which you licensed this sample source code. If
        you did not accept the terms of the license agreement, you are not
        authorized to use this sample source code. For the terms of the license,
        please see the license agreement between you and Microsoft or, if applicable,
        see the LICENSE.RTF on your install media or the root of your tools installation.
        THE SAMPLE SOURCE CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.

    .SYNOPSIS
        Queries the job limits from inside a process-isolated container

    .DESCRIPTION
        Queries the job limits from inside a process-isolated container

    .PARAMETER Verbose 
        If passed, dump verbose output
        
    .EXAMPLE
        .\Query-JobLimits.ps1
#>
#Requires -Version 5.0

[CmdletBinding(DefaultParameterSetName="Standard")]
param(
    [Parameter(Mandatory=$True)]
    [ValidateSet("JobMemoryLimit", "PeakJobMemoryUsed")]
    [string]$LimitType
)

Add-Type @"

    using System;
    using System.ComponentModel;
    using System.Text;
    using System.Runtime.InteropServices;

    public class Api
    {
        public enum JOBOBJECTINFOCLASS
        {
            JobObjectBasicAccountingInformation = 1,
            JobObjectBasicLimitInformation,
            JobObjectBasicProcessIdList,
            JobObjectBasicUIRestrictions,
            JobObjectSecurityLimitInformation,
            JobObjectEndOfJobTimeInformation,
            JobObjectAssociateCompletionPortInformation,
            JobObjectBasicAndIoAccountingInformation,
            JobObjectExtendedLimitInformation,
            JobObjectJobSetInformation,
            MaxJobObjectInfoClass,
        }
        
        //
        // Basic Limits
        //
        public const UInt32 JOB_OBJECT_LIMIT_WORKINGSET = 0x00000001;
        public const UInt32 JOB_OBJECT_LIMIT_PROCESS_TIME = 0x00000002;
        public const UInt32 JOB_OBJECT_LIMIT_JOB_TIME = 0x00000004;
        public const UInt32 JOB_OBJECT_LIMIT_ACTIVE_PROCESS = 0x00000008;
        public const UInt32 JOB_OBJECT_LIMIT_AFFINITY = 0x00000010;
        public const UInt32 JOB_OBJECT_LIMIT_PRIORITY_CLASS = 0x00000020;
        public const UInt32 JOB_OBJECT_LIMIT_PRESERVE_JOB_TIME = 0x00000040;
        public const UInt32 JOB_OBJECT_LIMIT_SCHEDULING_CLASS = 0x00000080;

        //
        // Extended Limits
        //
        public const UInt32 JOB_OBJECT_LIMIT_PROCESS_MEMORY = 0x00000100;
        public const UInt32 JOB_OBJECT_LIMIT_JOB_MEMORY = 0x00000200;
        public const UInt32 JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION = 0x00000400;
        public const UInt32 JOB_OBJECT_LIMIT_BREAKAWAY_OK = 0x00000800;
        public const UInt32 JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK = 0x00001000;
        public const UInt32 JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x00002000;

        [StructLayout(LayoutKind.Sequential)]
        public struct JOBOBJECT_BASIC_LIMIT_INFORMATION
        {
            public UInt64 PerProcessUserTimeLimit;
            public UInt64 PerJobUserTimeLimit;
            public UInt32 LimitFlags;
            public UIntPtr MinimumWorkingSetSize;
            public UIntPtr MaximumWorkingSetSize;
            public UInt32 ActiveProcessLimit;
            public UIntPtr Affinity;
            public UInt32 PriorityClass;
            public UInt32 SchedulingClass;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct IO_COUNTERS
        {
            public UInt64 ReadOperationCount;
            public UInt64 WriteOperationCount;
            public UInt64 OtherOperationCount;
            public UInt64 ReadTransferCount;
            public UInt64 WriteTransferCount;
            public UInt64 OtherTransferCount;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION
        {
            public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
            public IO_COUNTERS IoInfo;
            public UIntPtr ProcessMemoryLimit;
            public UIntPtr JobMemoryLimit;
            public UIntPtr PeakProcessMemoryUsed;
            public UIntPtr PeakJobMemoryUsed;
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, EntryPoint = "QueryInformationJobObject", SetLastError = true)]
        public static extern bool QueryInformationJobObject(
           IntPtr handleJob,
           JOBOBJECTINFOCLASS jobObjectInfoClass,
		   IntPtr lpJobObjectInfo,
           UInt32 jobObjectInfoLength,
           ref UInt32 returnLength
           );

        // Query the extended limit information for the running job
        // If this is run outside of an executing job, or if the memory limit is not set,
        // the script will return zero.
        public static JOBOBJECT_EXTENDED_LIMIT_INFORMATION QueryExtendedLimitInformation()
        {
            // Allocate an JOBOBJECT_EXTENDED_LIMIT_INFORMATION
            int inSize = Marshal.SizeOf(typeof(Api.JOBOBJECT_EXTENDED_LIMIT_INFORMATION));
            IntPtr ptrData = IntPtr.Zero;
            try
            {
                // Marshal.AllocHGlobal will throw on failure, so we do not need to
                // check for allocation failure.
			    ptrData = Marshal.AllocHGlobal( inSize );
                UInt32 outSize = 0;

                // Query the job object for its extended limits
                bool result = Api.QueryInformationJobObject(IntPtr.Zero,
                    Api.JOBOBJECTINFOCLASS.JobObjectExtendedLimitInformation,
                    ptrData,
                    (UInt32)inSize,
                    ref outSize);
                if (result)
                {
                    // Marshal the result data into a .NET structure
                    Api.JOBOBJECT_EXTENDED_LIMIT_INFORMATION jobinfo =
                      (Api.JOBOBJECT_EXTENDED_LIMIT_INFORMATION)Marshal.PtrToStructure(ptrData, typeof(Api.JOBOBJECT_EXTENDED_LIMIT_INFORMATION));

                    // Return the extended limit information to the caller
                    return jobinfo;
                }
                else
                {
                    throw new Win32Exception(Marshal.GetLastWin32Error());
                }
             }
             finally
             {
                 if (ptrData != IntPtr.Zero)
                 {
                    Marshal.FreeHGlobal( ptrData );	
                 }
             }
        }
    }

"@

$result = [Api]::QueryExtendedLimitInformation()

switch ($LimitType) {
    "JobMemoryLimit" {
        $result.JobMemoryLimit
    }

    "PeakJobMemoryUsed" {
        $result.PeakJobMemoryUsed
    }

    Default {
        Write-Error "Limit type unknown: $LimitType"
    }
}
