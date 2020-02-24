from PIL import Image
import sys

img = Image.open(sys.argv[1])
img = img.convert("LA")
data = img.getdata()
new_data = []
for item in data:
    if item[0] == 0:
        new_data.append((0, 0))
    else:
        new_data.append(item)
img.putdata(new_data)
img.save(sys.argv[1])
