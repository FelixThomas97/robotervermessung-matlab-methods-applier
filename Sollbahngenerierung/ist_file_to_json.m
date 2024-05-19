function  ist_file_to_json(filename_json,data_ist,col_names,i,split)
%%    
    % Extrahiere die Daten aus dem Table 
    timestamp_ist = data_ist{:, 1};
    x_ist = data_ist{:, 2};
    y_ist = data_ist{:, 3};
    z_ist = data_ist{:, 4};
    tcp_velocity_ist = data_ist{:, 5};
    tcp_acceleration_ist = data_ist{:, 6};
    cpu_temperature_ist = data_ist{:, 7};
    joint_states_ist = data_ist{:, 8:13};

    %%%%% Muss nicht sein.
    % joint_states_ist in ein einziges Array in Zeilenreihenfolge umwandeln
    % joint_states_flat = reshape(joint_states_ist', 1, []);

    % Abrufen der Werte der Spalten q_ist
    q_ist_columns = {'q1_ist', 'q2_ist', 'q3_ist', 'q4_ist'};
    q_ist = zeros(length(timestamp_ist), 4, 'uint32');
    for j = 1:numel(q_ist_columns)
        col_idx = strcmp(col_names, q_ist_columns{j});
        if any(col_idx)
            q_ist(:, j) = uint32(data_ist{:, col_idx});
        end
    end
    clear col_names
%%
    % Header Id generieren
    if split == true 
        trajectory_header_id = "robot0"+string(round(posixtime(datetime('now','TimeZone','UTC'))))+string(i);
    else
        trajectory_header_id = "robot0"+string(round(posixtime(datetime('now','TimeZone','UTC'))));
    end

    % Daten als JSON exportieren
    data_json = struct();
    data_json.trajectory_header_id = trajectory_header_id;
    data_json.timestamp_ist = timestamp_ist;
    data_json.x_ist = x_ist/1000;  % Warum in Meter --> in Workspace wird auch in mm geladen
    data_json.y_ist = y_ist/1000;
    data_json.z_ist = z_ist/1000;
    data_json.tcp_velocity_ist = tcp_velocity_ist;
    data_json.tcp_acceleration = tcp_acceleration_ist;
    data_json.cpu_temperature = cpu_temperature_ist;
    data_json.q1_ist = q_ist(:, 1);
    data_json.q2_ist = q_ist(:, 2);
    data_json.q3_ist = q_ist(:, 3);
    data_json.q4_ist = q_ist(:, 4);
    % data_json.joint_states_ist = joint_states_flat;
    data_json.joint_states_ist = joint_states_ist;
%%
    % Konvertiert die Struktur in einen JSON-String
    jsonString = jsonencode(data_json);
    
    % Schreiben der JSON-Zeichenfolge in eine Datei
    if split == true
        fid = fopen(filename_json+string(i)+'.json', 'w');
    else
        fid = fopen(filename_json+string('.json'), 'w');
    end
    if fid == -1
        error('Cannot create JSON file');
    end
    fwrite(fid, jsonString, 'char');
    fclose(fid);
%%
    % Speichern der Variablen im Workspace
    assignin('base', 'trajectory_header_id', trajectory_header_id)
    assignin('base', 'timestamp_ist', timestamp_ist);
    assignin('base', 'x_ist', x_ist);
    assignin('base', 'y_ist', y_ist);
    assignin('base', 'z_ist', z_ist);
    assignin('base', 'tcp_velocity_ist', tcp_velocity_ist);
    assignin('base', 'tcp_acceleration_ist', tcp_acceleration_ist);
    assignin('base', 'cpu_temperature_ist', cpu_temperature_ist);
    assignin('base', 'q_ist', q_ist(:, 1:4));
    assignin('base', 'joint_states_ist', joint_states_ist);
    % assignin('base', 'joint_states_flat', joint_states_flat);

end