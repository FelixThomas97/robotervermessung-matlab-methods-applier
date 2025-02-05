% Upload der in Position und Orientierung transformierten Daten

%% Einstellungen
clear;

%bahn_id_ = '1738682877';
bahn_id_ = '1721049183';% Orientierungsänderung ohne Kalibrierungsdatei
plots = true;              % Plotten der Daten 
upload_all = false;        % Upload aller Bahnen
upload_single = false;     % Nur eine einzelne Bahn
transform_only = true;    % Nur Transformation und Plot, kein Upload
is_pick_and_place = true;  % NEU: Flag für Pick-and-Place Aufgaben

schema = 'bewegungsdaten';

% Verbindung mit PostgreSQL
datasource = "RobotervermessungMATLAB";
username = "felixthomas";
password = "manager";
conn = postgresql(datasource,username,password);

% Überprüfe Verbindung
if isopen(conn)
    disp('Verbindung erfolgreich hergestellt');
else
    error('Datenbankverbindung fehlgeschlagen');
end

clear datasource username password

%% Vorbereitung der zu verarbeitenden Bahn-IDs

% Initialisiere leere Arrays
bahn_ids_to_process = [];
existing_bahn_ids = [];

% Hole existierende Bahn-IDs nur wenn Upload geplant ist
if upload_all || upload_single
    query = ['SELECT DISTINCT bahn_id FROM robotervermessung.' schema '.bahn_pose_trans'];
    existing_bahn_ids = str2double(table2array(fetch(conn, query)));
end

% Bestimme zu verarbeitende Bahn-IDs je nach Modus
if upload_all
    % Hole alle verfügbaren Bahn-IDs
    query = ['SELECT bahn_id FROM robotervermessung.' schema '.bahn_info'];
    all_bahn_ids = str2double(table2array(fetch(conn, query)));
    bahn_ids_to_process = all_bahn_ids;
elseif upload_single || transform_only
    % Einzelne Bahn verarbeiten
    if isempty(bahn_id_)
        error('Bitte geben Sie eine bahn_id an');
    end
    bahn_ids_to_process = str2double(bahn_id_);
end

% Informative Ausgabe
fprintf('Modus: %s\n', getModeString(transform_only, upload_single, upload_all));
if ~isempty(bahn_ids_to_process)
    fprintf('Zu verarbeitende Bahn-IDs: %s\n', ...
        strjoin(string(bahn_ids_to_process), ', '));
end

%% Hauptverarbeitungsschleife
tic;

% Verarbeite jede Bahn entsprechend dem gewählten Modus
for bahn_id = bahn_ids_to_process'
    current_bahn_id = num2str(bahn_id);
    
    % Bei Upload-Modus: Prüfe ob Bahn bereits existiert
    if (upload_all || upload_single) && ismember(bahn_id, existing_bahn_ids)
        disp(['Bahn-ID ' current_bahn_id ' bereits vorhanden - wird übersprungen']);
        continue;
    end

    try
        % Suche nach Kalibrierungslauf
        disp(['Verarbeite Bahn-ID: ' current_bahn_id]);
        calibration_id = findCalibrationRun(conn, current_bahn_id, schema);
        
        % Extrahieren der Kalibrierungs-Daten für die Position
        tablename_cal = ['robotervermessung.' schema '.bahn_pose_ist'];
        opts_cal = databaseImportOptions(conn,tablename_cal);
        opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
        data_cal_ist= sqlread(conn,tablename_cal,opts_cal);
        data_cal_ist = sortrows(data_cal_ist,'timestamp');
        
        tablename_cal = ['robotervermessung.' schema '.bahn_events'];
        opts_cal = databaseImportOptions(conn,tablename_cal);
        opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
        data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
        data_cal_soll = sortrows(data_cal_soll,'timestamp');
        
        % Positionsdaten für Koordinatentransformation
        calibration(data_cal_ist,data_cal_soll)
        
        % Extrahieren der Kalibrierungs-Daten für die Orientierung
        tablename_cal = ['robotervermessung.' schema '.bahn_orientation_soll'];
        opts_cal = databaseImportOptions(conn,tablename_cal);
        opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
        data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
        data_cal_soll = sortrows(data_cal_soll,'timestamp');
        
        % Berechnung der relativen Rotationsmatrix für die Orientierung 
        euler_transformation(data_cal_ist,data_cal_soll)
        
        clear data_cal data_cal_info diff_bahn_id min_diff_bahn_id min_idx opts_cal tablename_cal check_bahn_id
        clear query_cal min_diff_idx
        clear data_cal_ist data_cal_soll

        % Auslesen der gesamten Ist-Daten
        query = ['SELECT * FROM robotervermessung.' schema '.bahn_pose_ist ' ...
                'WHERE robotervermessung.' schema '.bahn_pose_ist.bahn_id = ''' bahn_id_ ''''];
        data_ist = fetch(conn, query);
        data_ist = sortrows(data_ist,'timestamp');
        
        % Auslesen der gesamten Soll-Daten der Orientierung
        query = ['SELECT * FROM robotervermessung.' schema '.bahn_orientation_soll ' ...
                'WHERE robotervermessung.' schema '.bahn_orientation_soll.bahn_id = ''' bahn_id_ ''''];
        data_orientation_soll = fetch(conn, query);
        data_orientation_soll = sortrows(data_orientation_soll,'timestamp');
        
        % Transformation der Quarternionen zu Euler-Winkeln
        q_soll = table2array(data_orientation_soll(:,5:8));
        q_soll = [q_soll(:,4), q_soll(:,3), q_soll(:,2), q_soll(:,1)];
        euler_soll = quat2eul(q_soll,"ZYX");
        euler_soll = rad2deg(euler_soll);
        
        q_ist = table2array(data_ist(:,8:11));
        q_ist = [q_ist(:,4), q_ist(:,3), q_ist(:,2), q_ist(:,1)];
        euler_ist = quat2eul(q_ist,"ZYX");
        euler_ist = rad2deg(euler_ist);

        % Auslesen der gesamten Soll-Daten der Position
        query = ['SELECT * FROM robotervermessung.' schema '.bahn_position_soll ' ...
                'WHERE robotervermessung.' schema '.bahn_position_soll.bahn_id = ''' bahn_id_ ''''];
        data_position_soll = fetch(conn, query);
        data_position_soll = sortrows(data_position_soll,'timestamp');
        
        position_ist = table2array(data_ist(:,5:7));
        position_soll = table2array(data_position_soll(:,5:7));
        
        clear q_ist q_soll query

        euler_transformation(euler_ist,euler_soll, trafo_euler,trafo_rot);
        coord_transformation(position_ist,trafo_rot,trafo_trans);
        
        % Wenn Upload-Modus: Speichere in Datenbank
        if upload_all || upload_single
            uploadTransformedData(conn, current_bahn_id, calibration_id, data_ist, data_ist_trafo, euler_trans, schema);
        end

        % Wenn Plots aktiviert: Visualisiere Ergebnisse
        if plots
           plotResults(data_ist,data_ist_trafo, data_orientation_soll, position_soll, euler_soll, euler_trans)
        end

    catch ME
        warning(['Fehler bei Bahn-ID ' current_bahn_id ': ' ME.message]);
        continue;
    end
end

toc;

%% Hilfsfunktionen

function mode_str = getModeString(transform_only, upload_single, upload_all)
    if transform_only
        mode_str = 'Nur Transformation';
    elseif upload_single
        mode_str = 'Upload einzelne Bahn';
    elseif upload_all
        mode_str = 'Upload alle Bahnen';
    else
        mode_str = 'Kein Modus ausgewählt';
    end
end

function calibration_id = findCalibrationRun(conn, bahn_id, schema)
    % Prüfe erst, ob aktuelle Bahn selbst ein Kalibrierungslauf ist
    query = sprintf(['SELECT calibration_run FROM robotervermessung.' schema '.bahn_info ' ...
                    'WHERE bahn_id = ''%s'''], bahn_id);
    is_calibration = logical(fetch(conn, query).calibration_run);
    
    if is_calibration
        disp('Die aktuelle Bahn ist selbst eine Kalibrierungsbahn');
        calibration_id = bahn_id;
        return;
    end
    
    % Hole alle Kalibrierungsläufe
    query = ['SELECT bahn_id, recording_date FROM robotervermessung.' schema '.bahn_info WHERE calibration_run = true'];
    cal_data = fetch(conn, query);
    
    % Hole Aufnahmedatum der aktuellen Bahn
    query = sprintf(['SELECT recording_date FROM robotervermessung.' schema '.bahn_info ' ...
                    'WHERE bahn_id = ''%s'''], bahn_id);
    current_date = fetch(conn, query);
    current_datetime = datetime(current_date.recording_date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
    
    % Finde beste passende Kalibrierung
    best_time_diff = Inf;
    calibration_id = bahn_id;  % Default falls keine passende Kalibrierung gefunden
    
    for i = 1:height(cal_data)
        cal_datetime = datetime(cal_data.recording_date(i), 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
        
        % Prüfe ob Kalibrierung am gleichen Tag und vor der aktuellen Messung liegt
        if dateshift(cal_datetime, 'start', 'day') == dateshift(current_datetime, 'start', 'day') && ...
           cal_datetime < current_datetime
            
            time_diff = seconds(current_datetime - cal_datetime);
            if time_diff < best_time_diff
                best_time_diff = time_diff;
                calibration_id = char(cal_data.bahn_id(i));
            end
        end
    end
    
    if best_time_diff < Inf
        disp(['Passende Kalibrierung gefunden: ' calibration_id]);
        disp(['Zeitlicher Abstand: ' num2str(best_time_diff/60, '%.1f') ' Minuten']);
    else
        disp('Keine passende Kalibrierung gefunden - verwende aktuelle Bahn als Referenz');
    end
end

function uploadTransformedData(conn, bahn_id, calibration_id, data_ist, data_ist_trafo, euler_trans, schema)
    try
        % Erstelle Tabelle für transformierte Daten
        bahn_pose_trans = table('Size', [height(data_ist), 10], ...
            'VariableTypes', {'string', 'string', 'string', 'double', 'double', ...
                            'double', 'double', 'double', 'double', 'string'}, ...
            'VariableNames', {'bahn_id', 'segment_id', 'timestamp', 'x_trans', ...
                            'y_trans', 'z_trans', 'roll_trans', 'pitch_trans', ...
                            'yaw_trans', 'calibration_id'});
        
        % bahn_pose_trans.bahn_id = data_ist.bahn_id;
        calibration_ids = repelem(string(calibration_id),height(bahn_pose_trans))';
        bahn_pose_trans{:,:} = [data_ist{:,2:4}, data_ist_trafo, euler_trans, calibration_ids];
        
        % Upload zur Datenbank
        sqlwrite(conn, ['robotervermessung.' schema '.bahn_pose_trans'], bahn_pose_trans);
        disp(['Bahn-ID ' bahn_id ' erfolgreich in Datenbank geschrieben']);
        
    catch ME
        error('Fehler beim Datenbank-Upload: %s', ME.message);
    end
end

%% Plots
function plotResults(data_ist,data_ist_trafo, data_orientation_soll, position_soll, euler_soll, euler_trans)
    % Farben
    c1 = [0 0.4470 0.7410];
    c2 = [0.8500 0.3250 0.0980];
    c3 = [0.9290 0.6940 0.1250];
    c4 = [0.4940 0.1840 0.5560];

    % Timestamps in Sekunden
    time_ist = str2double(data_ist.timestamp);
    time_soll = str2double(data_orientation_soll.timestamp);
    timestamps_ist = (time_ist(:,1)- time_soll(1,1))/1e9;
    timestamps_soll = (time_soll(:,1)- time_soll(1,1))/1e9;


    % % Transformation aller Winkel 
    % euler_transformation(euler_ist,euler_soll, trafo_euler, trafo_rot)
    % % Winkel zwischen 0 - 360°
    % euler_soll = abs(mod(euler_soll+180,360)-180);
    % euler_trans = abs(mod(euler_trans+180,360)-180);

    % Plot Winkel
    figure('Color','white','Name','Eulerwinkel von 0° bis 360°')
    hold on 
    plot(timestamps_soll,euler_soll(:,1),Color=c1,LineWidth=1.5)
    plot(timestamps_soll,euler_soll(:,2),Color=c2,LineWidth=1.5)
    plot(timestamps_soll,euler_soll(:,3),Color=c4,LineWidth=1.5)
    plot(timestamps_ist,euler_trans(:,1),Color=c1, LineWidth=3.5)
    plot(timestamps_ist,euler_trans(:,2),Color=c2, LineWidth=3.5)
    plot(timestamps_ist,euler_trans(:,3),Color=c4, LineWidth=3.5)
    
    xlabel('Zeit [s]'); ylabel('Winkel [°]');
    legend("roll","pitch","yaw")
    hold off

    % Plot Position
    figure;
    hold on
    plot3(data_ist_trafo(:,1),data_ist_trafo(:,2),data_ist_trafo(:,3),Color=c1,LineWidth=1.5)
    plot3(position_soll(:,1),position_soll(:,2),position_soll(:,3),Color=c2,LineWidth=1.5)
    hold off

    clear c1 c2 c3 c4 
end