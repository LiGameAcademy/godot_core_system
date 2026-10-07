extends RefCounted

## Abstract method to compress byte data.
## Return PackedByteArray (empty is valid) on success, or null on failure.
func compress(bytes: PackedByteArray) -> Variant:
	CoreSystem.logger.error("CompressionStrategy.compress() must be implemented by subclasses.")
	return null

## Abstract method to decompress byte data.
func decompress(bytes: PackedByteArray) -> PackedByteArray:
	CoreSystem.logger.error("CompressionStrategy.decompress() must be implemented by subclasses.")
	return PackedByteArray() 
