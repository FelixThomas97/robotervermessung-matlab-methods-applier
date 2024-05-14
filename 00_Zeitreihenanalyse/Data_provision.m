%% Skript zur Erstellung von .mat Dateien aus Trajektorien

soll = table2array(trajectoryrobot017115516521275697(:, {'xSoll','ySoll','zSoll'}));
ist = table2array(trajectoryrobot017115516521275697(:, {'xIst','yIst','zIst'}));

i = ~isnan(soll);
j = ~isnan(ist);

A = soll(i);
B = ist(j);
pathX = reshape(A,sum(i(:,1)),sum(i(1,:)))';
pathY = reshape(B,sum(j(:,1)),sum(j(1,:)))';

soll = pathX';
ist = pathY';

clear A B i j

%% Plot erstellen
figure;
hold on;
plot3(pathX(1,:), pathX(2,:), pathX(3,:), 'b','Marker','o', 'LineWidth', 1.5);
plot3(pathY(1,:), pathY(2,:), pathY(3,:), 'r','Marker','o', 'LineWidth', 1.5);
xlabel('x');
ylabel('y');
zlabel('z')
title('Vergleich zweier Zeitreihen');
legend;
grid on;
axis padded;
view(3)
hold off
