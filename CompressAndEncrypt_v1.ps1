# Author: Paul John Figueroa
# Systems Administrator @ GRBP.
# Date: August 8, 2023
# Version 1.0

# INSTRUCTIONS
# Set the script parameters
# Add this script to Task Schedule
# Schedule it to run after the SQL backup schedule

<# 
# Example: Powershell and Task Scheduler
# .\CompressAndEncrypt_v1.ps1 -SourceDir 'C:\DATA\GRBP 2023\PROJECTS\Automation Projects\Tests\test_files\' -EncFileDestDir 'C:\DATA\iDRIVE\' -origFileNewDirPath 'C:\DATA\GRBP 2023\PROJECTS\Automation Projects\Tests\test_files\' -origFileNewDirName 'origx_files' -fileExtension 'mp3' -logFile './log_file.txt' -logFileDuplicate './log_file_duplicate.txt'
#>

# This will do the following
# Get Hash (Sha256)
# Generate Password
# Encrypt with password and Key file

# ------------------------------------------------------------------------------------------------------------
# command line parameters
Param(
    
    # Default parameter values

    # The directory/folder where the files to be processed are located.
    $SourceDir = "C:\DATA\GRBP 2023\PROJECTS\Automation Projects\Tests\test_files\",
    # The directory where the processed files will be saved.
    $EncFileDestDir = "C:\DATA\iDRIVE\",
    # The directory where the new directory for the processed original (unprocessed) files will be created.
    $origFileNewDirPath = "C:\DATA\GRBP 2023\PROJECTS\Automation Projects\Tests\test_files\",
    # The actual directory where the original (unprocessed) files will be transferred to after processing.
    $origFileNewDirName = "orig_files",
    # The file extension of siles that will be processed.
    $fileExtension = "mp3",
    # The log file
    $logFile = "./encryption_log.txt",
    $logFileDuplicate = "./encryption_log_duplicate.txt"

)

# ------------------------------------------------------------------------------------------------------------
# Password Generator
function GenPwd {
    param (
        [Parameter(Mandatory)]
        [int] $length,
        [int] $amountOfNonAlphanumeric = 1
    )
    Add-Type -AssemblyName 'System.Web'
    return [System.Web.Security.Membership]::GeneratePassword($length, $amountOfNonAlphanumeric)
}

# ------------------------------------------------------------------------------------------------------------
# Check if the log file already exists
if (-Not(Test-Path -Path $logFile)) {
    # Log File Header
    "Date" + "`t" + "File Path" + "`t" + "SHA256(HASH)" + "`t" + "File Size" + "`t" + "Password" + "`t" + "Remarks" | Out-File -FilePath $logFile -Append
}

# Check if the duplicate log file already exists
if (-Not(Test-Path -Path $logFileDuplicate)) {
    # Log File Header
    "Date" + "`t" + "File Path" + "`t" + "SHA256(HASH)" + "`t" + "File Size" + "`t" + "Password" + "`t" + "Remarks" | Out-File -FilePath $logFileDuplicate -Append
}

# ------------------------------------------------------------------------------------------------------------
# create orig file's new directory
if (-Not(Test-Path -Path "$($origFileNewDirPath)$($origFileNewDirName)")) {
    New-Item -Path $origFileNewDirPath -Name $origFileNewDirName -ItemType "directory"  
}
$origFileNewLocation = "$($origFileNewDirPath)$($origFileNewDirName)"


# ------------------------------------------------------------------------------------------------------------
# Process all files in a directory (non-recursive)
foreach ($file in Get-ChildItem $SourceDir) {
    
    $fileName = [System.IO.Path]::GetFileName($file)

    if ($file.Attributes -ne "Directory" -and $fileName -like "*.$($fileExtension)") {
        # Current Date
        $date = Get-Date -format "yyyy-MM-dd-hh-mm-ss"
        # Generate a password for each file
        $passwd = GenPwd 40
        # Get file size in MB
        $fileSize = (Get-Item -Path $file.FullName).Length / 1MB
        # Get the hash file using SHA256                                 
        # $fileHash = Get-FileHash $file.FullName | 
        # For powershell version lower than 5.1, get the file hash using certutil
        $fileHash = certutil -hashfile $file.FullName SHA256 | findstr /v "hash"

        # Piped from preceeding line. Extract only the Hash value
        ForEach-Object -MemberName Hash  
        
        $remarks = "Failed"

        # Run PeaZip, encrypt file using the password and key file 
        # (DANGER: DO NOT TOUCH OR MODIFY)
        $compressFile = & "C:\Program Files\PeaZip\res\bin\7z\7z.exe" a -t7z -m0=LZMA2 -mmt=on -mx3 -md=4m -mfb=32 -ms=1g -mqs=on -sccUTF-8 "-pEAmtJdpYLoSwcgOunO3f3XueowVRzS+zb1x25vfMiSE=$($passwd)" -bb0 -bse0 -bsp2 "-w$($SourceDir)\" -mtc=on -mta=on "$($EncFileDestDir)\$($file)-enc.7z" $file.FullName 

        # Check if successful
        if ($null -ne $compressFile) {
            # Write-Host "Success"
            $remarks = "Success"
            
            # Append to log file
            $date + "`t" + $file.FullName + "`t" + $fileHash + "`t" + [math]::Round($fileSize, 2) + "`t" + $passwd + "`t" + $remarks | Out-File -FilePath $logFile -Append 
            
            # Append to duplicate log file
            $date + "`t" + $file.FullName + "`t" + $fileHash + "`t" + [math]::Round($fileSize, 2) + "`t" + $passwd + "`t" + $remarks | Out-File -FilePath $logFileDuplicate -Append 
            
            # move original file to the new location
            Move-Item -Path $file.FullName -Destination "$($origFileNewLocation)/$($fileName)" 
            
            Write-Host  $remarks "-->" $fileName
        }

    }

    else {
        # Invalid file formats or extensions
        Write-Host "Skipped --> File < $($fileName) > is NOT a valid file or directory."
    }
}
# ------------------------------------------------------------------------------------------------------------

exit
# End
# ------------------------------------------------------------------------------------------------------------