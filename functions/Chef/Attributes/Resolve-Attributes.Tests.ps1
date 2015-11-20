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

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

# Include other required functions
. "$PSScriptRoot\..\..\Helpers\Merge-Hashtables.ps1"
. "$PSScriptRoot\..\..\Miscellaneous\Sort-Hashtable.ps1"
. "$PSScriptRoot\..\..\Exported\ConvertFrom-JsonToHashtable.ps1"
. "$PSScriptRoot\..\Node\Get-Node.ps1"

# Only functions that already exist can be Mocked
# Stub out Write-Log function so that it can be mocked
function Write-Log(){}
function Invoke-AnalysePlatform(){
	@{platform = "windows"}
}

. "$here\$sut"

Describe "Resolve-Attributes" {

	# Mock the Write-Log function and do nothing
	# This is in case the Logging module is not vailable
	Mock Write-Log -MockWith {}
	# Mock Get-Node -MockWith { return @{automatic = @{testing = "Pester"}} }

	# Create a file that will act as an attribute file
	# Setup -File "cache\attributes.psd1" `
	# Get the PSDrive and therefore the root so that the full path can be used
	$PSDriveName = "TestDrive"
	$PSDrive = Get-PSDrive -Name $PSDriveName

	New-Item -Path ("{0}\cache" -f $PSDrive.Root) -Type directory | Out-Null

	$attribute_file = "{0}\cache\attributes.psd1" -f $PSDrive.Root
	Set-Content -Path $attribute_file `
@"

@{
	default = @{
		Base = @{
			Timezone = "GMT Standard Time"
			Fruit = @(
				"apple"
			)
		}
	}
}

"@

	# Configure the session variable containing the path to the cache directory
	# This will also contain the role attributes that need to be applied
	$script:session = @{
		config = @{
			paths = @{
				file_cache_path = $PSDrive.Root
				conf = "C:\POSHChef\conf"
				handlers = "C:\POSHChef\handlers"
				plugins = "C:\POSHChef\plugins"
				notifications = "C:\POSHChef\notifications"
			}
			attributes = @{}
			file = "C:\POSHchef\conf\client.psd1"
		}
		environment = "_default"
		
	}

	It "Given node and role attributes and an array, ensure they are added together" {

		# Add the role attributes to the session
		$script:session.attributes = @{
		
				roles = @{

					base = @{
						Fruit = @(
							"banana"
						)
					}
				}
		}

		# build the expected object
		$expected = [Ordered] @{
						AllNodes = @(
							[Ordered] @{
								base = [Ordered] @{
									Fruit = @(
										"banana"
										"apple"
									)
									Timezone = "GMT Standard Time"
								}
								chef = [Ordered] @{
									chef_environment = "_default"
									config_file = "C:\POSHChef\conf\client.psd1"
								}
								NodeName = $env:computername
								platform = "windows"
								POSHChef = [Ordered] @{
									cache = $PSDrive.Root
									conf = "C:\POSHChef\conf"
									handlers_path = "C:\POSHChef\handlers"
									notifications = "C:\POSHChef\notifications"
									plugins = "C:\POSHChef\plugins"
								}
								PSDscAllowPlainTextPassword = $true
								recipes = $null
								roles = $null
								thisrun = @{
									logdir = $null
								}
							}
						)
					}

		# Get the result of the resolved attributes
		$resolved = Resolve-Attributes | Sort-Hashtable

		# Perform the comparison of the objects
		# Compare the JSON representation of the hash tables
		# This is so that a string comparison can be done
		# Compare-Object uses objects and will only look at one level, it will not recusrively look
		$result = ($expected |  ConvertTo-Json -Depth ([int]::maxvalue)) -eq ($resolved | ConvertTo-Json -depth ([int]::maxvalue))

		# if the result is the same as the expected then all good
		$result | Should Be $true
	}

	it "Overrides a node attribute" {
		
		# Add the role attributes to the session
		$script:session.attributes = @{
		
				roles = @{

					testing = "NUnit"
				}
		}
		
		# build the expected object
		$expected = [Ordered] @{
						AllNodes = @(
							[Ordered] @{
								base = [Ordered] @{
									Fruit = @(
										"apple"
									)
									Timezone = "GMT Standard Time"
								}
								chef = [Ordered] @{
									chef_environment = "_default"
									config_file = "C:\POSHChef\conf\client.psd1"
								}
								NodeName = $env:computername
								platform = "windows"
								POSHChef = [Ordered] @{
									cache = $PSDrive.Root
									conf = "C:\POSHChef\conf"
									handlers_path = "C:\POSHChef\handlers"
									notifications = "C:\POSHChef\notifications"
									plugins = "C:\POSHChef\plugins"
								}
								PSDscAllowPlainTextPassword = $true
								recipes = $null
								roles = $null
								testing = "NUnit"
								thisrun = @{
									logdir = $null
								}
							}
						)
					}

		# Get the result of the resolved attributes
		$resolved = Resolve-Attributes | Sort-Hashtable
		
		# Perform the comparison of the objects
		# Compare the JSON representation of the hash tables
		# This is so that a string comparison can be done
		# Compare-Object uses objects and will only look at one level, it will not recusrively look
		$result = ($expected | ConvertTo-Json -Depth 10) -eq ($resolved | ConvertTo-Json -depth 10)

		# if the result is the same as the expected then all good
		$result | Should Be $true
		
	}

	$role_timezone = "New Zealand Standard Time"
	It "Given role attributes, override the timezone with '$role_timezone'" {

		# Add the role attributes to the session
		$script:session.attributes = @{
		
				roles = @{

					base = @{
						Timezone = $role_timezone
					}
				}
		}

		# build the expected object
		$expected = [Ordered] @{
						AllNodes = @(
							[Ordered] @{
								base = [Ordered] @{
									Fruit = @(
										"apple"
									)
									Timezone = $role_timezone
								}
								chef = [Ordered] @{
									chef_environment = "_default"
									config_file = "C:\POSHChef\conf\client.psd1"
								}
								NodeName = $env:computername
								platform = "windows"
								POSHChef = [Ordered] @{
									cache = $PSDrive.Root
									conf = "C:\POSHChef\conf"
									handlers_path = "C:\POSHChef\handlers"
									notifications = "C:\POSHChef\notifications"
									plugins = "C:\POSHChef\plugins"
								}
								PSDscAllowPlainTextPassword = $true
								recipes = $null
								roles = $null
								thisrun = @{
									logdir = $null
								}
							}
						)
					}

		# Get the result of the resolved attributes
		$resolved = Resolve-Attributes | Sort-Hashtable
		
		# Perform the comparison of the objects
		# Compare the JSON representation of the hash tables
		# This is so that a string comparison can be done
		# Compare-Object uses objects and will only look at one level, it will not recusrively look
		$result = ($expected | ConvertTo-Json -Depth 10) -eq ($resolved | ConvertTo-Json -depth 10)

		# if the result is the same as the expected then all good
		$result | Should Be $true
	}

	$env_timezone = "GMT"
	It "Given environment attributes, override the timezone with '$env_timezone'" {

		# Add the role attributes to the session
		$script:session.attributes = @{

				environments = @{

					Base = @{
						Timezone = $env_timezone
					}
				}
			}


		# build the expected object
		$expected = [Ordered] @{
						AllNodes = @(
							[Ordered] @{
								base = [Ordered] @{
									Fruit = @(
										"apple"
									)
									Timezone = $env_timezone
								}
								chef = [Ordered] @{
									chef_environment = "_default"
									config_file = "C:\POSHChef\conf\client.psd1"
								}
								NodeName = $env:computername
								platform = "windows"
								POSHChef = [Ordered] @{
									cache = $PSDrive.Root
									conf = "C:\POSHChef\conf"
									handlers_path = "C:\POSHChef\handlers"
									notifications = "C:\POSHChef\notifications"
									plugins = "C:\POSHChef\plugins"
								}
								PSDscAllowPlainTextPassword = $true
								recipes = $null
								roles = $null
								thisrun = @{
									logdir = $null
								}
							}
						)
					}

		# Get the result of the resolved attributes
		$resolved = Resolve-Attributes | Sort-Hashtable

		# Perform the comparison of the objects
		# Compare the JSON representation of the hash tables
		# This is so that a string comparison can be done
		# Compare-Object uses objects and will only look at one level, it will not recusrively look
		$result = ($expected | ConvertTo-Json -Depth 10) -eq ($resolved | ConvertTo-Json -depth 10)

		# if the result is the same as the expected then all good
		$result | Should Be $true
	}

	$env_executionpolicy = "RemoteSigned"
	It "Given role and environment attributes, override timezone with '$env_timezone' and add an execution policy of '$env_executionpolicy'" {

		# Add the role attributes to the session
		$script:session.attributes = @{

				roles = @{

					Base = @{
						
						ExecutionPolicy = $env_executionpolicy

						Timezone = $role_timezone

					}
				}

				environments = @{

					Base = @{
						Timezone = $env_timezone
					}
				}
			}

		# build the expected object
		$expected = [Ordered] @{
						AllNodes = @(
							[Ordered] @{
								base = [Ordered] @{
									ExecutionPolicy = $env_executionpolicy
									Fruit = @(
										"apple"
									)
									Timezone = $env_timezone
								}
								chef = [Ordered] @{
									chef_environment = "_default"
									config_file = "C:\POSHChef\conf\client.psd1"
								}
								NodeName = $env:computername
								platform = "windows"
								POSHChef = [Ordered] @{
									cache = $PSDrive.Root
									conf = "C:\POSHChef\conf"
									handlers_path = "C:\POSHChef\handlers"
									notifications = "C:\POSHChef\notifications"
									plugins = "C:\POSHChef\plugins"
								}
								PSDscAllowPlainTextPassword = $true
								recipes = $null
								roles = $null
								thisrun = @{
									logdir = $null
								}
							}
						)
					}

		# Get the result of the resolved attributes
		$resolved = Resolve-Attributes | Sort-Hashtable

		# Perform the comparison of the objects
		# Compare the JSON representation of the hash tables
		# This is so that a string comparison can be done
		# Compare-Object uses objects and will only look at one level, it will not recusrively look
		$result = ($expected | ConvertTo-Json -Depth 10) -eq ($resolved | ConvertTo-Json -depth 10)

		# if the result is the same as the expected then all good
		$result | Should Be $true
	}

	# Create two more attributes files
	# These will represent the files from different cookbooks that have the same hashtable set
	# In this case the values should be merged
	Setup -File "cache\cookbooks\notepad\attributes.psd1" `
@"
@{

	default = @{
		Chocolatey = @{
			Packages = @{
				notepadplusplus = @{
					windows_display_name = "Notepad ++"
				}
			}
		}
	}
}
"@

	Setup -File "cache\cookbooks\logstash\attributes.psd1" `
@"
@{

	default = @{
		Chocolatey = @{
			Packages = @{
				logstash = @{
					windows_display_name = "Logstash"
				}
			}
		}
	}
}
"@

	It "Given hashtables at the same scope, e.g. cookbook attributes, the hashtables are merged" {

		# build the expected object
		$expected = [Ordered] @{
						AllNodes = @(
							[Ordered] @{
								base = [Ordered] @{
									ExecutionPolicy = $env_executionpolicy
									Fruit = @(
										"apple"
									)
									Timezone = $env_timezone
								}
								chef = [Ordered] @{
									chef_environment = "_default"
									config_file = "C:\POSHChef\conf\client.psd1"
								}
								Chocolatey = [Ordered] @{
									Packages = [Ordered] @{
										logstash = [Ordered] @{
											windows_display_name = "Logstash"
										}
										notepadplusplus = [Ordered] @{
											windows_display_name = "Notepad ++"
										}
									}
								}
								NodeName = $env:computername
								platform = "windows"
								POSHChef = [Ordered] @{
									cache = $PSDrive.Root
									conf = "C:\POSHChef\conf"
									handlers_path = "C:\POSHChef\handlers"
									notifications = "C:\POSHChef\notifications"
									plugins = "C:\POSHChef\plugins"
								}
								PSDscAllowPlainTextPassword = $true
								recipes = $null
								roles = $null
								thisrun = @{
									logdir = $null
								}
							}
						)
					}

		# Get the result of the resolved attributes
		$resolved = Resolve-Attributes | Sort-Hashtable

		# Perform the comparison of the objects
		# Compare the JSON representation of the hash tables
		# This is so that a string comparison can be done
		# Compare-Object uses objects and will only look at one level, it will not recusrively look
		$result = ($expected | ConvertTo-Json -Depth 10) -eq ($resolved | ConvertTo-Json -depth 10)

		# if the result is the same as the expected then all good
		$result | Should Be $true

	}

	It "outputs information to the screen" {
		Assert-VerifiableMocks
	}
	
}
