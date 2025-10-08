#!/usr/bin/env python3
import sys
import os

# Simple approach: use sips to convert to JPEG then back to PNG
# This removes alpha channel
os.system('sips -s format jpeg Icon-App-1024x1024@1x.png --out temp_icon.jpg')
os.system('sips -s format png temp_icon.jpg --out Icon-App-1024x1024@1x-opaque.png')
os.system('rm temp_icon.jpg')

print("Alpha channel removed successfully")
