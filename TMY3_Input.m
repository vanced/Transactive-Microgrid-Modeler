function [Solar_Data, Load_Data] = TMY3_Input(Monthpoint)
%TMY3_INPUT The purpose of this 'function' is to input TMY3 Solar and Load Data.

%Load TMY3 Solar data for geographical location
load Erie_PA.txt
load Indianapolis_IN.txt
load LittleRock_AR.txt
load Phoenix_AZ.txt
load SanAntonio_TX.txt
%load PV_Validation.txt

%Determines which TMY3 location is actually used. Make sure load matches!
%Monthpoint is used to quickly change the month of both solar and load
Solar_Data = circshift(LittleRock_AR,Monthpoint); 

%Load TMY3 residential load data for geographical location     
load Erie_PA_LOAD.txt 
load Indianapolis_IN_LOAD.txt
load LittleRock_AR_LOAD.txt
load Phoenix_AZ_LOAD.txt
load SanAntonio_TX_LOAD.txt

%Make sure that Load Data matches geographically with Solar Data!!!! 
Load_Data = circshift(LittleRock_AR_LOAD,Monthpoint); 

end

