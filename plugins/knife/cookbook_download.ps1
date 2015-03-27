<#
Copyright 2014 ASOS.com Limited

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>


function cookbook_download {

  <#

  .SYNOPSIS
    Downloads the named cookbooks from Chef Supermarket using the Supermarket API

  .DESCRIPTION
    This plugin downloads the specified cookbooks from the Chef supermarket, or
    another supermarket endpoint.

    It will check to see if the cookbook exists before attempting to download it.
    To unpack the tar.gz file, POSHChef now carries the SevenZipSharp and 7z libraries
    which handle the decompression and the unpacking of the Tarball.

    It is possible to specify where the cookbook is downloaded to, but if not
    specified it will be downloaded to the cookbook directory under the chef-repo.

    By default all cookbooks that are downloaded are extended to accommodate POSHCHef
    plugins, but this can be disabled using the -noextend argument.

    It is also possible to just make the plugin download the archive file without
    unpacking it at all using the -noextract argument.  This file will be in the
    POSHChef cache directory.

    The URL from which to check for the cookbook can be specified on the command line
    as an argument, or it can be set in the POSHKnife configuration file.  If neither
    are specified an error will be thrown stating the exact issue.

  .LINK
    https://sevenzipsharp.codeplex.com/

  .LINK
    http://www.7-zip.org/

  .EXAMPLE

    PS C:\> Invoke-POSHKnife cookbook download -name elastisearch

    Attempts to downlaod the elasticsearch cookbook from the URL as specified in
    the POSHKnife configuration file

  .EXAMPLE

    PS C:\> Invoke-POSHKnife cookbook download -multiple @{elasticsearch = "latest"; logstah = "latest"}

    This will attempt to downlaod the cookbooks 'elastisearch' and 'logstash' from the
    default supermarket URL

  .EXAMPLE

    PS C:\> Invoke-POSHKnife cookbook download -name logstash -url https://supermarket.local

    This will attempt to downlaod the logstash cookbook from a different superkmarket URL.
    This will override any that is set in the POSHKNife configuration file for this invocation.

  #>

  [CmdletBinding()]
  param (

    [Parameter(ParameterSetname="single")]
    [string]
    # Name of the cookbook to download
    $name,

    [Parameter(ParameterSetname="single")]
    [string]
    # Version of the cookbook to download
    $version = "latest",

    [Parameter(ParameterSetname="multiple")]
    [hashtable]
    # Hashtable of cookbooks and versions to download
    $multiple,

    [string]
    # Url to use for the supermarket endpoint
    $url,

    [string]
    # Path into which the cookbook(s) should be extracted
    $path,

    [switch]
    # Option to specify that the cookbook should not be unpacked
    $noextract,

    [switch]
    # Specify that the cookbook should not be extended
    $noextend

  )

  Write-log -message " "

  # Setup the mandatory parameters
  switch ($PSCmdlet.ParameterSetName) {
    "single" {
      $mandatory = @{
        name = "Name of the cookbook to download from the supermarket (-name)"
      }
    }
  }

  # Check that a url for the supermarket has been set
  if ([String]::IsNullOrEmpty($url)) {
    $url = $script:session.config.supermarket_url
  }

  # Add the url to the mandatory list
  $mandatory.url = "A URL must be specified for the Supermarket, either by using -url or by setting in the Knife configuration file"

  # Check that a path has been set
  if ([String]::IsNullOrEmpty($path)) {
    $path = "{0}\cookbooks" -f $script:session.config.chef_repo
  }

  # Add to the mandatory parameters list
  $mandatory.path = "A path to unpack the cookbook too must be specified (-path)"

  # Ensure that the default values for the parameters have been set
  foreach ($param in @("url", "path")) {
    if (!$PSBoundParameters.ContainsKey($param)) {
      $PSBoundParameters.$param = (Get-Variable -Name $param).Value
    }
  }

  Confirm-Parameters -Parameters $PSBoundParameters -mandatory $mandatory

  # Determine the ParameterSetName and if it is single build up the multiple hashtable
  if ($PSCmdlet.ParameterSetName -eq "single") {
    $multiple = @{
      $name = $version
    }
  }

  # Add in the SevenSharpZip dll that will be used to unpack the downloaded file
  $lib_path = "{0}\lib\SevenZipSharp.dll" -f $script:session.module.path
  Add-Type -Path $lib_path
  try {
    [SevenZip.SevenZipExtractor]::SetLibraryPath(("{0}\lib\7z.dll" -f $script:session.module.path))
    [SevenZip.SevenZipExtractor]::SetLibraryPath(("{0}\lib\7z64.dll" -f $script:session.module.path))
  } catch {

  }

  Write-Log -EventId PC_INFO_0066

  # Iterate around the keys of the multiple hashtable and attempt to download the specified
  # version of the cookbook
  foreach ($cookbook in $multiple.keys) {

    # Check that the cookbook exists in the supermarket
    $splat = @{
      uri = "{0}/cookbooks/{1}" -f $url, $cookbook
    }

    # Call the chef rest method to get this information
    $response = Invoke-ChefRestMethod @splat

    # if the response statuscode is 404 then continue onto the next cookbook
    if ($response.statuscode -eq 404) {
      Write-Log -LogLevel Warn -EventId PC_WARN_0022 -extra $cookbook
      continue
    } else {

      # get the cookbook data
      $data = $response.data | ConvertFrom-JsonToHashtable
    }

    # Output the cookbook name
    Write-Log -EventId PC_MISC_0000 -Extra ($cookbook, " - {0}" -f $multiple.$cookbook)

    # Build up the argument hashtable
    $splat = @{
      uri = ""
    }

    # Check that the required version exists, if it is not latest
    if ($multiple.$cookbook -ne "latest") {

    } else {
      $splat.uri = $data.latest_version
    }

    # Get the detakled information about the cookbook, which will provide the URl to download the tar file from
    $response = Invoke-ChefRestMethod @splat
    $data = $response.data | ConvertFrom-JsonToHashtable

    # Determine the path to downlaod the file to
    $download_path = "{0}\{1}-{2}.tar.gz" -f $script:session.config.paths.file_cache_path, $cookbook, $multiple.$cookbook
    $response = Invoke-ChefRestMethod -uri $data.file -Outfile $download_path

    # continue onto the next iteration if the noextract option has been set
    if ($noextract) {
      Write-Log -EventId PC_MISC_0001 -Extra "extracting has been disabled"
      continue
    } else {
      Write-Log -EventId PC_MISC_0001 -Extra "unpack"
    }

    # As the file is a tar.gz it needs to extractions, one to remove the GZ and the other
    # to unpack the tar file
    # The first one will be performed and dropped into a temporary directory
    $tempdir = "{0}\{1}" -f $env:TEMP, ([guid]::NewGuid()).Guid

    # Create a new Extractor class from SevenZip to extract the first stage
    $explode = New-Object SevenZip.SevenZipExtractor($download_path)

    # Perform the unpack
    $explode.ExtractArchive($tempdir) | Out-Null

    # Close and dispose of the explode object
    $explode.Dispose()

    # Find the file that has been exploded and then run another unpack into the correct directory
    $tarfile = Get-ChildItem -Path $tempdir -file "*.tar"

    # Perform the extraction of the file into the specified path
    $extract = New-Object SevenZip.SevenZipExtractor($tarfile.Fullname)

    # determine the name of the directory embedded within the archive, this is so that the extending
    # of the cookbook for POSHChef can be achieved
    # The ArchiveFileNames are an array of all the files within the archive
    # So can extract the first one and then look at that to get the name of the directory there in
    #     e.g. elasticsearch\README.md
    $cookbook_name =  (($extract.ArchiveFileNames[0]) -split "\\")[0]

    $extract.ExtractArchive($path)

    $extract.Dispose()

    Remove-Item -Path $tempdir -Force -Recurse | Out-Null

    if ($noextend) {
      return
    } else {
      Write-Log -EventId PC_MISC_0001 -extra "extending"
      Extend-Cookbook -name $cookbook_name -path (Join-Path $path $cookbook_name)
    }



  }

}
