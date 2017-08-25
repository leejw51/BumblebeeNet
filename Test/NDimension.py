import numpy as np
a = np.array( [1,2,3] )
print(a)
print(a.ndim)


a = np.array( [ [1,2,3], [4,5,6] ] )
print(a)
print(a.ndim)



a = np.array( [ [1,2,3], [4,5,6], [7,8,9], [10,11,12] ] )
print(a)
print(a.ndim)


a = np.array( [[ [1,2,3], [4,5,6], [7,8,9], [10,11,12] ]] )
print(a)
print(a.ndim)


a = np.array( [[[ [1,2,3], [4,5,6], [7,8,9], [10,11,12] ]]] )
print(a)
print(a.ndim)


a= np.array( [  [1,2] , [3,4] ])
print(a)
print(a.ndim)
print(a[0][1])
print(a[1][0])
