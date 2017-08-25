import tensorflow as tf
a = tf.constant(20, name = 'a')
b = tf.constant(30, name = 'b')
mul_op = a * b
session = tf.Session()
tw= tf.summary.FileWriter("log_dir", graph=session.graph)
o = session.run(mul_op)
print(o)
