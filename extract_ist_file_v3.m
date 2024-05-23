function extract_ist_file_v3(filename_excel)
%%
    % %%%%% Eingefügt um nicht als Funtkion zu testen
    % filename_excel = 'iso_diagonal_v1000_15x.xlsx';  % Input Excel file name
    % % ----
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
    data_ist(1:index_events(2)-1,:) = []; % bis zum 2. Ereignis da hier erste Position erreicht wird
    
    % Aktualisieren der Events
    events_ist = data_ist{:,14};

    events_all = rmmissing(events_ist);
%% 
    % Laden in Workspace
    assignin("base","events_ist",events_ist);
    assignin('base','data_ist',data_ist);
    assignin('base','col_names',col_names);
    assignin('base',"events_all",events_all);
    assignin('base',"index_events",index_events);
    
end