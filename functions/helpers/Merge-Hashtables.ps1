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


function Merge-Hashtables {

	<#

	.SYNOPSIS
	Merges two hashtables together and returns the result

	.DESCRIPTION
	When adding two hashes together, an error will be thrown if there are duplicate keys in the table.

	The order in which the hashtables are passed to the function is very important.  So the primary hashtable
	will be the master, and keys that exist here will override the same one in the secondary hashtable.

	The only exception to this is that the system will determine if both keys are another hashtable.  If they are
	then the function is called recursively again to provide the merged tables

	Credit
	Originally taken from the following page: http://jdhitsolutions.com/blog/2013/01/join-powershell-hash-tables

	#>


	[cmdletbinding()]
	Param (
		[hashtable]
		# First hashtable to merge, this will have priority
		$primary,

		[hashtable]
		# second hashtable to merge
		$secondary
	)

	# If in debug mode, show the function currently in
	Write-Log -IfDebug -Message $("***** {0} *****" -f $MyInvocation.MyCommand)

	# Craete an array of types that can be merged.
	# Hashtables and Dictionaries can be merged
	$types = @(
		"Hashtable"
		"Dictionary``2"
	)

	#check for any duplicate keys
	$duplicates = $primary.keys | where {$secondary.ContainsKey($_)}

	if ($duplicates) {
		foreach ($key in $duplicates) {

				# if the item is a hashtable then call this function again
				if ($types -contains $primary.$key.gettype().name -and
				    $types -contains $secondary.$key.gettype().name) {

					# set the argument hashtable
					$splat = @{
						primary = $primary.$key
						secondary = $secondary.$key
					}

					$Primary.$key = Merge-Hashtables @splat
				}

				# if the key is an array merge the two items
				if ($primary.$key.GetType().Name -eq "Object[]" -and $secondary.$key.GetType().name -eq "Object[]") {

					$result = @()

					# Because an array can contain many different types, need to be careful how this information is merged
					# This means that the normal additional functions and the Unique parameter of Select will not work properly
					# so iterate around each of the two arrays and add to a result array
					foreach ($arr in @($primary.$key, $secondary.$key)) {

						# analyse each item in the arr
						foreach ($item in $arr) {

							# Switch on the type of the item to determine how to add the information
							switch ($item.GetType().Name) {
								"Object[]" {
									$result += , $item
								}

								# If the type is a string make sure that the array does not already
								# contain the same string
								"String" {
									if ($result -notcontains $item) {
										$result += $item
									}
								}

								# For everything else add it in
								default {
									$result += $item
								}
							}
						}
					}

					# Now assign the result back to the primary array
					$primary.$key = $result
				}

				#force primary key, so remove secondary conflict
				$Secondary.Remove($key)

		}
	}

	#join the two hash tables and return to the calling function
	$Primary + $Secondary

}
