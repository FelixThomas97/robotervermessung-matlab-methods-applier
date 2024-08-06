%% 
clear;
% filename_excel_ist = 'iso_various_v2000_xx.xlsx';
% filename_excel_soll = 'ist_testPTP_v1000.xlsx';
% filename_excel_ist = 'ist_iso_diagonal_l630_v2000_4x.xlsx';
% filename_excel_ist = 'squares500_isodiagonalB_cubes1to5_v1000_100hz_steuerung.xlsx';
filename_excel_soll = 'soll_iso_diagonal_l630_v2000_1x.xlsx';
% filename_excel_soll = [];
% filename_excel_soll = 'soll_squares_l400_v1000_1x.xlsx'; %%%%% Keine Geschwindigkeit aufgezeichnet
% filename_excel_soll = 'soll_squares_l400_v2000_1x.xlsx'; %%%% komisches Event drin spielt aber keine Rolle
% filename_excel_ist = 'ist_squares_l400_v2000_4x.xlsx';
% filename_excel_soll = [];

filename_excel_ist = 'iso_diagonal_v2000_15x.xlsx';
% filename_excel_soll = 'iso_diagonal_v1000_15x.xlsx';

% filename_excel_ist = "ist_squares_l400_v2000_4x.xlsx";

pflag = false;

split = true;

euclidean = true;
dtw = true;
sidtw = true;
frechet = true;
lcss = true;

do_segments = true; 

upload2mongo = false;
upload2mongo_segments = false;

%% Dateneingabe Header
header_data = struct();
header_data.data_id = [];                               % automatisch
%header_data.robot_name = "robot0";
header_data.robot_model = "abb_irb4400";
%header_data.trajectory_type = "iso_path_A"; % "iso_path_A"
%header_data.carthesian = "true";
header_data.path_solver = "abb_steuerung";
header_data.recording_date = "2024-06-23T18:30:00.241866"; %automatisch - hier kommt der erste Zeitstempel der Bahn // von UNIX auf Zeit konvertieren
header_data.real_robot = "true";
header_data.number_of_points_ist = [];                  % automatisch
header_data.number_of_points_soll = [];                 % automatisch
header_data.sample_frequency_ist = [];                  % automatisch
header_data.sample_frequency_soll = [];                 % automatisch
header_data.source_data_ist = "vicon";
header_data.source_data_soll = "abb_steuerung";
header_data.evaluation_source = "matlab";

%%
% Datenvorverarbeitung für durch ABB Robot Studio generierte Tabellen
data_provision(filename_excel_ist);
preprocess_data(table_ist);
%%
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
    datasoll2struct(trajectories_soll{i}, defined_velocity, interpolate);
    dataist2struct(trajectories_ist{i},trajectory_header_id_base,i)

    % Istdaten in die Struktur schreiben
    struct_data{i} = data_ist_part;

    % Solldaten der Struktur hinzufügen
    fields_soll = fieldnames(data_soll_part);
    for j = 1:length(fields_soll)
        struct_data{i}.(fields_soll{j}) = data_soll_part.(fields_soll{j});
    end

    % Struktur für Header erzeugen
    header2struct(trajectory_header_id, header_data, trajectories_ist{i}, trajectories_soll{i}, interpolate);
    struct_header{i} = header_data;

end

% Datenbankstruktur für alle einzelnen Bahnabschnitte
for i = 1:1:num_segments

    % Funktionen zur Erzeugung der Datenstruktur für Soll und Istbahn 
    datasoll2struct(segments_soll{i}, defined_velocity, interpolate);
    dataist2struct(segments_ist{i},trajectory_header_id_base_segments,i)

    % Istdaten in die Struktur schreiben
    struct_data_segments{i} = data_ist_part;

    % Solldaten der Struktur hinzufügen
    fields_soll = fieldnames(data_soll_part);
    for j = 1:length(fields_soll)
        struct_data_segments{i}.(fields_soll{j}) = data_soll_part.(fields_soll{j});
    end

    % Struktur für Header erzeugen
    header2struct(trajectory_header_id, header_data, segments_ist{i}, segments_soll{i}, interpolate);
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

%%%%%%% Datenstruktur ereugen
    % Funktionen zur Erzeugung der Datenstruktur für Soll und Istbahn 
    datasoll2struct(trajectory_soll, defined_velocity, interpolate);
    dataist2struct(trajectory_ist, trajectory_header_id_base);

    % Istdaten in die Struktur schreiben
    struct_data = data_ist_part;

    % Solldaten der Struktur hinzufügen
    fields_soll = fieldnames(data_soll_part);
    for j = 1:length(fields_soll)
        struct_data.(fields_soll{j}) = data_soll_part.(fields_soll{j});
    end

    % Struktur für Header erzeugen
    header2struct(trajectory_header_id, header_data, trajectory_ist, trajectory_soll, interpolate);
    struct_header = header_data;
        
    clear dt freq currentArray timestamps_soll timestamps_soll_new
    clear timestamp_first timestamp_last index_first index_last
end


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Berechnung der Metriken %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% - eucl   : Euklidischer Abstand
% - dtw    : Dynamic Time Warping (Standard)
% - sidtw  : Dynamic Time Warping mit selektiver Interpolation (Johnen)
% - frechet: Frechet Abstand
% - lcss   : Longest Common Subsequence

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
        metric2struct_eucl(trajectory_soll, eucl_interpolation, eucl_distances,trajectory_header_id);

        struct_euclidean = metrics_euclidean;
    end
    % DTW für Gesamtheit der Daten
    if dtw == true
        [dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, dtw_path, ~, ~, ~] = ...
        fkt_dtw3d(trajectory_soll, trajectory_ist, pflag);
        metric2struct_dtw(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y);
        
        struct_dtw = metrics_dtw;
    end
    % SIDTW für Gesamtheit der Daten
    if sidtw == true
        [sidtw_distances, sidtw_max, sidtw_av,...
            sidtw_accdist, sidtw_X, sidtw_Y, sidtw_path, ~, ~]...
            = fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
        metric2struct_sidtw(trajectory_header_id,sidtw_max, sidtw_av, ...
            sidtw_distances,sidtw_X,sidtw_Y,sidtw_accdist,sidtw_path);
        
        struct_sidtw = metrics_johnen;
    end
    % Frechet Distanz für Gesamtheit der Daten
    if frechet == true
        fkt_discreteFrechet(trajectory_soll,trajectory_ist,pflag);
        metric2struct_frechet(trajectory_header_id, frechet_av, frechet_dist, frechet_distances, frechet_matrix, frechet_path);
        
        struct_frechet = metrics_frechet;
    end

    if lcss == true
        [lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon] = fkt_lcss(trajectory_soll,trajectory_ist,pflag);
        metric2struct_lcss(trajectory_header_id, lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon);

        struct_frechet = metrics_frechet;

    end

% Berechnung der Metriken für die einzelnen Messfahrten
else

    struct_euclidean = cell(1,num_trajectories);
    struct_dtw = cell(1,num_trajectories);
    struct_sidtw = cell(1,num_trajectories);
    struct_frechet = cell(1,num_trajectories);
    struct_lcss = cell(1,num_trajectories);
    
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
            metric2struct_eucl(trajectory_soll, eucl_interpolation, eucl_distances,trajectory_header_id,i);           
            struct_euclidean{i} = metrics_euclidean;
        else
            clear struct_euclidean
        end
        % DTW für die einzelnen Messfahrten
        if dtw == true
            [dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, dtw_path, ~, ~, ~] = ...
            fkt_dtw3d(trajectory_soll, trajectory_ist, pflag);
            metric2struct_dtw(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y,i);
            struct_dtw{i} = metrics_dtw;
        else
            clear struct_dtw
        end
        % SIDTW für die einzelnen Messfahrten
        if sidtw == true
            [sidtw_distances, sidtw_max, sidtw_av,...
                sidtw_accdist, sidtw_X, sidtw_Y, sidtw_path, ~, ~]...
                = fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
            metric2struct_sidtw(trajectory_header_id,sidtw_max, sidtw_av, ...
                sidtw_distances,sidtw_X,sidtw_Y,sidtw_accdist,sidtw_path,i);
            struct_sidtw{i} = metrics_johnen;
        else
            clear struct_sidtw
        end
        % Frechet-Distanz für die einzelnen Messfahrten
        if frechet == true
            fkt_discreteFrechet(trajectory_soll,trajectory_ist,pflag);
            metric2struct_frechet(trajectory_header_id, frechet_av, frechet_dist, frechet_distances, frechet_matrix, frechet_path,i);
            
            struct_frechet{i} = metrics_frechet;
        else
            clear struct_frechet
        end

        % LCSS für die einzelnen Trajectorien
        if lcss == true
            [lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon] = fkt_lcss(trajectory_soll,trajectory_ist,pflag);
            metric2struct_lcss(trajectory_header_id, lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon,i);
    
            struct_lcss{i} = metrics_lcss;
        else
            clear struct_lcss
        end
    end
end

% Berechnung der Metriken für die einzelnen Bahnabschnitte   
if do_segments == true

    struct_euclidean_segments = cell(1,num_segments);
    struct_dtw_segments = cell(1,num_segments);
    struct_sidtw_segments = cell(1,num_segments);
    struct_frechet_segments = cell(1,num_segments);
    struct_lcss_segments = cell(1,num_segments);

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
            metric2struct_eucl(segment_soll, eucl_interpolation, eucl_distances,trajectory_header_id,i);         
            struct_euclidean_segments{i} = metrics_euclidean;
        else
            clear struct_euclidean_segments
        end

        % DTW für alle Bahnabschnitte
        if dtw == true
            [dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, dtw_path,  ~, ~, ~] = ...
            fkt_dtw3d(segment_soll, segment_ist, pflag);
            metric2struct_dtw(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y,i);
            struct_dtw_segments{i} = metrics_dtw;
        else
            clear struct_dtw_segments
        end

        % SIDTW für alle Bahnabschnitte
        if sidtw == true
            [sidtw_distances, sidtw_max, sidtw_av,...
                sidtw_accdist, sidtw_X, sidtw_Y, sidtw_path, ~, ~]...
                = fkt_selintdtw3d(segment_soll,segment_ist,pflag);
            metric2struct_sidtw(trajectory_header_id,sidtw_max, sidtw_av, ...
                sidtw_distances,sidtw_X,sidtw_Y,sidtw_accdist,sidtw_path,i);
            struct_sidtw_segments{i} = metrics_johnen;
        else
            clear struct_sidtw_segments
        end

        % Frechet-Distanz für die einzelnen Messfahrten
        if frechet == true
            fkt_discreteFrechet(segment_soll,segment_ist,pflag);
            metric2struct_frechet(trajectory_header_id, frechet_av, frechet_dist, frechet_distances, frechet_matrix, frechet_path,i);
            
            struct_frechet_segments{i} = metrics_frechet;
        else
            clear struct_frechet_segments
        end

        % LCSS für alle Bahnabschnitte
        if lcss == true

            [lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon] = fkt_lcss(segment_soll,segment_ist,pflag);
            metric2struct_lcss(trajectory_header_id, lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon,i);

            struct_lcss_segments{i} = metrics_lcss;
        else
            clear struct_lcss_segments
        end
    end
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%  Upload in Datenbank  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% upload2mongo = false;
% upload2mongo_segments = false;

if upload2mongo == true
    
    % Upload in Datenbank (nur wenn alle Metriken berechnet wurden)
    if euclidean && dtw && sidtw && frechet %&& lcss
    
        % Verbindung mit MongoDB
        connectionString = 'mongodb+srv://felixthomas:felixthomas@cluster0.su3gj7l.mongodb.net/';
        connection = mongoc(connectionString, 'robotervermessung');
        
        % Überprüfe Verbindung
        if isopen(connection)
            disp('Verbindung erfolgreich hergestellt');
        else
            disp('Verbindung fehlgeschlagen');
        end
    else
        error('Für den Upload in die Datenbank müssen alle Metriken berechnet werden!');
    end

    % Anzahl Trajektorien auf 1 setzen falls...
    if split == false
        num_trajectories = 1;

        a = cell(1,1);

        a{1} = struct_header;
        struct_header = a;

        a{1} = struct_data;
        struct_data = a;

        a{1} = struct_dtw;
        struct_dtw = a;

        a{1} = struct_sidtw;
        struct_sidtw = a;

        a{1} = struct_frechet;
        struct_frechet = a;

        a{1} = struct_euclidean;
        struct_euclidean = a; 

        a{1} = struct_lcss;
        struct_lcss = a; 

        clear a
    end

    for i = 1:1:num_trajectories
    
        % Löscht die Kostenmatrix falls Datenmenge zu groß für MongoDB ist
        struct_dtw{i} = check_bytes(struct_dtw{i},'dtw');
        struct_sidtw{i} = check_bytes(struct_sidtw{i},'sidtw');
        struct_frechet{i} = check_bytes(struct_frechet{i},'frechet');
        struct_lcss{i} = check_bytes(struct_lcss{i},'lcss');
        
        % Upload in Datenbank 
        insert(connection, 'header', struct_header{i});
        insert(connection, 'data', struct_data{i});     
        insert(connection, 'metrics', struct_sidtw{i});
        insert(connection, 'metrics', struct_euclidean{i});
        insert(connection, 'metrics', struct_dtw{i});
        insert(connection, 'metrics', struct_frechet{i});
        insert(connection, 'metrics', struct_lcss{i});
        if split == false
            disp('Die Gesamttrajektorie wurde erfolgreich hochgeladen: '+ trajectory_header_id_base);
        else
            disp('Die Trajektorien wurden separiert hochgeladen: '+ trajectory_header_id_base+num2str(i));
        end
    end

    if upload2mongo_segments == true

        for i = 1:1:num_segments
    
            % Löscht die Kostenmatrix falls Datenmenge zu groß für MongoDB
            struct_dtw_segments{i} = check_bytes(struct_dtw_segments{i},'dtw');
            struct_sidtw_segments{i} = check_bytes(struct_sidtw_segments{i},'sidtw');
            struct_frechet_segments{i} = check_bytes(struct_frechet_segments{i},'frechet');
            struct_lcss_segments{i} = check_bytes(struct_lcss_segments{i},'lcss');
            
            % Upload in Datenbank (nur wenn alle Metriken berechnet wurden)
            if euclidean && dtw && sidtw && frechet %&& lcss
                insert(connection, 'header', struct_header_segments{i});
                insert(connection, 'data', struct_data_segments{i});     
                insert(connection, 'metrics', struct_sidtw_segments{i});
                insert(connection, 'metrics', struct_euclidean_segments{i});
                insert(connection, 'metrics', struct_dtw_segments{i});
                insert(connection, 'metrics', struct_frechet_segments{i});
                insert(connection, 'metrics', struct_lcss_segments{i});

                disp('Die einzelnen Bahnabschnitte wurden erfolgreich hochgeladen: ' +trajectory_header_id_base_segments+num2str(i));
            end
        end
    end
end

%% Einzelne Segmente plotten

% figure;
% hold on
% plot3(segments_soll{1}(:,1),segments_soll{1}(:,2),segments_soll{1}(:,3),'ko');
% plot3(segments_ist{1}(:,2),segments_ist{1}(:,3),segments_ist{1}(:,4),'-bo');
% plot3(segments_soll{2}(:,1),segments_soll{2}(:,2),segments_soll{2}(:,3),'ko');
% plot3(segments_soll{3}(:,1),segments_soll{3}(:,2),segments_soll{3}(:,3),'ko');
% plot3(segments_soll{4}(:,1),segments_soll{4}(:,2),segments_soll{4}(:,3),'ko');
% plot3(segments_soll{5}(:,1),segments_soll{5}(:,2),segments_soll{5}(:,3),'ko');
% view(3)
% hold off

%% Ganze Trajektorien plotten

% Eine bestimmte Trajektorie plotten
figure;
hold on
plot3(trajectories_soll{1}(:,2),trajectories_soll{1}(:,3),trajectories_soll{1}(:,4),'ko');
plot3(trajectories_ist{1}(:,2),trajectories_ist{1}(:,3),trajectories_ist{1}(:,4),'-bo');
xlabel('x');ylabel('y');zlabel('z')
grid on 
view(3)
hold off

%% Plotten aller Trajektorien
% 
pflag = true;
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
        xlabel('x');ylabel('y');zlabel('z')
end

%% Aufräumen für Übersicht

clear data_ist_part data_soll_part fields_soll i j 
clear filename_excel_ist filename_excel_soll