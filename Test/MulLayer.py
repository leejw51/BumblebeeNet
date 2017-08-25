import numpy as np
import matplotlib

class MulLayer:
    def __init__(self):
        self.x = None
        self.y = None

    def forward(self, x, y):
        self.x = x
        self.y = y
        out = x*y
        return out

    def backward(self, dout):
        dx = dout * self.y
        dy = dout * self.x

        return dx,dy


#test
mul_apple_layer = MulLayer()
mul_tax_layer = MulLayer()

def test_forward():
        apple = 100
        apple_num = 2
        tax = 1.1


        apple_price = mul_apple_layer.forward(apple, apple_num)
        price = mul_tax_layer.forward( apple_price, tax)
        print(price)


def test_backward():
        dprice = 1
        dapple_price, dtax = mul_tax_layer.backward(dprice)
        dapple, dapple_num = mul_apple_layer.backward(dapple_price)
        print("dapple=", dapple)
        print("dapple_num=", dapple_num)
        print("dtax=", dtax)

       

#test_forward()
#test_backward()


