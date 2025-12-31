# png_to_PDF.py
import sys
from PIL import Image

if len(sys.argv) < 3:
    print("Usage: png_to_PDF.py input.png output.pdf")
    sys.exit(1)

png_path = sys.argv[1]
pdf_path = sys.argv[2]

image = Image.open(png_path).convert("RGB")
image.save(pdf_path, "PDF")
