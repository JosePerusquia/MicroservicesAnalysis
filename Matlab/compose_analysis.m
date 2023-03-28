%% Script to read the traces inside the compose folder

% Add the path to where the functions are located
addpath(cd+"/Functions");

% Change current folder to the data folder
cd ../x-traces/compose/individual/
path=cd+"/";

%% Reads all the traces
compose=read_Traces(path);
no_files=length(compose);

%% Plots the first trace
trace1=task_features(compose(1).feats,compose(1).no_reps);
plot_trace(trace1)

%% More detailed analysis by finding traces with different number of services used
detailed_traces=trace_processes(compose);

num_processes=zeros(no_files,1);
for i=1:no_files
    num_processes(i)=length(unique(compose(i).feats.Services));
end

different_traces=find(num_processes~=10);
% 4 traces contain less processes: 1058,1498,1771,1920

% Plot the traces that are different
plot_trace(detailed_traces(1058).processes)
plot_trace(detailed_traces(1498).processes)
plot_trace(detailed_traces(1771).processes)
plot_trace(detailed_traces(1920).processes)


%% We extract the overall response time in each Service
indices=setdiff(1:no_files,different_traces);
processes=unique(compose(1).feats.Services,'stable');
resp_time_processes=resp_processes(detailed_traces(indices),processes);

for i=1:10
    subplot(5,2,i)
    plot(resp_time_processes(i).process.arrival(1:135),resp_time_processes(i).process.response(1:135),'.','MarkerSize',20)
    title(processes(i),'FontSize',10)
    ylabel('Response Time','FontSize',10)
    xlabel('Time','FontSize',10)
end
