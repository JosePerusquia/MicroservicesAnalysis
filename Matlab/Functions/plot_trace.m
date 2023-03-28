function plot_trace(table_features)

%Plots a distributed trace comprised of processes, threads and events, from
%a structure created through the trace_features.m file.

    n=height(table_features);
    times=milliseconds(table_features.arrival-table_features.arrival(1));
    
    unique_processes=unique(table_features.process,'stable');
    no_unique_processes=length(unique_processes);
    
    unique_thread=unique(table_features.thread,'stable');
    no_unique_thread=length(unique_thread);
    
    group_threads=[];
    color_threads=[];
    for i=1:no_unique_processes
        threads=unique(table_features.thread(table_features.process==unique_processes(i)),'stable');
        group_threads=[group_threads;threads];
        color_threads=[color_threads repelem(i,length(threads))];
    end
    
    y=zeros(n,1);
    
    for i = 1:no_unique_thread
        y(table_features.thread==group_threads(i))=no_unique_thread+1-i;
    end
    
    plot(times,y,'k.','MarkerSize',15)
        
    hold on    
    ylim([0,no_unique_thread+1])
    xlim([-5,5+ceil(times(end))])
    yticks([1:22])
    yticklabels(string(flip(unique_thread)))
    
    %Since some nodes contain two parents we plot parent 1 first, if the
    %parent's process is different a red line is used, otherwise a blue
    %line is used.
    
    for i=2:n
        index=table_features.id==table_features.parent_1(i);
       if table_features.process(index)==table_features.process(i)
           plot([times(index),times(i)],[y(index),y(i)],'b-','MarkerSize',10)
       else
           plot([times(index),times(i)],[y(index),y(i)],'r-','MarkerSize',10)
       end
    end
    
    %The same process for the second parent.
    
    for i=2:n
        if table_features.parent_2(i)~=""
            index=table_features.id==table_features.parent_2(i);
    
            if table_features.process(index)==table_features.process(i)
                plot([times(index),times(i)],[y(index),y(i)],'b-','MarkerSize',10)
            else
                plot([times(index),times(i)],[y(index),y(i)],'r-','MarkerSize',10)
            end
        end
    end
    
    %We select random colours for each process. This can be modified for
    %each process to have its unique colour once we know all the different
    %processes present in the data.
    
    colors=[rand(no_unique_processes,3)];
    
    x_1=5+ceil(times(end));
    f = [1 2 3 4];
    for i=1:no_unique_thread
       v = [-5 no_unique_thread+.5-i; -5 no_unique_thread+1.5-i; x_1 no_unique_thread+1.5-i ; x_1 no_unique_thread+.5-i];
       patch('Faces',f,'Vertices',v,'FaceColor',colors(color_threads(i),:),'FaceAlpha',.25);
    end
    hold off
end

