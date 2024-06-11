
% Ist noch nicht feddich! --> main_v2 benutzen!

%% Laden der Daten
clear;
%%%%%%%%%%%%%%%%%%%%%% Bereits hinzugefügte Daten %%%%%%%%%%%%%%%%%%%%%%%%%
% 'iso_diagonal_v1000_15x.xlsx' ---> robot01716299489i
% 'iso_diagonal_v2000_15x.xlsx' ---> robot01716299123i

% filename_excel = 'iso_diagonal_v1000_15x.xlsx';  
filename_excel = 'iso_various_v2000_xx.xlsx';
filename_ist = 'data_ist';   % .json wird später hinzugefügt 
extract_ist_file_v3(filename_excel);

pflag = 0;
split = 0;

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
% Extrahieren der Codezeilen wo Ereignisse stattfinden
pattern = '\d+$'; % sucht nach mehreren aufeinanderfolgenden Ziffern am Ende eines Strings
matches = regexp(events_ist, pattern, 'match'); 
emptyCells = cellfun('isempty', matches); % Findet leere Zellen
matches(emptyCells) = {NaN}; % Füllt leere Zellen mit NaN

% strings in double umwandeln 
events_ist_double = cellfun(@str2double, matches);
events_ist_all = rmmissing(events_ist_double); 
events_ist_double(isnan(events_ist_double)) = 0;

% Indizierung und Anzahl der Keypoints bestimmen
startpoint = events_ist_all(1);
index_num_keypoints = find(events_ist_all ==startpoint)';
num_keypoints = diff(find(events_ist_all ==startpoint))';
num_keypoints(end+1) = diff(events_ist_all(index_num_keypoints(end)):events_ist_all(end));
% Indizes aller Vorkommen des Startwerts finden
wdh_teilbahn = length(find(events_ist_double == startpoint));

% Finden und Anzahl der Ereignisse während Aufzeichnung
events_index = find(~cellfun('isempty', events_ist)); 
events_ist_num = length(events_index);

clear col_names emptyCells  filename_ist filename_excel matches pattern
%%












%%

trajectory_ist = [data_ist(:,2) data_ist(:,3) data_ist(:,4)];
positions_all = zeros(events_ist_num,3);

% Alle Keypoints
for i = 1:1:events_ist_num
    positions_all(i,:) = trajectory_ist(events_index(i),:);
end


positions_soll = cell(1,wdh_teilbahn);
last_index = 0;
first_index = 1;

for i = 1:wdh_teilbahn

    % Sucht nach den Indizes der Keypoints für die einzelnen Sollbahnen
    last_index = first_index + num_keypoints(i);
    num_points = num_keypoints(i)+1;

    index_keypoints = linspace(first_index,last_index,num_points);

    first_index = last_index;

    % Fülle Positionsarray mit den Keypoints der Sollbahnausschnitte
    positions_soll{i} = positions_all(index_keypoints,:);  

end

teilbahnen_soll = cell(1,wdh_teilbahn);
for i = 1:1:length(positions_soll)

    % Interpoliere Sollbahn
    trajectory_soll = interpolate_trajectory(num_points_per_segment,positions_soll{i});
    teilbahnen_soll{i} = trajectory_soll;
end


%% Plots
if pflag
figure(1)
plot3(trajectory_ist(:,1),trajectory_ist(:,2),trajectory_ist(:,3))
figure(2)
plot3(positions_all(:,1),positions_all(:,2),positions_all(:,3))
hold on
plot3(positions_all(1,1),positions_all(1,2),positions_all(1,3),'*r')
figure(3)
plot3(positions_all(1:8,1),positions_all(1:8,2),positions_all(1:8,3))
hold on
plot3(positions_all(8,1),positions_all(8,2),positions_all(8,3),'*r')
end

plot3(teilbahnen_soll{1}(:,1),teilbahnen_soll{1}(:,2),teilbahnen_soll{1}(:,3))
%%

% Um die Anzahl der Keypoints der Bahn herrauszufinden könnte man jetzt einfach
%   die wdh_teilbahnen durch die Anzahl der rapid_lines2 teilen. Es muss aber 
%   auch beachtet werden, dass nachdem die Bahn den Startpunkt erreicht hat, eine 
%   andere Bahn abgefahren wird, wie z.b. bei Random o.ä.. Außerdem kann es sein 
%   dass Aufzeichnungen frühzeitig abgebrochen werden o.ä.
%   Der folgende Code teilt Bahnen immer dann auf, sobald sie erneut den Startpunkt
%   erreichen, unabhängig von der Bahn die gefahren wurde. 


%%







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

