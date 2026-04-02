extends RefCounted

## Abstract method to encrypt byte data.
## [param bytes] The data to encrypt.
## [param key] The encryption key.
func encrypt(bytes: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	CoreSystem.logger.error("EncryptionStrategy.encrypt() must be implemented by subclasses.")
	return PackedByteArray()

## Abstract method to decrypt byte data.
## [param bytes] The data to decrypt.
## [param key] The encryption key.
func decrypt(bytes: PackedByteArray, key: PackedByteArray) -> PackedByteArray:
	CoreSystem.logger.error("EncryptionStrategy.decrypt() must be implemented by subclasses.")
	return PackedByteArray() 
