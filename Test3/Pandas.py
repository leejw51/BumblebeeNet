import pandas as pd
data = {'name':['john', 'anna', 'peter', 'linda'],
  'location': [ 'new york', 'paris', 'berlin', 'london'],
  'age': [24, 13, 53, 33]}
data_pandas = pd.DataFrame(data)
print(data_pandas)
