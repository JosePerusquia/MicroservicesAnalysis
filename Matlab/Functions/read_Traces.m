function structure = read_Traces(path)

files=dir(fullfile(path,'*.json'));  % Reads all the json files in the directory.
no_files=length(files);              % Number of files in the directory.
structure(no_files)=struct();        % Structure containing the information of the traces.

for j = 1:no_files
    name=files(j).name;                 % Access the name of the i-th file.
    name_aux=split(name,'.');           % Split the name
    structure(j).name=name_aux{1};     

    fid = fopen(strcat(path,name));
    raw = fread(fid,inf); 
    str = char(raw'); 
    fclose(fid); 
    val = jsondecode(str);              %Structure containing the information of the file

    structure(j).id=val.id;  
    no_reports=length(val.reports);     %Number of reports of the trace
    structure(j).no_reps=no_reports;
    features=struct();
    
    microServices=strings(1,no_reports);
    operations=strings(1,no_reports);
    threads=zeros(1,no_reports);
    HRT=zeros(1,no_reports);
    eventID=strings(1,no_reports);
    parentsID=cell(1,no_reports);
    entries=strings(1,no_reports);
    

    for i = 1:no_reports
      events=val.reports(i);
      
      if isfield(events{1},'Operation')
           operations(i)=events{1}.Operation;
      end

      if isfield(events{1},'ParentEventID')
           parentsID{i}=events{1}.ParentEventID;
      else
           parentsID{i}='';
      end
      
      if isempty(events{1}.ProcessName)
          microServices(i)='Reference';
      else
          microServices(i)=events{1}.ProcessName;
      end
      
      entries(i)=events{1}.Agent;
      threads(i)=events{1}.ThreadID;
      eventID(i)=events{1}.EventID;
      HRT(i)=events{1}.HRT;
      
    end

    features.Operations=operations;
    features.Threads=threads;
    features.Services=microServices;
    features.eventID=eventID;
    features.parentsID=parentsID;
    features.HRT=HRT;
    features.Agents=entries;

    structure(j).feats=features;
    structure(j).initial_Time=min(HRT);
    structure(j).last_Time=max(HRT);

end
end

