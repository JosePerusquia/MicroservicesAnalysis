#Servicio social. Martín Guzmán Ruelas.

import os
import json
import pandas as pd
import datetime
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as patches

def read_traces(path):
    '''
    Dada una carpeta de x_traces, lee todo su contenido y obtiene información de cada reporte.
    
    Parámetros
    ----------
    path : String
        Cadena que contiene la ruta de una carpeta de x_traces.

    Productos
    -------
    structure1 : DataFrame
        Un data frame donde cada fila representa un reporte y contiene información relevante del mismo.
    
    structure2 : List
        Una lista de data frames donde cada data frame contiene información detallada de los eventos de cada reporte.

    '''
    
    files = os.listdir(path) #una lista con todos los archivos .json
    structure1 = pd.DataFrame(columns = ['name', 'id', 'no_reps', 'initial_time', 'last_time']) #un data frame con información de cada archivo
    structure2 = [] #una lista de data frames (uno por cada archivo); cada data frame contiene las características detalladas de cada archivo
    
    row = 0 #indicador 
    
    for file in files:
        #se abre el archivo actual
        with open(path + file) as current_file:
            current_data = json.load(current_file)[0]
        
        #número de reportes
        no_reports = len(current_data['reports'])
        
        #características a obtener
        ids = []
        operations = []
        threads = []
        services = []
        hrt = []
        arrival = []
        agents = []
        parents_id = []
        parent_1 = []
        parent_2 = []
        
        for i in range(no_reports):
            events = current_data['reports'][i]
            
            #para id
            ids.append(events['EventID'])
            
            #para operation
            if 'Operation' in events:
                operations.append(events['Operation'])
            else:
                operations.append('')
            
            #para thread
            threads.append(events['ThreadID'])
            
            #para service
            if events['ProcessName'] == '':
                services.append('Reference')
            else: 
                services.append(events['ProcessName'])
            
            #para hrt
            hrt.append(events['HRT'])
            
            #para arrival
            arrival.append(datetime.datetime.fromtimestamp(events['HRT'] / 1000000000))
            
            #para agent
            agents.append(events['Agent'])
            
            #para parents_id, parent_1 y parent_2
            if 'ParentEventID' in events:
                parents = events['ParentEventID']
                parents_id.append(parents)
                no_parents = len(parents)
                
                if no_parents == 0:
                    parent_1.append('')
                    parent_2.append('')
                elif no_parents == 1:
                    parent_1.append(parents[0])
                    parent_2.append('')
                elif no_parents == 2:
                    parent_1.append(parents[0])
                    parent_2.append(parents[1])
            else:
                parents_id.append('')
                parent_1.append('')
                parent_2.append('')
        
        #se resumen todas las caracteristicas en un diccionario 
        features = {'id': ids,
                    'operation': operations,
                    'thread': threads,
                    'service': services,
                    'hrt': hrt,
                    'arrival': arrival,
                    'agent':agents,
                    'parent_id':parents_id,
                    'parent1':parent_1,
                    'parent2':parent_2}
        
        #se agrega el data frame a la lista correspondiente
        structure2.append(pd.DataFrame(features).sort_values(by = 'hrt'))
        
        #se agrega la fila al data frame correspondiente
        structure1.loc[row] = {'name'         : file,
                               'id'           : current_data['id'],
                               'no_reps'      : len(current_data['reports']),
                               'initial_time' : min(hrt),
                               'last_time'    : max(hrt)}
        
        row += 1
        
    return structure1, structure2
    
def resp_processes(structure2, processes):
    '''
    Dada una lista de data frames (producto de la función read_path), devuelve información útil del tiempo de respuesta de los eventos para ciertos procesos (servicios).
    
    Parámetros
    ----------
    structure2 : List
        Lista de data frames, producto de la función read_path. OJO: Todos los data frames deben contener todos los procesos enlistados en processes; de lo contrario habrá error
        
    processes : List
        Lista de los procesos para los cuales se busca obtener la información

    Productos
    -------
    resp_processes : dict
        Diccionario donde cada llave es un proceso y cada valor es un data frame con la información obtenida de structure2 para el respectivo proceso.

    '''
    n = len(processes) #número de procesos
    m = len(structure2) #número de reportes
    
    resp_processes = {} #diccionario vacío; se llenará y será el producto final
    
    for i in range(n):
        process = processes[i] #proceso actual
        
        #información a obtener
        arrival = []
        departure = []
        response = []
        
        for j in range(m):
            indexes = np.argwhere(np.array(structure2[j].service == process))
            arrival.append(structure2[j].arrival.loc[indexes[0][0]]) #tiempo inicial del proceso
            departure.append(structure2[j].arrival.loc[indexes[-1][0]]) #tiempo final del proceso
            response.append((departure[j] - arrival[j]).microseconds / 1000) #tiempo de respuesta
            
        #se crea un data frame con la información obtenida
        process_df = pd.DataFrame({'arrival' : arrival,
                                  'departure' : departure,
                                  'response' : response})
        
        #se agrega el data frame al diccionario
        resp_processes[process] = process_df
        
    return resp_processes
    
def plot_trace(table_features):
    '''
    Genera la gráfica de un trace
    
    Parámetros
    ----------
    table_features : DataFrame
        Un data frame que contiene la información detallada de los eventos de un reporte (este data frame sale de la lista de dataframes devuelta en read_path, o sea que es un elemento de structure2)

    Productos
    -------
    Solo se muestra la gráfica del trace. 

    '''
    
    n = len(table_features) #número de eventos en el reporte
    times = [time_diff.microseconds / 1000 for time_diff in (table_features['arrival'] - table_features['arrival'].iloc[0])] #se calcula en qué momento empezó cada evento tomando como referencia el primer evento
    
    unique_processes = table_features['service'].unique() #servicios únicos en el reporte
    no_unique_processes = len(unique_processes)
    
    unique_thread = table_features['thread'].unique() #threads únicos en el reporte
    no_unique_thread = len(unique_thread)
    
    #información de los threads para separarlos según el servicio al que pertenecen (el color es para graficarlos)
    group_threads = np.empty(0)
    color_threads = []
    
    for i in range(len(unique_processes)):
        threads = (table_features[table_features['service'] == unique_processes[i]]['thread']).unique()
        group_threads = np.concatenate((group_threads, threads))
        color_threads = color_threads + [i for j in range(len(threads))]
     
    #coordenadas verticales para la gráfica (cada coordenada corresponde a un thread)
    y = np.empty(n)    
      
    for i in range(no_unique_thread):
        index = np.argwhere(np.array(table_features['thread'] == group_threads[i]))
        
        y[index] = no_unique_thread - i
    
    #creación de la gráfica
    fig, ax = plt.subplots(figsize = (15, 10))
    
    #límites y etiquetas del eje vertical (es decir, los nombres de los threads)
    ax.set_ylim([0, no_unique_thread + 1])
    ax.set_xlim([-5, 5 + times[-1]])
    ax.set_yticks(np.arange(1, no_unique_thread + 1, 1), unique_thread)
    
    #se grafica el inicio de cada evento del reporte como un punto negro
    ax.scatter(times, y, c = 'black')
    
    #se grafican líneas para representar las conexiones con los parents
    for i in range(1, n):
        #para el primer parent
        index = np.argwhere(np.array(table_features['id'] == table_features['parent1'].iloc[i]))[0][0] #índice del parent
        x_values = [times[int(index)], times[i]]
        y_values = [y[int(index)], y[i]]
        
        if table_features['service'].iloc[index] == table_features['service'].iloc[i]:
            #si el padre y el hijo son del mismo servicio, la línea es azul
            ax.plot(x_values, y_values, 'b', linestyle="-")
        else:
            #si el padre y el hijo son de servicios distintos, la línea es roja
            ax.plot(x_values, y_values, 'r', linestyle="-")
        
        #para el segundo parent (es el mismo proceso, pero no todos tienen segundo parent)
        if table_features['parent2'].iloc[i] != '':
            index2 = np.argwhere(np.array(table_features['id'] == table_features['parent2'].iloc[i]))[0][0]
            x2_values = [times[int(index2)], times[i]]
            y2_values = [y[int(index2)], y[i]]
            
            if table_features['service'].iloc[index2] == table_features['service'].iloc[i]:
                ax.plot(x2_values, y2_values, 'b', linestyle="-")
            else:
                ax.plot(x2_values, y2_values, 'r', linestyle="-")
    
    #se generan colores aleatorios (en código rgb) para los procesos 
    colors = np.random.rand(no_unique_processes, 3)
    
    #se grafican rectángulos de colores para cada thread; el color depende del servicio, no del thread
    for i in range(no_unique_thread):
        ax.add_patch(patches.Rectangle(
                    (-5, no_unique_thread - i - 0.5),
                    times[-1] + 10, 1,
                    color = colors[color_threads[i]],
                    fill=True, 
                    alpha=0.4))
    
    plt.show()

def plot_services(report, out_name):
    services = report['service'].unique()
    
    services_index = {}
    for i in range(len(services)):
        services_index[services[i]] = i
    
    report_detailed = report[['id','service', 'parent1', 'parent2']].merge(report[['id', 'service']], left_on = 'parent1', right_on = 'id', suffixes = ["", "_parent1"])
    report_detailed = report_detailed.merge(report[['id', 'service']], how = 'left', left_on = 'parent2', right_on = 'id', suffixes = ["", "_parent2"])
    for_adjacency = pd.get_dummies(report_detailed[['id', 'service', 'service_parent1']], columns = ['service_parent1'], prefix = "", prefix_sep = "")
    adjacency = for_adjacency.groupby('service')[services].sum()
    adjacency.rename(index = services_index, columns = services_index, inplace = True)

    g = ig.Graph(directed=True).Weighted_Adjacency(adjacency, loops = False)

    g.vs['label'] = services
    
    # Plot the graph
    ig.plot(g, out_name, margin = 100, edge_size = 3, edge_curved = True)
