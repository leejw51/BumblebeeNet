import numpy as np
from dataset.mnist import *
from common.functions import *
from PIL import Image

def img_show(img):
    pil_img = Image.fromarray(np.uint8(img))
    pil_img.show()


def get_data():
    (x_train, t_train), (x_test, t_test) = load_mnist(normalize=True, flatten=True, one_hot_label=False)
    return x_test, t_test, x_train, t_train

def init_network():
    with open ("sample_weight.pkl", 'rb') as f:
        network = pickle.load(f)
    return network


def predict(network, x):
    W1, W2, W3 = network['W1'], network['W2'], network['W3']
    b1, b2, b3 = network['b1'], network['b2'], network['b3']
    a1 = np.dot(x, W1) + b1
    z1 = sigmoid(a1)
    a2 = np.dot(z1, W2) + b2
    z2= sigmoid(a2)
    a3 = np.dot(z2, W3) + b3
    y = softmax(a3)
    return y





x,t,  x_train, t_train = get_data()
print("test x=", x.shape)
print("test t=", t.shape)
print("train x=", x_train.shape)
print("train t=", t_train.shape)
network = init_network()
print("10000 images X=", x.shape)
print("a image X=", x[0].shape)
print("Network=", len(network))
print("W1 Shape=",network['W1'].shape)
print("W2 Shape=",network['W2'].shape)
print("W3 Shape=",network['W3'].shape)
print("b1 Shape=",network['b1'].shape)
print("b2 Shape=",network['b2'].shape)
print("b3 Shape=",network['b3'].shape)
y = predict(network, x[0])
print("x[0] shape=", x[0].shape)
x_img = x[0].reshape(28,28)*255
img_show(x_img)
print("y shape=", y.shape)
print("sum=",np.sum(y),"  predict=", y,  "  choice=", np.argmax(y))

accuracy_cnt = 0
for i in  range(len(x)):
    y = predict(network, x[i])
    p = np.argmax(y)
    if p == t[i]:
        accuracy_cnt += 1

print("Accuray:"+ str(float(accuracy_cnt)/len(x)))

