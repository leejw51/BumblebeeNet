import numpy as np
import matplotlib.pylab as plt
from dataset.mnist import load_mnist
from two_layer_net import TwoLayerNet

(x_train, t_train), (x_test, t_test) = load_mnist(normalize=True, one_hot_label=True)
train_loss_list = []

print("x_train=", x_train.shape)
print("t_train=", t_train.shape)


print("x_test=", x_test.shape)
print("t_test=", t_test.shape)


iters_num = 1
train_size = x_train.shape[0]
batch_size = 10
print("train_size=", train_size, "  batch_size=", batch_size)
learning_rate = 0.1
network = TwoLayerNet(input_size=784, hidden_size=50, output_size=10)

for i in range(iters_num) :
    batch_mask = np.random.choice(train_size, batch_size)
    print("batch_mask=", batch_mask.shape)
    x_batch = x_train[batch_mask]
    t_batch = t_train[batch_mask]
    print("x_batch=", x_batch.shape)
    print("t_batch=", t_batch.shape)

    grad = network.numerical_gradient(x_batch, t_batch)
    print("grad W1=", grad['W1'].shape)
    print("grad b1=", grad['b1'].shape)
    print("grad W2=", grad['W2'].shape)
    print("grad b2=", grad['b2'].shape)
    for key in ('W1', 'b1', 'W2', 'b2') :
        network.params[key] -= learning_rate * grad[key]

    loss = network.loss(x_batch, t_batch)
    print("loss=", loss)
    train_loss_list.append(loss)
    print("loss list=", train_loss_list)

