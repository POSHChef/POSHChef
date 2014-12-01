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


function Set-LogDir {

	<#
	
		.SYNOPSIS
		Creates the logging directory for all components
	
	#>
	
	[CmdletBinding()]
	param (
		
		[string]
		# Log directory that should be created
		$logdir = [String]::Empty,

		[Parameter(Mandatory=$true)]
		[array]
		# Array of the logtargets that are already configured
		$logtargets,

		[switch]
		# Specify if logging to a file should be added by default
		$logtofile
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Set the datetime for the log directory
	$datetime = Get-Date -Date ([DateTime]::UTCNow) -Format "yyyy-MM-dd HH-mm-ss"
		
	# If the logdir has not been passed to the function get it from the configuration
	if ([String]::IsNullOrEmpty($logdir)) {
	
		# use the logdir within the paths item in the config
		$logdir = $script:session.config.paths.logdir

	}

	# set the log_dir parent so that the housekeeping can be performing
	$log_dir_parent = $logdir

	# append the date to the log_dir
	$logdir = "{0}\{1}" -f $logdir, $datetime

	# add in a logfile if one has not been specified
	$logprovider_specified = $logtargets | Where-Object { $_.logProvider -eq "logfile" }
	if ($logtofile -and [String]::IsNullOrEmpty($logprovider_specified)) {

		# Output information about where the run is to be logged to when in debug mode
		Write-Log -EventId PC_DEBUG_0032 -LogLevel Debug -Extra $logdir

		$logtargets += @{
			logProvider = "logfile"
			verbosity = $loglevel
			logdir = $logdir
			logfilename = $logfilename		
		}

		# Update the log parameters
		Set-LogParameters -targets $logtargets -module (Get-ModuleFunctions -module $moduleinfo)	
	}



	# see if the log directory exists, and create it if not 
	if (!(Test-Path -Path $logdir)) {
		New-Item -Type directory -Path $logdir | Out-Null
	}

	# Get the number of log files that are to be kept
	$logs_to_keep = $script:session.config.logs.keep

	Write-Log " "
	Write-Log -EventId PC_INFO_0010 -extra @("Directory:`t{0}" -f $logdir
											 "Keep:`t`t{0}" -f $logs_to_keep)

	# Perform some housekeeping on the log directory
	Write-Log -eventid PC_INFO_0011

	# only perform housekeeping if the log dir exists
	Get-ChildItem -Path $log_dir_parent | Where-Object { $_.PsIsContainer } | Sort-Object CreationTime -Descending | Select-Object -Skip $logs_to_keep | Remove-Item -Force -Recurse

	Write-Log -IfDebug -eventid BRB_DEBUG_0004 -extra $logdir

	# $global:cmdlog = "{0}\commands.log" -f $log_dir

	# return the logdir to the calling fucntion
	$script:session.config.logdir = $logdir
}
