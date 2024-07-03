function vicon_get_basepoints(positions, min_index_distance, threshold)
%% Zum Testen 
% % clear;
% % load vicon_data_120hz.mat
% 
% positions = vicon_positions/1000;
% 
% % Schrittweite der Indizes für die nach gleichen Punkten gesucht wird
% min_index_distance = 125;
% 
% threshold = 0.1;
%%
if nargin < 3
    % Oberer Grenzwert des Abstands für den Punkte als Gleich angenommen werden
    threshold = 0.1;
end

% Punktweise Berechnung der Abstände
M = size(positions, 1);
position_distances = zeros(M-1, 1);
for i = 1:M-1
    % Differenz zwischen aufeinanderfolgenden Punkten
    diffs = positions(i+1, :) - positions(i, :);
    % Euklidische Distanz
    position_distances(i) = norm(diffs);
end

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
        points_all = [points_all; positions(idx, :)];
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

% Indzies der Daten mit sehr geringem Abstand (gleiche Punkte)
index_equal_points = find(dist_points_all <= threshold*5);

% Fehlermeldung wenn index_equal_points leer ist, möglicherweise weil Daten
% in falscher Einheit vorliegen. 
if isempty(index_equal_points)
    error('Keine Übereinstimmung in den Positionen gefunden. Stellen sie sicher, dass die Positionsdaten in der richtigen Einheit vorliegen (mm)');
end

% Sicherstellen, dass der erste und letzte relevante Punkt nicht gelöscht wird
a = index_equal_points(1:end-1)+1;
index_deleted_points = [index_equal_points(1,:); a];

% Erster Punkt der nicht gelöscht werden darf
first_relevant_point = setdiff(index_deleted_points,index_equal_points);
% index_deleted_points(index_deleted_points==first_relevant_point) = [];
% --> funkts nicht wenn mehrere Punkte 
for i = 1:length(first_relevant_point)
    if ismember(first_relevant_point(i),index_deleted_points)
        index_deleted_points(index_deleted_points==first_relevant_point(i)) = [];
    end
end

indices_points(index_deleted_points) = [];
dist_points(index_deleted_points) = [];
points(index_deleted_points,:) = [];
% Letzer Abstand nicht relevant
dist_points(end) = [];

% Laden in Workspace 
assignin('base',"base_points_idx",indices_points);
assignin('base','base_points_dist',dist_points);
assignin('base',"base_points_vicon",points);


end

%% Plotten
% points(:,1) = points(:,1)+1;
% 
% figure('Color','white'); 
% plot3(vicon_positions(:,1),vicon_positions(:,2),vicon_positions(:,3),'r',LineWidth=2)
% hold on
% plot3(points(:,1),points(:,2),points(:,3),'b',LineWidth=2)
% axis equal
% plot3(points(1,1),points(1,2),points(1,3),'og',LineWidth=2)
% plot3(points(end,1),points(end,2),points(end,3),'ok',LineWidth=5)
% 
% clear indices_points_all indices_threshold idx last_saved_index
% clear  diffs M 