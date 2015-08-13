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

<#

  .SYNOPSIS
    Pester tests to ensure that the Patching of templates works

  .DESCRIPTION
    POSHChef has a resource that allows templates to be rendered based on the variables
    and node attributes that are passed to it.  The tests here check that template
    files are rendered correctly with single and multiline expressions as well as
    a mixture of both in the file

#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

# Scource the function
. "$here\$sut"

Describe "Patch Template" {

  It "Evaluates a single line expression" {

    # Set the template value
    $template = @'
Hello [[ $node.name ]]
'@

    # Set what is expected
    $expected = "Hello World"

    # Call the function
    $result = Expand-Template -template $template -attributes @{name = "World"}

    $result -eq $expected | Should be $true
  }

  It "Evalutes a multi line expression" {

    # Define the template
    $template = @'
Hello
[[
  $node.Name
  1..10
]]
'@
    # Set what is expected
    $expected = @"
Hello
World
1
2
3
4
5
6
7
8
9
10
"@

    # Call the function
    $result = Expand-Template -template $template -attributes @{name = "World"}

    $result -eq $expected | Should be $true

  }

  It "Evalutes a mixture of single and multiline expressions" {

    # Define the template
    $template = @'
Hello [[ $node.name ]]
[[
  function getAnswer {
    42
  }
]]
The answer is [[ getAnswer ]]
'@

    # Set what is expected
    $expected = @"
Hello World

The answer is 42
"@

    # Call the function
    $result = Expand-Template -template $template -attributes @{name = "World"}

    $result -eq $expected | Should be $true

  }

  it "Correctly resolves expressions contained in the delimiter character" {

    # Define the template
    $template = @'
; SQL Server Configuration file
[[[ $node.stanza.name ]]]
'@

    # Set what is expected
    $expected = @"
; SQL Server Configuration file
[OPTIONS]
"@

    # Call the function
    $result = Expand-Template -template $template -attributes @{stanza = @{name = "OPTIONS"}}

    $result -eq $expected | Should be $true
  }

  It "Given a file the contents are correctly rendered" {

    # Build up the attributes to use
  	$attributes = @{
  		default = @{
  			ElasticSearch = @{
  				cluster_name = "pester_tests"
  				paths = @{
  					data = "D:\ElasticSearch\data"
  				}
  			}
  		}
  	}

  	# Set the psdrive
  	$PSDriveName = "TestDrive"
  	$PSDrive = Get-PSDrive $PSDriveName

  	# Build up the source and destination
  	$source = "{0}\template.yml.tmpl" -f $PSDrive.Root
  	$destination = "{0}\dummy\template.yml" -f $PSDrive.Root

    # Ensure the source file has the correct information
  	$source_content = @'
cluster.name: [[ $node.ElasticSearch.cluster_name ]]
path.data: [[ $node.ElasticSearch.paths.data ]]
'@
    [system.io.file]::WriteAllText($source, $source_content)

# set the expected string
    $expected = @"
cluster.name: {0}
path.data: {1}
"@ -f $attributes.default.ElasticSearch.cluster_name, $attributes.default.ElasticSearch.paths.data

    $result = Expand-Template -path $source -attributes $attributes.default

    $result -eq $expected | Should be $true

  }
}
