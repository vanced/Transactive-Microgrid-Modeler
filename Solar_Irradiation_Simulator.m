function [Solar] = Solar_Irradiation_Simulator(Number_of_trials,Simulation_Years,Total_Maximum,BIG_cum_STM,Months)
%The purpose of this function is to take the cumulative STM from
%'Solar_Irradiation_Cum_STM_Generator' and generate simulation results.

%Variable Months gives number of days in each month (No Leap Year)
%Months = [31 31 30 31 30 31 31 28 31 30 31 30]; %Solar data begins in July!!

%Initialize Solar 
Solar = zeros(8760*Simulation_Years,Number_of_trials);

for tr=1:Number_of_trials
    
    %Generate a matrix of random number (hour, day, month), but choose to
    %yield only 12 months of results. This is making note of the fact that
    %there will likely be MORE than 12 months of data being used to make
    %the STMs. So, define a new variable for the number of months you
    %actually want to simulate.
    m_sim = 12*Simulation_Years;
    A = 100*rand(24,31,12*Simulation_Years);
    
    %Determine the solar insolation level based on the cumulative
    %probability function and assign (-1 values that will be removed later.
    %They indicate values for days that don't exist, such as February 30th.
    %All other day values that do exist will replace the '-1' values with
    %real solar values.
    Sol_Level = zeros(24,31,m_sim); %(hour,day,month)
    Sol_Level = Sol_Level - 1;
    
    %Provides a repeating set of 12 months
    for m_calc = 1:m_sim
        m_act =mod(m_calc,12);
        if m_act == 0
            m_act = 12;
        end
        
        %Accounts for extra data points from having more than one year.
        for d_calc = 1:Months(m_calc)
         row = 1;
         
         %For 23 STMs, assuming the 24th (midnight) will be 0.
         for h_trans = 1:24
             if h_trans == 24
                 Sol_Level(h_trans,d_calc,m_calc) = 0;
             else
                 q = 0;
                 for j = 1:((Total_Maximum/10)+1)
                     if A(h_trans,d_calc,m_calc)<BIG_cum_STM(m_act,h_trans,row,j) && q == 0
                         
                         %The matrix starts at 0 W/m^2, i.e. 1/1 in the
                         %matrix corresponds to 0 W/m^2 transitioning to 0
                         %W/m^2.
                         q = 1;
                         Sol_Level(h_trans,d_calc,m_calc) = (j-1)*10;
                         nextrow = j;
                         break;
                     end
                 end
             end
             row = nextrow;
         end
        end
    end
    
    
    %=====================================================================
    %The data needs to be placed into a column vector and massaged to
    %remove days that don't exist. (Not all months have 30 days!)
    
    %Places into a column vector
    z = reshape(Sol_Level,24*m_sim*31,1);    
    
    %Removes the extra day generated due to Leap year.(Not required with
    %TMY3)
    %z(8761:8784) = -1;
    
    %Removes all rows where the value is equal to -1.
    z(all(z==-1,2),:) = [];
     
    %The STM approach yields data that is one hour off (i.e., data at 10 am
    %is showing up at 9 am instead. This is due to the fact that each day
    %starts at midnight, not at 1 am. The column vector above will now be
    %"shifted" down to ensure the estimated solar data shows up at the
    %right time of the day.
    
    s1 = size(z); %Size of the column vector
    s2 = s1(1); %Number of datapoints
    zshift = z(1:(s2-1));
    first_point = 0; %Adds a zero at the beginning of the simulated data set.
    Solar(:,tr) = cat(1,first_point,zshift); %The "shifted" set of solar data
end
end