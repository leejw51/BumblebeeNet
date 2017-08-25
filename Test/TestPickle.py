import numpy
import matplotlib

import pickle

f = open("file.dat", "wb")
d = {"apple":100,  "pear":200,  "strawberry":2000}
pickle.dump(d, f)
f.close()

f = open("file.dat", "rb")
d2 = pickle.load(f)
print(d2)
f.close()
