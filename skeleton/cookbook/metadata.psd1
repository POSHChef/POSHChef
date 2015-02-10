# PowerShell version of the metadata.rb file
# When a cookbook is uploaded this file will be used to generated the metadata.rb file
# that is required by Chef and the native client

@{ 

    # Name of the cookbook
    name = "$cookbook_name"

    # Version of the cookbook
    # Chef stores versions of cookbooks that have been uploaded
    version = '0.0.1'

    # Who is the maintainer of the cookbook?
    maintainer = "$username"
    maintainer_email = "<YOUR EMAIL>"

    # What is the licence of the cookbook
    # NOTE:  This must be set as 'license'
    license = "All rights reserved"

    # A short description of the cookbook
    description = "SHORT DESCRIPTION"

    # The long description about the cookbook
    # It is expected to be a file in the root of the cookbook
    long_description = "README.md"

}
