import numpy as np
import matplotlib.pylab as plt
from matplotlib.pylab import log, sum

def cross_entropy_error(y,t):
    delta = 1e-7
    ret = -sum(  t* log(y+ delta) )
    return ret


t = np.array( [0,0, 1, 0,0,    0,0,0,0,0])
y = np.array( [0.1, 0.05, 0.6, 0, 0.05,       0.1, 0, 0.1, 0,0])
r = cross_entropy_error(  y, t)
print(r)


y = np.array( [0.1, 0.05, 0.1, 0, 0.05,        0.1, 0, 0.6, 0,0] )
r = cross_entropy_error( y, t)
print(r)

