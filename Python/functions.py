#Servicio social. Martín Guzmán Ruelas.

import os
import json
import pandas as pd
import datetime

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
        
        for i in range(no_reports):
            events = current_data['reports'][i]
            
            if 'Operation' in events:
                operations.append(events['Operation'])
            else:
                operations.append('')
            
            if 'ParentEventID' in events:
                parentsID.append(events['ParentEventID'])
            else:
                parentsID.append('')
            
            if events['ProcessName'] == '':
                microservices.append('Reference')
            else: 
                microservices.append(events['ProcessName'])
            
            agents.append(events['Agent'])
            threads.append(events['ThreadID'])
            eventID.append(events['EventID'])
            HRT.append(events['HRT'])
            
        features = {'Operations': operations,
                    'Threads': threads,
                    'Services': microservices,
                    'EventID': eventID,
                    'ParentID':parentsID,
                    'HRT': HRT,
                    'Agents':agents}
        
        structure2.append(pd.DataFrame(features))
            
        structure1.loc[row] = {'name'         : file,
                               'id'           : current_data['id'],
                               'no_reps'      : len(current_data['reports']),
                               'initial_time' : min(HRT),
                               'last_time'    : max(HRT)}
        
        row = row + 1
        
    return structure1, structure2

#replicating table_feats function
def table_feats(feats):
    arrival = []
    operation = []
    thread = []
    process = []
    ids = []
    parent_1 = []
    parent_2 = []
    agents = []
    
    for i in range(len(feats)):
        temp = datetime.datetime.fromtimestamp(feats.loc[i]['HRT'] / 1000000000)
        arrival.append(temp)
        operation.append(feats.loc[i]['Operations'])
        thread.append(feats.loc[i]['Threads'])
        agents.append(feats.loc[i]['Agents'])
        process.append(feats.loc[i]['Services'])
        ids.append(feats.loc[i]['EventID'])
        no_parents = len(feats.loc[i]['ParentID'])
        parents = feats.loc[i]['ParentID']
        
        if no_parents == 0:
            parent_1.append('')
            parent_2.append('')
        elif no_parents == 1:
            parent_1.append(parents[0])
            parent_2.append('')
        elif no_parents == 2:
            parent_1.append(parents[0])
            parent_2.append(parents[1])
    
    return pd.DataFrame({'id'        : ids,
                         'arrival'   : arrival,
                         'process'   : process,
                         'agents'    : agents,
                         'thread'    : thread,
                         'operation' : operation,
                         'parent1'   : parent_1,
                         'parent2'   : parent_2})
            

