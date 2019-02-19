function [PV_Output, Total_PV_Generation] = PV_Output_Calculator(Solar,Number_of_Trials,Solar_Panel_Range,Solar_Panel_Rating,PV_Derating_Factor) %Solar_Panel_Rating not used
%PV_Output_Calculator Takes the simulated solar data and solar panel
%information to determine the PV output for each solar panel configuration.

%Determines the number of configurations 
Number_of_Configurations = size(Solar_Panel_Range,2);

%Initialize variable PV_output
PV_Output = zeros(8760,Number_of_Configurations,Number_of_Trials);
Total_PV_Generation = zeros(Number_of_Configurations,Number_of_Trials);

for Trial_Number = 1:Number_of_Trials
    for Configuration_Number = 1:Number_of_Configurations
        for Hour = 1:8760
            Configuration = Solar_Panel_Range(Configuration_Number);
        PV_Output(Hour,Configuration_Number,Trial_Number) = PV_Derating_Factor*Solar(Hour,Trial_Number)/1000*Configuration*Solar_Panel_Rating/1000; %Sohttps://www.homerenergy.com/products/pro/docs/3.11/how_homer_calculates_the_pv_array_power_output.htmllar_Panel_Rating not included;
        Total_PV_Generation(Configuration_Number,Trial_Number) = Total_PV_Generation(Configuration_Number,Trial_Number) + PV_Output(Hour,Configuration_Number,Trial_Number);
        end
    end
end
end