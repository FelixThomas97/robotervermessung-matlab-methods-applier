function  ist_file_to_struct(data_ist,col_names,i,split)
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
    data_ist_part = struct();
    data_ist_part.trajectory_header_id = trajectory_header_id;
    data_ist_part.timestamp_ist = timestamp_ist;
    data_ist_part.x_ist = x_ist/1000;  % Warum in Meter --> in Workspace wird auch in mm geladen
    data_ist_part.y_ist = y_ist/1000;
    data_ist_part.z_ist = z_ist/1000;
    data_ist_part.tcp_velocity_ist = tcp_velocity_ist;
    data_ist_part.tcp_acceleration = tcp_acceleration_ist;
    data_ist_part.cpu_temperature = cpu_temperature_ist;
    data_ist_part.q1_ist = q_ist(:, 1);
    data_ist_part.q2_ist = q_ist(:, 2);
    data_ist_part.q3_ist = q_ist(:, 3);
    data_ist_part.q4_ist = q_ist(:, 4);
    data_ist_part.joint_states_ist = joint_states_ist; 

%%
    % if split == true
    %     filename = 'data_ist_'+string(i);
    % else
    %     filename = 'data_ist'; 
    % end

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
    % assignin('base', filename, data_json);

    assignin('base', 'data_ist_part', data_ist_part);
    
end