import functions

directorio = '/Users/tinruelas/Downloads/x-traces/compose/individual/'
str1, str2 = functions.read_traces(directorio)
report = str2[5]

functions.plot_services(report)

        
    
    