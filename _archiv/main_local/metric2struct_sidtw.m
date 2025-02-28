function metric2struct_sidtw(trajectory_header_id,maxDistance_selintdtw, avDistance_selintdtw, ...
    distances_selintdtw,X_selintdtw,Y_selintdtw,accdist_selintdtw,path_selintdtw,segment_id)
    
    path_selintdtw = path_selintdtw';

    % Erzeugung des Structs
    metrics_johnen = struct(); 
    % Wenn kein i eingeht dann nur die Base-ID
    if nargin < 9
        metrics_johnen.trajectory_header_id = trajectory_header_id;
        metrics_johnen.segment_id = trajectory_header_id;
    else
        metrics_johnen.trajectory_header_id = trajectory_header_id;
        metrics_johnen.segment_id = segment_id; 
    end
    % DTW Johnen
    metrics_johnen.dtw_max_distance = maxDistance_selintdtw/1000;
    metrics_johnen.dtw_average_distance = avDistance_selintdtw/1000;
    metrics_johnen.dtw_distances = distances_selintdtw/1000;
    metrics_johnen.dtw_X = X_selintdtw/1000;
    metrics_johnen.dtw_Y = Y_selintdtw/1000;
    metrics_johnen.dtw_accdist = accdist_selintdtw/1000;
    metrics_johnen.dtw_path = path_selintdtw;
    metrics_johnen.metric_type = 'dtw_johnen'; % 'euclidean'
    

    %% Metrics in Workspace
    assignin("base","metrics_johnen",metrics_johnen)


end