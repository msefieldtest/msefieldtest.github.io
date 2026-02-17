from PIL import Image
import os
import json

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
		image.save(jpg_path, "JPEG", quality=90)
		# print(f"Successfully converted {png_path} to {jpg_path}")
		return True
	except Exception as e:
		print(f"Error converting {png_path}: {e}")
		return False

def process_set_directory(set_dir):
	"""Processes a single set directory.

	Args:
		set_dir: Path to the set directory (e.g., 'DOWNLOADED_SETS/ABY-files').
	"""
	set_code = os.path.basename(set_dir).replace("-files", "")
	img_dir = os.path.join(set_dir, "img")
	json_path = os.path.join(set_dir, f"{set_code}.json")

	if not os.path.exists(img_dir):
		print(f"Skipping {set_dir}: 'img' directory not found.")
		return

	# Convert images in the img directory
	print(f"Processing images in {img_dir}...")
	for filename in os.listdir(img_dir):
		if filename.lower().endswith(".png"):
			png_path = os.path.join(img_dir, filename)
			jpg_filename = os.path.splitext(filename)[0] + ".jpg"
			jpg_path = os.path.join(img_dir, jpg_filename)
			if convert_png_to_jpg(png_path, jpg_path):
				os.remove(png_path)

	# Update the JSON file
	if os.path.exists(json_path):
		print(f"Updating {json_path}...")
		try:
			with open(json_path, 'r', encoding='utf-8-sig') as f:
				data = json.load(f)
			
			data["image_type"] = "jpg"
			with open(json_path, 'w', encoding='utf-8-sig') as f:
				json.dump(data, f, indent=4)
			print(f"Successfully updated image_type in {json_path}")
		except Exception as e:
			print(f"Error updating {json_path}: {e}")
	else:
		print(f"Warning: JSON file not found at {json_path}")

if __name__ == "__main__":
	downloaded_sets_root = "DOWNLOADED_SETS"

	if not os.path.exists(downloaded_sets_root):
		print(f"Error: {downloaded_sets_root} directory not found.")
	else:
		for item in os.listdir(downloaded_sets_root):
			item_path = os.path.join(downloaded_sets_root, item)
			if os.path.isdir(item_path) and item.endswith("-files"):
				process_set_directory(item_path)