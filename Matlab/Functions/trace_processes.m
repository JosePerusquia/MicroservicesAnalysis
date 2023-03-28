function trace_features = trace_processes(structure)

%This function creates a suitable structure for each trace in order to be
%plotted.

    n=length(structure);
    trace_features(n)=struct();
    
    for i=1:n
       trace_features(i).processes=task_features(structure(i).feats,structure(i).no_reps);
    end
    
end

