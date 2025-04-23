extends "./compression_strategy.gd"
class_name GzipCompressionStrategy

# 压缩模式常量
const COMPRESSION_MODE = FileAccess.COMPRESSION_GZIP

# 估算解压缩缓冲区大小的乘数 (如果经常出错，需要调整)
const DECOMPRESSION_BUFFER_MULTIPLIER = 10
# 解压缩缓冲区最小大小 (防止估算为0)
const MIN_DECOMPRESSION_BUFFER_SIZE = 1024



## 使用 Gzip 压缩字节数据
func compress(bytes: PackedByteArray) -> PackedByteArray:
	if bytes.is_empty():
		return bytes
	return bytes.compress(COMPRESSION_MODE)

## 使用 Gzip 解压缩字节数据
func decompress(bytes: PackedByteArray) -> PackedByteArray:
	if bytes.is_empty():
		return bytes
	
	# 估算解压缩后的大小。需要足够大，否则解压会失败或不完整。
	var estimated_size = bytes.size() * DECOMPRESSION_BUFFER_MULTIPLIER
	# 确保缓冲区大小至少为最小值
	estimated_size = max(estimated_size, MIN_DECOMPRESSION_BUFFER_SIZE)
	
	var decompressed_bytes = bytes.decompress(estimated_size, COMPRESSION_MODE)
	
	# 注意：Godot 3.x/4.x 的 decompress 在缓冲区不足或其他错误时
	# 可能只返回部分数据或空数组，而不会抛出异常。
	# 无法完美检测解压是否完全成功，只能依赖后续数据校验。
	if decompressed_bytes.is_empty() and not bytes.is_empty():
		push_warning("Gzip Decompression resulted in empty bytes. Buffer size (%d) might be insufficient or data corrupted." % estimated_size)
	
	return decompressed_bytes
 
