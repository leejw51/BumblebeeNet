import sys, os
import numpy as np
from dataset.mnist import *
from PIL import Image 


def img_show(img):
    pil_img = Image.fromarray(np.uint8(img))
    pil_img.show()

(x_train, t_train), (x_test, t_test) = load_mnist(flatten=True, normalize=False)
print("x_train=", x_train.shape)
print("t_train=", t_train.shape)
print("x_test=", x_test.shape)
print("t_test=", t_test.shape)
img = x_train[0]
label = t_train[0]
print("train=",label)

print(img.shape)
img = img.reshape(28,28)
print(img.shape)
img_show(img)
	
