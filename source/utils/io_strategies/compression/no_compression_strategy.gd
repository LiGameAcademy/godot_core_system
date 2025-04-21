extends "./compression_strategy.gd"

## Returns the input bytes without modification.
func compress(bytes: PackedByteArray) -> PackedByteArray:
	return bytes

## Returns the input bytes without modification.
func decompress(bytes: PackedByteArray) -> PackedByteArray:
	return bytes 