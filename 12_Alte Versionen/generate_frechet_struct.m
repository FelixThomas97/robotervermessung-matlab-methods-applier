function generate_frechet_struct(trajectory_header_id, frechet_av, frechet_dist, frechet_distances, frechet_matrix, frechet_path,i,split)

frechet_path = frechet_path';

    % Erzeugung des Structs
    metrics_frechet = struct(); 
    if split == true
        metrics_frechet.trajectory_header_id = trajectory_header_id+string(i);
    else
        metrics_frechet.trajectory_header_id = trajectory_header_id;
    end
    % DTW Johnen
    metrics_frechet.frechet_max_distance = frechet_dist/1000;
    metrics_frechet.frechet_average_distance = frechet_av/1000;
    metrics_frechet.frechet_distances = frechet_distances/1000;
    metrics_frechet.frechet_matrix = frechet_matrix/1000;
    metrics_frechet.frechet_path = frechet_path;
    metrics_frechet.metric_type = 'discrete_frechet'; % 'euclidean'
    

    %% Metrics in Workspace
    assignin("base","metrics_frechet",metrics_frechet)


end