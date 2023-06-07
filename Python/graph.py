import functions
import os

os.chdir('..')
os.chdir(os.getcwd()+'/x-traces/compose/individual/')
str1, str2 = functions.read_traces(os.getcwd()+'/')
report = str2[5]
functions.plot_services(report, out_name = "", save=0)



directorio = '/Users/tinruelas/Downloads/x-traces/compose/individual/'
str1, str2 = functions.read_traces(directorio)
report = str2[5]

functions.plot_services(report, out_name = "/Users/tinruelas/Desktop/graph.pdf")

        
    
    
