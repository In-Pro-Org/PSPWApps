
function Remove-UnsafeCharacter {
	[CmdletBinding()]
	param(
		[string]$inputString
	)

	$inputString = $inputString -replace "'", "''"
	$inputString = $inputString -replace '"', '\"'
	$inputString = $inputString -replace ';', '\;'
	$inputString = $inputString -replace '--', '\-\-'
	$inputString = $inputString -replace '/\*', '/\*'
	$inputString = $inputString -replace '\*/', '\*/'
	$inputString = $inputString -replace '\\', '\\\\'

	return $inputString
}
