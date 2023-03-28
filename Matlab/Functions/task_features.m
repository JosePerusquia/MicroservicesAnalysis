function table_feats = task_features(struct,n)
%This function creates a suitable structure for each trace in order to be
%plotted by extracting from a previously created structure 

    arrival=cell(n,1);
    operation=strings(n,1);
    thread=zeros(n,1);
    process=strings(n,1);
    id=strings(n,1);
    parent_1=strings(n,1);
    parent_2=strings(n,1);
    agents=strings(n,1);
    
    for i = 1:n
        arrival{i}=datetime(struct.HRT(i)/1000000000,'ConvertFrom','posixTime','Format','dd-MM-yyyy HH:mm:ss.SSSSSSSSS');
        operation(i)=struct.Operations(i);
        agents(i)=struct.Agents(i);
        thread(i)=struct.Threads(i);
        process(i)=struct.Services(i);
        id(i)=struct.eventID(i);
        parents=struct.parentsID{i};
        if length(parents)==1
            parent_1(i)=parents{1};
        elseif length(parents)==2
            parent_1(i)=parents{1};
            parent_2(i)=parents{2};
        end
    end
    
    arrival=cell2table(arrival);    
    operation=array2table(operation);
    agents=array2table(agents);
    thread=array2table(thread);
    process=array2table(process);
    id=array2table(id);    
    parent_1=array2table(parent_1);
    parent_2=array2table(parent_2);
    
    table_feats=[id arrival process agents thread operation parent_1 parent_2];
    table_feats=sortrows(table_feats,2);

end

