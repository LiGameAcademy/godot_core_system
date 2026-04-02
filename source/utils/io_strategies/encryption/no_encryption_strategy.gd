extends "./encryption_strategy.gd"

## Returns the input bytes without modification.
func encrypt(bytes: PackedByteArray, _key: PackedByteArray) -> PackedByteArray:
	return bytes

## Returns the input bytes without modification.
func decrypt(bytes: PackedByteArray, _key: PackedByteArray) -> PackedByteArray:
	return bytes 