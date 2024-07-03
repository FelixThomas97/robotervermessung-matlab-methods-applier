

dist_points = base_points_dist;
points = base_points_vicon;
indices_points = base_points_idx;

% Ist-Bahn vorbereiten: Erkennen welcher Abschnitt des Iso-Cubes
% Annahme, dass Bahnlängen eine maximale Abweichung von ... mm haben
binWidth = 2;
histogram(dist_points, 'BinWidth', binWidth);
% Ermitteln der häufigsten Bahnlängen: Annahme diese ist die Kantenlänge des Iso-Würfels
[counts, edges] = histcounts(dist_points, 'BinWidth', binWidth);
[~, max_idx] = max(counts);
most_common_length = (edges(max_idx) + edges(max_idx + 1)) / 2;
most_common_length = round(most_common_length/5)*5;

%%

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

%%

% Aktualisieren der benötigten Punkte für die Sollbahngenerierung 
dist_points = dist_points(min_idx:max_idx);
points = points(min_idx:max_idx+1,:);
indices_points = indices_points(min_idx:max_idx+1,:);

%%
% Finden der Indizes die keiner Kante oder Diagonalen entprechen (P2P-Bahnen)
index_relevant = [index_edges; index_root2; index_root3];
index_relevant = sort(index_relevant);
index_all = (1:1:length(dist_points))';
index_p2p = setdiff(index_all,index_relevant);
%%
% Löschen der nicht benötigten Werte am Anfang und am Ende der Messung
data_ist = data(indices_points(1):indices_points(end),:);
trajectory_ist = position(indices_points(1):indices_points(end),:);
% Aktualisieren der Indizes
index_ist = indices_points - indices_points(1)+1;

clear root3 root2 edges min_idx max_idx 
clear most_common_length edges counts 
clear last_index last_saved_index index_all index_relevant