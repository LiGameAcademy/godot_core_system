extends RefCounted

## 由调用者处理错误，序列化工具不要求注册CoreSystem或初始化日志模块。
var last_error: String = ""

## Abstract method to serialize data into bytes.
## PackedByteArray（包含空数组）为成功，null 为失败。
func serialize(data: Variant) -> Variant:
	last_error = "SerializationStrategy.serialize() must be implemented by subclasses."
	return null

## Abstract method to deserialize bytes into data.
func deserialize(bytes: PackedByteArray) -> Variant:
	last_error = "SerializationStrategy.deserialize() must be implemented by subclasses."
	return null 
