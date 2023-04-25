import functions
import numpy as np

#read_traces
str1, str2 = functions.read_traces("/Users/tinruelas/Downloads/x-traces/compose/individual/")

#resp_processes
num_processes = [str2[i]['service'].nunique() for i in range(len(str2))]
good_indices = np.argwhere(np.array(num_processes) == 10) #indices de reportes con 10 servicios distintos      
reports_with_10 = [str2[int(good_indices[i])] for i in range(len(good_indices))]
resp_processes = functions.resp_processes(reports_with_10, str2[0]['service'].unique())

#plot_trace
functions.plot_trace(str2[5])