#====================================================================================#
# Written By: Christopher Roelle                                                     #
# Date: 02-22-2023                                                                   #
# Name: File Pair Pre-Processor V2                                                   #
# Purpose: Ensures that file pairs exists for WFs that use file pairs.               #
#====================================================================================#

clear

#Paths used. pickupPath is where the files are grabbed. dropOffPath is where the files are moved for processing.
$pickupPath = 'WhereAmIPickingUpTheFiles'
$dropOffPath = 'WhereAmIDroppingOffTheFilesWhenIEnsureBothExist'

#Backup files to the backupFolder. 1 -yes, 0 -no
$copyToBackupFolder = 1

#Path used for backup location.
$backupFolder = 'WhereDoYouWantThePreProcessedFilesBackedUp'

#Make sure there is a '.' before ext type
$fileExt1 = '.txt'
$fileExt2 = '.zip'

#Once matches are found, waits this long before transfer to ensure that the files are unlocked.
$waitInSeconds = 1


#======End Config======#
#===Begin Processing===#

#Add slashes to the end of the paths.
$pickupPath += '\'
$dropOffPath += '\'

#Make sure the pickup path exists.
if(test-path -Path $pickupPath)
{
    Write-Output($pickupPath + ' is a valid path.')

    #How many files
    $numOfFiles = ((Get-ChildItem -Path $pickupPath -File | Measure-Object).count).toString()

    if($numOfFiles -gt 0)
    {
        Write-Output($numOfFiles + ' file(s) found.')

        #Since the drop path has files. Make sure the drop path exists, otherwise, exit /w error.
        if(test-path -Path $dropOffPath)
        {
            Write-Output($dropOffPath + ' is a valid path.')
            Write-Output('')
        }
        else
        {
            Write-Output($dropOffPath + ' is NOT a valid path.')
            exit 1
        }

        #Continue...

        $filter = '*' + $fileExt1

        #Get all of the files with fileExt1
        Get-ChildItem -Path $pickupPath -Filter $filter |
        ForEach-Object {

            Write-Output($_.Name + ' found.')

            #Get first fileName and the matching file name
            $file1 = $pickupPath + $_.baseName + $fileExt1
            $file2 = $pickupPath + $_.baseName + $fileExt2

            #See if matching file exists.
            if(test-path -Path $file2 -PathType Leaf)
            {
                write-output($file2 + ' found.')

                #Both files exist, wait 'x' seconds to ensure both files are released.
                Write-Output('Waiting ' + $waitInSeconds + ' seconds before moving pair.')
                start-sleep -Seconds $waitInSeconds
                Write-Output('Wait complete.')

                #Move the pair to drop-Off location.
                Write-Output('Moving pair of files...')
                if($copyToBackupFolder)
                {
                    if(test-path -path $backupFolder){
                        Write-Output('Copying to backup folder.')
                        Copy-Item -Path $file1 -Destination $backupFolder
                        Copy-Item -Path $file2 -Destination $backupFolder
                    }
                    else #JobProc Folder doesnt exist, fail.
                    {
                        Write-Output($backupFolder + ' does NOT exist!')
                        exit 1
                    }
                }

                Write-Output('Moving ' + $_.baseName + $fileExt1 + ' to drop-off.')
                Move-Item -Path $file1 -Destination $dropOffPath

                Write-Output('Moving ' + $_.baseName + $fileExt2 + ' to drop-off.')
                Move-Item -Path $file2 -Destination $dropOffPath

                Write-Output('Pair moved.')
                Write-Output('')


            }
            else #Match doesnt exist... No error, notifier will send something to client.
            {
                write-output($_.baseName + $fileExt2 + ' NOT found.')
            }
        }
    }
    else #No files, end processing.
    {
        Write-Output('No files found, exiting.')
    }
}
else #Client Drop Path doesnt exist. Exit with error.
{
    Write-Output($pickupPath + ' is NOT a valid path.')
    exit 1
}
