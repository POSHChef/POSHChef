
# This file holds default attributes for the cookbook
# Any of these can be overridden using a Role or an Environment

# The format of the file is important due to the necessary interaction with Chef server
# It is a PowerShell based hashtable.
#

# At the end of a POSHChef run the attributes hash table is turned into a JSON object and then
# saved with the node.  So if this cookbook was called 'Acme' then the following structure would
# ensure that the attributes are part of the Acme cookbook
#
# @{
#	default = @{
#		Acme = @{
#			name = "RoadRunner"
#		}
#	}	
# }
#
# NOTE:  The word default is about the priorities of attributes.  For the moment POSHChef only
# supports the default priority

@{

	# Default attributes
	default = @{

		# Specific attributes for this cookbook should be added to the following object
		$($cookbook_name) = @{
		}
	}
}