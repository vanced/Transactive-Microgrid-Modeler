function [Months] = Months_Calculator(Initial_Year, Number_of_years)
%   Calculates the number of days in each month

%Number of years of data being uploaded.
%Initial_Year = 2008;
%Number_of_years = 3;

%Initializes variable Year which will be incremented below
Year = Initial_Year;

%Checks that variable Number_of_years makes sense (0 < Number < 100)
while (Number_of_years <1) || (Number_of_years > 100)
    disp('Invalid Entry');
    Number_of_years = input('Please enter an appropriate number of years of data to be analyzed.');
end

%Checks that variable Initial_Year makes sense (1500 < Initial_Year < 2020)
while (Initial_Year <1850) || (Initial_Year > 2020)
    disp('Invalid Entry');
    Number_of_years = input('Please enter an appropriate initial year for the data being analyzed.');
end

%Number of days per month, assuming no leap year
Months_NO_LeapYear = [31; 28; 31; 30; 31; 30; 31; 31; 30; 31; 30; 31];

%Number of days per month, assuming there is a leap year
Months_YES_LeapYear = [31; 29; 31; 30; 31; 30; 31; 31; 30; 31; 30; 31];

%Establishes zero values for variable months
Months = zeros(12*Number_of_years,1); 

%Checks if it's a leap year and fills up the months vector
for i = 1:Number_of_years
    
   %Initializes variable ly assuming no leap year initially
ly = 0;

    if mod(Year,4) == 0
        ly = 1; %Its a leap year
    end
    
    if mod(Year,100) == 0
        ly = 0; %Its not a leap year
    end
    
    if mod(Year,400) == 0
        ly = 1; %Its a leap year
    end
    
    %Fills up the months vector with proper number of days in each
    %month.
    if ly == 0
        Months(12*(i-1)+1:12*i) = Months_NO_LeapYear;
    else
        Months(12*(i-1)+1:12*i) = Months_YES_LeapYear;
    end
    Year = Year+1;
end
end

