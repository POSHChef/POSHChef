
# Build script for testing and packaging up POSHChef
#
# Author: Russell Seymour
# Company: Turtlesystems Consulting

param (
  [string]
  # Version to apply to the build
  $version = [String]::Empty
)

# Determine paths to required utilities
$nuget = $env:Nuget
if ([String]::IsNullOrEmpty($nuget)) {
  $nuget = "nuget"
}

# Get the version from the environment if it has not been set
if ([String]::IsNullOrEmpty($version)) {
  $version = $env:PackageVersion
}

# Invoke-Pester from the current location and get the results back
$results = Invoke-Pester -Path . -Passthru

# If there are failed tests then abort the build
if ($results.FailedCount -gt 0) {

  $message = "##myget[buildProblem description='Build failed, {0} tests failed']" -f $results.failedcount
  Write-Output $message

} else {

  # If there then the tests have passed so attempt to build the package
  . $nuget pack POSHChef.nuspec -version $version -nopackageanalysis
}
