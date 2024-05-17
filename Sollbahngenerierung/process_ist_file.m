function process_ist_file(filename_excel, filename_json)


    % %%%%% Eingefügt um nicht als Funtkion zu testen
    % filename_excel = 'iso_diagonal_v1000_15x.xlsx';  % Input Excel file name
    % filename_json = 'data_ist.json';   % Output JSON file name
    % ----
    % Lese Daten aus Excel Datei
    data_ist = readtable(filename_excel);
%%   
    % Überprüfen, ob die Spalten q1_ist, q2_ist, q3_ist und q4_ist vorhanden sind 
    col_names = data_ist.Properties.VariableNames;
    if ~ismember('q1_ist', col_names) || ~ismember('q2_ist', col_names) || ...
            ~ismember('q3_ist', col_names) || ~ismember('q4_ist', col_names)
        % Hinzufügen nach der letzten Datenspalte, wenn eine der Spalten fehlt
        last_data_col_idx = find(contains(col_names, 'timestamp_ist'), 1, 'last') - 1; % ???
        for i = 1:4
            data_ist.(sprintf('q%d_ist', i)) = zeros(size(data_ist, 1), 1, 'uint32');
        end
    end
%% So Funktioniert nicht!
    % Entferne Zeilen mit fehlenden Werten
    % data_ist =rmmissing(data_ist);
%%%%%%%%% Test Test Test
    % data1 = rmmissing(data_ist);
    % data2 = table2array(data1(:, {'TCP_Position_X_PositionBezogenAufDasAktuelleWerkobjekt','TCP_Position_Y_PositionBezogenAufDasAktuelleWerkobjekt','TCP_Position_Z_PositionBezogenAufDasAktuelleWerkobjekt'}));
    % plot3(data2(:,1),data2(:,2),data2(:,3),'*k')

%%
    % Bereinigen der Daten anhand der Ereignisse, sodass Bahn in Home beginnt
    events_ist = data_ist{:,14};
    index_events = find(~cellfun('isempty', events_ist));
    data_ist(1:index_events(2)-1,:) = [];
%%    
    % Extrahiere die restlichen Daten aus Tabelle
    trajectory_header_id = "robot0"+string(round(posixtime(datetime('now','TimeZone','UTC'))));
    timestamp_ist = data_ist{:, 1};
    x_ist = data_ist{:, 2};
    y_ist = data_ist{:, 3};
    z_ist = data_ist{:, 4};
    tcp_velocity_ist = data_ist{:, 5};
    tcp_acceleration_ist = data_ist{:, 6};
    cpu_temperature_ist = data_ist{:, 7};
    joint_states_ist = data_ist{:, 8:13};
    % Events nochmal aktualisieren für später
    events_ist = data_ist{:,14};
    %%%%% Muss nicht sein.
    % joint_states_ist in ein einziges Array in Zeilenreihenfolge umwandeln
    % joint_states_flat = reshape(joint_states_ist', 1, []);
    
    % Abrufen der Werte der Spalten q_ist
    q_ist_columns = {'q1_ist', 'q2_ist', 'q3_ist', 'q4_ist'};
    q_ist = zeros(length(timestamp_ist), 4, 'uint32');
    for i = 1:numel(q_ist_columns)
        col_idx = strcmp(col_names, q_ist_columns{i});
        if any(col_idx)
            q_ist(:, i) = uint32(data_ist{:, col_idx});
        end
    end
       
    %%
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
    fid = fopen(filename_json, 'w');
    if fid == -1
        error('Cannot create JSON file');
    end
    fwrite(fid, jsonString, 'char');
    fclose(fid);
    
    % Speichern der Variablen im Workspace
    assignin('base', 'trajectory_header_id', trajectory_header_id)
    assignin('base', 'timestamp_ist', timestamp_ist);
    assignin('base', 'x_ist', x_ist);
    assignin('base', 'y_ist', y_ist);
    assignin('base', 'z_ist', z_ist);
    assignin('base', 'tcp_velocity_ist', tcp_velocity_ist);
    assignin('base', 'tcp_acceleration_ist', tcp_acceleration_ist);
    assignin('base', 'cpu_temperature_ist', cpu_temperature_ist);
    assignin('base', 'q1_ist', q_ist(:, 1));
    assignin('base', 'q2_ist', q_ist(:, 2));
    assignin('base', 'q3_ist', q_ist(:, 3));
    assignin('base', 'q4_ist', q_ist(:, 4));
    assignin('base', 'joint_states_ist', joint_states_ist);
    % assignin('base', 'joint_states_flat', joint_states_flat);
    assignin("base","events_ist",events_ist);
    assignin('base','data_ist',data_ist);
end