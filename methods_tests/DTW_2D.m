%% Beispiel mit erfundenden Daten
% Abtastraten
t1 = 0:0.5:10; 
t2 = 0:0.3:10; 

% Beispielhafte X- und Y-Koordinaten für jede Zeitreihe
x1 = t1;
y1 = ones(1,length(t1));
y1(4) = 2;
y1(2) = 2;
x2 = t2;
y2 = sin(t2);
x3 = t2;
y3 = randn(1,length(t2));

% Zu Pfad zusammenfügen
pathX = [x1; y1];
pathY = [x2; y2];
pathY2 = [x3; y3];

% Plot erstellen
figure;
labels = string(1:length(pathX));
dy = 0.2;
hold on;
text(pathX(1,:), pathX(2,:)+dy, labels,"HorizontalAlignment","center","VerticalAlignment","bottom");
plot(pathX(1,:), pathX(2,:), 'b','Marker','o', 'LineWidth', 2);
labels = string(1:length(pathY));
text(pathY(1,:), pathY(2,:)+dy, labels,"HorizontalAlignment","center","VerticalAlignment","bottom");
plot(pathY(1,:), pathY(2,:), 'r','Marker','o', 'LineWidth', 2);
text(pathY2(1,:), pathY2(2,:)+dy, labels,"HorizontalAlignment","center","VerticalAlignment","bottom");
plot(pathY2(1,:), pathY2(2,:), 'g','Marker','o', 'LineWidth', 2);
xlabel('X-Koordinate');
ylabel('Y-Koordinate');
title('Vergleich zweier Zeitreihen');
legend; 
grid on;
axis equal;
hold off

clear x1 x2 x3 y1 y2 y3 t1 t2

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
    plot(j, i, 'wo',"LineWidth",4);
end

% Achsenbeschriftungen und Titel
xlabel('Index von PathY');
ylabel('Index von PathX');
title('Heatmap der AccumulatedCostMatrix mit Mapping');

% Achse mit pathX umdrehen, um die Konvention von Matrixindizes zu befolgen
set(gca, 'YDir', 'normal');
