import numpy as np
import matplotlib as plt

a = np.array( [ 0.3, 2.9, 4.0] )
exp_a = np.exp(a)
sum_a = np.sum(a)
sum_exp_a = np.sum(exp_a)
print(a)
print(exp_a)
print(sum_a)
print(sum_exp_a)

y = exp_a / sum_exp_a

print(y)

