import numpy as np
class Sigmoid:
    def __init__(self):
        self.out = None

    def forward(self, x):
        out = sigmoid(x)
        self.out = out
        return out

    def backward(self, dout=1):
        dx = dout * (1.0 - self.out) * self.out
        return dx


