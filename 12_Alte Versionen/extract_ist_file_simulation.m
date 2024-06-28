function extract_ist_file_simulation(filename_excel)
%%
    % %%%%% Eingefügt um nicht als Funtkion zu testen
     % filename_excel = 'iso_diagonal_v2000_15x.xlsx';  % Input Excel file name
    % % ----
    % Lese Daten aus Excel Datei
    data_ist_simulation = readtable(filename_excel);
%%   
    % Überprüfen, ob die Spalten q1_ist, q2_ist, q3_ist und q4_ist vorhanden sind 
    col_names = data_ist_simulation.Properties.VariableNames;
    if ~ismember('q1_ist', col_names) || ~ismember('q2_ist', col_names) || ...
            ~ismember('q3_ist', col_names) || ~ismember('q4_ist', col_names)
        % Hinzufügen nach der letzten Datenspalte, wenn eine der Spalten fehlt
        last_data_col_idx = find(contains(col_names, 'timestamp_ist'), 1, 'last') - 1;
        for i = 1:4
            data_ist_simulation.(sprintf('q%d_ist', i)) = zeros(size(data_ist_simulation, 1), 1, 'uint32');
        end
    end
%%
    % Bereinigen der Daten anhand der Ereignisse, sodass Bahn in Home beginnt

    % events_ist = data_ist_simulation{:,17};
    % index_events = find(~cellfun('isempty', events_ist));

    % data_ist(1:index_events(1)-1,:) = [];
%%    
    % % Extrahiere die Daten aus dem Table 
    % timestamp_ist = data_ist{:, 1};
    % x_ist = data_ist{:, 2};
    % y_ist = data_ist{:, 3};
    % z_ist = data_ist{:, 4};
    % tcp_velocity_ist = data_ist{:, 5};
    % tcp_acceleration_ist = data_ist{:, 6};
    % cpu_temperature_ist = data_ist{:, 7};
    % joint_states_ist = data_ist{:, 8:13};
    % 
    % %%%%% Muss nicht sein.
    % % joint_states_ist in ein einziges Array in Zeilenreihenfolge umwandeln
    % % joint_states_flat = reshape(joint_states_ist', 1, []);
    % 
    % % Abrufen der Werte der Spalten q_ist
    % q_ist_columns = {'q1_ist', 'q2_ist', 'q3_ist', 'q4_ist'};
    % q_ist = zeros(length(timestamp_ist), 4, 'uint32');
    % for i = 1:numel(q_ist_columns)
    %     col_idx = strcmp(col_names, q_ist_columns{i});
    %     if any(col_idx)
    %         q_ist(:, i) = uint32(data_ist{:, col_idx});
    %     end
    % end

    % Events nochmal aktualisieren für später
    % events_ist = data_ist_simulation{:,17};

%%
    % Speichern der Variablen im Workspace
    % assignin('base', 'timestamp_ist', timestamp_ist);
    % assignin('base', 'x_ist', x_ist);
    % assignin('base', 'y_ist', y_ist);
    % assignin('base', 'z_ist', z_ist);
    % assignin('base', 'tcp_velocity_ist', tcp_velocity_ist);
    % assignin('base', 'tcp_acceleration_ist', tcp_acceleration_ist);
    % assignin('base', 'cpu_temperature_ist', cpu_temperature_ist);
    % assignin('base', 'q_ist', q_ist(:, 1:4));
    % assignin('base', 'joint_states_ist', joint_states_ist);
    % % assignin('base', 'joint_states_flat', joint_states_flat);
    % assignin("base","events_ist",events_ist);
    assignin('base','data_ist_simulation',data_ist_simulation);
    assignin('base','col_names',col_names);
    
end