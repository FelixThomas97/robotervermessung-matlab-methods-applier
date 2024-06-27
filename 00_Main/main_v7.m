%% 
clear;
% filename_excel_ist = 'iso_various_v2000_xx.xlsx';
% filename_excel_ist = 'ist_testPTP_v1000.xlsx';
filename_excel_ist = 'ist_iso_diagonal_l630_v2000_4x.xlsx';
filename_excel_soll = 'soll_iso_diagonal_l630_v2000_1x.xlsx';
% filename_excel_soll = [];
% filename_excel_soll = 'soll_squares_l400_v1000_1x.xlsx'; %%%%% Keine Geschwindigkeit aufgezeichnet
% filename_excel_soll = 'soll_squares_l400_v2000_1x.xlsx'; %%%% komisches Event drin spielt aber keine Rolle
% filename_excel_ist = 'ist_squares_l400_v2000_4x.xlsx';
% filename_excel_soll = [];

pflag = false;

split = false;
euclidean = true;
dtw = true;
sidtw = true;
do_segments = true; 

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
header_data.sample_frequency_soll = [];                 % automatisch
header_data.source = "matlab";

%%
% Datenvorverarbeitung für durch ABB Robot Studio generierte Tabellen
data_provision(filename_excel_ist);
preprocess_data(table_ist);

% Zerlegung der Bahnen in einzelne Segmente und vollständige Messdurchläufe
calc_trajectories(data_ist,events_ist,zeros_index_ist);

% Geschwindigkeit (nur für generierte Sollbahn)
defined_velocity = max(data_ist(:,5));

% Überprüfen ob eine Sollbahn interpoliert werden muss
if isempty(filename_excel_soll)
    % Sollbahn muss interpoliert werden
    interpolate = true;
else
    % Sollbahn steht anhand simulierter Daten zur Verfügung
    interpolate = false;
    data_provision(filename_excel_soll,interpolate);
    preprocess_data(table_soll, interpolate);
    calc_trajectories(data_soll,events_soll,zeros_index_soll,interpolate);
end

% Multiplikationsfaktor für die Anzahl der Punkte der Sollbahn
keypoints_faktor = 1;

% Einmal vorab die Base für die ID generieren
trajectory_header_id_base = "robot0"+string(round(posixtime(datetime('now','TimeZone','UTC'))));
trajectory_header_id_base_segments = trajectory_header_id_base + "_";

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
num_trajectories = size(trajectories_ist,2)-1;  % letzte Messfahrt wird nicht berücksichtigt!
num_segments = size(segments_ist,2);            % alle Segmente werden berücksichtigt!

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
    generate_header(trajectory_header_id, header_data, trajectories_ist{i}, trajectories_soll{i}, interpolate);
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
    generate_header(trajectory_header_id, header_data, segments_ist{i}, segments_soll{i}, interpolate);
    struct_header_segments{i} = header_data;
    
end

%% Zusammensetzen zu einer Gesamttrajektorie
      
if split == false 

    trajectory_header_id = trajectory_header_id_base; 

    % Erste und letzte Element der Timestamps extrahieren
    timestamp_first = trajectories_ist{1}(1,1);
    timestamp_last = trajectories_ist{end-1}(end,1);
    index_first = find(data_ist(:,1) == timestamp_first);
    index_last = find(data_ist(:,1) == timestamp_last);
    % Zusammegeführte Gesamttrajektorie
    trajectory_ist = data_ist(index_first:index_last,:);
    
    % Alle Sollbahnen zusammensetzen (ginge auch so für Ist-Bahn)
    trajectory_soll = [];
    % Schleife durch alle Elemente der Sollbahnen
    for i = 1:length(trajectories_soll)-1          
        currentArray = trajectories_soll{i};
        trajectory_soll = vertcat(trajectory_soll, currentArray);
    end
    
    % Falls Sollbahn gemessen wurde Timestamps anpassen
    if interpolate == false 
        timestamps_soll = trajectories_soll{1}(:,1);
        dt = diff(timestamps_soll);
        freq = 1/mean(dt); 
        timestamps_soll_new = (0:length(trajectory_soll)-1)'/freq;
        % Die alten Timestamps überschreiben
        trajectory_soll(:,1) = timestamps_soll_new;
    end


        
    clear dt freq currentArray timestamps_soll timestamps_soll_new
    clear timestamp_first timestamp_last index_first index_last
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Berechnung der Metriken %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - eucl   : euclidischer Abstand
% - dtw    : Dynamic Time Warping (Standard)
% - sidtw  : Dynamic Time Warping mit selektiver Interpolation (Johnen)
% - frechet: Frechet Abstand

% Berechnung der Metriken für nur eine Gesamttrajektorie
if split == false

    % Ist-Bahn aus allen Daten
    trajectory_ist = trajectory_ist(:, 2:4);

    % Soll-Bahn aus allen Daten
    if interpolate == false
        trajectory_soll = trajectory_soll(:,2:4);
    else
        trajectory_soll = trajectory_soll(:,1:3);
    end

    % Euklidische Distanzen für die Gesamtheit der Daten
    if euclidean == true
        [eucl_interpolation,eucl_distances,eucl_t] = distance2curve(trajectory_ist,trajectory_soll,'linear');
        generate_euclidean_struct(trajectory_soll, eucl_interpolation, eucl_distances,trajectory_header_id,i,split);

        struct_euclidean = metrics_euclidean;
    end
    % DTW für Gesamtheit der Daten
    if dtw == true
        [dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, dtw_path, ix, iy, localdist] = ...
        fkt_dtw3d(trajectory_soll, trajectory_ist, pflag);
        generate_dtw_struct(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y,i,split);
        
        struct_dtw = metrics_dtw;
    end
    % SIDTW für Gesamtheit der Daten
    if sidtw == true
        [sidtw_distances, sidtw_max, sidtw_av,...
            sidtw_accdist, sidtw_X, sidtw_Y, sidtw_path, ~, ~]...
            = fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
        generate_dtwjohnen_struct(trajectory_header_id,sidtw_max, sidtw_av, ...
            sidtw_distances,sidtw_X,sidtw_Y,sidtw_accdist,sidtw_path,i,split);
        
        struct_sidtw = metrics_johnen;
    end
    % Frechet Distanz für Gesamtheit der Daten

% Berechnung der Metriken für die einzelnen Messfahrten
else

    struct_euclidean = cell(1,num_trajectories);
    struct_dtw = cell(1,num_trajectories);
    struct_sidtw = cell(1,num_trajectories);
    % struct_frechet = cell(1,num_trajectories);
    
    for i = 1:1:num_trajectories
        
        trajectory_header_id = trajectory_header_id_base;
        
        % Aktuelle Ist-Bahn
        trajectory_ist = trajectories_ist{i}(:, 2:4);

        % Aktuelle Soll-Bahn
        if interpolate == false
            trajectory_soll = trajectories_soll{i}(:,2:4);
        else
            trajectory_soll = trajectories_soll{i}(:,1:3);
        end
        
        % Euklidsche Distanzen für die einzelnen Messfahrten
        if euclidean == true
            [eucl_interpolation,eucl_distances,~] = distance2curve(trajectory_ist,trajectory_soll,'linear');
            generate_euclidean_struct(trajectory_soll, eucl_interpolation, eucl_distances,trajectory_header_id,i,split);           
            struct_euclidean{i} = metrics_euclidean;
        else
            clear struct_euclidean
        end
        % DTW für die einzelnen Messfahrten
        if dtw == true
            [dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, dtw_path, ix, iy, localdist] = ...
            fkt_dtw3d(trajectory_soll, trajectory_ist, pflag);
            generate_dtw_struct(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y,i,split);
            struct_dtw{i} = metrics_dtw;
        else
            clear struct_dtw
        end
        % SIDTW für die einzelnen Messfahrten
        if sidtw == true
            [sidtw_distances, sidtw_max, sidtw_av,...
                sidtw_accdist, sidtw_X, sidtw_Y, sidtw_path, ~, ~]...
                = fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
            generate_dtwjohnen_struct(trajectory_header_id,sidtw_max, sidtw_av, ...
                sidtw_distances,sidtw_X,sidtw_Y,sidtw_accdist,sidtw_path,i,split);
            struct_sidtw{i} = metrics_johnen;
        else
            clear struct_sidtw
        end
    end
end

% Berechnung der Metriken für die einzelnen Bahnabschnitte   
if do_segments == true

    struct_euclidean_segments = cell(1,num_segments);
    struct_dtw_segments = cell(1,num_segments);
    struct_sidtw_segments = cell(1,num_segments);
    % struct_frechet_segments = cell(1,num_segments);

    for i= 1:1:num_segments
        
        % Header-ID Aktualisieren
        trajectory_header_id = trajectory_header_id_base_segments;
        
        % Aktueller Ist-Bahnabschnitt
        segment_ist = segments_ist{i}(:, 2:4);

        % Aktueller Soll-Bahnabschnitt
        if interpolate == false
            segment_soll = segments_soll{i}(:,2:4);
        else
            segment_soll = segments_soll{i}(:,1:3);
        end

         % Euklidische Distanzen für alle Bahnabschnitte
        if euclidean == true
            [eucl_interpolation,eucl_distances,~] = distance2curve(segment_ist,segment_soll,'linear');
            generate_euclidean_struct(segment_soll, eucl_interpolation, eucl_distances,trajectory_header_id,i,split);         
            struct_euclidean_segments{i} = metrics_euclidean;
        else
            clear struct_euclidean_segments
        end

        % DTW für alle Bahnabschnitte
        if dtw == true
            [dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, dtw_path, ix, iy, localdist] = ...
            fkt_dtw3d(segment_soll, segment_ist, pflag);
            generate_dtw_struct(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y,i,split);
            struct_dtw_segments{i} = metrics_dtw;
        else
            clear struct_dtw_segments
        end

        % SIDTW für alle Bahnabschnitte
        if sidtw == true
            [sidtw_distances, sidtw_max, sidtw_av,...
                sidtw_accdist, sidtw_X, sidtw_Y, sidtw_path, ~, ~]...
                = fkt_selintdtw3d(segment_soll,segment_ist,pflag);
            generate_dtwjohnen_struct(trajectory_header_id,sidtw_max, sidtw_av, ...
                sidtw_distances,sidtw_X,sidtw_Y,sidtw_accdist,sidtw_path,i,split);
            struct_sidtw_segments{i} = metrics_johnen;
        else
            clear struct_sidtw_segments
        end
    end
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

% % Eine bestimmte Trajektorie plotten
% figure;
% hold on
% plot3(trajectories_soll{5}(:,2),trajectories_soll{5}(:,3),trajectories_soll{5}(:,4),'ko');
% plot3(trajectories_ist{5}(:,2),trajectories_ist{5}(:,3),trajectories_ist{5}(:,4),'-bo');
% hold off

% Plotten aller Trajektorien
if pflag 
    if interpolate == false
    
        for i = 1:num_trajectories % letzte wird hier nicht geplottet, sonst +1
            figure;
            hold on
            plot3(trajectories_soll{i}(:,2),trajectories_soll{i}(:,3),trajectories_soll{i}(:,4),'ko');
            plot3(trajectories_ist{i}(:,2),trajectories_ist{i}(:,3),trajectories_ist{i}(:,4),'-bo');
            hold off
            view(3)
        end
    
    else
        for i = 1:num_trajectories % letzte wird hier nicht geplottet, sonst +1
            figure;
            hold on
            plot3(trajectories_soll{i}(:,1),trajectories_soll{i}(:,2),trajectories_soll{i}(:,3),'ko');
            plot3(trajectories_ist{i}(:,2),trajectories_ist{i}(:,3),trajectories_ist{i}(:,4),'-bo');
            hold off
            view(3)
        end
    
    end
end

%% Aufräumen für Übersicht

clear data_ist_part data_soll_part fields_soll i j 
clear filename_excel_ist filename_excel_soll