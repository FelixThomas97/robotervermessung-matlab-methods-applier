
function new_base_points(vicon_positions, events_positions,idx_abb_events,data_timestamps,vicon_timestamps)

%% Berechne die Eckpunkte der Vicon-Daten

% vicon_positions = vicon(:,2:4);

% events_positions = data_(idx_abb_events,39:41);
events_timestamps = data_timestamps(idx_abb_events,1);

% Ermittlung der Zeitstempel wo Ereignisse stattfinden
idx_nearest_vicon = zeros(length(events_timestamps),1);
for i = 1:length(events_timestamps)
    [~,idx] = min(abs(events_timestamps(i)-vicon_timestamps));
    % Nächstliegender Index des des Zeitstempels bei Vicon 
    idx_nearest_vicon(i) = idx;
end

% Ausgabewerte berechnen
events_timestamps_vicon = vicon_timestamps(idx_nearest_vicon);

abb_base_points = events_positions;
base_points_vicon = vicon_positions(idx_nearest_vicon,:);
base_points_idx = idx_nearest_vicon;

base_points_dist = diff(base_points_vicon);
base_points_dist = sqrt(sum(base_points_dist.^2, 2));

% In den Workspace laden
assignin('base','abb_base_points',abb_base_points)
assignin("base","base_points_vicon",base_points_vicon)
assignin("base",'base_points_dist',base_points_dist)
assignin('base',"base_points_idx",base_points_idx);
assignin("base","events_timestamps_vicon",events_timestamps_vicon)

end

