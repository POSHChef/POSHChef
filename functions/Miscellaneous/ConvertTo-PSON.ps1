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

function ConvertTo-PSON {

  <#

  .SYNOPSIS
    Convert a Hashtable into a string so that it can be written to a file

  .DESCRIPTION
    This functions takes an input object and converts it to a format that can be written out to disk.  This assists
    in the creation of configuration files for example.

    The output is similar to JSON but it is PowerShell Object Notification

  .LINKS
    http://stackoverflow.com/questions/15139552/save-hash-table-in-powershell-object-notation-pson

  #>

  [CmdletBinding()]
  param (

    [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
    [AllowNull()]
    # Object to convert to PSON format
    $Object,

    [Int]
    # Depth at which the PSON should be written to
    # Analogous to the ConvertTo-JSON depth argument
    $Depth = 9,

    [Int]
    # Determines the layout of the PSON in the strng
    # 0 - One line withouth any spaces (compressed mode)
    # 1 - One line formatted with spaces (default)
    # X - Multuple layers are expsnded over multiple lines until a depth of X levels (indents)
    $Layers = 1,

    [Switch]
    # add DataType hints to the PSON so that when it is read back in the types
    # are explicit
    $Strict,

    [Version]
    # PowerShell 2.0 does not except the [PSCustomObject] type which will be replace with
    # New-Object PSObject –Property when ran PowerShell 2.0, if you like to interchange data
    # from a higher version of PowerShell with PowerShell 2.0 you can use the –Version 2.0 option.
    $Version = $PSVersionTable.PSVersion

  )

  # If in debug mode, show the function currently in
  Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

  $Format = $Null

  $Quote = If ($Depth -le 0) {""} Else {""""}

  $Space = If ($Layers -le 0) {""} Else {" "}

  If ($Object -eq $Null) {"`$Null"} Else {
    $Type = "[" + $Object.GetType().Name + "]"
    $PSON = If ($Object -is "Array") {
      $Format = "@(", ",$Space", ")"
      If ($Depth -gt 1) {
        For ($i = 0; $i -lt $Object.Count; $i++) {
          ConvertTo-PSON -Object $Object[$i] -Depth ($Depth - 1) -Layers ($Layers - 1) -Strict:$Strict
        }
      }

    } ElseIf ($Object -is "Xml") {
        $Type = "[Xml]"
        $String = New-Object System.IO.StringWriter
        $Object.Save($String)
        $Xml = "'" + ([String]$String).Replace("`'", "&apos;") + "'"

        If ($Layers -le 0) {
          ($Xml -Replace "\r\n\s*", "") -Replace "\s+", " "
        } ElseIf ($Layers -eq 1) {
          $Xml
        } Else {
          $Xml.Replace("`r`n", "`r`n`t")
        }

        $String.Dispose()

    } ElseIf ($Object -is "DateTime") {
      "$Quote$($Object.ToString('s'))$Quote"

    } ElseIf ($Object -is "String") {

      0..11 | ForEach {
        $Object = $Object.Replace([String]"```'""`0`a`b`f`n`r`t`v`$"[$_], ('`' + '`''"0abfnrtv$'[$_]))
      }; "$Quote$Object$Quote"

    } ElseIf ($Object -is "Boolean") {
      If ($Object) {
        "`$True"
      } Else {
        "`$False"
      }
    } ElseIf ($Object -is "Char") {
      If ($Strict) {
        [Int]$Object
      } Else {
        "$Quote$Object$Quote"
      }
    } ElseIf ($Object -is "ValueType") {
      $Object
    } ElseIf ($Object.Keys -ne $Null) {
      If ($Type -eq "[OrderedDictionary]") {
        $Type = "[Ordered]"
      }
      $Format = "@{", ";$Space", "}"
      If ($Depth -gt 1) {
        $Object.GetEnumerator() | ForEach {
          $_.Name + "$Space=$Space" + (ConvertTo-PSON -Object $_.Value -Depth ($Depth - 1) -Layers ($Layers - 1) -Strict:$Strict)
        }
      }
    } ElseIf ($Object -is "Object") {
      If ($Version -le [Version]"2.0") {
        $Type = "New-Object PSObject -Property "
      }
      $Format = "@{", ";$Space", "}"
      If ($Depth -gt 1) {
        $Object.PSObject.Properties | ForEach {
          $_.Name + "$Space=$Space" + (ConvertTo-PSON -Object $_.Value -Depth ($Depth - 1) -Layers ($Layers - 1) -Strict:$Strict)
        }
      }
    } Else {$Object}
      If ($Format) {
        $PSON = $Format[0] + (&{
          If (($Layers -le 1) -or ($PSON.Count -le 0)) {
            $PSON -Join $Format[1]
          } Else {
            ("`r`n" + ($PSON -Join "$($Format[1])`r`n")).Replace("`r`n", "`r`n`t") + "`r`n"
          }
        }) + $Format[2]
      }
        If ($Strict) {"$Type$PSON"} Else {"$PSON"}
    }
  }
