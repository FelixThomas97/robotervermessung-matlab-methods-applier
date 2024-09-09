% Laden der Daten
load('robotdata_ist.mat');
load('robotdata_soll.mat');

% Umwandeln der Tabellen in Arrays
data_odom = table2array(robotdata_ist);
x_odom = data_odom(:,1);
y_odom = data_odom(:,2);
z_odom = data_odom(:,3);

data_soll = table2array(robotdata_soll);
x_soll = data_soll(:,1);
y_soll = data_soll(:,2);
z_soll = data_soll(:,3);

% Erstellen der Kurve und Kartendaten
curvexy = [x_soll, y_soll, z_soll];
mapxy = [x_odom, y_odom, z_odom];
[xy, distance, t] = distance2curve(curvexy, mapxy, 'linear');

% Initialisieren der Matrix für die Liniensegmente
numPoints = size(mapxy, 1);
lines = zeros(numPoints, 6);

% Zeichnen der Figuren und Speichern der Liniensegmente
figure(2)
hold on
plot3(curvexy(:,1), curvexy(:,2), curvexy(:,3), 'ko')

for i = 1:numPoints
    % Zeichnen der Linie
    line([mapxy(i,1), xy(i,1)], [mapxy(i,2), xy(i,2)], [mapxy(i,3), xy(i,3)], 'color', 'red');
    
    % Speichern der Koordinaten in der Matrix
    lines(i, 1:3) = mapxy(i, :); % Startpunkt (x, y, z)
    lines(i, 4:6) = xy(i, :);    % Endpunkt (x, y, z)
end

plot3(x_odom, y_odom, z_odom, 'LineWidth', 3, 'Color', '#003560')

xlim auto
ylim auto
zlim auto
box on
grid on
view(3)
xlabel("x [cm]", "FontWeight", "bold")
ylabel("y [cm]", "FontWeight", "bold")
zlabel("z [cm]", "FontWeight", "bold")

avg_distance = mean(distance);

hold off

% Konvertieren der lines-Matrix in eine Struktur
lineSegments = struct();
for i = 1:numPoints
    lineSegments(i).x = [lines(i, 1), lines(i, 4)];
    lineSegments(i).y = [lines(i, 2), lines(i, 5)];
    lineSegments(i).z = [lines(i, 3), lines(i, 6)];
end

% Konvertieren der Struktur in JSON-Format
jsonStr = jsonencode(lineSegments);

% Speichern der JSON-Zeichenkette in einer Datei
fid = fopen('lineSegments.json', 'w');
if fid == -1, error('Cannot create JSON file'); end
fwrite(fid, jsonStr, 'char');
fclose(fid);

% Ausgabe der Struktur zur Überprüfung
disp(lineSegments);
