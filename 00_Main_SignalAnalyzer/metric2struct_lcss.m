function metric2struct_lcss(trajectory_header_id, lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon,segment_id)

    lcss_path = lcss_path';

    % Erzeugung des Structs
    metrics_lcss = struct(); 

    % Wenn kein i eingeht dann nur die Base-ID
    if nargin < 11
        metrics_lcss.trajectory_header_id = trajectory_header_id;
        metrics_lcss.segment_id = trajectory_header_id;
    else
        metrics_lcss.trajectory_header_id = trajectory_header_id;
        metrics_lcss.segment_id = segment_id;
    end
    % LCSS
    metrics_lcss.lcss_max_distance = lcss_max/1000;
    metrics_lcss.lcss_average_distance = lcss_av/1000;
    metrics_lcss.lcss_distances = lcss_distances/1000;
    metrics_lcss.lcss_X = lcss_X/1000;
    metrics_lcss.lcss_Y = lcss_Y/1000;
    metrics_lcss.lcss_accdist = lcss_accdist/1000;
    metrics_lcss.lcss_path = lcss_path;
    % Score sagt aus wieviel Prozent der Punkte zugeordnet wurden
    metrics_lcss.lcss_score = lcss_score;
    metrics_lcss.lcss_threshold = lcss_epsilon/1000;
    metrics_lcss.metric_type = 'lcss'; 

    %% Metrics in Workspace
    assignin("base","metrics_lcss",metrics_lcss)
    
end