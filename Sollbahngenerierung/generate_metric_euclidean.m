function generate_metric_euclidean(eucl_distances,trajectory_header_id,i,split)

    eucldist_av = mean(eucl_distances);
    eucldist_max = max(eucl_distances);
    eucldist_stddev = std(eucl_distances);
    
    metrics_euclidean = struct();
    if split == true
        metrics_euclidean.trajectory_header_id = trajectory_header_id+string(i);
    else
        metrics_euclidean.trajectory_header_id = trajectory_header_id;
    end
    % Euklidische Distanz
    metrics_euclidean.euclidean_distances = eucl_distances;
    metrics_euclidean.euclidean_max_distances = eucldist_max;
    metrics_euclidean.euclidean_average_distance = eucldist_av;
    metrics_euclidean.euclidean_standard_deviation = eucldist_stddev;
    metrics_euclidean.euclidean_intersections = []; % Weiss nicht was das ist 
    metrics_euclidean.metric_type = 'euclidean';
    
    %% Header Generierung

    % In json Format umwandeln
    jsonStr = jsonencode(metrics_euclidean);
    
    % json in Datei schreiben
    if split == true
        fid = fopen('metrics_euclidean_'+string(trajectory_header_id)+string(i)+'.json', 'w');
    else
        fid = fopen('metrics_euclidean_'+string(trajectory_header_id)+'.json', 'w');
    end
    if fid == -1
        error('Cannot create JSON file');
    end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);


    %% Metrics in Workspace
    assignin("base","metrics_euclidean",metrics_euclidean)
    assignin("base","eucldist_max",eucldist_max)
    assignin("base","eucldist_av",eucldist_av)
    assignin("base","eucldist_stddev",eucldist_stddev)
    % eventuell noch die interceptions ...