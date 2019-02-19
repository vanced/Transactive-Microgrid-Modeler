function [Table_IES,delta_IES,IES_Battery_Stored] = IES_Analysis_N_Systems(Hourly_Load,PV_Output,Total_PV_Generation,Battery_Capacity,Battery_Efficiency,Initial_Battery,Solar_Panel_Range,Battery_Cost,Solar_Panel_Cost,SAPV_Analysis,LPSP_Count,Initial_Charge,Interconnection_Cost)
%IES_ANALYSIS
%   Battery State of Charge (SOC) is calculated (every hour), if battery
%   SOC exceeds 100% and no other system can take it that energy is stored
%   in energy excess array, if battery SOC breaks 0% and no other system
%   can sell it the amount of energy not supplied is stored in energy
%   deficit array.

fprintf('=============================================================================\n')
fprintf('                               IES ANALYSIS                                  \n')
fprintf('=============================================================================\n')

%Number of Configurations
Number_of_Configurations = size(PV_Output,2);

%Number of Trials
Number_of_Trials = size(PV_Output,3);

%Number of simulation hours
Simulation_Hours = size(Hourly_Load,1);

%Number of SAPV Systems.
Number_of_SAPV_Systems = size(Hourly_Load,2);

%Compares energy produced by solar panels with the load
delta_IES= zeros(Simulation_Hours,Number_of_SAPV_Systems,Number_of_Configurations,Number_of_Trials);

%Variable gives amount of storage in battery at present time. Begins at
%full charge
IES_Battery_Stored = zeros(Simulation_Hours,Number_of_SAPV_Systems,Number_of_Configurations,Number_of_Trials);

%Used in iteration 
Battery = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
Battery(:) = Initial_Battery;

% Calculates Total Energy Storage, LPSP, PV Utilization and Capital
%     Cost for every system
Total_Energy_Storage = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
LPSP = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
PV_Utilization = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
Total_Solar_Panel_Cost = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
Total_Battery_Cost = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
Capital_Cost = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);

%Variable to count how many hours you are fully charged (Loss of PV
%Generation) and how much solar power is unutilized. Used to calculate %PV
%Utilization.
LOPVG_count = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
LOPVG_loss = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
    
%Variable to count how many times a system buys energy when it is empty and
%sells energy when it is full
System_Buy = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
System_Sell = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
     
%Variable to count how many times a system buys energy when it is not empty and
%sells energy when it is not full
System_Buy_NotEMPTY = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
System_Sell_NotFULL = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);

%Variable counts the total trades by all systems
Total_Trade = zeros(Number_of_Configurations,Number_of_Trials);

%Initializes variables which will be used to take the average of all
%systems
Average_Battery = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_LOPVG_count = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_LOPVG_loss = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_PV_Utilization = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_Panel_Cost = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_Battery_Cost = zeros(Number_of_Configurations,Number_of_SAPV_Systems);
Average_Capital_Cost = zeros(Number_of_Configurations,Number_of_SAPV_Systems);

%Energy Deficit Array. Counts how many hours you are fully discharged%(Loss
%of Storage) and how much energy is lacking. Used to calculate LPSP.
LOS_count = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);
LOS_lack = zeros(Number_of_Configurations,Number_of_Trials,Number_of_SAPV_Systems);

%Initializes excel file to store data so it's not done on every iteration.
%SAPV_Analysis = 'SAPV_Analysis.xlsx';
excel_datapoint = 0;

%Initializes array for use in writing to excel file. xlswrite is slow!
total_datapoints = Number_of_Trials * Number_of_Configurations;
Table_IES = zeros(total_datapoints,16,Number_of_SAPV_Systems);

for configuration = 1:Number_of_Configurations
    for trial = 1:Number_of_Trials

%Variable solved indicates when reliability requirement met
solved = 0;

while solved == 0
    
%Energy Deficit Array. Counts how many hours you are fully discharged%(Loss
%of Storage) and how much energy is lacking. Used to calculate LPSP.
LOS_count(configuration,trial,:) = 0;
LOS_lack(configuration,trial,:) = 0;
     
for hour = 1:Simulation_Hours
    for system = 1:Number_of_SAPV_Systems
    delta_IES(hour,system,configuration,trial) = PV_Output(hour,configuration,trial)-Hourly_Load(hour,system,trial);
    end
    if hour == 1
        for system = 1:Number_of_SAPV_Systems
        IES_Battery_Stored(hour,system,configuration,trial) = Initial_Charge*Battery(configuration,trial,system)*Battery_Capacity; %Battery not fully charged initially!!
        end
    else
        for system = 1:Number_of_SAPV_Systems
            if delta_IES(hour-1,system,configuration,trial) >= 0
                IES_Battery_Stored(hour,system,configuration,trial)=min(IES_Battery_Stored(hour-1,system,configuration,trial)+(Battery_Efficiency*delta_IES(hour-1,system,configuration,trial)),Battery(configuration,trial,system)*Battery_Capacity);
            else
                %Battery Efficiency only considered when charging
                IES_Battery_Stored(hour,system,configuration,trial)=max(IES_Battery_Stored(hour-1,system,configuration,trial)+delta_IES(hour-1,system,configuration,trial),0);
            end
        end
                
            
%A system has no charge
for system = 1:Number_of_SAPV_Systems
    if IES_Battery_Stored(hour,system,configuration,trial)== 0

%If no system can handle the trade, increment LOS_count and LOS_lack, otherwise find a
%system to trade with, initiate the trade, and increment System_Buy and
%System_Sell_NotFULL
[Max_Value,Max_System] = max(IES_Battery_Stored(hour-1,:,configuration,trial));
        if Max_Value <= abs(delta_IES(hour-1,system,configuration,trial)+delta_IES(hour-1,Max_System,configuration,trial))
            LOS_count(configuration,trial,system) = LOS_count(configuration,trial,system) +1;
            LOS_lack(configuration,trial,system) = LOS_lack(configuration,trial,system) + abs(IES_Battery_Stored(hour-1,system,configuration,trial)+delta_IES(hour-1,system,configuration,trial));
        else
            IES_Battery_Stored(hour,Max_System,configuration,trial) = Max_Value+delta_IES(hour-1,system,configuration,trial)+delta_IES(hour-1,Max_System,configuration,trial);
            System_Buy(configuration,trial,system) = System_Buy(configuration,trial,system) +1;
            System_Sell_NotFULL(configuration,trial,Max_System) = System_Sell_NotFULL(configuration,trial,Max_System) +1;
            Total_Trade(configuration,trial) = Total_Trade(configuration,trial) + 1;
        end
    end
end
                        
%A system has full charge
for system = 1:Number_of_SAPV_Systems
    if IES_Battery_Stored(hour,system,configuration,trial) == Battery(configuration,trial,system)*Battery_Capacity

%If no system can handle the trade, increment LOPVG_count and LOPVG_loss, otherwise find a
%system to trade with, initiate the trade, and increment System_Sell and
%System_Buy_NotEMPTY
[Min_Value,Min_System] = min(IES_Battery_Stored(hour-1,:,configuration,trial));
        if (Min_Value + Battery_Efficiency*((delta_IES(hour-1,system,configuration,trial)+(delta_IES(hour-1,Min_System,configuration,trial))))) >= Battery(Min_System)*Battery_Capacity
            LOPVG_count(configuration,trial,system) = LOPVG_count(configuration,trial,system) + 1;
            LOPVG_loss(configuration,trial,system) = LOPVG_loss(configuration,trial,system) + delta_IES(hour,system,configuration,trial);
        else
            IES_Battery_Stored(hour,Min_System,configuration,trial) = Min_Value + Battery_Efficiency*((delta_IES(hour-1,system,configuration,trial))+(delta_IES(hour-1,Min_System,configuration,trial)));
            System_Sell(configuration,trial,system) = System_Sell(configuration,trial,system) +1;
            System_Buy_NotEMPTY(configuration,trial,Min_System) = System_Buy_NotEMPTY(configuration,trial,Min_System) +1;
            Total_Trade(configuration,trial) = Total_Trade(configuration,trial) + 1;
        end
    end
end
    end
end
    
if LOS_count(configuration,trial,:) <= LPSP_Count    %Success!

    excel_datapoint = excel_datapoint + 1;
    solved=1;
    fprintf('%d - %d\n',configuration,trial);
    

    for system = 1:Number_of_SAPV_Systems
        Total_Energy_Storage(configuration,trial,system) = Battery(configuration,trial,system)*Battery_Capacity;
        LPSP(configuration,trial,system) = (LOS_count(configuration,trial,system)/Simulation_Hours)*100;
        PV_Utilization(configuration,trial,system) = ((Total_PV_Generation(configuration,trial)-LOPVG_loss(configuration,trial,system))/Total_PV_Generation(configuration,trial))*100;
        Total_Solar_Panel_Cost(configuration,trial,system) = Solar_Panel_Range(configuration)*Solar_Panel_Cost;
        Total_Battery_Cost(configuration,trial,system) = (Battery(configuration,trial,system)*Battery_Cost);
        Capital_Cost(configuration,trial,system) = Total_Solar_Panel_Cost(configuration,trial,system) + Total_Battery_Cost(configuration,trial,system)+Interconnection_Cost; % Charge_Controller_Cost + Inverter_Cost; 
    end
        
%==========================================================================        
%       Used to display important information in the Command Window
%==========================================================================
% for system = 1:Number_of_SAPV_Systems
%         fprintf('=============================================================================\n')
%         fprintf('Trial Number = %d, Configuration Number = %d, IES System\n',trial,configuration)
%         fprintf('=============================================================================\n')
%         fprintf('%d batteries for a total of %2.0f kWh of energy storage\n',Battery(system),Total_Energy_Storage(system))
%         fprintf('with %2.0f solar panels results in:\n',Solar_Panel_Range(configuration))
%         fprintf('%d hours of loss of supply and %d hours of loss of PV generation\n', LOS_count(system), LOPVG_count(system))
%         fprintf('%5.1f kWh of loss of supply and %1.1f kWh of loss of PV generation\n', LOS_lack(system), LOPVG_loss(system))
%         fprintf('%1.3f %%LPSP and %1.1f %%PV Utilization \n',LPSP(system),PV_Utilization(system))
%         fprintf('and an initial capital cost of $%2.0f dollars \n\n',Capital_Cost(system))
% end
%--------------------------------------------------------------------------
%                           PLOTS
%--------------------------------------------------------------------------

% % Battery Storage, Hourly Load, and PV Output in kWH vs. Time for System 1
%         figure('Name','IES Scenario')
%         subplot(2,1,1)
%         plot(IES_Battery_Stored_1(:,configuration,trial))
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
% % Battery Storage, Hourly Load, and PV Output in kWH vs. Time for System 1        
%         subplot(2,1,2)
%         plot(IES_Battery_Stored_2(:,configuration,trial))
%         hold on
%         plot(Hourly_Load(:,2,trial))
%         plot(PV_Output(:,configuration,trial))
%         hold off
%         xlim([0 8760])
%         title('Battery Storage, Hourly Load, and PV Output vs. Time for System 2')
%         xlabel('Time')
%         ylabel('kWh')
%         legend('Battery Storage','Hourly Load','PV Output')
             
%==========================================================================
%                   Used to save data to excel file
%==========================================================================
for system = 1:Number_of_SAPV_Systems
    Table_IES(excel_datapoint,1,system) = trial;
    Table_IES(excel_datapoint,2,system) = Solar_Panel_Range(configuration);
    Table_IES(excel_datapoint,3,system) = Battery(configuration,trial,system);
    Table_IES(excel_datapoint,4,system) = LOS_count(configuration,trial,system);
    Table_IES(excel_datapoint,5,system) = LOPVG_count(configuration,trial,system);
    Table_IES(excel_datapoint,6,system) = LOS_lack(configuration,trial,system);
    Table_IES(excel_datapoint,7,system) = LOPVG_loss(configuration,trial,system);
    Table_IES(excel_datapoint,8,system) = LPSP(configuration,trial,system);
    Table_IES(excel_datapoint,9,system) = PV_Utilization(configuration,trial,system);
    Table_IES(excel_datapoint,10,system) = Total_Solar_Panel_Cost(configuration,trial,system);
    Table_IES(excel_datapoint,11,system) = Total_Battery_Cost(configuration,trial,system);
    Table_IES(excel_datapoint,12,system) = Capital_Cost(configuration,trial,system);
    Table_IES(excel_datapoint,13,system) = System_Buy(configuration,trial,system);
    Table_IES(excel_datapoint,14,system) = System_Sell(configuration,trial,system);
    Table_IES(excel_datapoint,15,system) = System_Buy_NotEMPTY(configuration,trial,system);
    Table_IES(excel_datapoint,16,system) = System_Sell_NotFULL(configuration,trial,system);
end
%==========================================================================
end
    
%If the system did not meet reliability requirement, increment battery.
for system = 1:Number_of_SAPV_Systems
    if LOS_count(configuration,trial,system) > LPSP_Count 
          Battery(configuration,trial,system) = Battery(configuration,trial,system) +1;    %Else the number of batteries does not meet the LPSP requirement.
    end
end
end
    end
end

%Writes to the excel file outside of 'For' loop to speed up process.
Column_Names = {'Trial Number','Solar Panels','Batteries','LOS Count','LOPVG Count','Loss of Supply (kWh)','LOPVG (kWh)','LPSP','PV Utilization','Solar Panel Cost','Battery Cost','Capital Cost','System_Buy','System_Sell','System_Buy_NotEMPTY','System_Sell_NotFULL'};
xlswrite(SAPV_Analysis,Column_Names,'IES','A1')
xlswrite3(SAPV_Analysis,Table_IES,'IES','A2',1)

%Finds averages of desired values for each system in order to simplify data manipulation
Averages_datapoints = Number_of_Configurations * Number_of_SAPV_Systems;
Table_Averages_IES = zeros(Averages_datapoints,9);
datapoint = 0;

for system = 1:Number_of_SAPV_Systems
    for configuration = 1:Number_of_Configurations
        datapoint = datapoint +1;
        Table_Averages_IES(datapoint,1) = system;
        Table_Averages_IES(datapoint,2) = Solar_Panel_Range(configuration);
        Table_Averages_IES(datapoint,3) = mean(Battery(configuration,:,system));
        Table_Averages_IES(datapoint,4) = mean(LOPVG_count(configuration,:,system));
        Table_Averages_IES(datapoint,5) = mean(LOPVG_loss(configuration,:,system));
        Table_Averages_IES(datapoint,6) = mean(PV_Utilization(configuration,:,system));
        Table_Averages_IES(datapoint,7) = mean(Total_Solar_Panel_Cost(configuration,:,system));
        Table_Averages_IES(datapoint,8) = mean(Total_Battery_Cost(configuration,:,system));
        Table_Averages_IES(datapoint,9) = mean(Capital_Cost(configuration,:,system));
        
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
Column_Names_Averages = {'System','Solar Panels','Average Batteries','Average LOPVG Count',',Average LOPVG Loss','Average PV Utilization','Average Cost for Solar Panels','Average Cost for Batteries','Average Capital Cost'};
xlswrite(SAPV_Analysis,Column_Names_Averages,'IES','R1')
xlswrite(SAPV_Analysis,Table_Averages_IES,'IES','R2')

%Finds averages of desired values for every system in order to simplify data manipulation
Average_Systems_datapoints = Number_of_Configurations;
Table_Systems_IES = zeros(Average_Systems_datapoints,8);
datapoint = 0;

for configuration = 1:Number_of_Configurations
        datapoint = datapoint +1;
        Table_Systems_IES(datapoint,1) = Solar_Panel_Range(configuration);
        Table_Systems_IES(datapoint,2) = mean(Average_Battery(configuration,:));
        Table_Systems_IES(datapoint,3) = mean(Average_LOPVG_count(configuration,:));
        Table_Systems_IES(datapoint,4) = mean(Average_LOPVG_loss(configuration,:));
        Table_Systems_IES(datapoint,5) = mean(Average_PV_Utilization(configuration,:));
        Table_Systems_IES(datapoint,6) = mean(Average_Panel_Cost(configuration,:));
        Table_Systems_IES(datapoint,7) = mean(Average_Battery_Cost(configuration,:));
        Table_Systems_IES(datapoint,8) = mean(Average_Capital_Cost(configuration,:));
        Table_Systems_IES(datapoint,9) = mean(Total_Trade(configuration,:));
end

%Writes to the excel file outside of 'For' loop to speed up process.
Column_Names_Systems = {'Solar Panels','Average Batteries','Average LOPVG Count','Average LOPVG Loss','Average PV Utilization','Average Cost for Solar Panels','Average Cost for Batteries','Average Capital Cost','Total Trades'};
xlswrite(SAPV_Analysis,Column_Names_Systems,'IES','AB1')
xlswrite(SAPV_Analysis,Table_Systems_IES,'IES','AB2')

% plot(Table_Averages(:,2),Table_Averages(:,3))
% hold
end