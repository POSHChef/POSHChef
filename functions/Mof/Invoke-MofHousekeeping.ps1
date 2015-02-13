
function Invoke-MofHousekeeping {

  <#

  .SYNOPSIS
    Ensures that existing MOF files are deleted or removed

  .DESCRIPTION
    It is possible for POSHChef to keep an archive of previously generated MOF files
    If this is has not been set in the configuration file for POSHChef then the
    old MOF files are just removed.

    No parameters are required for this function as all the information is in the session configuration

  #>

  # If in debug mode, show the function currently in
  Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

  Write-Log -Message " "
  Write-Log -EVentId PC_INFO_0062

  # Check to see if the MOF files should be archive or not
  if ($script:session.config.mof.archive) {

    Write-Log -EventId PC_MISC_0001 -extra ("Archiving last MOF file, keeping {0} in history" -f $script:session.config.mof.keep)

    # Get a timestamp of now to apply to the file
    $timestamp = Get-Date -uformat "%Y%m%d_%H%M%S"

    # Get a list of the files that are in the MOF file so that they can be copied
    # with a timestamp
    $files = Get-ChildItem -Path $script:session.config.paths.mof_file_path

    # Iterate around the files and move them to the archive directory
    foreach ($file in $files) {

      # Get the file name of the file without the extension
      # this is so that the timestamp can be added to it
      $filename = [System.IO.Path]::GetFileNameWithoutExtension($file.name)
      $filename = "{0}.{1}.mof" -f $filename, $timestamp

      # Build up the path to the destination
      $destination = "{0}\{1}" -f $script:session.config.paths.mof_file_archive_path, $filename

      # Build up the hashtable of arguments
      $splat = @{
        path = $file.fullname
        destination = $destination
      }

      Move-Item @splat
    }

    # Now ensure that there is only the specified number of files in the archive path
    Get-ChildItem -Path $script:session.config.paths.mof_file_archive_path | Sort-Object CreationTime -Descending | Select-Object -Skip $script:session.config.mof.keep | Remove-Item -Force

  } else {

    Write-Log -EventId PC_MISC_0001 -extra "Removing last MOF file"

    # Ensure that existing MOF files are cleared out from the MOF file path
    Remove-Item -Path $script:session.config.paths.mof_file_path -Include "*.mof" -Force -Recurse | Out-Null

  }

}
