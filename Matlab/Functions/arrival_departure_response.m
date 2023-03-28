function table_Times= arrival_departure_response(struct)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
    n=length(struct);
    arrival=cell(n,1);
    departure=cell(n,1);
    response=zeros(n,1);
    
    for i = 1:n
        initial=datetime(struct(i).initial_Time/1000000000,'ConvertFrom','posixTime','Format','dd-MM-yyyy HH:mm:ss.SSSSSSSSS');
        arrival{i}=initial;

        last=datetime(struct(i).last_Time/1000000000,'ConvertFrom','posixTime','Format','dd-MM-yyyy HH:mm:ss.SSSSSSSSS');
        departure{i}=last;
        response(i)=milliseconds(last-initial);
    end
    
    % Transform them into tables
    arrival=cell2table(arrival);
    departure=cell2table(departure);
    response=array2table(response);
    
    % Create table
    table_Times=[arrival departure response];
    
    % Sort table with respect to arrival times
    
    table_Times=sortrows(table_Times,1);
    
end 

