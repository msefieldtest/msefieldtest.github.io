from PIL import Image
import os
import sys

def convert_png_to_jpg(png_path, jpg_path):
	"""Converts a PNG image to JPG format.

	Args:
		png_path: Path to the input PNG image.
		jpg_path: Path to save the output JPG image.
	"""
	try:
		image = Image.open(png_path)
		# Convert to RGB if the image has transparency
		if image.mode in ("RGBA", "LA") or (image.mode == "P" and "transparency" in image.info):
			image = image.convert("RGB")
		image.save(jpg_path, "JPEG")
		print(f"Successfully converted {png_path} to {jpg_path}")
	except Exception as e:
		print(f"Error converting {png_path}: {e}")


if __name__ == "__main__":
	directory = sys.argv[1]

	if not os.path.exists(directory):
		print("Bad directory.")

	else:
		for filename in os.listdir(directory):
			if filename.lower().endswith(".png"):
				png_path = os.path.join(directory, filename)
				jpg_filename = os.path.splitext(filename)[0] + ".jpg"
				jpg_path = os.path.join(directory, jpg_filename)
				convert_png_to_jpg(png_path, jpg_path)
				os.remove(png_path)