from PIL import Image
import shutil
import os
import sys

shutil.copy(sys.argv[1], sys.argv[1] + ".bak")

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
