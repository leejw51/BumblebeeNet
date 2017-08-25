import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import tensorflow as tf
a = tf.constant(100)
b = tf.constant(200)
add_op = a + b
v = tf.Variable(0)
let_op = tf.assign(v, add_op)
    
sess = tf.Session()
#sess.run(tf.tf.global_variables_initializer())
sess.run(let_op)
print(sess.run(v))
