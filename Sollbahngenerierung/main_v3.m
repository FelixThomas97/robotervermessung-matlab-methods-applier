%% Laden der Daten
clear;
%%%%%%%%%%%%%%%%%%%%%% Bereits hinzugefügte Daten %%%%%%%%%%%%%%%%%%%%%%%%%
% 'iso_diagonal_v1000_15x.xlsx' ---> robot01716299489i
% 'iso_diagonal_v2000_15x.xlsx' ---> robot01716299123i

filename_excel = 'iso_diagonal_v1000_15x.xlsx';  
filename_json = 'data_ist';   % .json wird später hinzugefügt 
extract_ist_file_v3(filename_excel);

%% Dateneingabe

    % Dateneingabe für Header
    header_data = struct();
    header_data.data_id = [];                   % leere Zellen werden später gefüllt
    header_data.robot_name = "robot0";
    header_data.robot_model = "abb_irb4400";
    header_data.trajectory_type = "iso_path_A";
    header_data.carthesian = "true";
    header_data.path_solver = "abb_steuerung";
    header_data.recording_date = "2024-05-16T16:37:00.241866";
    header_data.real_robot = "true";
    header_data.number_of_points_ist = [];      % leere Zellen werden später gefüllt
    header_data.number_of_points_soll = [];     % leere Zellen werden später gefüllt
    header_data.sample_frequency_ist = [];      % leere Zellen werden später gefüllt
    header_data.source = "matlab";

    % Besteht Gesamtbahn aus mehreren Bahnen und soll zerlegt werden
    split = true;
% 
%     % Welche Metriken sollen berechnet werden
%     dtw_johnen = true;
%     euclidean = true; 
%     frechet = false;
%     lcss = false;
% 
%     % Automatisch in Datenbank eingtragen
%     mongoDB = true;
% 
%     % Plotten der Ergebnisse 
%     pflag = false;
    
    num_points_per_segment = 50;  % Anzahl der Interpolationspunkte pro Teilbahn
    defined_velocity = 1000;
    %num_sample_soll = num_points_per_segment*(num_key_points-1)+1;


%% 
%%%%%%%% Variante 1 
% Extrahieren der Codezeilen wo Ereignisse stattfinden
pattern = '\d+$'; % sucht nach mehreren aufeinanderfolgenden Ziffern am Ende eines Strings
matches = regexp(events_ist, pattern, 'match'); 

emptyCells = cellfun('isempty', matches); % Findet leere Zellen
matches(emptyCells) = {NaN}; % Füllt leere Zellen mit NaN

% strings in double umwandeln
rapid_lines = cellfun(@str2double, matches);
rapid_start = rapid_lines(1);

% Indizes aller Vorkommen des Startwerts finden
index_teilbahnen = find(rapid_lines == rapid_start);
wdh_teilbahn = length(index_teilbahnen);

% leeres Cell-Array für die Teilbahnen erstellen 
teilbahnen = cell(1,wdh_teilbahn);

% Finden und Anzahl der Ereignisse während Aufzeichnung
events_index = find(~cellfun('isempty', events_ist)); 
num_events_ist = length(events_index);

rapid_lines_num = rmmissing(rapid_lines);
indices = find(rapid_lines_num == rapid_lines_num(1));


% Länge der Zwischenwerte berechnen
if length(rapid_lines_num) > 1
    lengths = diff(rapid_lines_num);
else
    lengths = []; % Falls der Startwert nur einmal vorkommt
end

% disp(lengths);

%% Abfrage ob die Bahn zerlegt werden soll
% 
% if split == true % Bahn soll zerlegt werden
% 
%     struct_header = cell(1,wdh_teilbahn);
%     struct_data = cell(1,wdh_teilbahn);
% 
%     for i = 1:1:wdh_teilbahn
% 
%         if i < wdh_teilbahn
%             teilbahnen{i} = data_ist(index_teilbahnen(i):index_teilbahnen(i+1)-1,:);
%         else
%             teilbahnen{i} = data_ist(index_teilbahnen(i):end,:);
%         end
% 
%         % Ist Daten
%         ist_file_to_struct(teilbahnen{i},col_names,i,split);
%         struct_data{i} = data_ist_part;
%         % Header Daten
%         generate_header_struct(trajectory_header_id, header_data, timestamp_ist,num_sample_soll, i,split);
%         struct_header{i} = header_data;
% 
%         % Ist Daten und Soll Daten zusammenfügen
%         fields_soll = fieldnames(data_soll);
%         for j = 1:length(fields_soll)
%             struct_data{i}.(fields_soll{j}) = data_soll.(fields_soll{j});
%         end
% 
%     end
% 
% else % Bahn soll nicht zerlegt werden
% 
%     % Ist Daten
%     ist_file_to_struct(data_ist,col_names,i,split);
%     struct_data = data_ist_part;  
%     % Header Daten
%     generate_header_struct(trajectory_header_id, header_data, timestamp_ist, num_sample_soll, i,split);
%     struct_header = header_data;
% 
%     % Ist Daten und Soll Daten zusammenfügen
%     fields_soll = fieldnames(data_soll);
%     for j = 1:length(fields_soll)
%         struct_data.(fields_soll{j}) = data_soll.(fields_soll{j});
%     end
% 
% end

