#Servicio social. Martín Guzmán Ruelas.

import os
import json
import pandas as pd
import datetime
import numpy as np

#replicating read_traces function
def read_traces(path):

    files = os.listdir(path) #a list with all the .json files
    structure1 = pd.DataFrame(columns = ['name', 'id', 'no_reps', 'initial_time', 'last_time']) #a dictionary containing the information of files
    structure2 = [] #a list that contains a dataframe for each file; this dataframe contains features information
    
    row = 0 #indicator
    
    for file in files:
        #we open the file in order to read its information
        with open(path + file) as current_file:
            current_data = json.load(current_file)[0]
        
        #creating the dataframe of features
        no_reports = len(current_data['reports'])
        
        #features
        operations = []
        threads = []
        eventID = []
        parentsID = []
        HRT = []
        agents = []
        microservices = []
        arrival = []
        parent_1 = []
        parent_2 = []
        
        for i in range(no_reports):
            events = current_data['reports'][i]
            
            #for operation
            if 'Operation' in events:
                operations.append(events['Operation'])
            else:
                operations.append('')
            
            #for process name
            if events['ProcessName'] == '':
                microservices.append('Reference')
            else: 
                microservices.append(events['ProcessName'])
            
            #for parents
            if 'ParentEventID' in events:
                parents = events['ParentEventID']
                parentsID.append(parents)
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
                parentsID.append('')
                parent_1.append('')
                parent_2.append('')
            
            #all of the other values
            agents.append(events['Agent'])
            threads.append(events['ThreadID'])
            eventID.append(events['EventID'])
            HRT.append(events['HRT'])
            temp = datetime.datetime.fromtimestamp(events['HRT'] / 1000000000)
            arrival.append(temp)
            
        features = {'id': eventID,
                    'operation': operations,
                    'thread': threads,
                    'service': microservices,
                    'hrt': HRT,
                    'arrival': arrival,
                    'agent':agents,
                    'parent_id':parentsID,
                    'parent1':parent_1,
                    'parent2':parent_2}
        
        structure2.append(pd.DataFrame(features))
            
        structure1.loc[row] = {'name'         : file,
                               'id'           : current_data['id'],
                               'no_reps'      : len(current_data['reports']),
                               'initial_time' : min(HRT),
                               'last_time'    : max(HRT)}
        
        row = row + 1
        
    return structure1, structure2
    
def resp_processes(structure2, processes):
    
    n = len(processes)
    m = len(structure2)
    
    resp_processes = {}
    
    for i in range(n):
        process = processes[i]
        arrival = []
        departure = []
        response = []
        
        for j in range(m):
            indices = np.argwhere(np.array(structure2[j].service == process))
            arrival.append(structure2[j].arrival.loc[indices[0][0]])
            departure.append(structure2[j].arrival.loc[indices[-1][0]])
            response.append((departure[j] - arrival[j]).microseconds / 1000)
            
        process_df = pd.DataFrame({'arrival' : arrival,
                                  'departure' : departure,
                                  'response' : response})
        
        resp_processes[process] = process_df
        
    return resp_processes
