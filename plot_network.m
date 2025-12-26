function plot_network(P_Flows_mean, Z)
GEN_Loc = [zeros(29,1); ones(10,1)];

mpc = loadcase('case39');
branch = mpc.branch;
% Build graph using from/to buses
line_from = branch(:, 1);
line_to   = branch(:, 2);
nl = size(branch,1);

G = graph(line_from, line_to);   % undirected graph

hG = plot(G, 'Layout', 'force', 'NodeLabel', []);
bus_x = hG.XData;
bus_y = hG.YData;
delete(hG);      % remove default graph plot, keep coordinates
hold on;

%Plot blue circles for DERs, black squares for gens, purple triangles for
%both
for i = 1:length(bus_x)

    hasDER = (Z(i) == 1);
    hasGEN = (GEN_Loc(i) == 1);

    if hasDER && hasGEN
        plot(bus_x(i), bus_y(i), '^', ...
             'MarkerSize', 10, ...
             'MarkerFaceColor', [0.5 0 0.5], ...
             'MarkerEdgeColor', [0.5 0 0.5]);
        continue;
    end
    if hasDER
        plot(bus_x(i), bus_y(i), 'o', ...
             'MarkerSize', 8, ...
             'MarkerFaceColor', 'b', ...
             'MarkerEdgeColor', 'b');
    end
    if hasGEN
        plot(bus_x(i), bus_y(i), 's', ...
             'MarkerSize', 9, ...
             'MarkerFaceColor', 'k', ...
             'MarkerEdgeColor', 'k');
    end
end

% Parameters for congestion visualization

% Plot lines with flows and congestion highlighting
P_max = 220;   % MW
flow  = P_Flows_mean;

flow_mag = abs(P_Flows_mean);
flow_clipped = min(flow_mag, P_max);
flows_norm = flow_clipped / P_max;

lineColor = [flows_norm, 1-flows_norm, zeros(nl,1)];

for ell = 1:nl
    b_from = line_from(ell);
    b_to   = line_to(ell);

    x1 = bus_x(b_from);  y1 = bus_y(b_from);
    x2 = bus_x(b_to);    y2 = bus_y(b_to);

          % MW

    
    % 
    % if loading >= cong_threshold
    %     lineColor = 'r';           % congested
    %     lineWidth = 3;
    % else
    %     lineColor = [0.4 0.4 0.4]; % non-congested
    %     lineWidth = 1.5;
    % end
    % Draw the line
    plot([x1, x2], [y1, y2], '-','Color', lineColor(ell,:),'LineWidth', 2.5);

    % Midpoint for annotation
    xm = 0.5*(x1 + x2);
    ym = 0.5*(y1 + y2);

    % Annotate flow
    text(xm, ym, sprintf('%.1f MW', abs(flow(ell))), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 7);

    % Direction arrow (positive from -> to)
    dx = x2 - x1;
    dy = y2 - y1;
    if abs(dx) + abs(dy) > 1e-6
        net_scale   = max(max(bus_x) - min(bus_x), max(bus_y) - min(bus_y));
        arrow_scale = 0.015 * net_scale;

        if flow >= 0
            xa = xm - 0.3*dx;
            ya = ym - 0.3*dy;
            quiver(xa, ya, arrow_scale*dx, arrow_scale*dy, 0, ...
                   'MaxHeadSize', 1.5, 'LineWidth', 0.8,'Color', 'k');
        else
            xa = xm + 0.3*dx;
            ya = ym + 0.3*dy;
            quiver(xa, ya, -arrow_scale*dx, -arrow_scale*dy, 0, ...
                   'MaxHeadSize', 1.5, 'LineWidth', 0.8,'Color', 'k');
        end
    end
end

% Legend for DER/Generator Placement
h_der = plot(nan, nan, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
h_gen = plot(nan, nan, 'ks', 'MarkerSize', 9, 'MarkerFaceColor', 'k');
h_both = plot(nan, nan, '^', 'MarkerSize', 9, 'MarkerFaceColor', [0.5 0 0.5]);
legend([h_der, h_gen, h_both], ...
       {'DER Placement (circle)', 'Generator Placement (square)', 'Both DER & Generator (triangle)'}, ...
       'Location', 'bestoutside');

axis equal;
axis off;
hold off;