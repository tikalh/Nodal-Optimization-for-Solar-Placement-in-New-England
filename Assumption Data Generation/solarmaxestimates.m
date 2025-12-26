function Solar_Max_Matrix = solarmaxestimates()

% SOLARMAXESTIMATES Estimate max solar availability at each node
% OUTPUT:
%   Solar_Max_Matrix : (Nodes × Total_Hours)
%       Solar_Max_Matrix(i,t) = max solar MW at node i at time t

rng(42);

% --- USER SETTINGS -------------------------------------------------
Num_Nodes        = 39;
Num_Days_Sampled = 30;        % same concept as the load sampler
samples_per_day  = 12;         % 2-hour resolution (24/12 = 2 hr)
dt               = 24 / samples_per_day;

% Total time points
Total_Hours = Num_Days_Sampled * samples_per_day;

% --- 1. Node-specific max solar capacities (MW) -------------------------
min_cap = 10;
max_cap = 300;
node_space_limits = min_cap + (max_cap - min_cap) * rand(1, Num_Nodes);  % 1×39

% --- 2. Choose evenly spaced days through the year ------------------
% (Same as your load scenario method)
sampled_days = round(linspace(1, 365, Num_Days_Sampled));  % 1×50

% --- 3. Build solar irradiance time profile -------------------------
time_profile = zeros(Total_Hours, 1);

idx = 1; % time index counter

for d = sampled_days
    
    % ---- Seasonal factor (mid-summer ≈ peak) ----
    season = (1 - cos((d - 10)*2*pi/365)) / 2;   % 0.7–1 range effectively
    daily_peak = 0.7 + 0.3*season;
    day_len    = 9 + 6*season;
    
    % ---- Daily solar pattern sampled every dt hours ----
    for h = 0:dt:(24-dt)
        
        val = daily_peak * cos((pi/day_len)*(h - 12));
        if val < 0
            val = 0;
        end
        
        time_profile(idx) = val;
        idx = idx + 1;
    end
    
end

% --- 4. Expand to (Nodes × Hours) matrix ----------------------------
% time_profile : (T × 1)
% node_space_limits : (1 × N)
%
% (time_profile * node_space_limits) → (T × N)
% Transpose → (N × T)

Solar_Max_Matrix = (time_profile * node_space_limits).';

end