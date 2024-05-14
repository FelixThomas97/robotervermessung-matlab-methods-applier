%% Daten eventuell benötigt (C#)

% classdef CDTW
%     properties (Constant)
%         Epsilon = 0.000001;
%     end
% 
%     properties (Access = private)
%         PathX;
%         PathY;
%         ParamX;
%         ParamY;
%     end
% 
%     properties
%         AccumulatedDistanceX;
%         AccumulatedDistanceY;
%         Path;
%         PathIndexes;
%     end
% 
%     methods
%         function obj = DynamicTimeWarping(pathX, pathY)
%             obj.PathX = pathX;
%             obj.PathY = pathY;
% 
%             % Initialisierung der anderen Eigenschaften
%             obj.AccumulatedDistanceX = [];
%             obj.AccumulatedDistanceY = [];
%             obj.ParamX = [];
%             obj.ParamY = [];
%             obj.Path = {};
%             obj.PathIndexes = {};
%         end
%     end
% end


%% Daten initialisieren

% Laden der trajectories
load trajektory2.mat
% Die ersten 6 Einträge der Matrix löschen
trajektory2(:,1:6) = [];
 
% Anzahl der aufgezeichneten Punkte für ist/soll/vicon - 1
% % trajektory1.mat
% i = 172;
% j = 60;

% trajektory2.mat
i = 286;
j = 100;


% Schreiben der Koordinaten in eigene Vektoren
x_ist = trajektory2(:,1:1+i);
y_ist = trajektory2(:,2+i:2+2*i);
z_ist = trajektory2(:,3+2*i:3+3*i);
z_ist = z_ist-0.7;

x_soll = trajektory2(:,4+3*i:4+3*i+j);
y_soll = trajektory2(:,5+3*i+j:5+3*i+2*j);
z_soll = trajektory2(:,6+3*i+2*j:6+3*i+3*j);

x_vicon = trajektory2(:,7+3*i+3*j:7+4*i+3*j);
y_vicon = trajektory2(:,8+4*i+3*j:8+5*i+3*j);
z_vicon = trajektory2(:,9+5*i+3*j:9+6*i+3*j);

pathX = [x_ist; y_ist; z_ist];
pathY = [x_soll; y_soll; z_soll];
% pathX2 = [x_vicon;y_vicon;z_vicon];

clear x_ist y_ist z_ist x_soll y_soll z_soll x_vicon y_vicon z_vicon dy labels
clear trajektory1 trajektory2 i j 

%% AccumulatedDistance
% Berechnung der Akkumulierten Kostenmatrizen X, Y und der
% Parametermatrizen X, Y

% Erstellen von leeren Matrizen mit den richtigen Dimensionen
XAccumulatedDistanceX = zeros(length(pathY), length(pathX));
YAccumulatedDistanceY = zeros(length(pathY), length(pathX));
paramX = zeros(length(pathY), length(pathX));
paramY = zeros(length(pathY), length(pathX));

% Initialisierung
% Berechnung der Werte für die Startpositionen
XAccumulatedDistanceX(1, 1) = EuclDist(1, 1, pathY, pathX);
YAccumulatedDistanceY(1, 1) = XAccumulatedDistanceX(1, 1);

% Erste Spalte
for i = 2:length(pathY)
    XAccumulatedDistanceX(i, 1) = XAccumulatedDistanceX(i - 1, 1) + EuclDist(i, 1, pathY, pathX);
    YAccumulatedDistanceY(i, 1) = XAccumulatedDistanceX(i, 1);
end
% Erste Zeile 
for j = 2:length(pathX)
    XAccumulatedDistanceX(1, j) = XAccumulatedDistanceX(1, j - 1) + EuclDist(1, j, pathY, pathX);
    YAccumulatedDistanceY(1, j) = XAccumulatedDistanceX(1, j);
end

% Berechnung des ersten Wertes nach dem CDTW-Verfahren &
% Abspeichern der Parameter
XAccumulatedDistanceX(2, 2) = XAccumulatedDistanceX(1, 1) + MinDistParam(pathY(:,1), pathY(:,2), pathX(:,2));
[~, param] = MinDistParam(pathY(:,1), pathY(:,2), pathX(:,2));
paramX(2, 2) = param;
YAccumulatedDistanceY(2, 2) = YAccumulatedDistanceY(1, 1) + MinDistParam(pathX(:,1), pathX(:,2), pathY(:,2));
[~, param] = MinDistParam(pathX(:,1), pathX(:,2), pathY(:,2));
paramY(2, 2) = param;

% Berechnung der ersten Zeile und Spalte nach dem CDTW-Verfahren &
% Abspeichern der Parameter
for i = 3:length(pathY)
    XAccumulatedDistanceX(i, 2) = XAccumulatedDistanceX(i - 1, 1) + MinDistParam(pathY(:,i - 1), pathY(:,i), pathX(:,2));
    [~, param] = MinDistParam(pathY(:,i - 1), pathY(:,i), pathX(:,2));
    paramX(i, 2) = param;
    YAccumulatedDistanceY(i, 2) = YAccumulatedDistanceY(i - 1, 1) + MinDistParam(pathX(:,1), pathX(:,2), pathY(:,i));
    [~, param] = MinDistParam(pathX(:,1), pathX(:,2), pathY(:,i));
    paramY(i, 2) = param;
end

for j = 3:length(pathX)
    XAccumulatedDistanceX(2, j) = XAccumulatedDistanceX(1, j - 1) + MinDistParam(pathY(:,1), pathY(:,2), pathX(:,j));
    [~, param] = MinDistParam(pathY(:,1), pathY(:,2), pathX(:,j));
    paramX(2, j) = param;
    YAccumulatedDistanceY(2, j) = YAccumulatedDistanceY(1, j - 1) + MinDistParam(pathX(:,j - 1), pathX(:,j), pathY(:,2));
    [~, param] = MinDistParam(pathX(:,j - 1), pathX(:,j), pathY(:,2));
    paramY(2, j) = param;
end

% Berechnung der restlichen Elemente nach dem CDTW-Verfahren
for i = 3:length(pathY)
    for j = 3:length(pathX)
        if XAccumulatedDistanceX(i, j - 1) < YAccumulatedDistanceY(i - 1, j)
            XAccumulatedDistanceX(i, j) = XAccumulatedDistanceX(i, j - 1) + MinDistParam(pathY(:,i - 1), pathY(:,i), pathX(:,j));
            [~, param] = MinDistParam(pathY(:,i - 1), pathY(:,i), pathX(:,j));
            paramX(i, j) = param;
            YAccumulatedDistanceY(i, j) = XAccumulatedDistanceX(i, j - 1) + MinDistParam(pathX(:,j - 1), pathX(:,j), pathY(:,i));
            [~, param] = MinDistParam(pathX(:,j - 1), pathX(:,j), pathY(:,i));
            paramY(i, j) = param;
        else
            XAccumulatedDistanceX(i, j) = YAccumulatedDistanceY(i - 1, j) + MinDistParam(pathY(:,i - 1), pathY(:,i), pathX(:,j));
            [~, param] = MinDistParam(pathY(:,i - 1), pathY(:,i), pathX(:,j));
            paramX(i, j) = param;
            YAccumulatedDistanceY(i, j) = YAccumulatedDistanceY(i - 1, j) + MinDistParam(pathX(:,j - 1), pathX(:,j), pathY(:,i));
            [~, param] = MinDistParam(pathX(:,j - 1), pathX(:,j), pathY(:,i));
            paramY(i, j) = param;
        end
    end
end

%% CalcDTW
% % Pfad mit den geringsten Kosten berechnen
% 
% result = 
% 
% % Berechnung der Werte für die erste Spalte
% for i = 2:length(pathX)
%     [AccumulatedDistanceX(i, 1), paramX(i, 1)] = MinDistParam(pathX(:,i - 1), pathX(:,i), pathY(:,1));
%     AccumulatedDistanceY(i, 1) = AccumulatedDistanceX(i, 1);
%     paramY(i, 1) = paramX(i, 1);
% end
% 
% % Berechnung der Werte für die erste Zeile
% for j = 2:length(pathY)
%     [AccumulatedDistanceX(1, j), paramX(1, j)] = MinDistParam(_pathX(1).Position, _pathX(2).Position, _pathY(j).Position);
%     AccumulatedDistanceY(1, j) = AccumulatedDistanceX(1, j);
%     paramY(1, j) = paramX(1, j);
% end
% 
% % Berechnung der Werte für die restlichen Elemente der Matrizen
% for i = 2:length(_pathX)
%     for j = 2:length(_pathY)
%         if AccumulatedDistanceX(i, j - 1) < AccumulatedDistanceY(i - 1, j)
%             [AccumulatedDistanceX(i, j), paramX(i, j)] = MinDistParam(_pathX(i - 1).Position, _pathX(i).Position, _pathY(j).Position);
%             AccumulatedDistanceY(i, j) = AccumulatedDistanceX(i, j - 1);
%             paramY(i, j) = paramX(i, j);
%         else
%             [AccumulatedDistanceY(i, j), paramY(i, j)] = MinDistParam(_pathY(j - 1).Position, _pathY(j).Position, _pathX(i).Position);
%             AccumulatedDistanceX(i, j) = AccumulatedDistanceY(i - 1, j);
%             paramX(i, j) = paramY(i, j);
%         end
%     end
% end


%% CalcDTW
% Pfad mit den geringsten Kosten berechnen --> Ausgabe Pfad und Koordinaten

% Initialisiere Ergebnisvariablen
result = {};
PathIndexes = {};

% Startindizes setzen
i = length(pathY);
j = length(pathX);
result{end+1} = {pathY(:,i), pathX(:,j)};

% Schleife durchführen, bis i und j kleiner als 1 sind
while i > 1 || j > 1
    if i == 1
        j = j - 1;
    elseif j == 1
        i = i - 1;
    else
        % Indexpaar zur Pfadindizesliste hinzufügen
        PathIndexes{end+1} = [i, j];

        if XAccumulatedDistanceX(i, j - 1) < YAccumulatedDistanceY(i - 1, j)
            % Berechne die Position des nächsten Punktes basierend auf paramX
            nextX = pathY(:,i - 1) + (pathY(:,i) - pathY(:,i - 1)) * paramX(i, j - 1);
            
            % Füge das Tupel (x, y) dem Ergebnis hinzu
            result{end+1} = {nextX, pathX(j - 1)};
            
            % Wenn paramX(i, j - 1) gleich 0 ist, verringere i um 1
            if paramX(i, j - 1) == 0
                i = i - 1;
            end
            j = j - 1;
        else
            % Berechne die Position des nächsten Punktes basierend auf paramY
            nextY = pathX(:,j - 1) + (pathX(:,j) - pathX(:,j - 1)) * paramY(i - 1, j);

            % Füge das Tupel (x, y) dem Ergebnis hinzu
            result{end+1} = {pathY(i - 1), nextY};
            
            % Wenn _paramY(i - 1, j) gleich 0 ist, verringere j um 1
            if paramY(i - 1, j) == 0
                j = j - 1;
            end
            i = i - 1;
        end
    end
end


%% Heatmap

% Ihre Daten für die Heatmap und den Pfad minimaler Kosten
% Angenommen, Sie haben Ihre Daten in den Matrizen AccumulatedDistanceX und AccumulatedDistanceY sowie im Zellarray Path gespeichert

% Erstellen Sie eine Heatmap der AccumulatedDistanceX-Matrix
figure;
subplot(1,2,1);
imagesc(XAccumulatedDistanceX);
colorbar;
title('AccumulatedDistanceX Heatmap');

% Zeichnen Sie den Pfad minimaler Kosten auf der Heatmap
hold on;
for i = 1:numel(PathIndexes)
    x = PathIndexes{i}(1);
    y = PathIndexes{i}(2);
    plot(y, x, 'w.', 'LineWidth', 2);
end
set(gca, 'YDir', 'normal');
hold off;

subplot(1,2,2);
imagesc(YAccumulatedDistanceY);
colorbar;
title('AccumulatedDistanceY Heatmap');
hold on;
for i = 1:numel(PathIndexes)
    x = PathIndexes{i}(1);
    y = PathIndexes{i}(2);
    plot(y, x, 'w.', 'LineWidth', 2);
end
set(gca, 'YDir', 'normal');
hold off;

%% Abfrage ob die Matrizen gleich sind... 
if XAccumulatedDistanceX == YAccumulatedDistanceY
    disp('Die Kostenfunktionen X und Y sind gleich!')
else
    disp('Die Kostenfunktionen X und Y sind nicht gleich')
end