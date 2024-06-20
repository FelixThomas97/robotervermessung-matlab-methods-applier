%% 
clear;
% filename_excel_ist = 'iso_various_v2000_xx.xlsx';
% filename_excel_ist = 'ist_testPTP_v1000.xlsx';
filename_excel_ist = 'ist_iso_diagonal_l630_v2000_4x.xlsx';
filename_excel_soll = 'soll_iso_diagonal_l630_v2000_1x.xlsx';
% filename_excel_soll = [];
% filename_excel_soll = [];
% filename_excel_soll = 'soll_squares_l400_v1000_1x.xlsx'; %%%%% Keine Geschwindigkeit aufgezeichnet
% filename_excel_soll = 'soll_squares_l400_v2000_1x.xlsx'; %%%% komisches Event drin spielt aber keine Rolle
% filename_excel_ist = 'ist_squares_l400_v2000_4x.xlsx';


%% Dateneingabe Header
header_data = struct();
header_data.data_id = [];                               % automatisch
header_data.robot_name = "robot0";
header_data.robot_model = "abb_irb4400";
header_data.trajectory_type = "iso_path_A";
header_data.carthesian = "true";
header_data.path_solver = "abb_steuerung";
header_data.recording_date = "2024-05-16T16:37:00.241866";
header_data.real_robot = "true";
header_data.number_of_points_ist = [];                  % automatisch
header_data.number_of_points_soll = [];                 % automatisch
header_data.sample_frequency_ist = [];                  % automatisch
header_data.source = "matlab";

%%
% Datenvorverarbeitung für durch ABB Robot Studio generierte Tabellen
data_provision(filename_excel_ist);
preprocess_data(table_ist);

% Zerlegung der Bahnen in einzelne Segmente und vollständige Messdurchläufe
calc_trajectories(data_ist,events_ist,zeros_index_ist);

% Überprüfen ob eine Sollbahn interpoliert werden muss
if isempty(filename_excel_soll)
    % Sollbahn muss interpoliert werden
    interpolate = true;
else
    % Sollbahn steht anhand simulierter Daten zur Verfügung
    interpolate = false;
    data_provision(filename_excel_soll,interpolate);
    preprocess_data(table_soll, interpolate)
    calc_trajectories(data_soll,events_soll,zeros_index_soll,interpolate)
end

% Multiplikationsfaktor für die Anzahl der Punkte der Sollbahn
keypoints_faktor = 1;

% Geschwindigkeit für genierte Sollbahn
defined_velocity = 2000;

% Einmal vorab die Base für die ID generieren
trajectory_header_id_base = "robot0"+string(round(posixtime(datetime('now','TimeZone','UTC'))));
trajectory_header_id_base_segments = trajectory_header_id_base + "segment";

%% Solldaten für Bahnvergleich erzeugen/präperieren

% Für gemessene Sollbahn
if interpolate == false

    % Zusammensetzten der Sollbahnen anhand der Anzahl an Istbahnen
    combine_data(trajectories_ist, trajectories_soll);
    trajectories_soll = elements_soll;
    % Zusammensetzen der Bahnabschnitte
    combine_data(segments_ist, segments_soll);
    segments_soll = elements_soll;
    clear elements_soll

% Für generierte Sollbahn
else
    generate_soll(segments_ist,trajectories_ist,events_all_ist,keypoints_faktor)
end


%% Datenstrukturen erzeugen

% Anzahl der Messfahrten und Bahnabschnitte
num_trajectories = size(trajectories_ist,2);
num_segments = size(segments_ist,2);

% Leere Cell-Arrays für die Bewegungsdaten und Header
struct_data = cell(1,num_trajectories);
struct_data_segments = cell(1,num_segments);
struct_header = cell(1,num_trajectories);
struct_header_segments = cell(1,num_segments);

% Datenbank Struktur für ganze Messfahrten
for i = 1:1:num_trajectories

    % Funktionen zur Erzeugung der Datenstruktur für Soll und Istbahn 
    generate_struct_data_soll(trajectories_soll{i}, defined_velocity, interpolate);
    generate_struct_data_ist(trajectories_ist{i},trajectory_header_id_base,i)

    % Istdaten in die Struktur schreiben
    struct_data{i} = data_ist_part;

    % Solldaten der Struktur hinzufügen
    fields_soll = fieldnames(data_soll_part);
    for j = 1:length(fields_soll)
        struct_data{i}.(fields_soll{j}) = data_soll_part.(fields_soll{j});
    end

    % Struktur für Header erzeugen
    generate_header(trajectory_header_id, header_data, trajectories_ist{i}, trajectories_soll{i});
    struct_header{i} = header_data;

end

% Datenbankstruktur für alle einzelnen Bahnabschnitte
for i = 1:1:num_segments

    % Funktionen zur Erzeugung der Datenstruktur für Soll und Istbahn 
    generate_struct_data_soll(segments_soll{i}, defined_velocity, interpolate);
    generate_struct_data_ist(segments_ist{i},trajectory_header_id_base_segments,i)

    % Istdaten in die Struktur schreiben
    struct_data_segments{i} = data_ist_part;

    % Solldaten der Struktur hinzufügen
    fields_soll = fieldnames(data_soll_part);
    for j = 1:length(fields_soll)
        struct_data_segments{i}.(fields_soll{j}) = data_soll_part.(fields_soll{j});
    end

    % Struktur für Header erzeugen
    generate_header(trajectory_header_id, header_data, segments_ist{i}, segments_soll{i});
    struct_header_segments{i} = header_data;
    
end

%% Funktionen

% Generiere Struktur der Istdaten für die Datenbankeintragung 
function generate_struct_data_ist(trajectory_ist,trajectory_header_id_base,i)

    % Extrahiere die Daten aus Array
    timestamp_ist = trajectory_ist(:, 1);
    x_ist = trajectory_ist(:, 2);
    y_ist = trajectory_ist(:, 3);
    z_ist = trajectory_ist(:, 4);
    tcp_velocity_ist = trajectory_ist(:, 5);
    tcp_acceleration_ist = trajectory_ist(:, 6);
    cpu_temperature_ist = trajectory_ist(:, 7);
    joint_states_ist = trajectory_ist(:, 8:13);
    q_ist = trajectory_ist(:, 14:17);
    % events_ist = trajectory_ist(:, 18);  %%%%%% Falls Events auch sollen

    % Header ID nur hochzählen wenn mehrere Bahnen existieren !
    if nargin < 3
    % Header ID generieren
        trajectory_header_id = trajectory_header_id_base;
    else
        trajectory_header_id = trajectory_header_id_base + num2str(i);
    end

    % Struktur für Datenbank erstellen
    data_ist = struct();
    data_ist.trajectory_header_id = trajectory_header_id;
    data_ist.timestamp_ist = timestamp_ist;
    data_ist.x_ist = x_ist/1000;  
    data_ist.y_ist = y_ist/1000;
    data_ist.z_ist = z_ist/1000;
    data_ist.tcp_velocity_ist = tcp_velocity_ist;
    data_ist.tcp_acceleration = tcp_acceleration_ist;
    data_ist.cpu_temperature = cpu_temperature_ist;
    data_ist.q1_ist = q_ist(:, 1);
    data_ist.q2_ist = q_ist(:, 2);
    data_ist.q3_ist = q_ist(:, 3);
    data_ist.q4_ist = q_ist(:, 4);
    data_ist.joint_states_ist = joint_states_ist; 
    % data_ist.events = events_ist; 

    % Laden in Workspace
    assignin('base', 'trajectory_header_id', trajectory_header_id)
    assignin('base', 'data_ist_part', data_ist);
end

% Generiere Struktur der Solldaten für die Datenbankeintragung 
function generate_struct_data_soll(trajectory_soll, defined_velocity, interpolate)
    
    if interpolate == true
    % Für generierte Sollbahnen
   
        % Anzahl der Elemnete bestimmen
        num_points = size(trajectory_soll,1);   
        
        timestamp_soll = linspace(0, num_points-1, num_points)';
        x_soll = trajectory_soll(:, 1)/1000;
        y_soll = trajectory_soll(:, 2)/1000;
        z_soll = trajectory_soll(:, 3)/1000;
        % Daten die nicht verfügbar sind
        q_soll = zeros(num_points, 4);
        tcp_velocity_soll = defined_velocity;
        joint_state_soll = [];        
        % events_soll = zeros(num_points,1); %%%%%% Falls Events auch sollen

    else
    % Für gemessene Sollbahnen
        
        % Extrahiere die Daten aus Array
        timestamp_soll = trajectory_soll(:, 1);
        x_soll = trajectory_soll(:, 2);
        y_soll = trajectory_soll(:, 3);
        z_soll = trajectory_soll(:, 4);
        tcp_velocity_soll = trajectory_soll(:, 5);
        % tcp_acceleration_soll = trajectory_soll(:, 6);
        % cpu_temperature_soll = trajectory_soll(:, 7);
        joint_state_soll = trajectory_soll(:, 8:13);
        q_soll = trajectory_soll(:, 14:17);
        % events_soll = trajectory_soll(:,18);
        
    end

    % Struktur für Datenbank erstellen
    data_soll = struct();
    data_soll.timestamp_soll = timestamp_soll;
    data_soll.x_soll = x_soll;
    data_soll.y_soll = y_soll;
    data_soll.z_soll = z_soll;
    data_soll.q1_soll = q_soll(:,1);
    data_soll.q2_soll = q_soll(:,2);
    data_soll.q3_soll = q_soll(:,3);
    data_soll.q4_soll = q_soll(:,4);
    data_soll.tcp_velocity_soll = tcp_velocity_soll;
    data_soll.joint_state_soll = joint_state_soll;
    % data_soll.events_soll = events_soll;        

    % Laden in Workspace
    assignin("base","data_soll_part",data_soll)
end

%% Einzelne Segmente plotten

% figure;
% hold on
% plot3(segments_soll{1}(:,1),segments_soll{1}(:,2),segments_soll{1}(:,3),'ko');
% % plot3(segments_ist{1}(:,2),segments_ist{1}(:,3),segments_ist{1}(:,4),'-bo');
% % plot3(segments_soll{2}(:,1),segments_soll{2}(:,2),segments_soll{2}(:,3),'ko');
% % plot3(segments_soll{3}(:,1),segments_soll{3}(:,2),segments_soll{3}(:,3),'ko');
% % plot3(segments_soll{4}(:,1),segments_soll{4}(:,2),segments_soll{4}(:,3),'ko');
% % plot3(segments_soll{5}(:,1),segments_soll{5}(:,2),segments_soll{5}(:,3),'ko');
% % view(3)
% hold off

%% Ganze Trajektorien plotten

% figure;
% hold on
% plot3(trajectories_soll{5}(:,2),trajectories_soll{5}(:,3),trajectories_soll{5}(:,4),'ko');
% plot3(trajectories_ist{5}(:,2),trajectories_ist{5}(:,3),trajectories_ist{5}(:,4),'-bo');
% hold off