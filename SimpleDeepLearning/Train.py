import sys, os
import numpy as np
import matplotlib.pylab as plt
from TwoLayerNeural import TwoLayerNet
from sklearn import datasets
from sklearn.decomposition import PCA

class Trainer :
    def __init__(self):
        print("Trainer init")
        #read data
        #load iris data
        self.iris = datasets.load_iris()
        self.ax_train = self.iris.data
        self.at_train = np.zeros(( self.ax_train.shape[0],3))
        print("ax_train=", self.ax_train.shape)
        print("at_train=", self.at_train.shape)
        #make handy for processing
        for i in range(self.iris.target.shape[0]) :
                p =  self.iris.target[i]
                self.at_train[i][p] = 1
        #prepare
        self.network = TwoLayerNet(input_size=4, hidden_size=50, output_size=3)
        self.iters_num = 5000
        self.train_size = self.ax_train.shape[0] 
        self.batch_size = 5 
        self.learning_rate = 0.1
        #loss list
        self.train_loss_list = []
        #accuracy list
        self.train_acc_list = []
        self.iter_per_epoch = max(self.train_size / self.batch_size, 1)

    def run(self):
        self.process()
        self.draw()

    def process(self): 
        for i in range(self.iters_num):
            # randomly pick nodes from large datasets
            choices = np.random.choice(self.train_size, self.batch_size)
            self.x_batch = self.ax_train[choices]
            self.t_batch = self.at_train[choices]
            #back propagation
            #fast!
            grad = self.network.gradient(self.x_batch, self.t_batch) 
            #update parameters
            #two hidden layer
            for key in ('W1', 'b1', 'W2', 'b2'):
                self.network.params[key] -= self.learning_rate * grad[key]
            loss = self.network.loss(self.x_batch, self.t_batch)
            #add float to float list
            self.train_loss_list.append(loss)
            if 0 ==i % self.iter_per_epoch:
                    self.train_acc = self.network.accuracy(self.ax_train, self.at_train)
                    self.train_acc_list.append( self.train_acc)

    def draw(self):
        #draw graph
        x = np.arange(len(self.train_acc_list))
        y = self.train_acc_list
        plt.plot(x,y,label="train accuracy")
        plt.xlabel("epochs")
        plt.ylabel("accuracy")
        plt.show()
