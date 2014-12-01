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


function Set-DSCConfiguration {

	<#

	.SYNOPSIS
	Function to set the local configuration manager settings for DSC

	#>

	[CmdletBinding()]
	param (
		[hashtable]
		$configuration = @{AllNodes = @()}
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	Write-Log " "
	Write-Log -EventId PC_INFO_0040

	# If the configuration data for the node does not have a DSCConfig section
	# return to the calling function
	if (!($configuration.AllNodes[0].ContainsKey("DSCConfig"))) {

		# output some information
		Write-Log -EventId PC_INFO_0041

		return
	}

	Write-Log -EventId PC_INFO_0042

	# Now need to craete the configuration item for the local machine
	Configuration LocalDSCConfiguration {

		Node $env:COMPUTERNAME {
			LocalConfigurationManager {

				AllowModuleOverwrite = $configuration.AllNodes[0].DSCConfig.AllowModuleOverwrite
				CertificateId = $configuration.AllNodes[0].DSCConfig.CertificateId
				ConfigurationId = $configuration.AllNodes[0].DSCConfig.ConfigurationId
				ConfigurationMode = $configuration.AllNodes[0].DSCConfig.ConfigurationMode
				ConfigurationModeFrequencyMins = $configuration.AllNodes[0].DSCConfig.ConfigurationModeFrequencyMins
				Credential = $configuration.AllNodes[0].DSCConfig.Credential
				DownloadManagerCustomData = $configuration.AllNodes[0].DSCConfig.DownloadManagerCustomData
				DownloadManagerName = $configuration.AllNodes[0].DSCConfig.DownloadManagerName
				RebootNodeIfNeeded = $configuration.AllNodes[0].DSCConfig.RebootNodeIfNeeded
				RefreshFrequencyMins = $configuration.AllNodes[0].DSCConfig.RefreshFrequencyMins 
				RefreshMode = $configuration.AllNodes[0].DSCConfig.RefreshMode

			}
		}
	}

	# Call the configuration
	$dscsettings_mof = LocalDSCConfiguration -OutputPath $script:session.config.paths.mof_file_path

	Write-Log -EventId PC_MISC_0002 -extra $dscsettings_mof.fullname

	# Call the cmdlet to make the change, using the runspace
	# Set-DSCLocalConfigurationManager -Path $script:session.config.paths.mof_file_path
	Invoke-Runspace -Command Set-DSCLocalConfigurationManager -Arguments @{path = $script:session.config.paths.mof_file_path} -Stream Verbose
}
