function [Baseline_Table,Delta_baseline,Baseline_Battery_Stored] = Baseline_ESS_Analysis(Hourly_Load,PV_Output,Total_PV_Generation,Battery_Capacity,Battery_Efficiency,Initial_Battery,Solar_Panel_Range,Battery_Cost,Solar_Panel_Cost,SAPV_Analysis,LPSP_Count,Initial_Charge)
%BASELINE_ESS_ANALYSIS
%   Battery State of Charge (SOC) is calculated (every hour), if battery
%   SOC exceeds 100% that energy is stored in energy excess array, if
%   battery SOC breaks 0% the amount of energy not supplied is stored in
%   energy deficit array.

fprintf('=============================================================================\n')
fprintf('                      BASELINE ESS ANALYSIS                                  \n')
fprintf('=============================================================================\n')

%Number of Configurations
Number_of_Configurations = size(PV_Output,2);

%Number of Trials
Number_of_Trials = size(PV_Output,3);

%Number of simulation hours
Simulation_Hours = size(Hourly_Load,1);

%Number of SAPV Systems
Number_of_SAPV_Systems = size(Hourly_Load,2);

%Compares energy produced by solar panels with the load
Delta_baseline= zeros(Simulation_Hours,Number_of_SAPV_Systems,Number_of_Configurations,Number_of_Trials); 

%Variable gives amount of storage in battery at present time. Begins at
%full charge
Baseline_Battery_Stored = zeros(Simulation_Hours,Number_of_SAPV_Systems,Number_of_Configurations,Number_of_Trials);

%Used in iteration 
Battery = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
Battery(:) = Initial_Battery;

%Counts how many hours you are fully charged (Loss of PV Generation) and
%how much solar power is unutilized. Used to calculate %PV Utilization.
LOPVG_count = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
LOPVG_loss = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
PV_Utilization = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);

%Declares cost variables so averages can be taken
Total_Solar_Panel_Cost = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
Total_Battery_Cost = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
Capital_Cost = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);

%Initializes variables which will be used to take the average of all
%systems
Average_Battery = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_LOPVG_count = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_LOPVG_loss = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_PV_Utilization = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_Panel_Cost = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_Battery_Cost = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_Capital_Cost = zeros(Number_of_Configurations,Number_of_SAPV_Systems);

%Initializes excel file to store data so it's not done on every iteration.
%SAPV_Analysis = 'SAPV_Analysis.xlsx';
excel_datapoint = 1;

%Initializes array for use in writing to excel file. xlswrite is slow!
total_datapoints = Number_of_Trials * Number_of_Configurations;
Baseline_Table = zeros(total_datapoints,12,Number_of_SAPV_Systems);

for configuration = 1:Number_of_Configurations
    for trial = 1:Number_of_Trials
        for system = 1:Number_of_SAPV_Systems
            
%Variable solved indicates when reliability requirement met
solved = 0;

while solved == 0
    
%Energy Deficit Array. Counts how many hours you are fully discharged%(Loss
%of Storage) and how much energy is lacking. Used to calculate LPSP.
LOS_count = 0;
LOS_lack = 0;

    for hour = 1:Simulation_Hours
        Delta_baseline(hour,system,configuration,trial) = PV_Output(hour,configuration,trial)-Hourly_Load(hour,system,trial);
        if hour == 1
            Baseline_Battery_Stored(hour,system,configuration,trial) = Initial_Charge*Battery(configuration,trial,system)*Battery_Capacity; %Battery not shipped fully charged!
        else
            if Delta_baseline(hour-1,system,configuration,trial)<0
                %Battery Efficiency only considered when charging
                Baseline_Battery_Stored(hour,system,configuration,trial)=max(Baseline_Battery_Stored(hour-1,system,configuration,trial)+Delta_baseline(hour-1,system,configuration,trial),0);
                if Baseline_Battery_Stored(hour,system,configuration,trial) == 0
                    LOS_count = LOS_count +1;
                    LOS_lack = LOS_lack + abs(Baseline_Battery_Stored(hour-1,system,configuration,trial)+Delta_baseline(hour-1,system,configuration,trial));
                end
            else
                Baseline_Battery_Stored(hour,system,configuration,trial)=min(Baseline_Battery_Stored(hour-1,system,configuration,trial)+(Battery_Efficiency*Delta_baseline(hour-1,system,configuration,trial)),Battery(configuration,trial,system)*Battery_Capacity);
                if Baseline_Battery_Stored(hour,system,configuration,trial) == Battery*Battery_Capacity
                    LOPVG_count(configuration,trial,system) = LOPVG_count(configuration,trial,system) + 1;
                    LOPVG_loss(configuration,trial,system) = LOPVG_loss(configuration,trial,system) + Delta_baseline(hour,system,configuration,trial);
                end
            end
        end
    end
    
    if LOS_count <= LPSP_Count
        %Total_Energy_Storage = Battery(configuration,trial,system)*Battery_Capacity;
        LPSP = (LOS_count/Simulation_Hours)*100;
        PV_Utilization(configuration,trial,system) = ((Total_PV_Generation(configuration,trial)-LOPVG_loss(configuration,trial,system))/Total_PV_Generation(configuration,trial))*100;
        Total_Solar_Panel_Cost(configuration,trial,system) = (Solar_Panel_Range(configuration)*Solar_Panel_Cost);
        Total_Battery_Cost(configuration,trial,system) = Battery(configuration,trial,system)*Battery_Cost;
        Capital_Cost(configuration,trial,system) = Total_Solar_Panel_Cost(configuration,trial,system) + Total_Battery_Cost(configuration,trial,system); % + Charge_Controller_Cost + Inverter_Cost; 
        solved=1;
%==========================================================================        
%       Used to display important information in the Command Window
%==========================================================================
%         fprintf('=============================================================================\n')
%         fprintf('Trial Number = %d, Configuration Number = %d, SAPV System Number = %d\n',trial,configuration,system)
%         fprintf('=============================================================================\n')
%         fprintf('%d batteries for a total of %2.0f kWh of energy storage\n',Battery,Total_Energy_Storage)
%         fprintf('with %2.0f solar panels results in:\n',Solar_Panel_Range(configuration))
%         fprintf('%d hours of loss of supply and %d hours of loss of PV generation\n', LOS_count, LOPVG_count)
%         fprintf('%5.1f kWh of loss of supply and %1.1f kWh of loss of PV generation\n', LOS_lack, LOPVG_loss)
%         fprintf('%1.3f %%LPSP and %1.1f %%PV Utilization \n',LPSP,PV_Utilization)
%         fprintf('and an initial capital cost of $%2.0f dollars \n\n',Capital_Cost)
        
%--------------------------------------------------------------------------
%                           PLOTS
%--------------------------------------------------------------------------
% if system == 2
% % Battery Storage, Hourly Load, and PV Output in kWH vs. Time for System 1
%         figure('Name','Baseline')
%         subplot(2,1,1)
%         plot(Baseline_Battery_Stored(:,1,configuration,trial))
%         hold on
%         plot(Hourly_Load(:,1,trial))
%         plot(PV_Output(:,configuration,trial))
%         hold off
%         xlim([0 8760])
%         title('Battery Storage, Hourly Load, and PV Output vs. Time for System 1')
%         xlabel('Time')
%         ylabel('kWh')
%         legend('Battery Storage','Hourly Load','PV Output')
%         
% % Battery Storage, Hourly Load, and PV Output in kWH vs. Time for System 2        
%         subplot(2,1,2)
%         plot(Baseline_Battery_Stored(:,2,configuration,trial))
%         hold on
%         plot(Hourly_Load(:,2,trial))
%         plot(PV_Output(:,configuration,trial))
%         hold off
%         xlim([0 8760])
%         title('Battery Storage, Hourly Load, and PV Output vs. Time for System 2')
%         xlabel('Time')
%         ylabel('kWh')
%         legend('Battery Storage','Hourly Load','PV Output')
% end      
%==========================================================================
%                   Used to save data to excel file
%==========================================================================
        Baseline_Table(excel_datapoint,1,system) = trial;
        Baseline_Table(excel_datapoint,2,system) = Solar_Panel_Range(configuration);
        Baseline_Table(excel_datapoint,3,system) = Battery(configuration,trial,system);
        Baseline_Table(excel_datapoint,4,system) = LOS_count;
        Baseline_Table(excel_datapoint,5,system) = LOPVG_count(configuration,trial,system);
        Baseline_Table(excel_datapoint,6,system) = LOS_lack;
        Baseline_Table(excel_datapoint,7,system) = LOPVG_loss(configuration,trial,system);
        Baseline_Table(excel_datapoint,8,system) = LPSP;
        Baseline_Table(excel_datapoint,9,system) = PV_Utilization(configuration,trial,system);
        Baseline_Table(excel_datapoint,10,system) = Total_Solar_Panel_Cost(configuration,trial,system);
        Baseline_Table(excel_datapoint,11,system) = Total_Battery_Cost(configuration,trial,system);
        Baseline_Table(excel_datapoint,12,system) = Capital_Cost(configuration,trial,system);  
%==========================================================================
    
          else
        Battery(configuration,trial,system) = Battery(configuration,trial,system) +1;    %Else the number of batteries does not meet the LPSP requirement.
    end
end
        end
        excel_datapoint = excel_datapoint + 1;
    end
end

%Writes to the excel file outside of 'For' loop to speed up process.
Column_Names = {'Trial Number','Solar Panels','Batteries','LOS Count','LOPVG Count','Loss of Supply (kWh)','LOPVG (kWh)','LPSP','PV Utilization','Total Solar Panel Cost','Total Battery Cost','Capital Cost'};
xlswrite(SAPV_Analysis,Column_Names,'Baseline','A1')
xlswrite3(SAPV_Analysis,Baseline_Table,'Baseline','A2',1)

%Finds averages of desired values for each system in order to simplify data manipulation
Averages_datapoints = Number_of_Configurations * Number_of_SAPV_Systems;
Table_Averages_Baseline = zeros(Averages_datapoints,9);
datapoint = 0;

for system = 1:Number_of_SAPV_Systems
    for configuration = 1:Number_of_Configurations
        datapoint = datapoint +1;
        Table_Averages_Baseline(datapoint,1) = system;
        Table_Averages_Baseline(datapoint,2) = Solar_Panel_Range(configuration);
        Table_Averages_Baseline(datapoint,3) = mean(Battery(configuration,:,system));
        Table_Averages_Baseline(datapoint,4) = mean(LOPVG_count(configuration,:,system));
        Table_Averages_Baseline(datapoint,5) = mean(LOPVG_loss(configuration,:,system));
        Table_Averages_Baseline(datapoint,6) = mean(PV_Utilization(configuration,:,system));
        Table_Averages_Baseline(datapoint,7) = mean(Total_Solar_Panel_Cost(configuration,:,system));
        Table_Averages_Baseline(datapoint,8) = mean(Total_Battery_Cost(configuration,:,system));
        Table_Averages_Baseline(datapoint,9) = mean(Capital_Cost(configuration,:,system));
        
        Average_Battery(configuration,system) = mean(Battery(configuration,:,system));
        Average_LOPVG_count(configuration,system) = mean(LOPVG_count(configuration,:,system));
        Average_LOPVG_loss(configuration,system) = mean(LOPVG_loss(configuration,:,system));
        Average_PV_Utilization(configuration,system) = mean(PV_Utilization(configuration,:,system));
        Average_Panel_Cost(configuration,system) = mean(Total_Solar_Panel_Cost(configuration,:,system));
        Average_Battery_Cost(configuration,system) = mean(Total_Battery_Cost(configuration,:,system));
        Average_Capital_Cost(configuration,system) = mean(Capital_Cost(configuration,:,system));
    end
end

%Writes to the excel file outside of 'For' loop to speed up process.
Column_Names_Averages = {'System','Solar Panels','Average Batteries','Average LOPVG Count','Average LOPVG loss','Average PV Utilization','Average Cost for Solar Panels','Average Cost for Batteries','Average Capital Cost'};
xlswrite(SAPV_Analysis,Column_Names_Averages,'Baseline','N1')
xlswrite(SAPV_Analysis,Table_Averages_Baseline,'Baseline','N2')

%Finds averages of desired values for every system in order to simplify data manipulation
Average_Systems_datapoints = Number_of_Configurations;
Table_Systems_Baseline = zeros(Average_Systems_datapoints,8);
datapoint = 0;

for configuration = 1:Number_of_Configurations
        datapoint = datapoint +1;
        Table_Systems_Baseline(datapoint,1) = Solar_Panel_Range(configuration);
        Table_Systems_Baseline(datapoint,2) = mean(Average_Battery(configuration,:));
        Table_Systems_Baseline(datapoint,3) = mean(Average_LOPVG_count(configuration,:,:));
        Table_Systems_Baseline(datapoint,4) = mean(Average_LOPVG_loss(configuration,:,:));
        Table_Systems_Baseline(datapoint,5) = mean(Average_PV_Utilization(configuration,:,:));
        Table_Systems_Baseline(datapoint,6) = mean(Average_Panel_Cost(configuration,:,:));
        Table_Systems_Baseline(datapoint,7) = mean(Average_Battery_Cost(configuration,:,:));
        Table_Systems_Baseline(datapoint,8) = mean(Average_Capital_Cost(configuration,:));
end

%Writes to the excel f+ile outside of 'For' loop to speed up process.
Column_Names_Systems = {'Solar Panels','Average Batteries','Average LOPVG Count','Average LOPVG loss','Average PV Utilization','Average Cost for Solar Panels','Average Cost for Batteries','Average Capital Cost'};
xlswrite(SAPV_Analysis,Column_Names_Systems,'Baseline','X1')
xlswrite(SAPV_Analysis,Table_Systems_Baseline,'Baseline','X2')

end

