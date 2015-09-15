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

function Expand-Template {

    [CmdletBinding()]
    param (

        [String]
        [Parameter(ParameterSetName="string")]
        [alias("template")]
        # Template that is to be epxnaded
        $InputObject,

        [string]
        [Parameter(ParameterSetname="file")]
        # Path to a file that contains the string to be patched
        $path,

        [string]
        # Beginning tag denoting the start of an expression
        $beginTag = "[[",

        [string]
        # Ending tag denoting the end of an expression
        $endTag = "]]",

        [alias("attributes")]
        $node,

        $variables

    )

    # if the parameterset called is 'file' read the contents into the InputObject
    if ($PSCmdlet.ParameterSetname -eq "file") {

      # Check that the file exists
      if (!(Test-Path -Path $path)) {
        Write-Log -Message ("Template file cannot be located: {0}" -f $path) -LogLevel Verbose
      } else {
        $inputObject = Get-Content -Path $path -Raw
      }
    }

    # Append an ending expression to the inputobject so that the whole string is evaluated
    $inputObject += "`n{0} {1}" -f $beginTag, $endTag

    # Ensure the tags are escaped
	  $optionTagRaw = $beginTag[0]
	  $optionTag = [Regex]::Escape($optionTagRaw)
    $beginTag = [Regex]::Escape($beginTag)
    $endTag = [Regex]::Escape($endTag)

    # Previous versions of POSHChef used the vars keyword in the template so replicate that here
    $vars = $variables

    # Set the output string
    $output = [String]::Empty

    # Build up the expression to match with
	  # $pattern = "(?sm)(?<pre>.*?)[{0}?](?!{1})(?<exp>.*?){2}(?<post>.*?)$" -f $optionTag, $beginTag, $endTag
    $pattern = "(?sm)(?<pre>.*?){0}(?<exp>.*?){1}(?<post>.*?)$" -f $beginTag, $endTag

    # Create a Regex object using the pattern from above
    # This uses a .Net classes so that the named capture groups work.  The built in -match function did not cut it
    $regex = [regex] $pattern

    # Create a string builder in which the rendered template will be created
    $rendered = New-Object System.Text.StringBuilder

    foreach ($match in $regex.Matches($InputObject)) {

        # Add each component to the rendered template
        $rendered.Append(($match.Groups["pre"].Value)) | Out-Null

        # evaluate the expression if one exists
		    $expression = $match.Groups["exp"].Value.Trim($optionTagRaw)
        if (![String]::IsNullOrEmpty($expression)) {

            # invoke the expression
            $evaluated = (Invoke-Expression $expression | Out-String).Trim()
            $rendered.Append($evaluated) | Out-Null
        }

        $rendered.Append(($match.Groups["post"].Value)) | Out-Null

    }

    # Return the rendered template
    $rendered = $rendered.ToString().SubString(0, $rendered.ToString().Length - 1)
    return $rendered

}
