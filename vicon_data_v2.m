%% Daten laden und Bereinigen
clear;
% IsoCube 1-5: 
data_table = readtable('cubes1to5_v1000_300hz_data.csv');

% max. Abweichung der Gesamtlänge eines Bahnabschnitts, sonst Spline!
p = 0.03;

% Faktor für Interpolationspunkte der Sollbahn (1 = Anzahl Ist-Bahn)
keypoints_faktor = 1;

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
position_distances = zeros(M-1, 1);
for i = 1:M-1
    % Differenz zwischen aufeinanderfolgenden Punkten
    diffs = position(i+1, :) - position(i, :);
    % Euklidische Distanz
    position_distances(i) = norm(diffs);
end

% Oberer Grenzwert des Abstands für den Punkte als Gleich angenommen werden
threshold = 0.05; 

% Schrittweite der Indizes für die nach gleichen Punkten gesucht wird
min_index_distance = 150;

% Indizes der Abstände, die geringer als der Grenzwert sind
indices_threshold = find(position_distances < threshold);

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
    diffs = points_all(i+1, :) - points_all(i, :);
    dist_points_all(i) = norm(diffs);
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

clear points_all indices_points_all indices_threshold idx last_saved_index
clear dist_points_all diffs M 

%% Ist-Bahn vorbereiten: Erkennen welcher Abschnitt des Iso-Cubes
% Annahme, dass Bahnlängen eine maximale Abweichung von ... mm haben
binWidth = 2;
% histogram(dist_points, 'BinWidth', binWidth);
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
edges = abs(dist_points-length_edge);
index_edges = find(edges <= binWidth*2);

root2 = abs(dist_points-length_root2);
index_root2 = find(root2 <= binWidth*2);

root3 = abs(dist_points-length_root3);
index_root3 = find(root3 <= binWidth*2);

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

% Löschen der nicht benötigten Werte am Anfang und am Ende der Messung
data_ist = data(indices_points(1):indices_points(end),:);
trajectory_ist = position(indices_points(1):indices_points(end),:);
% Aktualisieren der Indizes
index_ist = indices_points - indices_points(1)+1;

clear root3 root2 edges min_idx max_idx 
clear most_common_length edges counts 
clear last_index last_saved_index index_all index_relevant

%% Bahnabschnitte der Ist-Bahn bestimmen
% Auch Klassifizierung ob es sich um P2P-Abschnitte handelt

% Initialisierung der benötigten Arrays
segments_ist = cell(1,length(dist_points));
is_spline = zeros(length(dist_points),1);
dist_segment = zeros(length(dist_points),1);

% Erstellen der Bahnabschnitte und Klassifizierung
for i = 1:1:size(segments_ist,2)

    % Startpunkt und Endpunkt festlegen
    idx1 = index_ist(i);
    if i < size(segments_ist,2)
        idx2 = index_ist(i+1)-1;
    else
        idx2 = index_ist(i+1);
    end
    segments_ist{i} = trajectory_ist(idx1:idx2,:);

    % Punktweise Berechnung der Abstände des Bahnabschnitts
    dists = zeros(size(segments_ist{i},1)-1,1);
    for j = idx1:idx2-1
        % Differenz zwischen aufeinanderfolgenden Punkten
        diffs = trajectory_ist(j+1, :) - trajectory_ist(j, :);
        % Euklidische Distanz
        dists(j-idx1+1) = norm(diffs);
    end
    % Addieren der einzelnen Abstände
    dist_segment(i) = sum(dists);

    % Prüfen ob lineare oder P2P-Bewegung (linear = 0, p2p = 1)
    if abs(dist_segment(i)-length_edge) <= p*length_edge ... 
            || abs(dist_segment(i)-length_root2) <= p*length_root2 ...
            || abs(dist_segment(i)-length_root3) <= p*length_root3
        is_spline(i) = 0;
    else
        is_spline(i) = 1;
    end
end

% Anzahl der Bahnabschnitte die Splines sind
num_splines = length(is_spline(is_spline == 1));

% Für Datenabgleich anhängen
dist_segment = [dist_segment is_spline];

clear diffs dists idx1 idx2


%% Sollbahngenerierung der Bahnabschnitte

% Initialisierung
segments_soll = cell(1,length(dist_points));
num_seg = size(segments_soll,2);

for i = 1:1:num_seg
    
    % Indizes der Anfangs und Endpunkte der Istbahnabschnitte
    idx1 = index_ist(i);
    if i < num_seg
        idx2 = index_ist(i+1)-1;
    else
        idx2 = index_ist(i+1);
    end

    % Ermittlung einer Auswahl an Punkte am Ende eines Abschnitts
    if i < num_seg
        selection = trajectory_ist(idx2-5:idx2+5,:);
    else
        selection = trajectory_ist(idx2-10:idx2,:);
    end
    % Ermittlung der normierten Richtungsvektoren für die 50 Punkte
    selection_direction = zeros(length(selection),3);
    selection_norm_direction = zeros(length(selection),3);
    for j = 1:length(selection)
        selection_direction(j,:) = selection(j,:) - trajectory_ist(idx1,:);
        norm_ = norm(selection_direction(j,:));
        if norm_ ~= 0
            selection_norm_direction(j,:) = selection_direction(j,:)/norm_;
        end
    end
    
    % Gemitteleter und normierter Richtungsvektor 
    direction_mean = mean(selection_norm_direction,1);
    direction_mean = direction_mean/norm(direction_mean);

    % Anzahl Punkte
    num_soll = abs(round(length(segments_ist{i})*keypoints_faktor)); % aufrunden und immer positiv
    % Erster Punkt 
    if i == 1
        first_point = trajectory_ist(idx1,:);
    end
    
    if ismember(i,index_edges)
        last_point = first_point + direction_mean*length_edge;
        % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
        segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
        first_point = last_point;
    elseif ismember(i,index_root2)
        last_point = first_point + direction_mean*length_root2;
        % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
        segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
        first_point = last_point;
    elseif ismember(i,index_root3)
        last_point = first_point + direction_mean*length_root3;
        % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
        segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
        first_point = last_point;
    else
        last_point = trajectory_ist(idx2,:);
        % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
        segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
        first_point = last_point;
    end
    
    % Eintragen in Cell-Array
    segments_soll{i} = segment_soll;

    diff_length(i) = vecnorm(first_point-last_point);
end

clear selection_norm_direction selection selection_direction norm_

% Zu Gesamttrajektorie zusammenführen und Abstände in den Ecken ermitteln
traj_soll_all = [];
diffs_corner = zeros(size(segments_soll,2),1);
for i = 1:size(segments_soll,2)
    traj_soll_all = [traj_soll_all; segments_soll{i}];
    diffs_corner(i) = norm(segments_soll{i}(1,:)-segments_ist{i}(1,:));
end

% Bahnabschnitte und Gesamttrajektorie ohne die als P2P klassifizierten Bahnabschnitte
trajectory_soll = [];
traj_ist_nospline = [];

segments_soll_nospline = cell(1, size(segments_soll,2));

segments_ist_nospline = cell(1, size(segments_ist,2));

for i = 1:size(segments_soll,2)
    if is_spline(i) == 0
        trajectory_soll = [trajectory_soll;  segments_soll{i}];
        traj_ist_nospline = [traj_ist_nospline; segments_ist{i}];
        segments_soll_nospline{i} =  segments_soll{i};
        segments_ist_nospline{i} = segments_ist{i};
    end
end

% Löschen der leeren Zellen 
segments_soll_nospline(cellfun(@isempty,segments_soll_nospline)) = [];
segments_ist_nospline(cellfun(@isempty,segments_ist_nospline)) = [];

% Plot aller Bahnabsschnitte von Soll und Istbahn
figure;
for i = 1:size(segments_soll_nospline,2)
    hold on
    plot3(segments_soll_nospline{i}(:,1),segments_soll_nospline{i}(:,2),segments_soll_nospline{i}(:,3),'b')
end
for i = 1:size(segments_ist,2)
    hold on 
    plot3(segments_ist{i}(:,1),segments_ist{i}(:,2),segments_ist{i}(:,3),'r')
end
%%
% Soll und Istbahnen ohne PTP Segmente
figure;
for i = 1:size(segments_soll_nospline,2)
    hold on
    plot3(segments_soll_nospline{i}(:,1),segments_soll_nospline{i}(:,2),segments_soll_nospline{i}(:,3),'b')
end
for i = 1:size(segments_ist_nospline,2)
    hold on 
    plot3(segments_ist_nospline{i}(:,1),segments_ist_nospline{i}(:,2),segments_ist_nospline{i}(:,3),'r')
end

%%
% figure;
% hold on
% plot3(traj_soll_all(:,1),traj_soll_all(:,2),traj_soll_all(:,3),'r')
% plot3(traj_soll_all(end,1),traj_soll_all(end,2),traj_soll_all(end,3),'ro',MarkerSize=5,MarkerFaceColor='r')
% plot3(traj_soll_all(1,1),traj_soll_all(1,2),traj_soll_all(1,3),'rsquare',MarkerSize=5,MarkerFaceColor='r')
% 
% plot3(trajectory_ist(:,1),trajectory_ist(:,2),trajectory_ist(:,3),'b');
% plot3(trajectory_ist(end,1),trajectory_ist(end,2),trajectory_ist(end,3),'bo',MarkerSize=5,MarkerFaceColor='b');
% plot3(trajectory_ist(1,1),trajectory_ist(1,2),trajectory_ist(1,3),'bsquare',MarkerSize=5,MarkerFaceColor='b');
% 
% plot3(trajectory_ist(index_ist(2),1),trajectory_ist(index_ist(2),2),trajectory_ist(index_ist(2),3),'bo',MarkerSize=5,MarkerFaceColor='b');
% 
% hold off
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

%% Plots der Segmente (mit Splines!)

figure;
hold on
plot3(segments_ist{1}(:,1),segments_ist{1}(:,2),segments_ist{1}(:,3),'r')% spline
plot3(segments_ist{2}(:,1),segments_ist{2}(:,2),segments_ist{2}(:,3),'b')
plot3(segments_ist{3}(:,1),segments_ist{3}(:,2),segments_ist{3}(:,3),'b')
plot3(segments_ist{4}(:,1),segments_ist{4}(:,2),segments_ist{4}(:,3),'b')
plot3(segments_ist{5}(:,1),segments_ist{5}(:,2),segments_ist{5}(:,3),'b')
plot3(segments_ist{6}(:,1),segments_ist{6}(:,2),segments_ist{6}(:,3),'b')
plot3(segments_ist{7}(:,1),segments_ist{7}(:,2),segments_ist{7}(:,3),'b')
plot3(segments_ist{8}(:,1),segments_ist{8}(:,2),segments_ist{8}(:,3),'b')
plot3(segments_ist{9}(:,1),segments_ist{9}(:,2),segments_ist{9}(:,3),'b')
plot3(segments_ist{10}(:,1),segments_ist{10}(:,2),segments_ist{10}(:,3),'r')% spline
plot3(segments_ist{11}(:,1),segments_ist{11}(:,2),segments_ist{11}(:,3),'b')
plot3(segments_ist{12}(:,1),segments_ist{12}(:,2),segments_ist{12}(:,3),'b')
plot3(segments_ist{13}(:,1),segments_ist{13}(:,2),segments_ist{13}(:,3),'b')
plot3(segments_ist{14}(:,1),segments_ist{14}(:,2),segments_ist{14}(:,3),'b')
plot3(segments_ist{15}(:,1),segments_ist{15}(:,2),segments_ist{15}(:,3),'b')
plot3(segments_ist{16}(:,1),segments_ist{16}(:,2),segments_ist{16}(:,3),'r')% spline
plot3(segments_ist{17}(:,1),segments_ist{17}(:,2),segments_ist{17}(:,3),'r')% spline
plot3(segments_ist{18}(:,1),segments_ist{18}(:,2),segments_ist{18}(:,3),'b')
plot3(segments_ist{19}(:,1),segments_ist{19}(:,2),segments_ist{19}(:,3),'r')% spline
plot3(segments_ist{20}(:,1),segments_ist{20}(:,2),segments_ist{20}(:,3),'r')% spline
plot3(segments_ist{21}(:,1),segments_ist{21}(:,2),segments_ist{21}(:,3),'b')
plot3(segments_ist{22}(:,1),segments_ist{22}(:,2),segments_ist{22}(:,3),'b')
plot3(segments_ist{23}(:,1),segments_ist{23}(:,2),segments_ist{23}(:,3),'b')
plot3(segments_ist{24}(:,1),segments_ist{24}(:,2),segments_ist{24}(:,3),'b')
plot3(segments_ist{25}(:,1),segments_ist{25}(:,2),segments_ist{25}(:,3),'b')
plot3(segments_ist{26}(:,1),segments_ist{26}(:,2),segments_ist{26}(:,3),'b')
plot3(segments_ist{27}(:,1),segments_ist{27}(:,2),segments_ist{27}(:,3),'b')
plot3(segments_ist{28}(:,1),segments_ist{28}(:,2),segments_ist{28}(:,3),'r')% spline
plot3(segments_ist{29}(:,1),segments_ist{29}(:,2),segments_ist{29}(:,3),'b')
plot3(segments_ist{30}(:,1),segments_ist{30}(:,2),segments_ist{30}(:,3),'b')
plot3(segments_ist{31}(:,1),segments_ist{31}(:,2),segments_ist{31}(:,3),'b')
plot3(segments_ist{32}(:,1),segments_ist{32}(:,2),segments_ist{32}(:,3),'b')
plot3(segments_ist{33}(:,1),segments_ist{33}(:,2),segments_ist{33}(:,3),'b')
plot3(segments_ist{34}(:,1),segments_ist{34}(:,2),segments_ist{34}(:,3),'b')
plot3(segments_ist{35}(:,1),segments_ist{35}(:,2),segments_ist{35}(:,3),'b')
plot3(segments_ist{36}(:,1),segments_ist{36}(:,2),segments_ist{36}(:,3),'b')
plot3(segments_ist{37}(:,1),segments_ist{37}(:,2),segments_ist{37}(:,3),'r')% spline
plot3(segments_ist{38}(:,1),segments_ist{38}(:,2),segments_ist{38}(:,3),'b')
plot3(segments_ist{39}(:,1),segments_ist{39}(:,2),segments_ist{39}(:,3),'b')
plot3(segments_ist{40}(:,1),segments_ist{40}(:,2),segments_ist{40}(:,3),'b')
plot3(segments_ist{41}(:,1),segments_ist{41}(:,2),segments_ist{41}(:,3),'b')
plot3(segments_ist{42}(:,1),segments_ist{42}(:,2),segments_ist{42}(:,3),'b')
plot3(segments_ist{43}(:,1),segments_ist{43}(:,2),segments_ist{43}(:,3),'b')
plot3(segments_ist{44}(:,1),segments_ist{44}(:,2),segments_ist{44}(:,3),'b')
plot3(segments_ist{45}(:,1),segments_ist{45}(:,2),segments_ist{45}(:,3),'b')


%%
figure;
plot3(trajectory_soll(:,1),trajectory_soll(:,2),trajectory_soll(:,3))
hold on
plot3(trajectory_ist(:,1),trajectory_ist(:,2),trajectory_ist(:,3),'r');

