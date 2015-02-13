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


function Initialize-Session {

	<#

	.SYNSOPIS
	Function responsible for loading up configuration data and making it available to the other functions


	#>

	[CmdletBinding()]
	param (

		# Object containing the arguments that have been passed to POSHChef
		$parameters,

		# Module information object
		$moduleinfo = [String]::Empty
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# if the moduleinfo is empty then get it
	if ([String]::IsNullOrEmpty($moduleinfo)) {
		$moduleinfo = Get-Module -Name POSHChef
	}

	# Create a global hashtable that contains all the properties for the different aspects of the session
	$Script:Session = @{

				# Configuration hash table
				config = @{

					# set the basedir for configuration
					# this is the only path that is outside of the paths as it should be rooted
					# and we do nto want to test for relative path on it
					basedir = $parameters.basedir

					paths = @{

						# define where the log directory should be
						logdir = "log"

						# Where the downloads files from chef should be stored
						file_cache_path = "cache"

						# Set the path that DSCResources should be copied to
						dscresources = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\"

						# Set the path to the module
						module = (Split-Path -Parent ($moduleInfo.Path))

						# Set the path to where the generated MOF files should be stored
						mof_file_path = "mof"

						# Set the path where mof files should be archived to
						mof_file_archive_path = "archive"

						# Set the location for the cookbooks
						cookbooks = "."

						conf = "conf"

						handlers = "handlers"

						knife_plugins = "plugins\knife"
						chef_plugins = "plugins\chef"

						# Set the name of the directory to hold notification
						notifications = "notifications"
					}

					# get information about the module
					module_info = $moduleInfo

					# Sepcify whether cookbook files should be downloaded or not
					download = $parameters.download

					# Set the server to connect to
					server = ""

					# the name of the node
					node = ""

					# name of the client
					client = ""

					# the file name of the client key
					key = $parameters.key

					# the number of logs to keep
					logs = @{

						keep = 20

					}

					# Set the name of the valiaotr and the key
					validation_name = "chef-validator"

					validation_key = "chef-validation.pem"

					# nugetsource for checking the version of POSHChef
					nugetsource = ""

					# full path to the configuration file being used for this run
					file = ""

				}

				# The environment that this machine belongs to
				environment = $false

				# Hash to hold the list of cookbooks that need to be retrieved from the Chef server
				# the order does not matter here
				cookbooks = @{}

				# Set a parameter to hold any local run_list that has been set
				local_runlist = $parameters.runlist

				# Define attribute to hold the expanded run list
				expanded_runlist = @()

				# create a resolve object that will hold the queue of cookobokos to download and the ones that have been
				resolve = @{
					queue = New-Object System.Collections.Queue
					done = @()
				}

				# Define property to hold all the recipes and roles that have been assigned
				recipes = @()
				roles = @()

				# attributes from the environment and the roles that have been specified
				attributes = @{

					roles = @{}

					environments = @{}

					# Hold attributes that have been specified on the command line
					cmdline = $parameters.json_attributes
				}

				# add in string array to set the items that should be skipped
				skip = $parameters.skip
			}


	# Build up the basic headers to access the Chef server
	#$global:headers = @{
	#		'X-Chef-Version' = '{0}' -f $chef_config.version
	#		}

	# define a the array which will contain the expanded run list for the node
	# $global:expanded_runlist = @()

	# ensure that the paths in the config section of the session are rewritten as absolute
	# paths if they are not already
	# Modifications need to be put into a temporary hash so that the iteration operation can continue
	$config_paths = @{}
	foreach ($path in $script:session.config.paths.keys) {

		Write-Log -IfDebug -EventId PC_DEBUG_0006 -extra ("{0} - {1}" -f $path, $script:session.config.paths.$path)

		# check to see if the path is rooted, if not reset with the path of the ModuleInfo
		if (![System.IO.Path]::IsPathRooted($script:session.config.paths.$path) -and $script:session.config.paths.$path -ne ".") {
			$config_paths.$path = "{0}\{1}" -f $script:session.config.basedir, $script:session.config.paths.$path

			# ensure that the parent path exists on the file system
			if (!(Test-Path -Path ($config_paths.$path))) {
				Write-Log -IfDebug -EventId PC_DEBUG_0012 -extra ($config_paths.$path)

				New-Item -Type directory -Path ($config_paths.$path) | Out-Null
			}
		} else {
			$config_paths.$path = $script:session.config.paths.$path
		}
	}

	# Now replace the paths with the modified ones
	$script:session.config.paths = $config_paths

	# If the local_runlist is not false, check that the specified file exists
	# and pull into the session
	if ($script:session.local_runlist -ne $false -and ![String]::IsNullOrEmpty($script:session.local.run_list)) {

		if ((Test-Path -Path ($script:session.local_runlist))) {

			Write-Log -IfDebug -EventId PC_DEBUG_0018 -extra ($script:session.local_runlist)

			# read the psd1 file in
			$script:session.local_runlist = Invoke-Expression (Get-Content -Path ($script:session.local_runlist) -raw)
		}
	}

}
