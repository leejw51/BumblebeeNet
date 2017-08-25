import numpy 
import matplotlib.pylab
from numpy import pi, arange, sin,cos
from matplotlib.pylab import plot,show


x = arange(-pi, pi,  0.01)
y = sin(x)

plot(x,y)
show()

