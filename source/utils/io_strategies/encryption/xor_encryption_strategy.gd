extends "./encryption_strategy.gd"

## Simple XOR encryption/decryption.
## NOTE: This is NOT cryptographically secure and is for demonstration/basic obfuscation only.

var _logger : CoreSystem.Logger = CoreSystem.logger

func encrypt(bytes: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	if key.is_empty():
		_logger.error("XOR encrypt: Empty key provided, returning original data.")
		return bytes
	
	var encrypted_bytes := PackedByteArray()
	encrypted_bytes.resize(bytes.size())
	for i in range(bytes.size()):
		encrypted_bytes[i] = bytes[i] ^ key[i % key.size()] # XOR with cycling key
	return encrypted_bytes

func decrypt(bytes: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	if key.is_empty():
		_logger.error("XOR decrypt: Empty key provided, returning original data.")
		return bytes
	
	# XOR decryption is the same operation as encryption
	return encrypt(bytes, key) 
