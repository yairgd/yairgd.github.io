---
title : "Bayer Image to RGB"
description : "Bayer to RGB conversion"
tags : 
 - "bayer"
 - "rgb"

date : "2020-02-17"
archives : "2020"
categories : 
 - "computer-vision"
 - "python"
menu : "no-main"
---
# Color transformation from Bayer to RGB
A Bayer filter mosaic is a color filter array (CFA) for arranging RGB color filters on a square grid of photosensors. Its particular arrangement of color filters is used in most single-chip digital image sensors used in digital cameras, camcorders, and scanners to create a color image. The filter pattern is 50% green, 25% red and 25% blue - [see here](https://en.wikipedia.org/wiki/Bayer_filter).


![Bayer filter](https://upload.wikimedia.org/wikipedia/commons/thumb/3/37/Bayer_pattern_on_sensor.svg/500px-Bayer_pattern_on_sensor.svg.png)

## Color conversion algorithm

## Implemantation
Implementation using python including that modules: matplotlib, numpy,cv2. To install these modules with pip:
```bash
pip install matplotlib --user
pip install numpy --user
#pip install cv2 --user  - not sure this will work , I did it with the gentoo package manager (in debian/ubuntu you can try apt-cache search)
```
Some images to work with can be download from here
[1](/post/bayer_conversion/bayer.raw)
[2](/post/bayer_conversion/movie-0443.raw)
[3](/post/bayer_conversion/movie-0601.raw)
[4](/post/bayer_conversion/movie-0697.raw)



* read raw image at a size of *540x600* in Bayer format

```python
import matplotlib.pyplot as plt
import numpy as np
import cv2
file_path = 'path-to-bayer.raw'
imrows = 540
imcols = 600
imsize = imrows*imcols
with open(file_path, "rb") as rawimage:
    bayer_img = np.fromfile(rawimage, np.dtype('u1'), imsize).reshape((imrows, imcols))
```
* define a conversion function
```python
def pixel (img):
    img = img.astype(np.float64) 
    pixel = lambda x,y : {
        0: [ img[x][y] , (img[x][y-1] + img[x-1][y] + img[x+1][y] + img[x][y+1]) / 4 ,  (img[x-1][y-1] + img[x+1][y-1] + img[x-1][y+1] + img[x+1][y+1]) / 4 ] ,
        1: [ (img[x-1][y] + img[x+1][y])  / 2,img[x][y] , (img[x][y-1] + img[x][y+1]) / 2 ],
        2: [(img[x][y-1] + img[x][y+1]) / 2 ,img[x][y], (img[x-1][y] + img[x+1][y]) / 2],
        3: [(img[x-1][y-1] + img[x+1][y-1] + img[x-1][y+1] + img[x+1][y+1]) / 4 , (img[x][y-1] + img[x-1][y] + img[x+1][y] + img[x][y+1]) / 4 ,img[x][y] ]
    } [  x % 2 + (y % 2)*2]
    res = np.zeros ( [    np.size(img,0) , np.size(img,1)  , 3] )
    for x in range (1,np.size(img,0)-2):
        for y in range (1,np.size(img,1)-2):
            p = pixel(x,y)
            p.reverse();
            res[x][y] = p
    res = res.astype(np.uint8)
    return res
```
* break image to to 3 channels : RGB
```python
def channel_break (img):
    img = img.astype(np.float64) 
    red=np.copy (img);red [1::2,:]=0;red[:,1::2]=0
    blue=np.copy (img);blue [0::2,:]=0;blue[:,0::2]=0
    green=np.copy (img);green [0::2,0::2]=0;green [1::2,1::2]=0;
    red = red.astype(np.float64) 
    blue = blue.astype(np.float64) 
    green = green.astype(np.float64) 
    return (red,green,blue)
```
* conver RGB to gray
```python
def rgb2gray(img):
    res = np.zeros ( [    np.size(img,0) , np.size(img,1)  , 3] )
    res = res.astype(np.float64) 
    for x in range (1,np.size(img,0)-1):
        for y in range (1,np.size(img,1)-1):
            res[x][y]=img[x][y][0]*0 + img[x][y][1]*0.5 + img[x][y][2]*0.5;
    res = res.astype(np.uint8)
    return res
```

* save results to png files
```python
# plot bayer imager
plt.imshow(bayer_img)
plt.title ('bayer img')
plt.imsave('bayer_img.png', bayer_img)
#plt.show()


# this algorithm conversion
rgb_res = pixel (bayer_img)
plt.imshow(rgb_res)
plt.title ('the article conversion')
plt.imsave('the_article_conversion.png', rgb_res)
#plt.show()

# open cv conversion
colour = cv2.cvtColor(bayer_img, cv2.COLOR_BAYER_BG2BGR)
plt.imshow(colour)
plt.title ('color image by open cv')
plt.imsave('color_image_by_opencv.png', colour)
#plt.show()

# convert to gray level
gray = rgb2gray(rgb_res)
plt.imshow(gray)
plt.title ('gray conversion')
plt.imsave('gray_level.png', gray)
#plt.show()


# break to RGB  channels
RGB = channel_break(bayer_img)
blue_only = pixel (RGB[0])
plt.imshow(blue_only)
plt.title ('blue only')
plt.imsave('blue_only.png',blue_only)
plt.show()

green_only = pixel (RGB[1])
plt.imshow(green_only)
plt.title ('green only')
plt.imsave('green_only.png',green_only)
plt.show()

red_only = pixel (RGB[2])
plt.imshow(red_only)
plt.title ('red only')
plt.imsave('red_only.png',red_only)
plt.show()

#plt.show()
```
# Results
{{< figure src="/post/bayer_conversion/bayer_img.png" title="Raw Bayer Image" >}}
{{< figure src="/post/bayer_conversion/rgb_res.png" title="Conversion to RGB" >}}
{{< figure src="/post/bayer_conversion/color_image_by_opencv.png" title="Conversion by OpenCV" >}}
{{< figure src="/post/bayer_conversion/gray_level.png" title="Conversion to Gray" >}}
{{< figure src="/post/bayer_conversion/red_only.png" title="Red Only" >}}
{{< figure src="/post/bayer_conversion/green_only.png" title="Green Only" >}}
{{< figure src="/post/bayer_conversion/blue_only.png" title="Blue Only" >}}


