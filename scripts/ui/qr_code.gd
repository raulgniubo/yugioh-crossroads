class_name QrCode
extends RefCounted
## A QR code for a short text (the invite code), drawn into an Image. Byte mode, error correction
## level M, versions 1 to 40, the usual mask choice. Follows the standard (ISO/IEC 18004) the same
## way the well-known small encoders do; checked module for module against Nayuki's reference encoder (tests/qr_check.tscn, tools/dev/qr_check.py).

const ECC_PER_BLOCK := [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28]
const BLOCKS := [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49]
const FORMAT_M := 0

var ver := 1
var size := 21
var mods: Array = []          # [y][x] bool
var fn: Array = []            # [y][x] bool: part of a fixed pattern


## The modules (true = dark) for `text`, or [] when it is too long. `mask` -1 = the best one.
static func matrix(text: String, mask := -1) -> Array:
	var q := QrCode.new()
	if not q._make(text.to_utf8_buffer(), mask):
		return []
	return q.mods


## The code as a black-on-white picture, `scale` pixels a module, with the usual 4-module margin.
static func image(text: String, scale := 8) -> Image:
	var m := matrix(text)
	if m.is_empty():
		return null
	var n := m.size()
	var w := (n + 8) * scale
	var img := Image.create(w, w, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	for y in n:
		for x in n:
			if m[y][x]:
				img.fill_rect(Rect2i((x + 4) * scale, (y + 4) * scale, scale, scale), Color.BLACK)
	return img


static func raw_modules(v: int) -> int:
	var r := (16 * v + 128) * v + 64
	if v >= 2:
		var na := v / 7 + 2
		r -= (25 * na - 10) * na - 55
		if v >= 7:
			r -= 36
	return r


static func data_codewords(v: int) -> int:
	return raw_modules(v) / 8 - ECC_PER_BLOCK[v] * BLOCKS[v]


func _make(data: PackedByteArray, mask: int) -> bool:
	# the version: the smallest that holds it
	ver = 0
	for v in range(1, 41):
		var cc := 8 if v <= 9 else 16
		if 4 + cc + data.size() * 8 <= data_codewords(v) * 8:
			ver = v
			break
	if ver == 0:
		return false
	size = ver * 4 + 17
	var bits: Array = []
	_put(bits, 4, 4)
	_put(bits, data.size(), 8 if ver <= 9 else 16)
	for b in data:
		_put(bits, b, 8)
	var cap := data_codewords(ver) * 8
	_put(bits, 0, mini(4, cap - bits.size()))
	_put(bits, 0, (8 - bits.size() % 8) % 8)
	var pad := 0xEC
	while bits.size() < cap:
		_put(bits, pad, 8)
		pad = 0x11 if pad == 0xEC else 0xEC
	var words := PackedByteArray()
	words.resize(bits.size() / 8)
	for i in bits.size():
		if bits[i]:
			words[i >> 3] |= 1 << (7 - (i & 7))
	var all := _with_ecc(words)
	mods = []
	fn = []
	for y in size:
		var r1: Array = []
		var r2: Array = []
		r1.resize(size)
		r2.resize(size)
		r1.fill(false)
		r2.fill(false)
		mods.append(r1)
		fn.append(r2)
	_patterns()
	_codewords(all)
	if mask < 0:
		var best := -1
		var low := 1 << 30
		for mk in 8:
			_mask(mk)
			_format(mk)
			var p := _penalty()
			if p < low:
				low = p
				best = mk
			_mask(mk)
		mask = best
	_mask(mask)
	_format(mask)
	return true


static func _put(bits: Array, val: int, n: int) -> void:
	for i in range(n - 1, -1, -1):
		bits.append(((val >> i) & 1) == 1)


func _dot(x: int, y: int, dark: bool) -> void:
	mods[y][x] = dark
	fn[y][x] = true


func _patterns() -> void:
	for i in size:
		_dot(6, i, i % 2 == 0)
		_dot(i, 6, i % 2 == 0)
	for c in [Vector2i(3, 3), Vector2i(size - 4, 3), Vector2i(3, size - 4)]:
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var x: int = c.x + dx
				var y: int = c.y + dy
				if x >= 0 and x < size and y >= 0 and y < size:
					var d := maxi(absi(dx), absi(dy))
					_dot(x, y, d != 2 and d != 4)
	var al := _align_positions()
	var n := al.size()
	for i in n:
		for j in n:
			if (i == 0 and j == 0) or (i == 0 and j == n - 1) or (i == n - 1 and j == 0):
				continue
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					_dot(al[i] + dx, al[j] + dy, maxi(absi(dx), absi(dy)) != 1)
	_format(0)
	if ver >= 7:
		var rem := ver
		for i in 12:
			rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
		var b := (ver << 12) | rem
		for i in 18:
			var bit := ((b >> i) & 1) == 1
			var a := size - 11 + i % 3
			var c2 := i / 3
			_dot(a, c2, bit)
			_dot(c2, a, bit)


func _align_positions() -> Array:
	if ver == 1:
		return []
	var na := ver / 7 + 2
	var step := (ver * 8 + na * 3 + 5) / (na * 4 - 4) * 2
	var out: Array = [6]
	var pos := size - 7
	while out.size() < na:
		out.insert(1, pos)
		pos -= step
	return out


func _format(mask: int) -> void:
	var d := (FORMAT_M << 3) | mask
	var rem := d
	for i in 10:
		rem = (rem << 1) ^ ((rem >> 9) * 0x537)
	var b := ((d << 10) | rem) ^ 0x5412
	var bit := func(i: int) -> bool: return ((b >> i) & 1) == 1
	for i in 6:
		_dot(8, i, bit.call(i))
	_dot(8, 7, bit.call(6))
	_dot(8, 8, bit.call(7))
	_dot(7, 8, bit.call(8))
	for i in range(9, 15):
		_dot(14 - i, 8, bit.call(i))
	for i in 8:
		_dot(size - 1 - i, 8, bit.call(i))
	for i in range(8, 15):
		_dot(8, size - 15 + i, bit.call(i))
	_dot(8, size - 8, true)


static func _gf(x: int, y: int) -> int:
	var z := 0
	for i in range(7, -1, -1):
		z = (z << 1) ^ ((z >> 7) * 0x11D)
		z ^= ((y >> i) & 1) * x
	return z


func _with_ecc(data: PackedByteArray) -> PackedByteArray:
	var nb: int = BLOCKS[ver]
	var el: int = ECC_PER_BLOCK[ver]
	var raw := raw_modules(ver) / 8
	var n_short := nb - raw % nb
	var short_len := raw / nb
	# the divisor
	var div: Array = []
	div.resize(el)
	div.fill(0)
	div[el - 1] = 1
	var root := 1
	for i in el:
		for j in el:
			div[j] = _gf(div[j], root)
			if j + 1 < el:
				div[j] ^= div[j + 1]
		root = _gf(root, 2)
	var blocks: Array = []
	var k := 0
	for i in nb:
		var take := short_len - el + (0 if i < n_short else 1)
		var dat: Array = []
		for t in take:
			dat.append(data[k + t])
		k += take
		var rem: Array = []
		rem.resize(el)
		rem.fill(0)
		for b in dat:
			var f: int = b ^ rem.pop_front()
			rem.append(0)
			for t in el:
				rem[t] ^= _gf(div[t], f)
		if i < n_short:
			dat.append(0)
		blocks.append(dat + rem)
	var out := PackedByteArray()
	for i in (blocks[0] as Array).size():
		for j in nb:
			if i != short_len - el or j >= n_short:
				out.append(blocks[j][i])
	return out


func _codewords(data: PackedByteArray) -> void:
	var i := 0
	var right := size - 1
	while right >= 1:
		if right == 6:
			right = 5
		for vert in size:
			for j in 2:
				var x := right - j
				var up := ((right + 1) & 2) == 0
				var y := size - 1 - vert if up else vert
				if not fn[y][x] and i < data.size() * 8:
					mods[y][x] = ((data[i >> 3] >> (7 - (i & 7))) & 1) == 1
					i += 1
		right -= 2


func _mask(m: int) -> void:
	for y in size:
		for x in size:
			if fn[y][x]:
				continue
			var inv := false
			match m:
				0: inv = (x + y) % 2 == 0
				1: inv = y % 2 == 0
				2: inv = x % 3 == 0
				3: inv = (x + y) % 3 == 0
				4: inv = (x / 3 + y / 2) % 2 == 0
				5: inv = x * y % 2 + x * y % 3 == 0
				6: inv = (x * y % 2 + x * y % 3) % 2 == 0
				7: inv = ((x + y) % 2 + x * y % 3) % 2 == 0
			if inv:
				mods[y][x] = not mods[y][x]


## How hard the code is to read with this mask (lower is better): runs of one color, 2x2 blocks,
## patterns that look like the finders, and how far from half dark it is.
func _penalty() -> int:
	var p := 0
	for pass_i in 2:
		for a in size:
			var run := 0
			var last := false
			var line: Array = []
			for b in size:
				var v: bool = mods[a][b] if pass_i == 0 else mods[b][a]
				line.append(v)
				if b > 0 and v == last:
					run += 1
					if run == 5:
						p += 3
					elif run > 5:
						p += 1
				else:
					run = 1
				last = v
			for b in size - 6:
				if line[b] and not line[b + 1] and line[b + 2] and line[b + 3] and line[b + 4] and not line[b + 5] and line[b + 6]:
					var before: bool = b >= 4 and not line[b - 1] and not line[b - 2] and not line[b - 3] and not line[b - 4]
					var after: bool = b + 10 < size and not line[b + 7] and not line[b + 8] and not line[b + 9] and not line[b + 10]
					if before or after:
						p += 40
	var dark := 0
	for y in size:
		for x in size:
			if mods[y][x]:
				dark += 1
			if x < size - 1 and y < size - 1:
				var c: bool = mods[y][x]
				if c == mods[y][x + 1] and c == mods[y + 1][x] and c == mods[y + 1][x + 1]:
					p += 3
	var total := size * size
	var k := int(ceil(absf(dark * 20.0 - total * 10.0) / total)) - 1
	p += maxi(0, k) * 10
	return p
