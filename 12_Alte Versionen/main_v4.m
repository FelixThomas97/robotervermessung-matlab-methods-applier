
% Ist noch nicht feddich! --> main_v2 benutzen!

%% Dateneingabe

    % % Dateneingabe Header
    % header_data = struct();
    % header_data.data_id = [];                               % automatisch
    % header_data.robot_name = "robot0";
    % header_data.robot_model = "abb_irb4400";
    % header_data.trajectory_type = "iso_path_A";
    % header_data.carthesian = "true";
    % header_data.path_solver = "abb_steuerung";
    % header_data.recording_date = "2024-05-16T16:37:00.241866";
    % header_data.real_robot = "true";
    % header_data.number_of_points_ist = [];                  % automatisch
    % header_data.number_of_points_soll = [];                 % automatisch
    % header_data.sample_frequency_ist = [];                  % automatisch
    % header_data.source = "matlab";

    % Besteht Gesamtbahn aus mehreren Bahnen und soll zerlegt werden
%     split = false;
% % 
% %     % Welche Metriken sollen berechnet werden
% %     dtw_johnen = true;
% %     euclidean = true; 
% %     frechet = false;
% %     lcss = false;
% % 
% %     % Automatisch in Datenbank eingtragen
% %     mongoDB = true;
% % 
%     % Plotten der Ergebnisse 
%     pflag = false;
    
    % num_points_per_segment = 50;  % Anzahl der Interpolationspunkte pro Teilbahn
    % defined_velocity = 1000;
    % num_sample_soll = num_points_per_segment*(num_key_points-1)+1;
%% Laden der Daten


%%%%%%%%%%%%%%%%%%%%%% Bereits hinzugefügte Daten %%%%%%%%%%%%%%%%%%%%%%%%%
% 'iso_diagonal_v1000_15x.xlsx' ---> robot01716299489i
% 'iso_diagonal_v2000_15x.xlsx' ---> robot01716299123i

% filename_excel = 'iso_diagonal_v1000_15x.xlsx';  
% filename_excel = 'iso_various_v2000_xx.xlsx';
% filename_excel = 'iso_diagonal_v2000_15x.xlsx'; 
%%
clear;
% filename_excel_ist = 'ist_iso_diagonal_l630_v2000_4x.xlsx';
filename_excel_ist = 'iso_various_v2000_xx.xlsx';
filename_excel_soll = 'soll_iso_diagonal_l630_v2000_1x.xlsx';
filename_excel_soll = [];

%%
% Datenvorverarbeitung für durch ABB Robot Studio generierte Tabellen
abb_data_provison(filename_excel_ist);
% Zerlegung der Bahnen in einzelne Segmente und vollständige Messdurchläufe
calc_abb_trajectories(data_ist,events_ist,events_all_ist);

% Überprüfen ob eine Sollbahn interpoliert werden muss
if isempty(filename_excel_soll) == 1
    interpolate = true;
else
    interpolate = false;
    abb_data_provison(filename_excel_soll,interpolate);
    calc_abb_trajectories(data_soll,events_soll,events_all_soll,interpolate)
end
% %%
% % Datenvorverarbeitung für durch ABB Robot Studio generierte Tabellen
% abb_data_soll_provison(filename_excel_ist);
% % Zerlegung der Bahnen in einzelne Segmente und vollständige Messdurchläufe
% calc_abb_trajectories(data_ist,events_ist,events_all_ist);
% 
% % Überprüfen ob eine Sollbahn interpoliert werden muss
% if isempty(filename_excel_soll) == 1
%     interpolate = true;
% else
%     interpolate = false;
%     abb_data_soll_provison(filename_excel_soll,interpolate);
%     calc_abb_trajectories(data_soll,events_soll,events_all_soll,interpolate)
% end

%%
% Multiplikationsfaktor für die Anzahl der Punkte der Sollbahn
keypoints_faktor = 1;

% Einmal vorab die Base für die ID generieren
trajectory_header_id_base = "robot0"+string(round(posixtime(datetime('now','TimeZone','UTC'))));

%% Generiere Sollbahn für die einzelnen Bahnabschnitte

segments_soll = cell(1,length(segments_ist));

for i = 1:1:num_segment

    segment_ist = segments_ist{i}(:,2:4);
    num_soll = abs(round(length(segment_ist)*keypoints_faktor)); % aufrunden und immer positiv
    first_point = segment_ist(1,:);
    last_point = segment_ist(end,:);

    % Lineare Interpolation zwischen Anfangs- und Endpunkt des Segments mit gleichbleibenden Abständen
    segment_soll = interp1([0 1], [first_point; last_point], linspace(0, 1, num_soll)); 
    
    % Eintragen 2n Cell-Array
    segments_soll{i} = segment_soll;
end

%% Zusammensetzen der Sollbahn-Abschnitte für gesamte Bahnen

index_first_elements = find(events_all_ist == events_all_ist(1));
segments_per_traj = diff(index_first_elements);

trajectories_soll = cell(1,length(trajectories_ist));
count = 1;

for i = 1:1:length(segments_per_traj)+1
    b = zeros(1,3);
    if i < length(segments_per_traj)+1
        k = segments_per_traj(i);

        for j = 1:1:k
            a = segments_soll{count};
            b = [b; a];
            count = count + 1;
        end

    else

        for j = count:1:num_segment
        a = segments_soll{j};
        b = [b;a];
        end

    end
    b = b(2:end,:);
    trajectories_soll{i} = b;
end

%% Datenstrukturen erzeugen

defined_velocity = 2000;

struct_data = cell(1,num_trajectories);

for i = 1:1:num_trajectories
    
    % Funktionen zur Erzeugung der Datenstruktur für Soll und Istbahn 
    generate_struct_data_soll(trajectories_soll{i}, defined_velocity, interpolate);
    generate_struct_data_ist(trajectories_ist{i},trajectory_header_id_base,i)

    % Istdaten in die Struktur schreiben
    struct_data{i} = data_ist_part;
    
    % Solldaten der Struktur hinzufügen
    fields_soll = fieldnames(data_soll);
    for j = 1:length(fields_soll)
        struct_data{i}.(fields_soll{j}) = data_soll.(fields_soll{j});
    end

end


%% Funktionen

% Generiere Struktur der Istdaten für die Datenbankeintragung 
function generate_struct_data_ist(trajectory_ist,trajectory_header_id_base,i)

    % Extrahiere die Daten aus dem Table 
    timestamp_ist = trajectory_ist(:, 1);
    x_ist = trajectory_ist(:, 2);
    y_ist = trajectory_ist(:, 3);
    z_ist = trajectory_ist(:, 4);
    tcp_velocity_ist = trajectory_ist(:, 5);
    tcp_acceleration_ist = trajectory_ist(:, 6);
    cpu_temperature_ist = trajectory_ist(:, 7);
    joint_states_ist = trajectory_ist(:, 8:13);
    q_ist = trajectory_ist(:, 14:17);

    % Header ID nur hochzählen wenn mehrere Bahnen existieren !
    if nargin < 3
    % Header ID generieren
        trajectory_header_id = trajectory_header_id_base;
    else
        trajectory_header_id =trajectory_header_id_base + num2str(i);
    end

    % Struktur für Datenbank erstellen
    data_ist_part = struct();
    data_ist_part.trajectory_header_id = trajectory_header_id;
    data_ist_part.timestamp_ist = timestamp_ist;
    data_ist_part.x_ist = x_ist/1000;  
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

    % Laden in Workspace
    assignin('base', 'trajectory_header_id', trajectory_header_id)
    assignin('base', 'data_ist_part', data_ist_part);
end

% Generiere Struktur der Solldaten für die Datenbankeintragung 
function generate_struct_data_soll(trajectory_soll, defined_velocity, interpolate)
    
    if interpolate == true

        % Anzahl der Elemnete bestimmen
        num_points = size(trajectory_soll,1);   

        % Quartanion mit Nullen füllen 
        q1_soll = zeros(num_points, 1);
        q2_soll = zeros(num_points, 1);
        q3_soll = zeros(num_points, 1);
        q4_soll = zeros(num_points, 1);
        timestamp_soll = linspace(0, num_points-1, num_points)';
        
        % Struktur für Datenbank erstellen
        data_soll = struct();
        data_soll.timestamp_soll = timestamp_soll;
        data_soll.x_soll = trajectory_soll(:, 1)/1000;
        data_soll.y_soll = trajectory_soll(:, 2)/1000;
        data_soll.z_soll = trajectory_soll(:, 3)/1000;
        data_soll.q1_soll = q1_soll;
        data_soll.q2_soll = q2_soll;
        data_soll.q3_soll = q3_soll;
        data_soll.q4_soll = q4_soll;
        data_soll.tcp_velocity_soll = defined_velocity;
        data_soll.joint_state_soll = [];
        
    else
        
    end

    % Laden in Workspace
    assignin("base","data_soll",data_soll)
end

%% Einzelne Segmente plotten

figure;
hold on
plot3(segments_soll{6}(:,1),segments_soll{6}(:,2),segments_soll{6}(:,3),'ko');
plot3(segments_ist{6}(:,2),segments_ist{6}(:,3),segments_ist{6}(:,4),'-bo');
hold off

%% Ganze Trajektorien plotten

figure;
hold on
plot3(trajectories_soll{2}(:,1),trajectories_soll{2}(:,2),trajectories_soll{2}(:,3),'ko');
plot3(trajectories_ist{2}(:,2),trajectories_ist{2}(:,3),trajectories_ist{2}(:,4),'-bo');
hold off