function metric2struct_frechet(trajectory_header_id, frechet_av, frechet_dist, frechet_distances, frechet_matrix, frechet_path,segment_id)

frechet_path = frechet_path';

    % Erzeugung des Structs
    metrics_frechet = struct(); 
    % Wenn kein i eingeht dann nur die Base-ID
    if nargin < 7
         metrics_frechet.trajectory_header_id = trajectory_header_id;
         metrics_frechet.segment_id = trajectory_header_id;
    else
         metrics_frechet.trajectory_header_id = trajectory_header_id;
         metrics_frechet.segment_id = segment_id; 
    end
    % 
    metrics_frechet.frechet_max_distance = frechet_dist/1000;
    metrics_frechet.frechet_average_distance = frechet_av/1000;
    metrics_frechet.frechet_distances = frechet_distances/1000;
    metrics_frechet.frechet_matrix = frechet_matrix/1000;
    metrics_frechet.frechet_path = frechet_path;
    metrics_frechet.metric_type = 'discrete_frechet'; 
    

    %% Metrics in Workspace
    assignin("base","metrics_frechet",metrics_frechet)


end