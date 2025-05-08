extends RefCounted

## Abstract method to compress byte data.
func compress(bytes: PackedByteArray) -> PackedByteArray:
	CoreSystem.logger.error("CompressionStrategy.compress() must be implemented by subclasses.")
	return PackedByteArray()

## Abstract method to decompress byte data.
func decompress(bytes: PackedByteArray) -> PackedByteArray:
	CoreSystem.logger.error("CompressionStrategy.decompress() must be implemented by subclasses.")
	return PackedByteArray() 