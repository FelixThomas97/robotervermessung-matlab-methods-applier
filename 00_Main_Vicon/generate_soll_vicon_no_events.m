function generate_soll_vicon_no_events(data,position,points,points_dist,points_idx,keypoints_faktor,threshold)
%% Zum Testen
% clear;
% load base_points_test1.mat
% points_dist = base_points_dist;
% points = base_points_vicon;
% points_idx = base_points_idx;
% 
% data = vicon; 
% position = vicon_transformed;
% % Ursprüngliche Vicon Daten mit transformierten Vicon Daten überschreiben
% data(:,2:4) = position;
% 
% % 3% von der Länge der programmierten Bahn
% p = 0.03;
% % Anzahl der Punkte der Sollbahn 
% keypoints_faktor = 1;
% 
% % So für 250Hz gut
% threshold = 0.1*4;
%%
% Ursprüngliche Vicon Daten mit transformierten Vicon Daten überschreiben
data(:,2:4) = position;

% 3% von der Länge der programmierten Bahn (erstmal fix angenommen)
p = 0.03;

% Abstand zwischen zwei Punkten für den diese als gleich gelten
% Standardabweichung *3
threshold = threshold*3;

%% Ist-Bahn vorbereiten: Erkennen welcher Abschnitt des Iso-Cubes
% Annahme, dass Bahnlängen eine maximale Abweichung von ... mm haben
binWidth = 2;
% histogram(points_dist, 'BinWidth', binWidth);
% Ermitteln der häufigsten Bahnlängen: Annahme diese ist die Kantenlänge des Iso-Würfels
[counts, edges] = histcounts(points_dist, 'BinWidth', binWidth);
[~, max_idx] = max(counts);
% Runden auf 5mm 
most_common_length = (edges(max_idx) + edges(max_idx + 1)) / 2;
most_common_length = round(most_common_length/5)*5;

% Schätzen der Kantenlänge des Würfels
length_edge = most_common_length;

% Berechnung der Diagonalen: Zweite und dritte Wurzel der Kantenlänge
length_root2 = most_common_length*sqrt(2);
length_root3 = most_common_length*sqrt(3);

% Finden der Indizes mit den entsprechenden Kantenlängen
edges = abs(points_dist-length_edge);
index_edges = find(edges <= binWidth*2);

root2 = abs(points_dist-length_root2);
index_root2 = find(root2 <= binWidth*2);

root3 = abs(points_dist-length_root3);
index_root3 = find(root3 <= binWidth*2);

% Relevante Daten anhand des maximalen Index und Minimalen Index finden
max_idx = [max(index_edges) max(index_root2) max(index_root3)];
min_idx = [min(index_edges) min(index_root2) min(index_root3)];

max_idx = max(max_idx);
min_idx = min(min_idx);

% Aktualisieren der benötigten Punkte für die Sollbahngenerierung 
points_dist = points_dist(min_idx:max_idx);
points = points(min_idx:max_idx+1,:);
points_idx = points_idx(min_idx:max_idx+1,:);

% Finden der Indizes die keiner Kante oder Diagonalen entprechen (P2P-Bahnen)
index_relevant = [index_edges; index_root2; index_root3];
index_relevant = sort(index_relevant);
index_all = (1:1:length(points_dist))';
index_p2p = setdiff(index_all,index_relevant);

% Löschen der nicht benötigten Werte am Anfang und am Ende der Messung
data_ist = data(points_idx(1):points_idx(end),:);
trajectory_ist = position(points_idx(1):points_idx(end),:);

% Aktualisieren der Indizes
index_ist = points_idx - points_idx(1)+1;

clear root3 root2 edges min_idx max_idx 
clear most_common_length edges counts 
clear last_index last_saved_index index_all index_relevant

%% Bahnabschnitte der Ist-Bahn bestimmen
% Auch Klassifizierung ob es sich um P2P-Abschnitte handelt


% Initialisierung der benötigten Arrays
segments_ist = cell(1,length(points_dist));
is_spline = zeros(length(points_dist),1);
dist_segment_ist = zeros(length(points_dist),1);

% Erstellen der Bahnabschnitte und Klassifizierung
for i = 1:1:size(segments_ist,2)

    % Startpunkt und Endpunkt festlegen
    idx1 = index_ist(i);
    if i < size(segments_ist,2)
        idx2 = index_ist(i+1)-1;
    else
        idx2 = index_ist(i+1);
    end
    segments_ist{i} = data_ist(idx1:idx2,:);

    % Punktweise Berechnung der Abstände des Bahnabschnitts
    dists = zeros(size(segments_ist{i},1)-1,1);
    for j = idx1:idx2-1
        % Differenz zwischen aufeinanderfolgenden Punkten
        diffs = trajectory_ist(j+1, :) - trajectory_ist(j, :);
        % Euklidische Distanz
        dists(j-idx1+1) = norm(diffs);
    end
    % Addieren der einzelnen Abstände
    dist_segment_ist(i) = sum(dists);

    % Prüfen ob lineare oder P2P-Bewegung (linear = 0, p2p = 1)
    if abs(dist_segment_ist(i)-length_edge) <= p*length_edge ... 
            || abs(dist_segment_ist(i)-length_root2) <= p*length_root2 ...
            || abs(dist_segment_ist(i)-length_root3) <= p*length_root3
        is_spline(i) = 0;
    else
        is_spline(i) = 1;
    end
end

% Anzahl der Bahnabschnitte die Splines sind
num_splines = length(is_spline(is_spline == 1));

% Für Datenabgleich anhängen
dist_segment_ist = [dist_segment_ist is_spline];

clear diffs dists idx1 idx2

%% Sollbahngenerierung der Bahnabschnitte

check_dim = 0;

% Initialisierung
segments_soll = cell(1,length(points_dist));
num_seg = size(segments_soll,2);
dist_segment_soll = zeros(size(segments_soll,2),1);

for i = 1:1:num_seg
    
    % Indizes der Anfangs und Endpunkte der Istbahnabschnitte
    idx1 = index_ist(i);
    if i < num_seg
        idx2 = index_ist(i+1)-1;
    else
        idx2 = index_ist(i+1);
    end

    % % Ermittlung einer Auswahl an Punkte am Ende eines Abschnitts
    % if i < num_seg
    %     selection = trajectory_ist(idx2-5:idx2+5,:);
    %     % selection = trajectory_ist(idx2:idx2,:);
    % else
    %     selection = trajectory_ist(idx2-10:idx2,:);
    % end
    % <--- so war vorher...

    % Ermittlung einer Auswahl an Punkte am Ende eines Abschnitts
    idxend = idx2;
    while idxend < size(trajectory_ist,1) && norm(trajectory_ist(idxend+1, :) - trajectory_ist(idxend, :)) < threshold
        idxend = idxend +1;
    end
    selection = trajectory_ist(idx2:idxend,:);
    
    % Nur zur überprüfung wie oft nur ein Wert in der selection gefunden wird
    if size(selection,1) == 1
        check_dim = check_dim +1;
    end

    % Ermittlung der normierten Richtungsvektoren für die Auswahl an Punkten
    selection_mean = mean(selection,1);
    selection_direction = selection_mean - trajectory_ist(idx1,:);
    selection_direction = selection_direction/norm(selection_direction);
    
    % Anzeigen der Distanzen der Auswahl zum Mittelwert der Auswahl
    mean_distance = mean(vecnorm(selection - selection_mean));

    % Ermittlung der normierten Richtungsvektoren für die Auswahl an Punkten
    % selection_direction = zeros(length(selection),3);
    % selection_norm_direction = zeros(length(selection),3);
    % for j = 1:size(selection,1)
    %     selection_direction(j,:) = selection(j,:) - trajectory_ist(idx1,:);
    %     norm_ = norm(selection_direction(j,:));
    %     if norm_ ~= 0
    %         selection_norm_direction(j,:) = selection_direction(j,:)/norm_;
    %     end
    % end
    % 
    % % Gemitteleter und normierter Richtungsvektor 
    % selection_direction = mean(selection_direction,1);
    % selection_direction = selection_direction/norm(selection_direction);
    %<--- so war vorher

    % Anzahl Punkte
    num_soll = abs(round(length(segments_ist{i})*keypoints_faktor)); % aufrunden und immer positiv
        
    % Falls erste Distanz keine erlaubte Kante im ISO-Würfel ist, müssen
    % die Indizes der Distanzen um 1 reduziert werden, sonst verschiebt
    % sich der Würfel. 
    if i == 1 && ~ismember(1,index_edges) && ~ismember(1,index_root2) && ~ismember(1,index_root3)
        first_point = trajectory_ist(idx1,:);
        index_edges = index_edges -1;
        index_root2 = index_root2 -1;
        index_root3 = index_root3 -1;
    elseif i == 1
        first_point = trajectory_ist(idx1,:);
    end
    
    if ismember(i,index_edges)
        % last_point = selection_mean;
        last_point = first_point + selection_direction*length_edge;
        % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
        segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
    elseif ismember(i,index_root2)
        % last_point = selection_mean;
        last_point = first_point + selection_direction*length_root2;
        % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
        segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
    elseif ismember(i,index_root3)
        % last_point = selection_mean;
        last_point = first_point + selection_direction*length_root3;
        % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
        segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
    else
        % last_point = trajectory_ist(idx2,:);
        last_point = first_point + selection_direction*length_edge;
        % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
        segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
    end
    
    % Eintragen in Cell-Array
    segments_soll{i} = segment_soll;
    
    % Distanzen der Bahnabschnitte
    dist_segment_soll(i) = vecnorm(first_point-last_point);
    
    % letzen Punkt als neuen ersten Punkt setzen
    first_point = last_point;
end

% Berechnung der Abstände in den Ecken
dist_segment_corner = zeros(size(segments_soll,2),1);
for i = 1:size(segments_soll,2)
    dist_segment_corner(i) = norm(segments_soll{i}(1,:)-segments_ist{i}(1,2:4));
end

clear selection_direction first_point last_point i j %selection
clear idx1 idx2 idxend mean_distance num_soll

%% Laden in Workspace
assignin("base","vicon_cleaned",data_ist);
assignin("base","segments_ist",segments_ist);
assignin("base","segments_soll",segments_soll);
assignin("base","is_spline",is_spline);
assignin("base","dist_segment_soll",dist_segment_soll);
assignin("base","dist_segment_ist",dist_segment_ist);
assignin("base","dist_segment_corner",dist_segment_corner);


%% Zur Überprüfung euklidische Distanz berechnen
% [~,eucl_dists,~] = distance2curve(trajectory_ist,trajectory_soll,'linear');
% eucl_mean = mean(eucl_dists);
% eucl_max = max(eucl_dists);

%% Plot aller Segmente der beiden Trajektorien
% % Plot aller Bahnabsschnitte von Soll und Istbahn
% figure;
% for i = 1:size(segments_soll_nospline,2)
%     hold on
%     plot3(segments_soll_nospline{i}(:,1),segments_soll_nospline{i}(:,2),segments_soll_nospline{i}(:,3),'b')
% end
% for i = 1:size(segments_ist,2)
%     hold on 
%     plot3(segments_ist{i}(:,1),segments_ist{i}(:,2),segments_ist{i}(:,3),'r')
% end
% 
% % Plot der beiden Trajektorien
% figure('Color','white'); 
% % plot3(vicon_transformed(:,1),vicon_transformed(:,2),vicon_transformed(:,3),'k',LineWidth=3)
% hold on
% plot3(trajectory_ist(:,1),trajectory_ist(:,2),trajectory_ist(:,3),'b')
% plot3(trajectory_soll(:,1),trajectory_soll(:,2),trajectory_soll(:,3),'r')
% xlabel('x'); ylabel('y'); zlabel('z');
% axis equal


end