function metric2struct_dtw(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y,i)

    dtw_path = dtw_path';

    % Erzeugung des Structs
    metrics_dtw = struct(); 

    % Wenn kein i eingeht dann nur die Base-ID
    if nargin < 9
        metrics_dtw.trajectory_header_id = trajectory_header_id;
    else
        metrics_dtw.trajectory_header_id = trajectory_header_id+string(i);
    end
    % DTW Johnen
    metrics_dtw.dtw_max_distance = dtw_max/1000;
    metrics_dtw.dtw_average_distance = dtw_av/1000;
    metrics_dtw.dtw_distances = dtw_distances/1000;
    metrics_dtw.dtw_X = dtw_X/1000;
    metrics_dtw.dtw_Y = dtw_Y/1000;
    metrics_dtw.dtw_accdist = dtw_accdist/1000;
    metrics_dtw.dtw_path = dtw_path;
    metrics_dtw.metric_type = 'dtw_standard'; % 'euclidean'
    

    %% Metrics in Workspace
    assignin("base","metrics_dtw",metrics_dtw)
    
end