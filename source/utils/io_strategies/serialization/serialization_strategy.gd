extends RefCounted

## Abstract method to serialize data into bytes.
## Return PackedByteArray (empty is valid) on success, or null on failure.
func serialize(data: Variant) -> Variant:
	CoreSystem.logger.error("SerializationStrategy.serialize() must be implemented by subclasses.")
	return null

## Abstract method to deserialize bytes into data.
func deserialize(bytes: PackedByteArray) -> Variant:
	CoreSystem.logger.error("SerializationStrategy.deserialize() must be implemented by subclasses.")
	return null 
