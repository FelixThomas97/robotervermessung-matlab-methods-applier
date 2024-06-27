%% Daten laden und Bereinigen
clear;
% IsoCube 1-5: 
data_table = readtable('cubes1to5_v1000_300hz_data.csv');

spline = true;

% Daten separieren, da NaN in verschiedenen Zeilen auftreten
data_time = data_table{:,1:3};
data_pose = data_table{:,4:10};
data_velocity = data_table{:,11:18};
data_accel = data_table{:,19:26};

% Alle NaN Zeilen löschen
clean_NaN = all(isnan(data_pose),2);
data_pose = data_pose(~clean_NaN,:);
clean_NaN = all(isnan(data_velocity),2);
data_velocity = data_velocity(~clean_NaN,:);
clean_NaN = all(isnan(data_accel),2);
data_accel = data_accel(~clean_NaN,:);

% Nur jeden dritten Wert der Zeit Daten verwenden
data_time = data_time(1:3:end, :);

% Daten wieder zusammenführen
data = [data_time data_pose data_velocity data_accel];

clear data_time data_pose data_velocity data_accel clean_NaN

% Positionen und Geschwindigkeit extrahieren und in mm umrechnen
position = data(:,4:6)*1000;
velocity = data(:,14)*1000;

% Punktweise Berechnung der Abstände
M = size(position, 1);
distances = zeros(M-1, 1);
for i = 1:M-1
    % Differenz zwischen aufeinanderfolgenden Punkten
    diff = position(i+1, :) - position(i, :);
    % Euklidische Distanz
    distances(i) = norm(diff);
end

% Oberer Grenzwert des Abstands für den Punkte als Gleich angenommen werden
threshold = 0.05; 

% Schrittweite der Indizes für die nach gleichen Punkten gesucht wird
min_index_distance = 150;

% Indizes der Abstände, die geringer als der Grenzwert sind
indices_threshold = find(distances < threshold);

% Berechnung der Indizes und Punkte ensprechend Schritweitte und Grenzwert
points_all = [];
indices_points_all = [];
last_saved_index = -min_index_distance;  % Initialisierung
for i = 1:length(indices_threshold)
    idx = indices_threshold(i);
    % Speichern der Indizes und Punkte wenn außerhalb der Schrittweite
    if idx - last_saved_index >= min_index_distance
        indices_points_all = [indices_points_all; idx];
        points_all = [points_all; position(idx, :)];
        last_saved_index = idx;
    end
end

% Berechnung der Abstände zwischen den Punkten
dist_points_all = zeros(length(points_all),1);
for i = 1:length(points_all)-1
    diff = points_all(i+1, :) - points_all(i, :);
    dist_points_all(i) = norm(diff);
end


% Neue Vektoren für Abstände Punkte und Indizes
points = points_all;
dist_points = dist_points_all;
indices_points = indices_points_all;

% Löschen der Daten mit zu geringem Abstand (gleiche Punkte)
index_equal_points = find(dist_points_all <= threshold*10);

indices_points(index_equal_points) = [];
dist_points(index_equal_points) = [];
points(index_equal_points,:) = [];
% Letzer Abstand nicht relevant
dist_points(end) = [];

%% 
% Annahme, dass Bahnlängen eine maximale Abweichung von 2-5 mm haben
binWidth = 2;
% Ermitteln der häufigsten Bahnlängen: Annahme diese ist die Kantenlänge des Iso-Würfels
[counts, edges] = histcounts(dist_points, 'BinWidth', binWidth);
[~, max_idx] = max(counts);
most_common_length = (edges(max_idx) + edges(max_idx + 1)) / 2;
most_common_length = round(most_common_length/5)*5;

% Schätzen der Kantenlänge des Würfels
length_edge = most_common_length;

% Berechnung der Diagonalen: Zweite und dritte Wurzel der Kantenlänge
length_root2 = most_common_length*sqrt(2);
length_root3 = most_common_length*sqrt(3);

% Finden der Indizes mit den entsprechenden Kantenlängen
test_edges = abs(dist_points-length_edge);
index_edges = find(test_edges <= binWidth*2);

test_root2 = abs(dist_points-length_root2);
index_root2 = find(test_root2 <= binWidth*2);

test_root3 = abs(dist_points-length_root3);
index_root3 = find(test_root3 <= binWidth*2);

% Relevante Daten anhand des maximalen Index und Minimalen Index finden
max_idx = [max(index_edges) max(index_root2) max(index_root3)];
min_idx = [min(index_edges) min(index_root2) min(index_root3)];

max_idx = max(max_idx);
min_idx = min(min_idx);

% Aktualisieren der benötigten Punkte für die Sollbahngenerierung 
dist_points = dist_points(min_idx:max_idx);
points = points(min_idx:max_idx+1,:);
indices_points = indices_points(min_idx:max_idx+1,:);

% Finden der Indizes die keiner Kante oder Diagonalen entprechen (P2P-Bahnen)
index_relevant = [index_edges; index_root2; index_root3];
index_relevant = sort(index_relevant);
index_all = (1:1:length(dist_points))';
index_p2p = setdiff(index_all,index_relevant);

clear test_root3 test_root2 test_edges
clear most_common_length edges counts 
clear last_index last_saved_index idx i M index_all index_relevant


% Löschen der nicht benötigten Werte am Anfang und am Ende der Messung
data_ist = data(indices_points(1):indices_points(end),:);
trajectory_ist = position(indices_points(1):indices_points(end),:);
% Aktualisieren der Indizes
index_ist = indices_points - indices_points(1)+1;

%% Ist-Bahn in Segmente splitten

% Cell-Array erstellen und abspeichern der Teilbahnen
segments_ist = cell(1,length(dist_points));
for i = 1:1:size(segments_ist,2)

    idx1 = index_ist(i);
    if i < size(segments_ist,2)
        idx2 = index_ist(i+1)-1;
    else
        idx2 = index_ist(i+1);
    end
    segments_ist{i} = trajectory_ist(idx1:idx2,:);    
end

%% Sollbahn-Generierung
keypoints_faktor = 1;
segments_soll = cell(1,length(dist_points));
num_segment = size(segments_soll,2);

diff_length = zeros(length(dist_points),1);

for i = 1:1:num_segment
    
    % Indizes der Anfangs und Endpunkte der Istbahnabschnitte
    idx1 = index_ist(i);
    idx2 = index_ist(i+1);
    
    % Ermittlung der 50 letzten Punkte eines Abschnitts
    last50 = trajectory_ist(idx2-50:idx2,:);
    % Ermittlung der normierten Richtungsvektoren für die 50 Punkte
    last50_direction = zeros(length(last50),3);
    last50_norm_direction = zeros(length(last50),3);
    for j = 1:length(last50)
        last50_direction(j,:) = last50(j,:) - trajectory_ist(idx1,:);
        norm_v = norm(last50_direction(j,:));
        if norm_v ~= 0
            last50_norm_direction(j,:) = last50_direction(j,:)/norm_v;
        end
    end
    
    % Gemitteleter und normierter Richtungsvektor 
    direction_mean = mean(last50_norm_direction,1);
    direction_mean = direction_mean/norm(direction_mean);

    % Anzahl Punkte
    num_soll = abs(round(length(segments_ist{i})*keypoints_faktor)); % aufrunden und immer positiv
    % Erster Punkt 
    first_point = trajectory_ist(idx1,:);
    
    if ismember(i,index_edges)
        last_point = first_point + direction_mean*length_edge;
    elseif ismember(i,index_root2)
        last_point = first_point + direction_mean*length_root2;
    elseif ismember(i,index_root3)
        last_point = first_point + direction_mean*length_root3;
    else
        last_point = trajectory_ist(idx2,:);
    end


    % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
    segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
    
    % Eintragen in Cell-Array
    segments_soll{i} = segment_soll;

    diff_length(i) = vecnorm(first_point-last_point);
end

clear last50_norm_direction last50 last50_direction norm_v

% Daten bereinigen anhand der Punkte die für Sollbahn genutzt werden sollen

trajectory_soll = [];
for i = 1:size(segments_soll,2)
    trajectory_soll = [trajectory_soll; segments_soll{i}];
end
%%
figure;
hold on
plot3(trajectory_soll(:,1),trajectory_soll(:,2),trajectory_soll(:,3),'r')
plot3(trajectory_soll(end,1),trajectory_soll(end,2),trajectory_soll(end,3),'ro',MarkerSize=5,MarkerFaceColor='r')
plot3(trajectory_soll(1,1),trajectory_soll(1,2),trajectory_soll(1,3),'rsquare',MarkerSize=5,MarkerFaceColor='r')

plot3(trajectory_ist(:,1),trajectory_ist(:,2),trajectory_ist(:,3),'b');
plot3(trajectory_ist(end,1),trajectory_ist(end,2),trajectory_ist(end,3),'bo',MarkerSize=5,MarkerFaceColor='b');
plot3(trajectory_ist(1,1),trajectory_ist(1,2),trajectory_ist(1,3),'bsquare',MarkerSize=5,MarkerFaceColor='b');

plot3(trajectory_ist(index_ist(2),1),trajectory_ist(index_ist(2),2),trajectory_ist(index_ist(2),3),'bo',MarkerSize=5,MarkerFaceColor='b');

hold off


%%

% a = min(velocity);
% 
% [b, index] = sort(velocity);
% 
% min_vel = [b index];
% 
% 
% figure;
% plot3(position(:,1),position(:,2),position(:,3));
% hold on 
% % plot3(position(1,1),position(1,2),position(1,3),'o',LineWidth=3);
% % plot3(position(end,1),position(end,2),position(end,3),'o',LineWidth=3);
% 
% plot3(points(:,1),points(:,2),points(:,3),'o',LineWidth=3)
% plot3(points(end,1),points(end,2),points(end,3),'o',LineWidth=3)
% % plot3(points(:,1),points(:,2),points(:,3),'o',LineWidth=3)



