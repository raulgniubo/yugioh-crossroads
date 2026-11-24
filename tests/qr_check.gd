extends Node
## Dumps QrCode matrices for a few texts and masks (rows of 0/1), to compare with the reference encoder (tools/dev/qr_check.py):
##   godot --headless --path . res://tests/qr_check.tscn | grep '^QR|' > /tmp/qr_out.txt
func _ready() -> void:
	var texts := ["hello", "XR1-" + "eyJ2IjoxLCJnIjoiYWJjZDEyMzQ1Njc4IiwibiI6IlJhdWwncyBUYWJsZSIsImMiOjAsImsiOiJ0c2tleS1hdXRoLWtBQkNERUZHSElKMTFDTlRSTC1hYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ejAxMjM0NTY3ODkiLCJ0IjoxNzk1NDk4MDEyLCJvIjoiUmF1bCJ9", "ñandú ⚡ " + "x".repeat(300)]
	for t in texts:
		for mk in [0, 3, 6, -1]:
			var m: Array = QrCode.matrix(t, mk)
			var rows: Array = []
			for r in m:
				var s := ""
				for v in r:
					s += "1" if v else "0"
				rows.append(s)
			print("QR|%d|%s|%s" % [mk, Marshalls.utf8_to_base64(t), ",".join(rows)])
	get_tree().quit()
