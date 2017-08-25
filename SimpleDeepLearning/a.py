import numpy as np
def test(ok=1, sky=20) :
    print("ok=",ok,"   sky=",sky)


a = np.array( [1,2,3, 4,5,6])

original = a.shape
print(a)
print(original)
print(*original)

d = a
d = d.reshape(3,-1)
print(d)

