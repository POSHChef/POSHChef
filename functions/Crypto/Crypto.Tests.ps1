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


# Import the functions needed to perform the RSA and AES encryption
. $PSScriptRoot\Invoke-Encrypt.ps1
. $PSScriptRoot\Invoke-Decrypt.ps1
. $PSScriptRoot\_InitialiseBouncyCastle.ps1
. $PSScriptRoot\_GetKeyPairFromPem.ps1
. $PSScriptRoot\Invoke-AESEncrypt.ps1
. $PSScriptRoot\Invoke-AESDecrypt.ps1

# Only functions that already exist can be Mocked
# Stub out Write-Log function so that it can be mocked
function Write-Log(){}

# Set a string for the private key
$private_key = @"
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA4aZN0ieNvW58Vm3m2O0QNMC3jpOzwQiOU4gIZ/fsyNmJFZYc
kYQw9y81YMJIlnW6IMyfVG708HnZsEYP9s1Vr0W5zFqr/VSDdQ7+uAOK6TWrhx66
YkaxX7BkBCiLDgdZseg4t8joOQ4jhwCdcMsX9fGJzFt38RmJ93FkO+5rlSEwyhH7
KjtK+Z6RNgJ8xnIKWU+ruxx/WQKULeWMOmQi9KdXgM0lfR5jxknH96BUMjUtrhIk
QVCxvfpu19Yci2j66IbREoQXL8wMGTvKQjiq95jg8gV7qUYPZo12iwULLF4s6vhO
Z5fh/QJhEn1tGqBSoQVk3U3aRNIIV+HRJ7K9qwIDAQABAoIBAQC7k3JXg1fZI9Iq
Sru+kfqJz7YGyJOBoKonmApc2wSzxdml3x4qfPfzUwQNRhPvNzgdcdv05TOp/7DN
TsCQigpzZAPac3lLYojQs0FdGFzOFjZbYVjQvzFNeST7K/TEGaofMQqNBG6+lxlD
bWhzTfDCGyJQhazD+FXvIwyOoVg/I0Np0HCXviizWJuVq3SEcHO8RHFBjSpWMc9V
wCBXYnNuAJxRbB4MR1GDekEY55lxHmNuHaJecvKsAyx1Ufj8aXAb4kYiaMu+czSs
Msuyuqpms5jSg4Ab3GnufS39HH6qlPQOJDEFdczslx4lIts7LdweEA/+RxA2rXM5
sUITvEbxAoGBAPW+ev0IlJ0kfoAgsXF3GjAg++d4cgufbYg0DzEwXYKE3fMy92Ho
rYG527z0WiAb1oKhNfZ/uR8E+tG4q9vmlCM14Wv06BZJ5hcItjAdtDJwzIhclSBJ
cmUFnMSlDnLZxMpgImp14OWPwbwXDThe4spqsk0UgqHjcupJwf/C5jXJAoGBAOsR
IqkwvuG9muLngVmAtPkME0nUx/QJJV8FDnd2HCKaaC5OmB6ZR31u6yN+f8K26yrc
vJlKARcFJvO6TqBhdE6vlc7g/LbPwHjp3EuoEN5gfdO2cFlsKgHLs8nF2P3y5mF2
CoATpcRSp9ivSkEx8drNn7+WDGYIbepKKD1fmaHTAoGAEi+ghm1GIkL7IZxJxW3d
AEbQnZaqSfXoczX3EdrUcL5IdqEE8bf4bytD+b3TlaC5xT0M80sMdiE2NqMGBOYR
fHGWVxjuvAeIAZhhczofhcQXPtgrKRKGZrd9nIfig9ld2OQ4Z8yFcjerTLIgBlXv
Tq+Ktm2YJUbh0DjZJIZV5xECgYEAg6VKExTwof4M4yyh/V0efSetGbkn7ly86DUt
v+uOoDZ3SA/OE7zmE7Jtz6gFpyfIFm4e1X5jk9/Xy8G4TQunFnYxYPYRsdQxx8W5
EUnjgJbrgQj4bKwt7mmFm+fIuZgyO7ze7pGSUZu00p6A6HgvKcnkwGgpM29fF0pG
tPB4Wu8CgYBDULwTk8bXJk3m87bCwF2ErFzpDoROvdqWeymMI6c8Ie7SpJVoNH8N
6WvZrHumavjcKvEZUuaT+B2+tHUqnXy1fdDs+9cQBSfBEpV2zXdae2F8o6I/Y5O+
TYa9HwyxMcE741pUbecFt868ranHYfSDyluu7w9fJMI7XqTcsH4tUQ==
-----END RSA PRIVATE KEY-----
"@

# Set the string for the public key
$public_key = @"
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4aZN0ieNvW58Vm3m2O0Q
NMC3jpOzwQiOU4gIZ/fsyNmJFZYckYQw9y81YMJIlnW6IMyfVG708HnZsEYP9s1V
r0W5zFqr/VSDdQ7+uAOK6TWrhx66YkaxX7BkBCiLDgdZseg4t8joOQ4jhwCdcMsX
9fGJzFt38RmJ93FkO+5rlSEwyhH7KjtK+Z6RNgJ8xnIKWU+ruxx/WQKULeWMOmQi
9KdXgM0lfR5jxknH96BUMjUtrhIkQVCxvfpu19Yci2j66IbREoQXL8wMGTvKQjiq
95jg8gV7qUYPZo12iwULLF4s6vhOZ5fh/QJhEn1tGqBSoQVk3U3aRNIIV+HRJ7K9
qwIDAQAB
-----END PUBLIC KEY-----
"@

# Set the text that needs to be encrypted
$plaintext = "Hello World!"

# Set a variable that contains the path to the Crypto DLL
$script:session = @{
	config = @{
		paths = @{
			module = "$PSScriptRoot\..\.."
		}
	}
}

# AES only
Describe "AES encryption round trip" {

	# Encrypt the plaintext
	$encrypt = Invoke-AESEncrypt -data $plaintext

	# Decrypt the data
	$decrypt = Invoke-AESDecrypt -data $encrypt.encrypted[0] -iv $encrypt.iv -key $encrypt.key

	# Check that the plaintext and the decrypt are the same
	It "returns a decrypt that is the same as the plaintext '$plaintext'" {
		$plaintext -eq $plaintext | Should Be $true
	}
}

# RSA only
Describe "RSA encryption round trip using keypair" {

	# Set up files for the private and public keys
	Setup -File "private_key.pem" $private_key
	Setup -File "public_key.pem" $public_key

	It "Performs cycle using the public key of key pair to encrypt.  Pem is passed as a file." {

		# perform the encryption
		$encrypted = Invoke-Encrypt -data $plaintext ("{0}\private_key.pem" -f $TestDrive)

		# Now perform decryption
		$decrypted = Invoke-Decrypt -cypher $encrypted -pempath ("{0}\private_key.pem" -f $TestDrive) -private

		# test the result
		$decrypted -eq $plaintext | Should Be $true
	}

	It "Performs cycle using the private key of key pair to encrypt.  Pem is passed as a file." {

		# perform the encryption
		$encrypted = Invoke-Encrypt -data $plaintext ("{0}\private_key.pem" -f $TestDrive) -private

		# Now perform decryption
		$decrypted = Invoke-Decrypt -cypher $encrypted -pempath ("{0}\private_key.pem" -f $TestDrive)

		# test the result
		$decrypted -eq $plaintext | Should Be $true
	}

	It "Performs cycle using the public key of key pair to encrypt.  Pem is passed as a string." {

		# perform the encryption
		$encrypted = Invoke-Encrypt -data $plaintext -pem $private_key

		# Now perform decryption
		$decrypted = Invoke-Decrypt -cypher $encrypted -pempath $private_key -private

		# test the result
		$decrypted -eq $plaintext | Should Be $true
	}

	It "Performs cycle using only the public key to encrypt" {

		# perform the encryption
		$encrypted = Invoke-Encrypt -data $plaintext -pem $public_key

		# perform the decryption
		$decrypted = Invoke-Decrypt -cypher $encrypted -pem $private_key  -private

		# test the result
		$decrypted -eq $plaintext | Should Be $true
	}

}

# AES and RSA encryption
# In this scenario the plaintext is encrypted using AES and then the key is encrypted with
# the public key.  The reverse of this is performed to make sure the entire process works
Describe "Encrypt with AES and then encrypt the AES key with RSA" {

	# Encrypt the plaintext and get back the encrypt object
	$aes_encrypt = Invoke-AESEncrypt -data $plaintext

	# Now encrypt the aes key with RSA
	$rsa_encrypt = Invoke-Encrypt -data $aes_encrypt.key -pem $public_key

	# Decrypt the rsa encrypted text
	$rsa_decrypt = Invoke-Decrypt -cypher $rsa_encrypt -pem $private_key -private -raw

	# finally decrypt the aes encrypted data with the decrypted key in rsa
	$aes_decrypt = Invoke-AESDecrypt -data $aes_encrypt.encrypted[0] -iv $aes_encrypt.iv -key $rsa_decrypt

	it "returns a decrypt which is the same as the plain text" {
		$aes_decrypt -eq $plaintext | Should be $true
	}

}

