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

	# RFC 1952：GZIP 尾部的 ISIZE（最后 4 字节，小端）为未压缩长度 mod 2^32。
	# 高压缩比时「压缩包大小 × 倍数」会远小于真实未压缩大小，必须用 ISIZE 或逐步放大缓冲区。
	var estimated_size: int = _estimate_gzip_uncompressed_size(bytes)
	var decompressed_bytes := bytes.decompress(estimated_size, COMPRESSION_MODE)

	var attempt := 0
	while decompressed_bytes.is_empty() and not bytes.is_empty() and attempt < 6:
		attempt += 1
		estimated_size = max(estimated_size * 4, int(bytes.size() * pow(10, attempt)))
		estimated_size = max(estimated_size, MIN_DECOMPRESSION_BUFFER_SIZE)
		decompressed_bytes = bytes.decompress(estimated_size, COMPRESSION_MODE)

	if decompressed_bytes.is_empty() and not bytes.is_empty():
		push_warning(
			"Gzip decompression failed after retries. Last buffer size %d, input size %d."
			% [estimated_size, bytes.size()]
		)

	return decompressed_bytes


func _estimate_gzip_uncompressed_size(bytes: PackedByteArray) -> int:
	if bytes.size() < 10:
		return max(bytes.size() * DECOMPRESSION_BUFFER_MULTIPLIER, MIN_DECOMPRESSION_BUFFER_SIZE)
	# 尾 4 字节 ISIZE
	var isize: int = (
		bytes[bytes.size() - 4]
		| (bytes[bytes.size() - 3] << 8)
		| (bytes[bytes.size() - 2] << 16)
		| (bytes[bytes.size() - 1] << 24)
	)
	if isize > 0:
		return max(isize, MIN_DECOMPRESSION_BUFFER_SIZE)
	return max(bytes.size() * DECOMPRESSION_BUFFER_MULTIPLIER, MIN_DECOMPRESSION_BUFFER_SIZE)
 
