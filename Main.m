%Run optimization with DER placement
DERmax = solarmaxestimates;
[Z, P_Flows_mean, LL_Cost_mean, ~] = optimize_DERs(DERmax);

%Run optimization without DERs (DERmax = 0)
DERmax = zeros(39,360);
[Z0, P_Flows_mean0, LL_Cost_mean0, Resistance] = optimize_DERs(DERmax);


Lines = length(P_Flows_mean0);

%Make colors vector to color bar graph by resistances

[~,res_sorted] = sort(Resistance, "Ascend");
cmap = [linspace(0,1,Lines)', linspace(1,0,Lines)', zeros(Lines,1)]; 

colors = zeros(Lines,3);
colors(res_sorted,:) = cmap;
%produces colors with red for higher value, green for lower value

x = 1:Lines;

figure(1);
subplot(2,2,1)
b = bar(P_Flows_mean0,'FaceColor','flat');
b.CData = colors;
xlabel('Lines')
ylabel('Power Flow (MW)')
title("Power Flows With No DERs Placed")

subplot(2,2,2)
b = bar(P_Flows_mean,'FaceColor','flat');
b.CData = colors;
xlabel('Lines')
ylabel('Power Flow (MW)')
title("Power Flows With DERs Placed")

subplot(2,2,3)
b = bar(LL_Cost_mean0,'FaceColor','flat');
b.CData = colors;
xlabel('Lines')
ylabel('Line Cost ($)')
title("Power Loss Cost With No DERs Placed")

subplot(2,2,4)
b = bar(LL_Cost_mean,'FaceColor','flat');
b.CData = colors;
xlabel('Lines')
ylabel('Line Cost ($)')
title("Power Loss Cost With DERs Placed")

figure(2);
plot_network(P_Flows_mean0, Z0)
title('Network Graph for System without DERs Placed')

figure(3);
plot_network(P_Flows_mean,Z)
title('Network Graph for System with DERs Placed')