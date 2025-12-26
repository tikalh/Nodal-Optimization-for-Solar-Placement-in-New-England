function load_scenarios = generate_load_scenarios(mpc)
%GENERATE_LOAD_SCENARIOS Generate hourly load scenarios for 1 year.
%
% OUTPUT FORMAT:
%   load_scenarios is a matrix:
%
%       (Nodes × Hours)
%
%   where:
%       - Hours = 8760 (24*365)
%       - load_scenarios(i, h) is the load at bus i during hour h
%       - Each hour is a *scenario*
%
% INPUTS:
%   mpc   MATPOWER case struct (must contain mpc.bus)
%
% METHOD:
%   - Uses base loads (P_base)
%   - Replaces zeros with random noise
%   - Creates seasonal and daily patterns
%   - Adds small noise per bus

rng(42);  % Repeatable random generator

Nodes = size(mpc.bus, 1);

% --- Choose 50 evenly spaced days across the year ---------------------
total_days = 365;
num_days = 30;
days_selected = round(linspace(1, total_days, num_days));   % e.g. 1, 8, 15, ...

% --- Scenarios every 2 hours ------------------------------------------
hours_per_day = 24;
dt = 2;                           % sampling period = 2 hours
samples_per_day = hours_per_day/dt;   % = 12 samples per day

Scenarios = num_days * samples_per_day;

% --- Base loads --------------------------------------------------------
P_base = mpc.bus(:, 3);

% --- Build time indices for all 600 scenarios -------------------------
scenario_hours = repmat(0:dt:22, 1, num_days);   % hours of each day (0,2,4,...22)
scenario_days  = repelem(days_selected, samples_per_day);

% --- Seasonal curve ----------------------------------------------------
season = 1 + 0.2 * cos(2*pi*(scenario_days - 200) / total_days);

% --- Daily curve -------------------------------------------------------
hour_idx = scenario_hours;
daily = 0.6 + 0.3 * exp(-((hour_idx - 9 ).^2)/10) + ...
              0.4 * exp(-((hour_idx - 19).^2)/10);
% --- Final load scenario matrix ---------------------------------------
load_scenarios = zeros(Nodes, Scenarios);
for i = 1:Nodes
    noise = 1 + 0.02 * randn(Scenarios, 1);
    load_scenarios(i, :) = (P_base(i) .* season .* daily .* noise');
end

load_scenarios = load_scenarios ./ 3;  % scale for 1-phase load model

end