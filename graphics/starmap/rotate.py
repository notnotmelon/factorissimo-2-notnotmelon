from PIL import Image

# Load the image
image = Image.open("C:\\Users\\zacha\\Documents\\factorio\\1.2\\mods\\factorissimo-2-notnotmelon\\graphics\\starmap\\factory-architecture-1.png")

# Rotate and save the image in 64 orientations
for i in range(64):
    rotated_image = image.rotate(i * (360 / 64))
    rotated_image.save(f"factory-floor-{i}.png")
    print(f"Saved factory-floor-{i}.png")