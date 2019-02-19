%Main.m
clc

%=========================================================================
% This main project file simulates the sizing of multiple SAPV
% systems for 3 possible cases: Isolated Self Consumption (Baseline),
% Centralized Energy Sharing, and Interconnected Energy Sharing.
%=========================================================================

%Excel File Name
SAPV_Analysis = 'LittleRock_20Systems_100Trials_90hours_June_10percentCharge_2.xlsx';
% SAPV_Analysis = 'Phoenix_Baseline_100trials_90hours_June_10percentcharge_2.xlsx';
% SAPV_Analysis = 'Indianapolis_100Systems_100Trials_90hours_June_10percentCharge_1.xlsx';
% SAPV_Analysis = 'Indianapolis_5Systems_100Trials_9hours_June_10percentcharge_NoVariability_2.xlsx';

%Number of SAPV systems to optimize. For Baseline, usually do 1 system
Number_of_SAPV_Systems = 20; 

%Number of trials to perform. Computation time should be considered. 
Number_of_Trials = 100;

%Number of acceptable outage hours. 
LPSP_Count = 90;
%9 hours ensures ~0.1% LPSP reliability
%18 hours ensures ~0.2% LPSP reliability
%27 hours ensures ~0.3% LPSP reliability
%36 hours ensures ~0.4% LPSP reliability
%45 hours ensures ~0.5% LPSP reliability
%90 hours ensures ~1% LPSP reliability

%Initial Charge, given as percentage of total battery capacity. 0.5 = 50%
%Baseline is 0.1 = 10%
Initial_Charge = 0.1;

Months = [30 31 31 30 31 30 31 31 28 31 30 31]; %Months must correspond with correct starting month!!
%Months = [31 28 31 30 31 30 31 31 30 31 30 31]; Corresponds with January
%Months = [28 31 30 31 30 31 31 30 31 30 31 31]; Corresponds with February
%Months = [31 30 31 30 31 31 30 31 30 31 31 28]; Corresponds with March
%Months = [30 31 30 31 31 30 31 30 31 31 28 31]; Corresponds with April
%Months = [31 30 31 31 30 31 30 31 31 28 31 30]; Corresponds with May
%Months = [30 31 31 30 31 30 31 31 28 31 30 31]; Corresponds with June
%Months = [31 31 30 31 30 31 31 28 31 30 31 30]; Corresponds with July
%Months = [31 30 31 30 31 31 28 31 30 31 30 31]; Corresponds with August
%Months = [30 31 30 31 31 28 31 30 31 30 31 31]; Corresponds with September
%Months = [31 30 31 31 28 31 30 31 30 31 31 30]; Corresponds with October
%Months = [30 31 31 28 31 30 31 30 31 31 30 31]; Corresponds with November
%Months = [31 31 28 31 30 31 30 31 31 30 31 30]; Corresponds with December

%Monthpoint is used to quickly change the initial month
Monthpoint = -3624;
%circshift(A,Monthpoint)
%circshift(A,0) = January 1st, 1 AM
%circshift(A,-744) = February 1st, 1 AM
%circshift(A,-1416) = March 1st, 1 AM
%circshift(A,-2160) = April 1st, 1 AM
%circshift(A,-2880) = May 1st, 1 AM
%circshift(A,-3624) = June 1st, 1 AM
%circshift(A,-4344) = July 1st, 1 AM
%circshift(A,-5088) = August 1st, 1 AM
%circshift(A,-5832) = September 1st, 1 AM
%circshift(A,-6552) = October 1st, 1 AM
%circshift(A,-7296) = November 1st, 1 AM
%circshift(A,-8016) = December 1st, 1 AM

%Whole number of years you wish to simulate results. (typically 1)
Simulation_years = 1;
if Simulation_years ~= 1
    fprintf('Warning: Simulation years are not equal to 1!!\n\n')
end

%TMY3_Input stores Solar and Load data for use in simulation from TMY3
[Solar_Data,Load_Data] = TMY3_Input(Monthpoint);

%=========================================================================
%Component Specifications for Solar Panels, Battery, Charge Controller,
%Inverter, and Wiring. Range of PV configurations is input, initial guess
%for required battery capacity is input. Each SAPV system is considered to
%have the same component specifications.
Component_Specifications;

%=========================================================================
%Solar Irradiation and PV output are simulated based on historical data.

%Generates a cumulative STM based on the provided solar data. Maximum_Solar
%gives the largest value of solar irradiation in the dataset
[Maximum_Solar,Big_Cumulative_STM] = Solar_Cumulative_STM_Generator(Solar_Data,Months); %,Months,Number_of_years

%Takes the cumulative STM from 'Solar_Irradiation_Cum_STM_Generator' and
%generates simulation results. 
Solar = Solar_Irradiation_Simulator(Number_of_Trials,Simulation_years,Maximum_Solar,Big_Cumulative_STM,Months);

%PV output energy for each possible PV configuration is calculated (every
%hour) based on solar irradiation simulated. Total_PV_Generation is the
%total PV output from each system over the whole simulation. (Used to
%calculate %PV Generation Utilization.)
[PV_Output,Total_PV_Generation] = PV_Output_Calculator(Solar,Number_of_Trials,Solar_Panel_Range,Solar_Panel_Rating,PV_Derating_Factor); %Solar_Panel_Rating not used

%=========================================================================
%Load demand is simulated once for each SAPV system based on typical
%residential load profile and then for the central battery case. 
[Hourly_Load,Shared_Hourly_Load] = Load_Demand_Simulator(Number_of_Trials,Number_of_SAPV_Systems,Simulation_years,Load_Data);

%==========================================================================
% Baseline: Energy storage analysis is performed based on the PV output
% energy and load demand required. Battery State of Charge (SOC) is
% calculated (every hour), if battery SOC exceeds 100% that energy is
% stored in energy excess array and LOPVG count is incremented, if battery
% SOC breaks 0% the amount of energy not supplied is stored in energy
% deficit array and LOS count is incremented.
% [Baseline_Table,Delta_Baseline,Baseline_Battery_Stored] = Baseline_ESS_Analysis(Hourly_Load,PV_Output,Total_PV_Generation,Battery_Capacity,Battery_Efficiency,Initial_Battery,Solar_Panel_Range,Battery_Cost,Solar_Panel_Cost,SAPV_Analysis,LPSP_Count,Initial_Charge);

%==========================================================================
% Centrally stored battery and shared solar panels. Acts as one SAPV system with
% combined loads and PV output. Calculates difference in storage and load,
% battery required and capital cost.
[Central_Table,Delta_Central,Central_Battery_Stored] = Central_ESS_Analysis(Number_of_SAPV_Systems,Shared_Hourly_Load,PV_Output,Total_PV_Generation,Battery_Capacity,Battery_Efficiency,Initial_Battery,Solar_Panel_Range,Battery_Cost,Solar_Panel_Cost,SAPV_Analysis,LPSP_Count,Initial_Charge,Interconnection_Cost);

%==========================================================================
% Interconnected Energy Sharing (each SAPV system has its own battery and
% solar panel configuration but systems are able to share energy: If
% battery SOC is equal to 100%, that SAPV system will sell its energy for
% that hour to another SAPV system (if another SAPV system can take that
% energy without going over 100% SOC itself).

% If battery SOC is equal to 0%, that SAPV system will buy its energy for
% that hour from another SAPV system (if another SAPV system can sell
% energy without reaching 0% SOC itself)
[Table_IES,Delta_IES,IES_Battery_Stored] = IES_Analysis_N_Systems(Hourly_Load,PV_Output,Total_PV_Generation,Battery_Capacity,Battery_Efficiency,Initial_Battery,Solar_Panel_Range,Battery_Cost,Solar_Panel_Cost,SAPV_Analysis,LPSP_Count,Initial_Charge,Interconnection_Cost);

%==========================================================================
% In each case: technical parameter will be calculated (from energy deficit
% array), if technical parameter is not met then battery capacity is
% incremented, if technical parameter is met that configuration will be
% stored for further testing, optimum configurations will be sorted based
% on economical parameter selected, and finally the best configurations can
% be compared based on additional parameters such as (%PV Generation
% Utilization (energy excess array), and Levelized Cost of Energy (compare
% to utility prices).

%Because of the long run time, added this to signal when run is finished
beep on;
beep;
beep;
beep;
