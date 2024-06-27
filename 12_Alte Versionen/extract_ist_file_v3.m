% function extract_ist_file_v3(filename_excel)
%%
    % %%%%% Eingefügt um nicht als Funtkion zu testen
    % filename_excel = 'iso_diagonal_v2000_15x.xlsx';  
    filename_excel = 'ist_iso_diagonal_l630_v2000_4x.xlsx';
    % Lese Daten aus Excel Datei
    data_ist = readtable(filename_excel);
%%   
    % Überprüfen, ob die Spalten q1_ist, q2_ist, q3_ist und q4_ist vorhanden sind 
    col_names = data_ist.Properties.VariableNames;
    if ~ismember('q1_ist', col_names) || ~ismember('q2_ist', col_names) || ...
            ~ismember('q3_ist', col_names) || ~ismember('q4_ist', col_names)
        % Hinzufügen nach der letzten Datenspalte, wenn eine der Spalten fehlt
        last_data_col_idx = find(contains(col_names, 'timestamp_ist'), 1, 'last') - 1;
        for i = 1:4
            data_ist.(sprintf('q%d_ist', i)) = zeros(size(data_ist, 1), 1, 'uint32');
        end
    end
%%
    % Bereinigen der Daten anhand der Ereignisse, sodass Bahn in Home beginnt
    events_ist = data_ist{:,14};
    index_events = find(~cellfun('isempty', events_ist));
    data_ist(1:index_events(1)-1,:) = []; % bis zum 1. Ereignis, kommt drauf an ob das Start Ereignis aufgezeichnet wurde...

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
    q_ist = zeros(length(timestamp_ist), 4); % 'uint32' weggemacht
    for j = 1:numel(q_ist_columns)
        col_idx = strcmp(col_names, q_ist_columns{j});
        if any(col_idx)
            q_ist(:, j) = uint32(data_ist{:, col_idx});
        end
    end

    % Aktualisieren der Events
    events_ist = data_ist{:,14};
    data_ist = [timestamp_ist x_ist y_ist z_ist tcp_velocity_ist tcp_acceleration_ist cpu_temperature_ist joint_states_ist q_ist];



    events_all = rmmissing(events_ist);
%% 
    % Laden in Workspace
    assignin("base","events_ist",events_ist);
    assignin('base','data_ist',data_ist);
    assignin('base','col_names',col_names);
    % assignin('base',"events_all",events_all);
    % assignin('base',"index_events",index_events);

    % assignin('base','trajectory_ist',trajectory_ist);
    
% end