function [Z, P_Flows_mean, LL_Cost_mean, Resistance] = optimize_DERs(DERmax)
yalmip('clear');

%Load 39 bus generator, bus, and branch data
mpc = case39;
Gen_data = mpc.gen;
Bus_data = mpc.bus;
Branch_data = mpc.branch;

%Load Assumption data -> dim = Nodes x Scenarios (MW)
PL = generate_load_scenarios(mpc);

%Define # gens, #nodes, #Scenarios,Gen location
Gens = size(Gen_data,1);
Gen_loc = Gen_data(:,1);
Scenarios = size(PL,2);
Nodes = size(Bus_data,1);

% Generator/DER power limits
Pmin = zeros(Nodes,Scenarios); 
Pmax = zeros(Nodes,Scenarios);
Pmax(Gen_loc,:) = repmat(Gen_data(:,9),1,Scenarios);
DERmin = zeros(Nodes,Scenarios);

%Line capacity limit (MW) - found by taking the average line
%capacity between the 3 lines for each phase
Fmax = repmat(sum(Branch_data(:,6:8),2)/3,1,Scenarios);

% Define cost coefficients for generators
Cgens = 45.5*2*ones(Nodes,1); % $/(2hours*MW) typical generator dispatch cost in New England cost for 2 hours because we are doing 2 hour timesteps

%Determine cost of Solar Farm placment
Solar_Farm_Cost = 1.2*10^6; %Cost $/MW to build a solar farm
Time_Step = 30; %Days
OandM = 15000; %$/MWYear
Solar_Farm_Lifespan = 30; %years
Solar_Farm_Capacity = 150; %MW
Solar_Cost_30Days = Solar_Farm_Cost*Solar_Farm_Capacity*Time_Step/(Solar_Farm_Lifespan*365) + OandM*Solar_Farm_Capacity*Time_Step/365; %$/30Days

%Determine cost coefficient for line loss
Cavg = (mean(Cgens))/2; %Average cost of power;
Resistance = Branch_data(:,3);
Closs = Cavg*.03/mean(Resistance)*Resistance; %average power cost times average transmission line loss (3%), times a normalized vector of line resistances


% Define decision variables (Z,PDER,PG)
Z = binvar(Nodes,1); %Z vector indicates if a DER should be placed at a given node
PDER = sdpvar(Nodes,Scenarios);%Power ouptut of DERs
PG = sdpvar(Nodes,Scenarios); %Power output of generators

%Define net power vector
P = PG+PDER-PL;

%Define PTDF matrix
PTDF = makePTDF(mpc.baseMVA, Bus_data, Branch_data);

% Objetive function: Minimize generation and losses cost
P_Flows = PTDF*P;
Line_loss_cost = abs(P_Flows.*repmat(Closs,1,Scenarios)); %replicate closs across every scenario
Cost = sum(sum(repmat(Cgens,1,Scenarios).*PG)) + sum(Z)*Solar_Cost_30Days + sum(sum(Line_loss_cost));

% Constraints
Constraints = [];
%Add Pgen+PDER = PL constraint for each scenario
for i = 1:Scenarios
Constraints = [Constraints, sum(PG(:,i)) + sum(PDER(:,i)) == sum(PL(:,i))]; % Power balance constraint
end
Constraints = [Constraints, Pmin <= PG <= Pmax]; % Generator limits
Constraints = [Constraints, DERmin <= PDER <= DERmax.*repmat(Z,1,Scenarios)];
Constraints = [Constraints, -Fmax <= PTDF*P <= Fmax];
Constraints = [Constraints, sum(Z)<=5];

% Solve the optimization problem
options = sdpsettings('solver', 'intlinprog', 'verbose', 1);
sol = optimize(Constraints, Cost, options);

%get value of Yalmip variables/get means for display
Z = value(Z);
PDER_mean = value(mean(PDER,2));
PG_mean = value(mean(PG,2));
P_Flows_mean = value(mean(P_Flows,2));
LL_Cost_mean = value(mean(Line_loss_cost,2));
Cost = value(Cost);

% Display results
if sol.problem == 0
    disp('DER placement by Node');
    disp(Z);
    disp('DER Outputs (MW average of scenarios)')
    disp(PDER_mean);
    disp('Generator Outputs (MW average of scenarios):');
    disp(PG_mean);
    disp('Line Power Flows (MW average of scenarios):');
    disp(P_Flows_mean);
    disp('Line Loss Cost ($ average of scenarios):');
    disp(sum(sum(value(Line_loss_cost))));
    disp('Total Line Loss Cost ($):');
    disp(LL_Cost_mean);

    disp('Total Cost ($):');
    disp(Cost);
else
    Z = 0;
    P_Flows_mean = 0;
    LL_Cost_mean = 0;
end

end