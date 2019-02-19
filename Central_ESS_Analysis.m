function [Central_Table,Delta_Central,Central_Battery_Stored_kWh] = Central_ESS_Analysis(Number_of_SAPV_Systems,Shared_Hourly_Load,PV_Output,Total_PV_Generation,Battery_Capacity,Battery_Efficiency,Initial_Battery,Solar_Panel_Range,Battery_Cost,Solar_Panel_Cost,SAPV_Analysis,LPSP_Count,Initial_Charge,Interconnection_Cost)
%CENTRAL_ESS_ANALYSIS
%   Acts as one SAPV system with combined loads and PV output. Calculates
%   difference in storage and load, battery required and capital cost.

fprintf('=============================================================================\n')
fprintf('                      CENTRAL ESS ANALYSIS                                  \n')
fprintf('=============================================================================\n')

%Number of Configurations
Number_of_Configurations = size(PV_Output,2);

%Number of Trials
Number_of_Trials = size(PV_Output,3);

%Number of simulation hours
Simulation_Hours = size(Shared_Hourly_Load,1);

%Converts PV_output and Total_PV_Generation to scenario with shared storage
Shared_PV_Output = PV_Output * Number_of_SAPV_Systems;
Shared_Total_PV_Generation = Total_PV_Generation * Number_of_SAPV_Systems;

%Compares energy produced by solar panels with the load
Delta_Central = zeros(Simulation_Hours,Number_of_Configurations,Number_of_Trials);

%Variable gives amount of storage in battery at present time. Begins at
%full charge
Central_Battery_Stored_kWh = zeros(Simulation_Hours,Number_of_Configurations,Number_of_Trials);

%Used in iteration
Shared_Battery = Initial_Battery;

%Variable to count how many hours you are fully charged (Loss of PV
%Generation) and how much solar power is unutilized. Used to calculate %PV
%Utilization.
LOPVG_count_central = zeros(Number_of_Configurations,Number_of_Trials);
LOPVG_loss_central = zeros(Number_of_Configurations,Number_of_Trials);

%Initializes variables for use in tables
Average_Battery_Shared = zeros(Number_of_Configurations,Number_of_Trials);
Average_Solar_Panels = zeros(Number_of_Configurations,Number_of_Trials);
PV_Utilization_central = zeros(Number_of_Configurations,Number_of_Trials);
Total_Solar_Panel_Cost = zeros(Number_of_Configurations,Number_of_Trials);
Total_Battery_Cost = zeros(Number_of_Configurations,Number_of_Trials);
Total_Capital_Cost_central = zeros(Number_of_Configurations,Number_of_Trials); 
Solar_Panel_Cost_per_System = zeros(Number_of_Configurations,Number_of_Trials);
Battery_Cost_per_System = zeros(Number_of_Configurations,Number_of_Trials);
Capital_Cost_per_System = zeros(Number_of_Configurations,Number_of_Trials);

%Initializes excel file to store data so it's not done on every iteration.
%SAPV_Analysis = 'SAPV_Analysis.xlsx';
excel_datapoint = 0;

%Initializes array for use in writing to excel file. xlswrite is slow!
total_datapoints = Number_of_Trials * Number_of_Configurations;
Central_Table = zeros(total_datapoints,17);

for configuration = 1:Number_of_Configurations
    for trial = 1:Number_of_Trials
        
%Variable solved indicates when reliability requirement met
solved = 0;

while solved == 0
    
%Energy Deficit Array. Counts how many hours you are fully discharged%(Loss
%of Storage) and how much energy is lacking. Used to calculate LPSP.
    LOS_count_central = 0;
    LOS_lack_central = 0;

    for hour_central = 1:Simulation_Hours
        Delta_Central(hour_central,configuration,trial) = Shared_PV_Output(hour_central,configuration,trial)-Shared_Hourly_Load(hour_central,trial);
        if hour_central == 1
            Central_Battery_Stored_kWh(hour_central,configuration,trial) = Initial_Charge*Shared_Battery*Battery_Capacity; %Battery not fully charged initially!!
        else
            if Delta_Central(hour_central,configuration,trial)<0
                Central_Battery_Stored_kWh(hour_central,configuration,trial)=max(Central_Battery_Stored_kWh(hour_central-1,configuration,trial)+Delta_Central(hour_central-1,configuration,trial),0);
                if Central_Battery_Stored_kWh(hour_central,configuration,trial) == 0
                    LOS_count_central = LOS_count_central +1;
                    LOS_lack_central = LOS_lack_central + abs(Central_Battery_Stored_kWh(hour_central-1,configuration,trial)+Delta_Central(hour_central-1,configuration,trial));
                end
            else
                Central_Battery_Stored_kWh(hour_central,configuration,trial)=min(Central_Battery_Stored_kWh(hour_central-1,configuration,trial)+(Battery_Efficiency*Delta_Central(hour_central,configuration,trial)),Shared_Battery*Battery_Capacity);
                if Central_Battery_Stored_kWh(hour_central,configuration,trial) == Shared_Battery*Battery_Capacity
                    LOPVG_count_central(configuration,trial) = LOPVG_count_central(configuration,trial) + 1;
                    LOPVG_loss_central(configuration,trial) = LOPVG_loss_central(configuration,trial) + Delta_Central(hour_central,configuration,trial);
                end
            end
        end
    end
    
    if LOS_count_central <= LPSP_Count
        %Total_Energy_Storage_central = Shared_Battery*Battery_Capacity;
        Average_Battery_Shared(configuration,trial) = Shared_Battery/Number_of_SAPV_Systems;
        Total_Solar_Panels_Shared = Number_of_SAPV_Systems * Solar_Panel_Range(configuration);
        Average_Solar_Panels(configuration,trial) = Total_Solar_Panels_Shared/Number_of_SAPV_Systems;
        LPSP_central = (LOS_count_central/Simulation_Hours)*100;
        PV_Utilization_central(configuration,trial) = ((Shared_Total_PV_Generation(configuration,trial)-LOPVG_loss_central(configuration,trial))/Shared_Total_PV_Generation(configuration,trial))*100;
        Total_Solar_Panel_Cost(configuration,trial) = Total_Solar_Panels_Shared*Solar_Panel_Cost;
        Total_Battery_Cost(configuration,trial) = Shared_Battery*Battery_Cost;
        Total_Capital_Cost_central(configuration,trial) = Total_Solar_Panel_Cost(configuration,trial) + Total_Battery_Cost(configuration,trial)+Interconnection_Cost*Number_of_SAPV_Systems; % + Charge_Controller_Cost + Inverter_Cost; 
        Solar_Panel_Cost_per_System(configuration,trial) = Total_Solar_Panel_Cost(configuration,trial)/Number_of_SAPV_Systems;
        Battery_Cost_per_System(configuration,trial) = Total_Battery_Cost(configuration,trial)/Number_of_SAPV_Systems;
        Capital_Cost_per_System(configuration,trial) = Solar_Panel_Cost_per_System(configuration,trial) + Battery_Cost_per_System(configuration,trial)+Interconnection_Cost;
        excel_datapoint = excel_datapoint + 1;
        solved=1;
%==========================================================================        
%       Used to display important information in the Command Window
%==========================================================================
%         fprintf('=============================================================================\n')
%         fprintf('Trial Number = %d, Configuration Number = %d, Centrally Shared Battery\n',trial,configuration)
%         fprintf('=============================================================================\n')
%         fprintf('%d batteries for a total of %2.0f kWh of energy storage\n',Shared_Battery,Total_Energy_Storage_central)
%         fprintf('with %d solar panels results in:\n',Total_Solar_Panels_Shared)
%         fprintf('%d hours of loss of load and %d hours of loss of PV generation\n', LOS_count_central, LOPVG_count_central)
%         fprintf('%5.1f kWh of loss of load and %6.1f kWh of loss of PV generation\n', LOS_lack_central, LOPVG_loss_central)
%         fprintf('%1.3f %%LPSP and %1.1f %%PV Utilization \n',LPSP_central,PV_Utilization_central)
%         fprintf('and an initial capital cost of $%2.0f \n\n',Total_Capital_Cost_central)
        
%--------------------------------------------------------------------------
%                           PLOTS
%--------------------------------------------------------------------------

% Battery Storage, Hourly Load, and PV Output in kWH vs. Time for System 1
%         figure('Name','Central Energy Storage')
%         plot(Central_Battery_Stored_kWh(:,configuration,trial))
%         hold on
%         plot(Shared_Hourly_Load(:,trial))
%         plot(Shared_PV_Output(:,configuration,trial))
%         hold off
%         xlim([0 8760])
%         title('Battery Storage, Hourly Load, and PV Output vs. Time for System 1')
%         xlabel('Time')
%         ylabel('kWh')
%         legend('Battery Storage','Hourly Load','PV Output')
        
%==========================================================================
%                   Used to save data to excel file
%==========================================================================
        Central_Table(excel_datapoint,1) = trial;        
        Central_Table(excel_datapoint,2) = Total_Solar_Panels_Shared;
        Central_Table(excel_datapoint,3) = Average_Solar_Panels(configuration,trial);
        Central_Table(excel_datapoint,4) = Shared_Battery;
        Central_Table(excel_datapoint,5) = Average_Battery_Shared(configuration,trial);
        Central_Table(excel_datapoint,6) = LOS_count_central;
        Central_Table(excel_datapoint,7) = LOPVG_count_central(configuration,trial);
        Central_Table(excel_datapoint,8) = LOS_lack_central;
        Central_Table(excel_datapoint,9) = LOPVG_loss_central(configuration,trial);
        Central_Table(excel_datapoint,10) = LPSP_central;
        Central_Table(excel_datapoint,11) = PV_Utilization_central(configuration,trial);
        Central_Table(excel_datapoint,12) = Total_Solar_Panel_Cost(configuration,trial);
        Central_Table(excel_datapoint,13) = Total_Battery_Cost(configuration,trial);
        Central_Table(excel_datapoint,14) = Total_Capital_Cost_central(configuration,trial);
        Central_Table(excel_datapoint,15) = Solar_Panel_Cost_per_System(configuration,trial);
        Central_Table(excel_datapoint,16) = Battery_Cost_per_System(configuration,trial);
        Central_Table(excel_datapoint,17) = Capital_Cost_per_System(configuration,trial);
%==========================================================================

    else
        Shared_Battery = Shared_Battery +1;
    end
end
Shared_Battery = Initial_Battery;
    end
end

%Writes to the excel file outside of 'For' loop to speed up process.
Column_Names = {'Trial Number','Total Solar Panels','Solar Panels per System','Total Batteries','Batteries per System','LOS Count','LOPVG Count','Loss of Supply (kWh)','LOPVG (kWh)','LPSP','PV Utilization','Total Solar Panel Cost','Total Battery Cost','Total Capital Cost','Solar Panel Cost per System','Battery Cost per System','Capital Cost per System'};
xlswrite(SAPV_Analysis,Column_Names,'Central','A1')
xlswrite(SAPV_Analysis,Central_Table,'Central','A2')

%Finds averages of desired values in order to simplify data manipulation
Averages_datapoints = Number_of_Configurations;
Table_Averages_Baseline = zeros(Averages_datapoints,12);
datapoint = 0;

for configuration = 1:Number_of_Configurations
        datapoint = datapoint +1;
        Table_Averages_Baseline(datapoint,1) = Number_of_SAPV_Systems;
        Table_Averages_Baseline(datapoint,2) = mean(Average_Solar_Panels(configuration,:));        
        Table_Averages_Baseline(datapoint,3) = mean(Average_Battery_Shared(configuration,:));
        Table_Averages_Baseline(datapoint,4) = mean(LOPVG_count_central(configuration,:));
        Table_Averages_Baseline(datapoint,5) = mean(LOPVG_loss_central(configuration,:));
        Table_Averages_Baseline(datapoint,6) = mean(PV_Utilization_central(configuration,:));
        Table_Averages_Baseline(datapoint,7) = mean(Total_Solar_Panel_Cost(configuration,:));
        Table_Averages_Baseline(datapoint,8) = mean(Total_Battery_Cost(configuration,:));
        Table_Averages_Baseline(datapoint,9) = mean(Total_Capital_Cost_central(configuration,:));
        Table_Averages_Baseline(datapoint,10) = mean(Solar_Panel_Cost_per_System(configuration,:));
        Table_Averages_Baseline(datapoint,11) = mean(Battery_Cost_per_System(configuration,:));
        Table_Averages_Baseline(datapoint,12) = mean(Capital_Cost_per_System(configuration,:));
end

%Writes to the excel file outside of 'For' loop to speed up process.
Column_Names_Averages = {'Number of Systems','Solar Panels per System','Battery per System','Average LOPVG Count','Average LOPVG Loss','Average PV Utilization','Total Cost for Solar Panels','Total Cost for Batteries','Total Capital Cost','Average Solar Panel Cost per System','Average Battery Cost per System','Average Capital Cost per System'};
xlswrite(SAPV_Analysis,Column_Names_Averages,'Central','S1')
xlswrite(SAPV_Analysis,Table_Averages_Baseline,'Central','S2')

end


