import numpy as np
import matplotlib.pylab as plt
from numpy import arange, sin, pi, radians, degrees
from matplotlib.pylab import plot,show

x = arange(-360, 360, 0.1)
y = sin(radians(x)) 

plot(x,y)
show()

