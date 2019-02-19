function [Hourly_Load, Shared_Hourly_Load] = Load_Demand_Simulator(Number_of_trials,Number_of_SAPV_Systems,Simulation_years,Load_Data)
%LOAD_DEMAND_SIMULATOR
%   Load demand is simulated once for each SAPV system based on typical
%residential load profile.

Load_Data_offset = zeros(8760,Number_of_SAPV_Systems,Number_of_trials);

% For no variability
% for trial = 1:Number_of_trials
%     for system = 1:(Number_of_SAPV_Systems)
%         Load_Data_offset(:,system,trial) = Load_Data;
%     end
% end

%For variability
for trial = 1:Number_of_trials
    for system = 1:(Number_of_SAPV_Systems)
        random_hour = randi(5); %Generates random number between (a,b) where random = a+(b-a)*rand()
        Load_Data_offset(:,system,trial) = circshift(Load_Data,random_hour-3); % circshift(A,3) 'lags by three hours'
        random_day = randi(5);
        Load_Data_offset(:,system,trial) = circshift(Load_Data,24*(random_day-3));
    end
end

%Initialize variable Hourly_Load which will be output
Hourly_Load = zeros(8760*Simulation_years,Number_of_SAPV_Systems,Number_of_trials);
Shared_Hourly_Load = zeros(8760*Simulation_years,Number_of_trials);

%Initialize variable datapoints, similiarly to
%Solar_Irradiation_Cum_STM_Generator.
datapoints = 0;

%Populates the variable Hourly_Load with historical data
for trial = 1:Number_of_trials
    for year = 1:Simulation_years
        for day_number =1:365
            for hour_number = 1:24
                datapoints = datapoints +1;
                for system = 1:Number_of_SAPV_Systems
                    Hourly_Load(datapoints+8760*(year-1),system,trial) = round(Load_Data_offset(datapoints,system,trial),3); 
                    Shared_Hourly_Load(datapoints+8760*(year-1),trial) = Shared_Hourly_Load(datapoints+8760*(year-1),trial) + Hourly_Load(datapoints+8760*(year-1),system,trial);
                end
            end
        end
        datapoints = 0;
    end
end

end