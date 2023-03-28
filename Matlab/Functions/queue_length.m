function table_Queue = queue_length(table_times)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    n=height(table_times);
    Queue_aux=[ones(1,n),-1*ones(1,n)];
    event_times=[table_times.arrival;table_times.departure];
    [event_sort,K]=sort(event_times);
    Queue_aux=Queue_aux(K);
    Queue=cumsum(Queue_aux);
    table_Queue=table(event_sort,transpose(Queue),transpose(Queue_aux),'VariableNames',{'Time','Queue','Arr_or_Dep'});
end

