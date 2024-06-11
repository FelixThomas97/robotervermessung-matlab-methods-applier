%% Beispiel mit echten Daten aus MongoDB

% Laden der trajectories
load trajektory2.mat
%load square1.mat

% Die ersten 6 Einträge der Matrix löschen
trajektory1(:,1:6) = [];
 
% Anzahl der aufgezeichneten Punkte für ist/soll/vicon - 1
% trajektory1.mat
i = 172;
j = 60;

% % trajektory2.mat
% i = 286;
% j = 100;


% Schreiben der Koordinaten in eigene Vektoren
x_ist = trajektory1(:,1:1+i);
y_ist = trajektory1(:,2+i:2+2*i);
z_ist = trajektory1(:,3+2*i:3+3*i);
z_ist = z_ist-0.7;

x_soll = trajektory1(:,4+3*i:4+3*i+j);
y_soll = trajektory1(:,5+3*i+j:5+3*i+2*j);
z_soll = trajektory1(:,6+3*i+2*j:6+3*i+3*j);

x_vicon = trajektory1(:,7+3*i+3*j:7+4*i+3*j);
y_vicon = trajektory1(:,8+4*i+3*j:8+5*i+3*j);
z_vicon = trajektory1(:,9+5*i+3*j:9+6*i+3*j);

pathX = [x_ist; y_ist; z_ist];
pathY = [x_soll; y_soll; z_soll];
% pathVICON2 = [x_vicon;y_vicon;z_vicon];

clear x_ist y_ist z_ist x_soll y_soll z_soll x_vicon y_vicon z_vicon dy labels
clear trajektory1 trajektory1
%% Plot erstellen
figure;
labels = string(1:length(pathX));
dy = 0.2;
hold on;
% text(pathIST(1,:), pathIST(2,:)+dy, labels,"HorizontalAlignment","center","VerticalAlignment","bottom");
plot3(pathX(1,:), pathX(2,:), pathX(3,:), 'b','Marker','o', 'LineWidth', 2);
labels = string(1:length(pathY));
% text(pathVICON(1,:), pathVICON(2,:), pathVICON(3,:)+dy, labels,"HorizontalAlignment","center","VerticalAlignment","bottom");
plot3(pathY(1,:), pathY(2,:), pathY(3,:), 'r','Marker','o', 'LineWidth', 2);
% text(pathSOLL(1,:), pathSOLL(2,:), pathSOLL(3,:)+dy, labels,"HorizontalAlignment","center","VerticalAlignment","bottom");
% plot3(pathSOLL(1,:), pathSOLL(2,:), pathSOLL(3,:), 'g','Marker','o', 'LineWidth', 2);
xlabel('X-Koordinate');
ylabel('Y-Koordinate');
zlabel('Z-Koordinate')
title('Vergleich zweier Zeitreihen');
legend;
grid on;
axis padded;
view(3)
hold off

%% CalcLocalCostMatrix 

% Erstellen einer leeren Matrix mit den richtigen Dimensionen
values = zeros(size(pathX, 2), size(pathY, 2));
MaxLocalCost = 0;
MinLocalCost = Inf;

% Schleife, die für jedes Element in values den euklidischen Abstand berechnet
% und in jedem Schritt die max. und min Kosten überprüft
for i = 1:size(pathX, 2)
    for j = 1:size(pathY, 2)
        values(i, j) = norm(pathX(:, i) - pathY(:, j));
        if values(i, j) > MaxLocalCost
            MaxLocalCost = values(i, j);
        end
        if values(i, j) < MinLocalCost
            MinLocalCost = values(i, j);
        end
    end
end

LocalCostMatrix = values;
clear values;


%% CalcAccumulatedCostMatrix

values = zeros(length(pathX), length(pathY));
% Initialisierung:
% Initialisieren des ersten Elements
values(1, 1) = 0; 
% Berechnung der Werte für die erste Spalte
for i = 2:length(pathX)
    values(i, 1) = values(i - 1, 1) + LocalCostMatrix(i, 1);
end
% Berechnung der Werte für die erste Zeile
for j = 2:length(pathY)
    values(1, j) = values(1, j - 1) + LocalCostMatrix(1, j);
end

% Iteration:
% Berechnung der restlichen Werte
for i = 2:length(pathX)
    for j = 2:length(pathY)
        values(i, j) = LocalCostMatrix(i, j) + min([values(i - 1, j), values(i, j - 1), values(i - 1, j - 1)]);
    end
end

AccumulatedCostMatrix = values; 
clear values

%% CalcDTW
% Kalkulation des Pfades mit den geringsen Kosten

% Initialisierung der Ergebnisliste
result = {};

% Startindizes beginnend vom letzen Element
i = length(pathX);
j = length(pathY);
result{1} = [i, j];

% Initialisierung der Mapping-Liste

Mapping = {};
Mapping{1} = {pathX(:,i), pathY(:,j)};

% Schleife, um die Indizes zu aktualisieren und die Ergebnisse hinzuzufügen
while i > 1 || j > 1
    if i == 1
        j = j - 1;
    elseif j == 1
        i = i - 1;
    else
        % Minimum zwischen den umliegenden Werten in AccumulatedCostMatrix finden
        min_val = min([AccumulatedCostMatrix(i-1, j), AccumulatedCostMatrix(i, j-1), AccumulatedCostMatrix(i-1, j-1)]);
        
        if AccumulatedCostMatrix(i-1, j-1) == min_val
            i = i - 1;
            j = j - 1;
        elseif AccumulatedCostMatrix(i-1, j) == min_val
            i = i - 1;
        elseif AccumulatedCostMatrix(i, j-1) == min_val
            j = j - 1;
        end
    end
    
    % Aktualisierte Indizes und Tupel hinzufügen
    result{end+1} = [i, j];
    Mapping{end+1} = {pathX(:,i), pathY(:,j)};
end

%% Heatmap erstellen

% heatmap(AccumulatedCostMatrix) --> lässt kein hold on zu!

figure;
imagesc(AccumulatedCostMatrix);
colorbar;

% Mapping hinzufügen
hold on;
for k = 1:numel(result)
    i = result{k}(1);
    j = result{k}(2);
    plot(j, i, 'w.',"LineWidth",4);
end

% Achsenbeschriftungen und Titel
xlabel('Index von PathY');
ylabel('Index von PathX');
title('Heatmap der AccumulatedCostMatrix mit Mapping');

% Achse mit pathX umdrehen, um die Konvention von Matrixindizes zu befolgen
set(gca, 'YDir', 'normal');
