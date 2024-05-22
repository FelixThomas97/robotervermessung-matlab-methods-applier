%% Test Test

load iso_path_A_1.mat;

dbquery = struct();
dbquery.x_soll = soll(:,1);
dbquery.y_soll = soll(:,2);
dbquery.z_soll = soll(:,3);
dbquery.x_ist = ist(:,1);
dbquery.y_ist = ist(:,2);
dbquery.z_ist = ist(:,3);


%%
% Angenommen, dbquery ist bereits definiert und initialisiert
data_id = 1; % Beispiel-Daten-ID
resolution = 10; % Beispiel-Interpolationsauflösung
trim_start = 1;
trim_end = 100; % Beispiel-End-Trim-Index

[euclidean_distances, points_interpolation, max_distance, average_distance] = euclideandistance_for_curves(dbquery, resolution, trim_start, trim_end);

% Ausgabe der Ergebnisse
disp('Euclidean Distances:');
disp(euclidean_distances);
disp('Interpolated Points:');
disp(points_interpolation);
disp('Max Distance:');
disp(max_distance);
disp('Average Distance:');
disp(average_distance);
%%
load iso_path_A_1.mat;

bahn_ist = ist;
xy = soll;

% Anzahl der Punkte bestimmen
numPoints = size(bahn_ist, 1);

% Initialisieren der Matrix für die Liniensegmente
lines = zeros(numPoints, 6);

% Füllen der Matrix mit Start- und Endpunkten der Liniensegmente
for i = 1:numPoints
    lines(i, 1:3) = bahn_ist(i, :); % Startpunkt (x, y, z)
    lines(i, 4:6) = xy(i, :);      % Endpunkt (x, y, z)
end

% Ausgabe der Liniensegmente
disp(lines);



% Initialisieren des Zell-Arrays für die Liniensegmente
linesCell = cell(numPoints, 1);

% Füllen des Zell-Arrays mit Start- und Endpunkten der Liniensegmente
for i = 1:numPoints
    linesCell{i} = [bahn_ist(i, :), xy(i, :)];
end

% Ausgabe der Liniensegmente
disp(linesCell);

