function generate_dtwjohnen_json(trajectory_header_id,maxDistance_selintdtw, avDistance_selintdtw, ...
    distances_selintdtw,X_selintdtw,Y_selintdtw,accdist_selintdtw,path_selintdtw,i,split)
    
    path_selintdtw = path_selintdtw';

    metrics_johnen = struct(); 
    if split == true
        metrics_johnen.trajectory_header_id = trajectory_header_id+string(i);
    else
        metrics_johnen.trajectory_header_id = trajectory_header_id;
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
    
    %% Header Generierung

    % In json Format umwandeln
    jsonStr = jsonencode(metrics_johnen);
    
    % json in Datei schreiben
    if split == true
        fid = fopen('metrics_johnen_'+string(trajectory_header_id)+string(i)+'.json', 'w');
    else
        fid = fopen('metrics_johnen_'+string(trajectory_header_id)+'.json', 'w');
    end
    if fid == -1
        error('Cannot create JSON file');
    end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);


    %% Metrics in Workspace
    assignin("base","metrics_johnen",metrics_johnen)


end