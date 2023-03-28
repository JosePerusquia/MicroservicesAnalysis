function struct_process = resp_processes(structure,processes)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    n=length(processes);
    m=length(structure);
    struct_process(n)=struct();
    
    for i=1:n
       name=processes(i);
       arrival=cell(m,1);
       departure=cell(m,1);
       response=zeros(m,1);
       for j=1:m
           indices=find(structure(j).processes.process==name);
           arrival{j}=structure(j).processes.arrival(indices(1));
           departure{j}=structure(j).processes.arrival(indices(end));
           response(j)=milliseconds(departure{j}-arrival{j});
       end
        arrival=cell2table(arrival);
        departure=cell2table(departure);
        response=array2table(response);
    
        % Create table
        table_Times=[arrival departure response];
        table_Times=sortrows(table_Times,1);

        
        struct_process(i).process=table_Times;
        struct_process(i).name=name;
    end
   
end

