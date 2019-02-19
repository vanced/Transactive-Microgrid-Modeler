function [Total_Maximum,BIG_STM_CUM] = Solar_Cumulative_STM_Generator(Solar_Data,Months)

%The purpose of this function is to generate a cumulative STM based on the
%provided solar data.

%Reshapes the months into a 12xNumber_of_years matrix, so all months can be
%worked on consecutively for developing the set of STMS. (Not necessary for
%TMY3 data with only one year)
%Months = [31 31 30 31 30 31 31 28 31 30 31 30]; %Solar data begins in July!!
size_of_months = size(Months);
month_reshape = size_of_months(1);
%rmonth = reshape(Months,(month_reshape/Number_of_years),(Number_of_years));

%========================================================================
%************************** Loads Solar Data ***************************
%========================================================================

%Initializes variable datapoints
datapoints = 0;

%Initialize the BIG matrix of hourly values of solar data for all months.
%Be aware, months not having 31 days will need to be handled (Not neccesary
%for TMY3)
BIG = zeros(month_reshape,31,24);

%Populate the BIG matrix with the solardata from the text file
for i1 = 1:12 %*Number_of_years
    for d1 = 1:Months(i1)
        for h1 = 1:24
            datapoints = datapoints + 1; 
            BIG(i1,d1,h1) = round(Solar_Data(datapoints),-1); 
            %But we need data from the same month eventually combined!
        end
    end
end

%Gives maximum solar radiation possible rounded to the nearest 10.
Total_Maximum = round(max(Solar_Data)*0.1)*10;

%=========================================================================
%Build STM for all months. 24 hours a day x 12 months = 288 STM matrices.
%The result of this code is a tally of the number of times of going from
%one solar radiation value to another solar radiation value, for each hour
%of each month. 
%=========================================================================

BIG_STM = zeros(12,24,((Total_Maximum/10)+1),((Total_Maximum/10)+1));

for m_STM = 1:12 %Each month of data, %for y_STM = 1:Number_of_years %Each year of data
    for day_STM = 1:Months(m_STM) %Number of days in the month
        for hourpoint = 1:23 %Helps with calculation. Hour 24+1 doesn't make sense. Just assume that midnight is always dark.
            initial_value = (BIG(m_STM,day_STM,hourpoint)/10)+1;
            next_value = (BIG(m_STM,day_STM,hourpoint+1)/10)+1;
            BIG_STM(m_STM,hourpoint,initial_value,next_value) = BIG_STM(m_STM,hourpoint,initial_value,next_value)+1;
        end
    end
end



%=========================================================================
%Builds up the transition probabilities within the STM matrix. 23 hourly
%transitions are used because of the hour 24 +1 in the last section. Assume
%midnight is always dark and doesn't require a transition probability.
%=========================================================================

BIG_STM_PROB = zeros(12,23,((Total_Maximum/10) +1),((Total_Maximum/10)+1));
for m_STM_p = 1:12
    for h_STM_p = 1:23
        for i_p = 1:((Total_Maximum/10) + 1)
            BIG_STMrowsum = sum(BIG_STM(m_STM_p,h_STM_p,i_p,:));
            if BIG_STMrowsum == 0
                BIG_STMrowsum = 1;
            end
            for j = 1:((Total_Maximum/10)+1)
                BIG_STM_PROB(m_STM_p,h_STM_p,i_p,j) = BIG_STM(m_STM_p,h_STM_p,i_p,j)/BIG_STMrowsum;
            end
        end
    end
end

%Converts BIG_STM_PROB to percentage
BIG_STM_PERCENT = BIG_STM_PROB*100;

%=========================================================================
%Generates the cumulative probability function based on the transition
%probabilities determined above.
%=========================================================================

BIG_STM_CUM = zeros(12,23,((Total_Maximum/10)+1),((Total_Maximum/10)+1));
for m_STM_cum = 1:12
    for h_STM_cum = 1:23
        for i_cum = 1:((Total_Maximum/10)+1)
            cum_STM_sum = 0;
            for j_CUM = 1:((Total_Maximum/10)+1)
                BIG_STM_CUM(m_STM_cum,h_STM_cum,i_cum,j_CUM) = BIG_STM_PERCENT(m_STM_cum,h_STM_cum,i_cum,j_CUM)+cum_STM_sum;
                cum_STM_sum = BIG_STM_CUM(m_STM_cum,h_STM_cum,i_cum,j_CUM);
            end
        end
    end
end
end

