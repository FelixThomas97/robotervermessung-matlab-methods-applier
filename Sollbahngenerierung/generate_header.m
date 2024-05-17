function generate_header(trajectory_header_id, timestamp_ist,num_sample_soll, i,split)

    %% Header - Eintragen
    data_id = trajectory_header_id;
    robot_name = "robot0";
    robot_model = "abb_irb4400";
    trajectory_type = "iso_path_A";
    carthesian = "true";
    path_solver = "abb_steuerung";
    recording_date = "2024-05-16T16:30:00.241866";
    real_robot = "true";
    number_of_points_ist = size(timestamp_ist,1);
    number_of_points_soll = num_sample_soll;
    sample_frequency_ist = length(timestamp_ist)/(timestamp_ist(end)-timestamp_ist(1)); % geändert 
    source = "matlab";

    %% Header Generierung
    header_data = struct(...
    'data_id', data_id, ...
    'robot_name', robot_name, ...
    'robot_model', robot_model, ...
    'trajectory_type', trajectory_type, ...
    'carthesian', carthesian, ...
    'path_solver', path_solver, ...
    'recording_date', recording_date, ...
    'real_robot', real_robot, ...
    'number_of_points_ist', number_of_points_ist, ...
    'number_of_points_soll', number_of_points_soll, ...
    'sample_frequency_ist', sample_frequency_ist, ...
    'source', source);

    % In json Format umwandeln
    jsonStr = jsonencode(header_data);
    
    % json in Datei schreiben
    if split == true
        fid = fopen('header'+string(i)+'.json', 'w');
    else
        fid = fopen('header.json', 'w');
    end
    if fid == -1
        error('Cannot create JSON file');
    end
    fwrite(fid, jsonStr, 'char');
    fclose(fid);
end