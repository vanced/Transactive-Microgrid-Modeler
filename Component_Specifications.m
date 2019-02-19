%Component_Specifications.m

% The purpose of this script is to input component specifications.

                    %%%%%% Solar Panels %%%%%%                    
%Solar Panel Rating
Solar_Panel_Rating = 3000; % in Watt.
% Solar_Panel_Rating = input('Please enter the solar panel rating.');

%Solar Panel Cost
Solar_Panel_Unit_Cost = 4877; % Price for one Solar Panel in U.S. Dollars / Watt. If given as average installed cost/W then no need to calculate labor cost or inverter cost
%Solar_Panel_Cost = input('Please enter the price for one solar panel.');

%Solar Panel Hardware Cost
Solar_Panel_Hardware_Cost = 500; %Price of hardware for one solar panel.

%Solar Panel Installation Cost
Solar_Panel_Installation_Cost = 3000; %Price of installation for one solar panel. Not necessary if solar panel cost given as the average installation cost /W. 

%Total Cost per Solar Panel
Solar_Panel_Cost = Solar_Panel_Unit_Cost + Solar_Panel_Installation_Cost + Solar_Panel_Hardware_Cost;

%Range of Solar Panels to Test. %Give as a range of solar panel numbers to
%optimize or one number. i.e Solar_Panel_Range = [1 6 9 16]
%Number_of_Configurations variable would be 4.
Solar_Panel_Range = (7:1:8); %(5:1:20); 

%PV Derating factor is a scaling factor that HOMER applies to the PV array
%power output to account for reduced output in real-world operating
%conditions compared to the conditions under which the PV panel was rated.
% Use the derating factor to account for such factors as soiling of the
% panels, wiring losses, shading, snow cover, aging, and so on. If you
% choose not to explicitly model the effect of temperature on the PV array,
% include temperature-related effects in the derating factor.
PV_Derating_Factor = 0.731;


                       %%%%%% Battery %%%%%%
%Battery Capacity
Battery_Capacity = 13.5; % Capacity of Battery in kWh
% Battery_Capacity = input('Please enter the battery capacity');

%Battery Efficiency
Battery_Efficiency = 0.90; % Round-trip efficiency of battery storage. Using for charging
%Battery_Efficiency = input('Please enter the battery efficiency');

%Battery Cost
Battery_Unit_Cost = 5900; % Price for one battery. If given as the average installation cost/W then no need to calculate labor cost or controller cost
%Battery_Cost = input('Please enter the battery cost');

%Battery Hardware Cost
Battery_Hardware_Cost = 700; %Price of hardware for each battery. Not necessary if using average installation cost/W for Battery Cost

%Battery Installation Cost
Battery_Installation_Cost = 1500; %Price of installation for each battery. Not necessary if using average installation cost/W for Battery Cost

%Total Cost per Battery
Battery_Cost = Battery_Unit_Cost + Battery_Hardware_Cost + Battery_Installation_Cost;

%Initial Guess for Number of Batteries. Used for every case
Initial_Battery = 1;
%Initial_Battery = input('Please enter the initial guess for number of batteries')

%Interconnection Cost, cost to interconnect systems in the CES and IES case
Interconnection_Cost = 200; 
