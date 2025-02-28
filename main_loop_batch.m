%% Einstellungen für Batch-Verarbeitung
clear;
tic;

% Konfigurationsparameter
BATCH_SIZE = 15;           % Anzahl der Bahnen pro Batch
evaluate_velocity = 0;
evaluate_orientation = 0;
evaluate_segmentwise = false;
evaluate_all = true;
plots = false;
upload = true;
upload_info = true;
upload_deviations = true;

% Datenbankverbindung herstellen
datasource = "RobotervermessungMATLAB";
username = "felixthomas";
password = "manager";
conn = postgresql(datasource,username,password);

% Überprüfe Verbindung
if isopen(conn)
    disp('Verbindung erfolgreich hergestellt');
else
    disp('Verbindung fehlgeschlagen');
    return;
end

clear datasource username password

%% Schleife um alle Daten auszuwerten 
query = 'SELECT bahn_id FROM robotervermessung.bewegungsdaten.bahn_info WHERE pick_and_place = true AND calibration_run = false';
bahn_ids = fetch(conn, query);
bahn_ids = double(string(table2array(bahn_ids)));

% Check ob Orientierung, Geschwindigkeit oder Position ausgewertet wird 
if evaluate_orientation == true && evaluate_velocity == false 
    query = "SELECT bahn_id FROM robotervermessung.auswertung.orientation_sidtw";
elseif evaluate_velocity == true && evaluate_orientation == false
    query = "SELECT bahn_id FROM robotervermessung.auswertung.speed_sidtw";
else
    query = "SELECT bahn_id FROM robotervermessung.auswertung.position_sidtw";
end

% Extrahieren aller Bahn-ID's die in der Datenbank vorliegen
existing_bahn_ids = fetch(conn, query);
existing_bahn_ids = double(string(table2array(existing_bahn_ids)));
existing_bahn_ids = unique(existing_bahn_ids);

%% Bestimmen der zu verarbeitenden Bahnen
unprocessed_bahn_ids = bahn_ids(~ismember(bahn_ids, existing_bahn_ids));
disp(['Anzahl der zu verarbeitenden Bahnen: ', num2str(length(unprocessed_bahn_ids))]);

%% Batch-Verarbeitung mit Upload nach jedem Batch
num_batches = ceil(length(unprocessed_bahn_ids) / BATCH_SIZE);
disp(['Verarbeitung in ', num2str(num_batches), ' Batches mit je max. ', num2str(BATCH_SIZE), ' Bahnen']);

% Bestimme den Evaluationstyp
if evaluate_velocity == false && evaluate_orientation == false
    evaluation_type = 'position';
elseif evaluate_velocity == false && evaluate_orientation == true
    evaluation_type = 'orientation';
elseif evaluate_velocity == true && evaluate_orientation == false
    evaluation_type = 'speed';
end

% Tracking der verarbeiteten IDs
all_processed_ids = [];

for batch_num = 1:num_batches
    batch_start_time = datetime('now');
    batch_start_idx = (batch_num-1) * BATCH_SIZE + 1;
    batch_end_idx = min(batch_num * BATCH_SIZE, length(unprocessed_bahn_ids));
    
    current_batch_ids = unprocessed_bahn_ids(batch_start_idx:batch_end_idx);
    disp(['Verarbeite Batch ', num2str(batch_num), ' von ', num2str(num_batches), ...
          ' (Bahnen ', num2str(batch_start_idx), '-', num2str(batch_end_idx), ' von ', ...
          num2str(length(unprocessed_bahn_ids)), ')']);
    
    % Verarbeite den Batch (nur Berechnungen, kein Upload)
    [batch_processed_ids, batch_euclidean_info, batch_sidtw_info, batch_dtw_info, batch_dfd_info, batch_lcss_info, ...
     batch_euclidean_deviations, batch_sidtw_deviations, batch_dtw_deviations, batch_dfd_deviations, batch_lcss_deviations] = ...
        processBatchWithoutUpload(conn, current_batch_ids, evaluate_velocity, evaluate_orientation, ...
                               evaluate_segmentwise, evaluate_all, plots);
    
    all_processed_ids = [all_processed_ids; batch_processed_ids];
    
    % Upload der aktuellen Batch-Daten
    if upload && ~isempty(batch_processed_ids)
        upload_start_time = datetime('now');
        disp(['Starte Upload für Batch ', num2str(batch_num), ' mit ', num2str(length(batch_processed_ids)), ' Bahnen...']);
        
        % Info-Tabellen hochladen
        if upload_info
            disp('Lade Info-Tabellen im Batch hoch...');
            if ~isempty(batch_sidtw_info)
                batchUpload2PostgreSQL('robotervermessung.auswertung.info_sidtw', batch_sidtw_info, evaluation_type, conn);
            end
            if ~isempty(batch_dtw_info)
                batchUpload2PostgreSQL('robotervermessung.auswertung.info_dtw', batch_dtw_info, evaluation_type, conn);
            end
            if ~isempty(batch_dfd_info)
                batchUpload2PostgreSQL('robotervermessung.auswertung.info_dfd', batch_dfd_info, evaluation_type, conn);
            end
            if evaluate_velocity == false
                if ~isempty(batch_euclidean_info)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.info_euclidean', batch_euclidean_info, evaluation_type, conn);
                end
                if ~isempty(batch_lcss_info)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.info_lcss', batch_lcss_info, evaluation_type, conn);
                end
            end
            disp('Info-Tabellen erfolgreich hochgeladen!');
        end
        
        % Abweichungs-Tabellen hochladen
        if upload_deviations
            disp('Lade Abweichungs-Tabellen im Batch hoch...');
            if evaluate_orientation == true && evaluate_velocity == false
                if ~isempty(batch_euclidean_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.orientation_euclidean', batch_euclidean_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_sidtw_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.orientation_sidtw', batch_sidtw_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_dtw_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.orientation_dtw', batch_dtw_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_dfd_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.orientation_dfd', batch_dfd_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_lcss_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.orientation_lcss', batch_lcss_deviations, evaluation_type, conn);
                end
            elseif evaluate_velocity == true && evaluate_orientation == false
                if ~isempty(batch_sidtw_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.speed_sidtw', batch_sidtw_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_dtw_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.speed_dtw', batch_dtw_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_dfd_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.speed_dfd', batch_dfd_deviations, evaluation_type, conn);
                end
            else
                if ~isempty(batch_euclidean_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.position_euclidean', batch_euclidean_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_sidtw_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.position_sidtw', batch_sidtw_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_dtw_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.position_dtw', batch_dtw_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_dfd_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.position_dfd', batch_dfd_deviations, evaluation_type, conn);
                end
                if ~isempty(batch_lcss_deviations)
                    batchUpload2PostgreSQL('robotervermessung.auswertung.position_lcss', batch_lcss_deviations, evaluation_type, conn);
                end
            end
            disp('Abweichungs-Tabellen erfolgreich hochgeladen!');
        end
        
        upload_end_time = datetime('now');
        upload_duration = seconds(upload_end_time - upload_start_time);
        disp(['Batch-Upload abgeschlossen in ', num2str(upload_duration), ' Sekunden!']);
    end
    
    % Speicher freigeben
    clear batch_euclidean_info batch_sidtw_info batch_dtw_info batch_dfd_info batch_lcss_info;
    clear batch_euclidean_deviations batch_sidtw_deviations batch_dtw_deviations batch_dfd_deviations batch_lcss_deviations;
    
    batch_end_time = datetime('now');
    batch_duration = seconds(batch_end_time - batch_start_time);
    disp(['Batch ', num2str(batch_num), ' abgeschlossen in ', num2str(batch_duration), ' Sekunden']);
end

total_duration = toc;
disp(['Gesamte Verarbeitung abgeschlossen in ', num2str(total_duration), ' Sekunden']);
disp(['Durchschnittliche Zeit pro Bahn: ', num2str(total_duration/length(all_processed_ids)), ' Sekunden']);

function batchUpload2PostgreSQL(tablename, data, evaluation_type, conn)
    try
        % Combine cell data if needed
        if iscell(data)
            try
                data = vertcat(data{:});
            catch e
                disp(['Fehler beim Kombinieren der Zell-Daten: ' e.message]);
                % Process each cell individually
                for i = 1:length(data)
                    if ~isempty(data{i})
                        sqlwrite(conn, tablename, data{i});
                    end
                end
                return;
            end
        end
        
        % Standardize data
        data = standardizeTableData(data);
        
        % Get total rows for progress tracking
        total_rows = height(data);
        disp(['Lade ' num2str(total_rows) ' Zeilen in ' tablename ' hoch...']);
        
        % Optimierte Einstellungen für Bulk-Import
        execute(conn, 'SET synchronous_commit = off');
        
        try
            % Manuell Transaktion starten
            execute(conn, 'BEGIN');
            
            % Optimierter Multi-Row Insert
            batchInsertMultipleRows(conn, tablename, data);
            
            % Commit transaction
            execute(conn, 'COMMIT');
            execute(conn, 'SET synchronous_commit = on');
            disp(['Erfolgreich ' num2str(total_rows) ' Zeilen in ' tablename ' hochgeladen']);
            
        catch inner_e
            % Rollback on error
            execute(conn, 'ROLLBACK');
            execute(conn, 'SET synchronous_commit = on');
            disp(['Fehler beim Batch-Upload, versuche Einzelzeilenmodus: ' inner_e.message]);
            
            % Try again with explicit INSERT statements for smaller batches
            batch_size = 250;
            for i = 1:batch_size:total_rows
                try
                    end_idx = min(i + batch_size - 1, total_rows);
                    current_batch = data(i:end_idx, :);
                    insertWithExplicitSQL(conn, tablename, current_batch);
                    
                    if mod(i, 500) == 0 || i == 1
                        disp(['Alternative Methode: ' num2str(end_idx) ' von ' num2str(total_rows)]);
                    end
                catch batch_e
                    disp(['Fehler bei Zeilen ' num2str(i) '-' num2str(end_idx) ': ' batch_e.message]);
                end
            end
        end
        
    catch e
        disp(['Fehler beim Hochladen der Daten: ' e.message]);
        disp('Stack Trace:');
        disp(getReport(e, 'extended'));
    end
end

function batchInsertMultipleRows(conn, tablename, data)
    % Get column names
    colNames = strjoin(data.Properties.VariableNames, ',');
    
    % Use multiple VALUES sets in a single statement
    batchSize = 10000; % Größe anpassen basierend auf Ihren Daten
    total_rows = height(data);
    
    for i = 1:batchSize:total_rows
        % Start building INSERT statement
        insertSql = ['INSERT INTO ' tablename ' (' colNames ') VALUES '];
        
        % Determine end index for this batch
        end_idx = min(i + batchSize - 1, total_rows);
        current_batch = data(i:end_idx, :);
        
        % Build values part with multiple rows
        valueStrings = cell(height(current_batch), 1);
        for j = 1:height(current_batch)
            rowValues = formatRowValues(current_batch(j,:));
            valueStrings{j} = ['(' rowValues ')'];
        end
        
        % Combine into final SQL
        insertSql = [insertSql strjoin(valueStrings, ', ')];
        
        % Execute the multi-row insert
        execute(conn, insertSql);
        
        % Show progress
        if mod(end_idx, batchSize*5) == 0 || end_idx == total_rows
            disp(['Hochgeladen: ' num2str(end_idx) ' von ' num2str(total_rows) ' Zeilen (' num2str(round(100*end_idx/total_rows)) '%)']);
        end
    end
end

% Alternative method using explicit SQL INSERT for small batches
function insertWithExplicitSQL(conn, tablename, data)
    % Get column names
    colNames = strjoin(data.Properties.VariableNames, ', ');
    
    % Process up to 10 rows at a time
    for i = 1:10:height(data)
        end_idx = min(i + 9, height(data));
        current_rows = data(i:end_idx, :);
        
        % Build INSERT statement
        insertSql = ['INSERT INTO ' tablename ' (' colNames ') VALUES '];
        
        valueStrings = cell(height(current_rows), 1);
        for j = 1:height(current_rows)
            rowValues = formatRowValues(current_rows(j,:));
            valueStrings{j} = ['(' rowValues ')'];
        end
        
        insertSql = [insertSql strjoin(valueStrings, ', ')];
        
        % Execute insert
        execute(conn, insertSql);
    end
end

function valueStr = formatRowValues(row)
    values = cell(1, width(row));
    
    for i = 1:width(row)
        val = row{1,i};
        
        if ischar(val) || isstring(val)
            values{i} = ['''' strrep(char(val), '''', '''''') ''''];
        elseif iscell(val)
            if isempty(val)
                values{i} = 'NULL';
            else
                values{i} = ['''' strrep(char(val{1}), '''', '''''') ''''];
            end
        elseif isnumeric(val)
            if isnan(val)
                values{i} = 'NULL';
            else
                values{i} = num2str(val);
            end
        else
            values{i} = 'NULL';
        end
    end
    
    valueStr = strjoin(values, ', ');
end

% Hilfsfunktion zum Standardisieren der Daten
function standardizedData = standardizeTableData(data)
    % Überprüfe jede Spalte auf konsistente Datentypen
    for col = 1:width(data)
        colName = data.Properties.VariableNames{col};
        colData = data.(colName);
        
        % Wenn es sich um eine Zellen-Spalte handelt
        if iscell(colData)
            % Prüfe auf Zellen, die selbst Zellen enthalten
            hasNestedCells = false;
            for i = 1:length(colData)
                if iscell(colData{i})
                    hasNestedCells = true;
                    break;
                end
            end
            
            if hasNestedCells
                % Unneste die Zellen
                newColData = cell(size(colData));
                for i = 1:length(colData)
                    if iscell(colData{i}) && ~isempty(colData{i})
                        newColData{i} = colData{i}{1};
                    else
                        newColData{i} = colData{i};
                    end
                end
                data.(colName) = newColData;
            end
        end
    end
    
    standardizedData = data;
end

function [processed_ids, batch_euclidean_info, batch_sidtw_info, batch_dtw_info, batch_dfd_info, batch_lcss_info, ...
          batch_euclidean_deviations, batch_sidtw_deviations, batch_dtw_deviations, batch_dfd_deviations, batch_lcss_deviations] = ...
    processBatchWithoutUpload(conn, batch_ids, evaluate_velocity, evaluate_orientation, ...
                         evaluate_segmentwise, evaluate_all, plots)
    % Initialisiere Batch-Sammlungen
    all_calibration_ids = {};
    all_segment_ids = {};
    
    % Tabellen für jede Metrik initialisieren
    batch_euclidean_info = table();
    batch_sidtw_info = table();
    batch_dtw_info = table();
    batch_dfd_info = table();
    batch_lcss_info = table();
    
    % Sammlungen für Abweichungsdaten
    batch_euclidean_deviations = {};
    batch_sidtw_deviations = {};
    batch_dtw_deviations = {};
    batch_dfd_deviations = {};
    batch_lcss_deviations = {};
    
    % Verarbeitete BahnIDs für diesen Batch
    processed_ids = [];
    
    % Bestimme den Evaluationstyp
    if evaluate_velocity == false && evaluate_orientation == false
        evaluation_type = 'position';
    elseif evaluate_velocity == false && evaluate_orientation == true
        evaluation_type = 'orientation';
    elseif evaluate_velocity == true && evaluate_orientation == false
        evaluation_type = 'speed';
    end
    
    % Schleife über alle Bahnen im Batch
    for i = 1:length(batch_ids)
        bahn_id_ = num2str(batch_ids(i));
        disp(['Verarbeite Bahn ', num2str(i), ' von ', num2str(length(batch_ids)), ': ', bahn_id_]);
        
        try
            % Suche nach zugehörigem "Calibration Run"
            [calibration_id, is_calibration_run] = findCalibrationRun(conn, bahn_id_, 'bewegungsdaten');
            
            % Extrahiere und verarbeite die Daten für diese Bahn
            [table_euclidean_info, table_sidtw_info, table_dtw_info, table_dfd_info, table_lcss_info, ...
             table_euclidean_deviation, table_sidtw_deviation, table_dtw_deviation, ...
             table_dfd_deviation, table_lcss_deviation, segment_ids] = ...
                processSingleTrajectory(conn, bahn_id_, calibration_id, evaluate_velocity, ...
                                       evaluate_orientation, evaluate_segmentwise, evaluate_all, plots, evaluation_type);
            
            % Sammle die Daten für den Batch-Upload
            processed_ids = [processed_ids; str2double(bahn_id_)];
            all_calibration_ids{end+1} = calibration_id;
            all_segment_ids{end+1} = segment_ids;
            
            % Sammle Info-Tabellen
            if ~isempty(table_euclidean_info)
                batch_euclidean_info = [batch_euclidean_info; table_euclidean_info];
            end
            if ~isempty(table_sidtw_info)
                batch_sidtw_info = [batch_sidtw_info; table_sidtw_info];
            end
            if ~isempty(table_dtw_info)
                batch_dtw_info = [batch_dtw_info; table_dtw_info];
            end
            if ~isempty(table_dfd_info)
                batch_dfd_info = [batch_dfd_info; table_dfd_info];
            end
            if ~isempty(table_lcss_info)
                batch_lcss_info = [batch_lcss_info; table_lcss_info];
            end
            
            % Sammle Abweichungsdaten
            if ~isempty(table_euclidean_deviation)
                batch_euclidean_deviations = [batch_euclidean_deviations; table_euclidean_deviation];
            end
            if ~isempty(table_sidtw_deviation)
                batch_sidtw_deviations = [batch_sidtw_deviations; table_sidtw_deviation];
            end
            if ~isempty(table_dtw_deviation)
                batch_dtw_deviations = [batch_dtw_deviations; table_dtw_deviation];
            end
            if ~isempty(table_dfd_deviation)
                batch_dfd_deviations = [batch_dfd_deviations; table_dfd_deviation];
            end
            if ~isempty(table_lcss_deviation)
                batch_lcss_deviations = [batch_lcss_deviations; table_lcss_deviation];
            end
            
            disp(['Bahn ', bahn_id_, ' erfolgreich verarbeitet']);
        catch e
            warning(['Fehler bei der Verarbeitung von Bahn ', bahn_id_, ': ', e.message]);
            % Protokolliere den Fehler und mache mit der nächsten Bahn weiter
            continue;
        end
    end
end



function [table_euclidean_info, table_sidtw_info, table_dtw_info, table_dfd_info, table_lcss_info, ...
          table_euclidean_deviation, table_sidtw_deviation, table_dtw_deviation, ...
          table_dfd_deviation, table_lcss_deviation, segment_ids] = ...
              processSingleTrajectory(conn, bahn_id_, calibration_id, evaluate_velocity, ...
                                      evaluate_orientation, evaluate_segmentwise, evaluate_all, plots, evaluation_type)
    % Hier sollte der eigentliche Verarbeitungscode des vorhandenen Skripts eingebaut werden,
    % aber ohne den Upload-Teil. Der Upload erfolgt später gesammelt.
    
    % Extrahieren der Kalibrierungs-Daten
    tablename_cal = 'robotervermessung.bewegungsdaten.bahn_pose_ist';
    opts_cal = databaseImportOptions(conn, tablename_cal);
    opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
    data_cal_ist = sqlread(conn, tablename_cal, opts_cal);
    data_cal_ist = sortrows(data_cal_ist, 'timestamp');
    
    tablename_cal = 'robotervermessung.bewegungsdaten.bahn_events';
    opts_cal = databaseImportOptions(conn, tablename_cal);
    opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
    data_cal_soll = sqlread(conn, tablename_cal, opts_cal);
    data_cal_soll = sortrows(data_cal_soll, 'timestamp');
    
    % Positionsdaten für Koordinatentransformation
    [trafo_rot, trafo_trans, ~] = calibration(data_cal_ist, data_cal_soll, plots);

if evaluate_orientation == true
    % Wenn Orientierung wird andere Collection benötigt
    tablename_cal = ['robotervermessung.' schema '.bahn_orientation_soll'];
    opts_cal = databaseImportOptions(conn,tablename_cal);
    opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
    data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
    data_cal_soll = sortrows(data_cal_soll,'timestamp');
    
    % Transformation der Quaternionen/Eulerwinkel
    calibrateQuaternion(data_cal_ist, data_cal_soll);
end

clear opts_cal tablename_cal data_cal_ist data_cal_soll

%% Auslesen der für die entsprechende Auswertung benötigten Daten

% Anzahl der Segmente der gesamten Messaufnahme bestimmen 
query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_info ' ...
         'WHERE robotervermessung.bewegungsdaten.bahn_info.bahn_id = ''' bahn_id_ ''''];
data_info = fetch(conn, query);
num_segments = data_info.np_ereignisse;

% Daten auslesen
if evaluate_velocity == false && evaluate_orientation == true

    % Auslesen der gesamten Ist-Daten
    query = ['SELECT * FROM robotervermessung.' schema '.bahn_pose_ist ' ...
            'WHERE robotervermessung.' schema '.bahn_pose_ist.bahn_id = ''' bahn_id_ ''''];
    data_ist = fetch(conn, query);
    data_ist = sortrows(data_ist,'timestamp');
    
    % Auslesen der gesamten Soll-Daten
    query = ['SELECT * FROM robotervermessung.' schema '.bahn_orientation_soll ' ...
            'WHERE robotervermessung.' schema '.bahn_orientation_soll.bahn_id = ''' bahn_id_ ''''];
    data_soll = fetch(conn, query);
    data_soll = sortrows(data_soll,'timestamp');
    
    q_ist = table2array(data_ist(:,8:11));
    q_ist = [q_ist(:,4), q_ist(:,1), q_ist(:,2), q_ist(:,3)];
    euler_ist = quat2eul(q_ist,"XYZ");
    euler_ist = rad2deg(euler_ist);

    % Position data for transformation
    position_ist = table2array(data_ist(:,5:7));
       
    % Transform position
    pos_ist_trafo = coord_transformation(position_ist, trafo_rot, trafo_trans);
    
    q_transformed = transformQuaternion(data_ist, data_soll, q_transform, trafo_rot);

elseif evaluate_velocity == true && evaluate_orientation == false 

    % Auslesen der gesamten Ist-Daten
    query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_twist_ist ' ...
            'WHERE robotervermessung.bewegungsdaten.bahn_twist_ist.bahn_id = ''' bahn_id_ ''''];
    data_ist = fetch(conn, query);
    data_ist = sortrows(data_ist,'timestamp');
    
    % Auslesen der gesamten Soll-Daten

    % query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_twist_soll ' ...
    %         'WHERE robotervermessung.bewegungsdaten.bahn_twist_soll.bahn_id = ''' bahn_id_ ''''];
    query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_position_soll ' ...
            'WHERE robotervermessung.bewegungsdaten.bahn_position_soll.bahn_id = ''' bahn_id_ ''''];
    data_soll = fetch(conn, query);
    data_soll = sortrows(data_soll,'timestamp');

    % Geschwindigkeitsdaten präperieren 
    velocity_prep(data_soll, data_ist)

else
    % Auslesen der gesamten Ist-Daten
    query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_pose_ist ' ...
            'WHERE robotervermessung.bewegungsdaten.bahn_pose_ist.bahn_id = ''' bahn_id_ ''''];
    data_ist = fetch(conn, query);
    data_ist = sortrows(data_ist,'timestamp');
    
    % Auslesen der gesamten Soll-Daten
    query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_position_soll ' ...
            'WHERE robotervermessung.bewegungsdaten.bahn_position_soll.bahn_id = ''' bahn_id_ ''''];
    data_soll = fetch(conn, query);
    data_soll = sortrows(data_soll,'timestamp');

end

clear q_ist q_soll


%% Extraktion und Separation der Segmente der Gesamtaufname

% Alle Segment-ID's 
query = ['SELECT segment_id FROM robotervermessung.bewegungsdaten.bahn_events ' ...
    'WHERE robotervermessung.bewegungsdaten.bahn_events.bahn_id = ''' bahn_id_ ''''];

segment_ids = fetch(conn,query);

% % % IST-DATEN % % %
% Extraktion der Indizes der Segmente 
seg_id = split(data_ist.segment_id, '_');
seg_id = double(string(seg_id(:,2)));
idx_new_seg_ist = zeros(num_segments,1);

% Suche nach den Indizes bei denen sich die Segmentnr. ändert
k = 0;
idx = 1;
for i = 1:1:length(seg_id)
    if seg_id(i) == k
        idx = idx + 1;
    else
        k = k +1;
        idx_new_seg_ist(k) = idx;
        idx = idx+1;
    end
end

% % % SOLL-DATEN % % %
seg_id = split(data_soll.segment_id, '_');
seg_id = double(string(seg_id(:,2)));
idx_new_seg_soll = zeros(num_segments,1);

k = 0;
idx = 1;
for i = 1:1:length(seg_id)
    if seg_id(i) == k
        idx = idx + 1;
    else
        k = k +1;
        idx_new_seg_soll(k) = idx;
        idx = idx+1;
    end
end


if evaluate_velocity == true && evaluate_orientation == false 

    disp('Es wird die Geschwindigkeit ausgewertet!')

    % Speichern der einzelnen Semgente in Tabelle
    segments_ist = array2table([{string(bahn_id_)+"_0"} table2array(data_ist(1:idx_new_seg_ist(1)-1,[3,4]))], "VariableNames",{'segment_id','tcp_speed_ist'});
   
    for i = 1:num_segments
    
        if i == length(idx_new_seg_ist)
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.tcp_speed_ist(idx_new_seg_ist(i):end)]);
        else
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.tcp_speed_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1)]);
        end
    
    end
    
    if idx_new_seg_soll(1) == 1
        segments_soll = array2table([{string(bahn_id_)+"_0"} table2array(data_soll(1:idx_new_seg_soll(1),[3,4]))], "VariableNames",{'segment_id','tcp_speed_soll'});
    else
        segments_soll = array2table([{string(bahn_id_)+"_0"} table2array(data_soll(1:idx_new_seg_soll(1)-1,[3,4]))], "VariableNames",{'segment_id','tcp_speed_soll'});
    end
    for i = 1:num_segments
        if i == length(idx_new_seg_soll)
            segments_soll(i+1,:) = array2table([{segment_ids{i,:}} data_soll.tcp_speed_soll(idx_new_seg_soll(i):end)]);
        else
            segments_soll(i+1,:)= array2table([{segment_ids{i,:}} data_soll.tcp_speed_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1)]);
        end    
    end
    
elseif evaluate_velocity == false && evaluate_orientation == true

    disp('Es wird die Orientierung ausgewertet!')

    % First segment IST data (quaternions)
    segments_ist = array2table([{data_ist.segment_id(1)} ...
                              data_ist.qw_ist(1:idx_new_seg_ist(1)-1) ...
                              data_ist.qx_ist(1:idx_new_seg_ist(1)-1) ...
                              data_ist.qy_ist(1:idx_new_seg_ist(1)-1) ...
                              data_ist.qz_ist(1:idx_new_seg_ist(1)-1)], ...
                              'VariableNames', {'segment_id', 'qw_ist', 'qx_ist', 'qy_ist', 'qz_ist'});
    
    % Remaining IST segments
    for i = 1:num_segments
        if i == length(idx_new_seg_ist)
            % Last segment
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} ...
                                             data_ist.qw_ist(idx_new_seg_ist(i):end) ...
                                             data_ist.qx_ist(idx_new_seg_ist(i):end) ...
                                             data_ist.qy_ist(idx_new_seg_ist(i):end) ...
                                             data_ist.qz_ist(idx_new_seg_ist(i):end)]);
        else
            % Middle segments
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} ...
                                             data_ist.qw_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) ...
                                             data_ist.qx_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) ...
                                             data_ist.qy_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) ...
                                             data_ist.qz_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1)]);
        end
    end
    
    
    if idx_new_seg_soll(1) == 1
        % First segment SOLL data
        segments_soll = array2table([{data_soll.segment_id(1)} ...
                                data_soll.qw_soll(1:idx_new_seg_soll(1)) ...
                                data_soll.qx_soll(1:idx_new_seg_soll(1)) ...
                                data_soll.qy_soll(1:idx_new_seg_soll(1)) ...
                                data_soll.qz_soll(1:idx_new_seg_soll(1))], ...
                                'VariableNames', {'segment_id', 'qw_soll', 'qx_soll', 'qy_soll', 'qz_soll'});

    else
        % First segment SOLL data
        segments_soll = array2table([{data_soll.segment_id(1)} ...
                                data_soll.qw_soll(1:idx_new_seg_soll(1)-1) ...
                                data_soll.qx_soll(1:idx_new_seg_soll(1)-1) ...
                                data_soll.qy_soll(1:idx_new_seg_soll(1)-1) ...
                                data_soll.qz_soll(1:idx_new_seg_soll(1)-1)], ...
                                'VariableNames', {'segment_id', 'qw_soll', 'qx_soll', 'qy_soll', 'qz_soll'});

    end
    
    
    % Remaining SOLL segments
    for i = 1:num_segments
        if i == length(idx_new_seg_soll)
            segments_soll(i+1,:) = array2table([{segment_ids{i,:}} ...
                                              data_soll.qw_soll(idx_new_seg_soll(i):end) ...
                                              data_soll.qx_soll(idx_new_seg_soll(i):end) ...
                                              data_soll.qy_soll(idx_new_seg_soll(i):end) ...
                                              data_soll.qz_soll(idx_new_seg_soll(i):end)]);
        else
            segments_soll(i+1,:) = array2table([{segment_ids{i,:}} ...
                                              data_soll.qw_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) ...
                                              data_soll.qx_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) ...
                                              data_soll.qy_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) ...
                                              data_soll.qz_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1)]);
        end
    end
    
    % Initialize transformation results
    segments_trafo = table();
    q_transformed_all = [];
    
    % Transform each segment
    for i = 1:num_segments+1
        % Extract quaternions for current segment
        segment_ist = table2struct(segments_ist(i,:));
        segment_soll = table2struct(segments_soll(i,:));
        
        % Create temporary tables with the segment data
        data_ist_seg = table(segment_ist.qw_ist, segment_ist.qx_ist, segment_ist.qy_ist, segment_ist.qz_ist, ...
                            'VariableNames', {'qw_ist', 'qx_ist', 'qy_ist', 'qz_ist'});
        data_soll_seg = table(segment_soll.qw_soll, segment_soll.qx_soll, segment_soll.qy_soll, segment_soll.qz_soll, ...
                             'VariableNames', {'qw_soll', 'qx_soll', 'qy_soll', 'qz_soll'});
        
        % Transform using existing function
        q_transformed = transformQuaternion(data_ist_seg, data_soll_seg, q_transform, trafo_rot);

        % Add row to segments_trafo
        segments_trafo(i,:) = table({segments_ist.segment_id(i)}, ...
                               {q_transformed(:,1)}, {q_transformed(:,2)}, ...
                               {q_transformed(:,3)}, {q_transformed(:,4)}, ...
                               'VariableNames', {'segment_id', 'qw_trans', 'qx_trans', 'qy_trans', 'qz_trans'});
    
        % Accumulate all transformed quaternions
        q_transformed_all = [q_transformed_all; q_transformed];
    end
    
    % Store results in workspace
    assignin('base', 'segments_trafo', segments_trafo);
    assignin('base', 'q_transformed', q_transformed_all);

%%%%%%% Sonst automatisch Auswertung von Positionsdaten 
else

    disp('Es wird die Position ausgewertet!')

    % Speichern der einzelnen Semgente in Tabelle
    segments_ist = array2table([{data_ist.segment_id(1)} data_ist.x_ist(1:idx_new_seg_ist(1)-1) data_ist.y_ist(1:idx_new_seg_ist(1)-1) data_ist.z_ist(1:idx_new_seg_ist(1)-1)], "VariableNames",{'segment_id','x_ist','y_ist','z_ist'});
    
    for i = 1:num_segments
    
        if i == length(idx_new_seg_ist)
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.x_ist(idx_new_seg_ist(i):end) data_ist.y_ist(idx_new_seg_ist(i):end) data_ist.z_ist(idx_new_seg_ist(i):end)]);
        else
            segments_ist(i+1,:) = array2table([{segment_ids{i,:}} data_ist.x_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) data_ist.y_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1) data_ist.z_ist(idx_new_seg_ist(i):idx_new_seg_ist(i+1)-1)]);
        end
    
    end
    
    if idx_new_seg_soll(1) == 1
        segments_soll = array2table([{data_soll.segment_id(1)} data_soll.x_soll(1:idx_new_seg_soll(1)) data_soll.y_soll(1:idx_new_seg_soll(1)) data_soll.z_soll(1:idx_new_seg_soll(1))], "VariableNames",{'segment_id','x_soll','y_soll','z_soll'});
    else    
        segments_soll = array2table([{data_soll.segment_id(1)} data_soll.x_soll(1:idx_new_seg_soll(1)-1) data_soll.y_soll(1:idx_new_seg_soll(1)-1) data_soll.z_soll(1:idx_new_seg_soll(1)-1)], "VariableNames",{'segment_id','x_soll','y_soll','z_soll'});
    end
    for i = 1:num_segments
        if i == length(idx_new_seg_soll)
            segments_soll(i+1,:) = array2table([{segment_ids{i,:}} data_soll.x_soll(idx_new_seg_soll(i):end) data_soll.y_soll(idx_new_seg_soll(i):end) data_soll.z_soll(idx_new_seg_soll(i):end)]);
        else
            segments_soll(i+1,:)= array2table([{segment_ids{i,:}} data_soll.x_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) data_soll.y_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1) data_soll.z_soll(idx_new_seg_soll(i):idx_new_seg_soll(i+1)-1)]);
        end    
    end
    
    % Koordinatentransformation für alle Segemente
    segments_trafo = table();
    for i = 1:1:num_segments+1
        pos_ist_trafo = coord_transformation(segments_ist(i,:),trafo_rot, trafo_trans);
        segments_trafo(i,:) = pos_ist_trafo;
    end

end

% Löschen des Segment 0: 
segments_soll = segments_soll(2:end,:);
segments_ist = segments_ist(2:end,:);
if evaluate_velocity == false
    segments_trafo = segments_trafo(2:end,:);
end
num_segments = num_segments -1;

clear idx k seg_id query seg_trafo

%% Berechnung der Metriken

% Tabellen initialisieren
table_sidtw_info = table();
table_sidtw_deviation = cell(num_segments,1);
table_dtw_info = table();
table_dtw_deviation = cell(num_segments,1);
table_dfd_info = table();
table_dfd_deviation = cell(num_segments,1);

% Wenn Geschwindigkeit ausgewertet werden soll sind die 1D-Metriken nicht durchfürbar
if size(segments_soll,2) > 2
    table_euclidean_info = table();
    table_euclidean_deviation = cell(num_segments,1);
    table_lcss_info = table();
    table_lcss_deviation = cell(num_segments,1);
end

% Berechnung der Metriken für alle Segmente
for i = 1:1:num_segments

    if evaluate_velocity == false && evaluate_orientation == false 
        segment_trafo = [segments_trafo.x_ist{i}, segments_trafo.y_ist{i}, segments_trafo.z_ist{i}];
        segment_soll = [segments_soll.x_soll{i}, segments_soll.y_soll{i}, segments_soll.z_soll{i}];
    elseif evaluate_velocity == true && evaluate_orientation == false 
        segment_trafo = segments_ist.tcp_speed_ist{i};
        segment_soll = segments_soll.tcp_speed_soll{i};
    elseif evaluate_velocity == false && evaluate_orientation == true 

        segment_trafo = [segments_trafo.qx_trans{i}, segments_trafo.qy_trans{i},  segments_trafo.qz_trans{i}, segments_trafo.qw_trans{i}];
        segment_soll = [segments_soll.qx_soll{i}, segments_soll.qy_soll{i}, segments_soll.qz_soll{i}, segments_soll.qw_soll{i}];
        
        segment_trafo = fixGimbalLock(rad2deg(quat2eul(segment_trafo)));
        segment_soll = fixGimbalLock(rad2deg(quat2eul(segment_soll)));
    end

    if size(segment_soll,2) > 1 % Wird nicht betrachtet wenn Geschwindigkeit ausgewertet wird 

    % Berechnung euklidischer Abstand
    [euclidean_soll, euclidean_distances,~] = distance2curve(segment_soll, segment_trafo,'linear');
    % Berechnung LCSS
    [~, ~, lcss_distances, ~, ~, lcss_soll, lcss_ist, ~, ~] = fkt_lcss(segment_soll,segment_trafo,false);

    end
    % Berechnung SIDTW
    [sidtw_distances, ~, ~, ~, sidtw_soll, sidtw_ist, ~, ~, ~] = fkt_selintdtw3d(segment_soll,segment_trafo,false);
    % Berechnung DTW
    [dtw_distances, ~, ~, ~, dtw_soll, dtw_ist, ~, ~, ~, ~] = fkt_dtw3d(segment_soll,segment_trafo,false);
    % Berechnung diskrete Frechet
    [~, ~, frechet_distances, ~, ~, frechet_soll, frechet_ist] = fkt_discreteFrechet(segment_soll,segment_trafo,false);


    if i == 1
        if size(segment_soll,2) > 1
            % Euklidischer Abstand
            [seg_euclidean_info, seg_euclidean_distances] = metric2postgresql('euclidean',euclidean_distances, euclidean_soll, segment_trafo, bahn_id_, segment_ids{i,:});
            table_euclidean_info = seg_euclidean_info;
            order_eucl_first = size(seg_euclidean_distances,1);
            seg_euclidean_distances = [seg_euclidean_distances, table((1:1:order_eucl_first)','VariableNames',{'points_order'})];
            table_euclidean_deviation{1} = seg_euclidean_distances;
            % LCSS
            [seg_lcss_info, seg_lcss_distances] = metric2postgresql('lcss',lcss_distances, lcss_soll, lcss_ist, bahn_id_, segment_ids{i,:});
            table_lcss_info = seg_lcss_info;
            order_lcss_first = size(seg_lcss_distances,1);
            seg_lcss_distances = [seg_lcss_distances, table((1:1:order_lcss_first)','VariableNames',{'points_order'})];
            table_lcss_deviation{1} = seg_lcss_distances;
        end
        % SIDTW
        [seg_sidtw_info, seg_sidtw_distances] = metric2postgresql('sidtw', sidtw_distances, sidtw_soll, sidtw_ist, bahn_id_, segment_ids{i,:});
        table_sidtw_info = seg_sidtw_info;
        order_sidtw_first = size(seg_sidtw_distances,1);
        seg_sidtw_distances = [seg_sidtw_distances, table((1:1:order_sidtw_first)','VariableNames',{'points_order'})];
        table_sidtw_deviation{1} = seg_sidtw_distances;

        % DTW
        [seg_dtw_info, seg_dtw_distances] = metric2postgresql('dtw',dtw_distances, dtw_soll, dtw_ist, bahn_id_, segment_ids{i,:});
        table_dtw_info = seg_dtw_info;
        order_dtw_first = size(seg_dtw_distances,1);
        seg_dtw_distances = [seg_dtw_distances, table((1:1:order_dtw_first)','VariableNames',{'points_order'})];
        table_dtw_deviation{1} = seg_dtw_distances;
        % DFD
        [seg_dfd_info, seg_dfd_distances] = metric2postgresql('dfd',frechet_distances, frechet_soll, frechet_ist, bahn_id_, segment_ids{i,:});
        table_dfd_info = seg_dfd_info;
        order_dfd_first = size(seg_dfd_distances,1);
        seg_dfd_distances = [seg_dfd_distances, table((1:1:order_dfd_first)','VariableNames',{'points_order'})];
        table_dfd_deviation{1} = seg_dfd_distances;       


    else
        if size(segment_soll,2) > 1
            % Euklidischer Abstand
            [seg_euclidean_info, seg_euclidean_distances] = metric2postgresql('euclidean',euclidean_distances, euclidean_soll, segment_trafo, bahn_id_, segment_ids{i,:});
            table_euclidean_info(i,:) = seg_euclidean_info;
            order_eucl_last = order_eucl_first + size(seg_euclidean_distances,1);
            seg_euclidean_distances = [seg_euclidean_distances, table((order_eucl_first+1:1:order_eucl_last)','VariableNames',{'points_order'})];
            order_eucl_first = order_eucl_last;
            table_euclidean_deviation{i} = seg_euclidean_distances;
            % LCSS
            [seg_lcss_info, seg_lcss_distances] = metric2postgresql('lcss',lcss_distances, lcss_soll, lcss_ist, bahn_id_, segment_ids{i,:});
            table_lcss_info(i,:) = seg_lcss_info;
            order_lcss_last = order_lcss_first + size(seg_lcss_distances,1);
            seg_lcss_distances = [seg_lcss_distances, table((order_lcss_first+1:1:order_lcss_last)','VariableNames',{'points_order'})];
            order_lcss_first = order_lcss_last;
            table_lcss_deviation{i} = seg_lcss_distances;
        end
        % SIDTW
        [seg_sidtw_info, seg_sidtw_distances] = metric2postgresql('sidtw',sidtw_distances, sidtw_soll, sidtw_ist, bahn_id_, segment_ids{i,:});
        table_sidtw_info(i,:) = seg_sidtw_info;
        order_sidtw_last = order_sidtw_first + size(seg_sidtw_distances,1);
        seg_sidtw_distances = [seg_sidtw_distances, table((order_sidtw_first+1:1:order_sidtw_last)','VariableNames',{'points_order'})];
        order_sidtw_first = order_sidtw_last;
        table_sidtw_deviation{i} = seg_sidtw_distances;
        % DTW
        [seg_dtw_info, seg_dtw_distances] = metric2postgresql('dtw',dtw_distances, dtw_soll, dtw_ist, bahn_id_, segment_ids{i,:});
        table_dtw_info(i,:) = seg_dtw_info;
        order_dtw_last = order_dtw_first + size(seg_dtw_distances,1);
        seg_dtw_distances = [seg_dtw_distances, table((order_dtw_first+1:1:order_dtw_last)','VariableNames',{'points_order'})];
        order_dtw_first = order_dtw_last;
        table_dtw_deviation{i} = seg_dtw_distances;
        % DFD
        [seg_dfd_info, seg_dfd_distances] = metric2postgresql('dfd',frechet_distances, frechet_soll, frechet_ist, bahn_id_, segment_ids{i,:});
        table_dfd_info(i,:) = seg_dfd_info;
        order_dfd_last = order_dfd_first + size(seg_dfd_distances,1);
        seg_dfd_distances = [seg_dfd_distances, table((order_dfd_first+1:1:order_dfd_last)','VariableNames',{'points_order'})];
        order_dfd_first = order_dfd_last;
        table_dfd_deviation{i} = seg_dfd_distances;


    end
end

% Berechnung der Kennzahlen für die Gesamtmessung
sidtw = table();
sidtw.bahn_id = {bahn_id_};  
sidtw.calibration_id = {calibration_id};  
sidtw.min_distance = min(table_sidtw_info.sidtw_min_distance); 
sidtw.max_distance = max(table_sidtw_info.sidtw_max_distance);
sidtw.average_distance = mean(table_sidtw_info.sidtw_average_distance);
sidtw.standard_deviation = mean(table_sidtw_info.sidtw_standard_deviation);
sidtw.metrik = "sidtw";

dtw = table();
dtw.bahn_id = {bahn_id_};  
dtw.calibration_id = {calibration_id};  
dtw.min_distance = min(table_dtw_info.dtw_min_distance); 
dtw.max_distance = max(table_dtw_info.dtw_max_distance);
dtw.average_distance = mean(table_dtw_info.dtw_average_distance);
dtw.standard_deviation = mean(table_dtw_info.dtw_standard_deviation);
dtw.metrik = "dtw";

dfd = table();
dfd.bahn_id = {bahn_id_};  
dfd.calibration_id = {calibration_id};  
dfd.min_distance = min(table_dfd_info.dfd_min_distance); 
dfd.max_distance = max(table_dfd_info.dfd_max_distance);
dfd.average_distance = mean(table_dfd_info.dfd_average_distance);
dfd.standard_deviation = mean(table_dfd_info.dfd_standard_deviation);
dfd.metrik = "dfd";

if size(segment_soll,2) > 1
lcss = table();
lcss.bahn_id = {bahn_id_};  
lcss.calibration_id = {calibration_id};  
lcss.min_distance = min(table_lcss_info.lcss_min_distance); 
lcss.max_distance = max(table_lcss_info.lcss_max_distance);
lcss.average_distance = mean(table_lcss_info.lcss_average_distance);
lcss.standard_deviation = mean(table_lcss_info.lcss_standard_deviation);
lcss.metrik = "lcss";

table_all_info = table();
table_all_info.bahn_id = {bahn_id_};
table_all_info.calibration_id = {calibration_id};
table_all_info.min_distance = min(table_euclidean_info.euclidean_min_distance);
table_all_info.max_distance = max(table_euclidean_info.euclidean_max_distance);
table_all_info.average_distance = mean(table_euclidean_info.euclidean_average_distance);
table_all_info.standard_deviation = mean(table_euclidean_info.euclidean_standard_deviation);
table_all_info.metrik = "euclidean";

table_all_info = [table_all_info; sidtw; dtw; dfd; lcss];

else
    table_all_info = [sidtw; dtw; dfd];
end

clear order_eucl_first order_eucl_last order_lcss_first order_lcss_last 
clear order_dfd_first order_dfd_last order_dtw_first order_dtw_last order_sidtw_first order_sidtw_last
clear sidtw sidtw_distances sidtw_ist sidtw_soll seg_sidtw_info seg_sidtw_distances
clear dtw dtw_distances dtw_ist dtw_soll seg_dtw_info seg_dtw_distances
clear dfd frechet_distances frechet_ist frechet_soll frechet_path frechet_matrix frechet_dist frechet_av seg_dfd_info seg_dfd_distances
clear lcss lcss_distances lcss_ist lcss_soll seg_lcss_info seg_lcss_distances
clear euclidean_distances euclidean_ist seg_euclidean_info seg_euclidean_distances
clear pos_ist_trafo segment_ist segment_soll segment_trafo i min_diff 

%% Auswertung der gesamten Messaufnahme 

if evaluate_all == true && evaluate_velocity == false

    % segment_id = bahn_id;

    % Zuerst die segment_ids richtig sortieren (numerisch nach der Zahl nach dem Unterstrich)
    segment_ids_array = table2array(segment_ids);
    segment_ids_numeric = zeros(size(segment_ids_array));
    
    for i = 1:length(segment_ids_array)
        tokens = regexp(segment_ids_array{i}, '_(\d+)$', 'tokens', 'once');
        if ~isempty(tokens)
            segment_ids_numeric(i) = str2double(tokens{1});
        end
    end
    
    [~, sort_idx] = sort(segment_ids_numeric);
    sorted_segment_ids = segment_ids_array(sort_idx);
    
    % Jetzt das erste und letzte Segment basierend auf den sortierten IDs abschneiden
    first_segment = sorted_segment_ids{1};
    last_segment = sorted_segment_ids{end};
    
    % Daten für IST filtern
    first_row_ist = find(data_ist.segment_id == first_segment, 1);
    last_row_ist = find(data_ist.segment_id == last_segment, 1) - 1;
    data_all_ist = data_ist(first_row_ist:last_row_ist,:);
    
    % Daten für SOLL filtern
    first_row_soll = find(data_soll.segment_id == first_segment, 1);
    last_row_soll = find(data_soll.segment_id == last_segment, 1) - 1;
    data_all_soll = data_soll(first_row_soll:last_row_soll,:);


    if evaluate_orientation == true
        q_transformed_all = transformQuaternion(data_all_ist, data_all_soll, q_transform, trafo_rot);
        
        % Quaternion-Transformation für die weitere Verarbeitung verwenden
        data_all_ist = q_transformed_all;
        data_ist_trafo = fixGimbalLock(rad2deg(quat2eul(data_all_ist)));
        data_all_soll = [data_all_soll.qw_soll, data_all_soll.qx_soll, data_all_soll.qy_soll, data_all_soll.qz_soll];
        data_all_soll = fixGimbalLock(rad2deg(quat2eul(data_all_soll)));
    else 
        data_all_ist = table2array(data_all_ist(:,5:7));
        data_all_soll = table2array(data_all_soll(:,5:7));
    
        % Koordinatentrafo für alle Daten 
        data_ist_trafo = coord_transformation(data_all_ist, trafo_rot, trafo_trans);
    end
    
    % Euklidischer Abstand
    tic
    [euclidean_ist,euclidean_distances,~] = distance2curve(data_ist_trafo,data_all_soll,'linear');
    toc
    disp('Euklidischer Abstand berechnet -->')

    % SIDTW
    tic
    [sidtw_distances, ~, ~, ~, sidtw_soll, sidtw_ist, ~, ~, ~] = fkt_selintdtw3d(data_all_soll,data_ist_trafo,false);
    toc
    disp('SIDTW berechnet -->')
    % DTW
    tic
    [dtw_distances, ~, ~, ~, dtw_soll, dtw_ist, ~, ~, ~, ~] = fkt_dtw3d(data_all_soll,data_ist_trafo,false);
    toc
    disp('DTW berechnet -->')
    % Frechet 
    tic
    [~, ~, frechet_distances, ~, ~, frechet_soll, frechet_ist] = fkt_discreteFrechet(data_all_soll,data_ist_trafo,false);
    toc
    disp('DFD berechnet -->')
    % LCSS
    tic
    [~, ~, lcss_distances, ~, ~, lcss_soll, lcss_ist, ~, ~] = fkt_lcss(data_all_soll,data_ist_trafo,false);
    toc
    disp('LCSS berechnet -->')

    [seg_euclidean_info, seg_euclidean_distances] = metric2postgresql('euclidean', euclidean_distances, data_all_soll, euclidean_ist, bahn_id_,bahn_id_);
    [seg_sidtw_info, seg_sidtw_distances] = metric2postgresql('sidtw', sidtw_distances, sidtw_soll, sidtw_ist, bahn_id_,bahn_id_);
    [seg_dtw_info, seg_dtw_distances] = metric2postgresql('dtw', dtw_distances, dtw_soll, dtw_ist, bahn_id_,bahn_id_);
    [seg_dfd_info, seg_dfd_distances] = metric2postgresql('dfd', frechet_distances, frechet_soll, frechet_ist, bahn_id_,bahn_id_);
    [seg_lcss_info, seg_lcss_distances] = metric2postgresql('lcss', lcss_distances, lcss_soll, lcss_ist, bahn_id_,bahn_id_);

    % Info Tabellen hinzufügen
    table_euclidean_info = [seg_euclidean_info; table_euclidean_info];
    table_sidtw_info = [seg_sidtw_info; table_sidtw_info];
    table_dtw_info = [seg_dtw_info; table_dtw_info];
    table_dfd_info = [seg_dfd_info; table_dfd_info];
    table_lcss_info = [seg_lcss_info; table_lcss_info];

    % Deviation Tabellen der Gesamtmessung hinzufügen
    seg_sidtw_distances = [seg_sidtw_distances, table((1:1:size(seg_sidtw_distances,1))','VariableNames',{'points_order'})];
    table_sidtw_deviation = [{seg_sidtw_distances}; table_sidtw_deviation];

    seg_dtw_distances = [seg_dtw_distances, table((1:1:size(seg_dtw_distances,1))','VariableNames',{'points_order'})];
    table_dtw_deviation = [{seg_dtw_distances}; table_dtw_deviation];

    seg_dfd_distances = [seg_dfd_distances, table((1:1:size(seg_dfd_distances,1))','VariableNames',{'points_order'})];
    table_dfd_deviation = [{seg_dfd_distances}; table_dfd_deviation];

    seg_euclidean_distances = [seg_euclidean_distances, table((1:1:size(seg_euclidean_distances,1))','VariableNames',{'points_order'})];
    table_euclidean_deviation = [{seg_euclidean_distances}; table_euclidean_deviation];

    seg_lcss_distances = [seg_lcss_distances, table((1:1:size(seg_lcss_distances,1))','VariableNames',{'points_order'})];
    table_lcss_deviation = [{seg_lcss_distances}; table_lcss_deviation];


%%%%%%%%%% Für die Auswertung in Matlab (für Datenbank irrelevant)
    % Anpassung der Spaltennamen für jede Tabelle
    seg_euclidean_info.Properties.VariableNames = {'bahn_id','segment_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    seg_sidtw_info.Properties.VariableNames = {'bahn_id','segment_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    seg_dtw_info.Properties.VariableNames = {'bahn_id','segment_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    seg_dfd_info.Properties.VariableNames = {'bahn_id','segment_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    seg_lcss_info.Properties.VariableNames = {'bahn_id','segment_id','min_distances', 'max_distance', 'average_distance', 'standard_deviation'};
    
    table_all_info_2 = [seg_euclidean_info(1,:); seg_sidtw_info(1,:); seg_dtw_info(1,:); seg_dfd_info(1,:); seg_lcss_info(1,:)];

    table_all_info_2.metrik = {'euclidean'; 'sidtw'; 'dtw'; 'dfd'; 'lcss'};

    % Hinzufügen der calibration_id wenn diese existiert
    if exist('calibration_id', 'var') == 1
        calibration_ids = repelem(calibration_id, height(table_all_info_2),1);
        table_all_info_2.calibration_id = calibration_ids;
        table_all_info_2 = table_all_info_2(:,[{'bahn_id'},{'calibration_id'},{'min_distances'},{'max_distance'},{'average_distance'},{'metrik'}]);
        clear calibration_ids
    end
%%%%%%%%%%
    clear sidtw_distances sidtw_ist sidtw_soll seg_sidtw_info seg_sidtw_distances
    clear dtw_distances dtw_ist dtw_soll seg_dtw_info seg_dtw_distances
    clear frechet_distances frechet_ist frechet_soll frechet_path frechet_matrix frechet_dist frechet_av seg_dfd_info seg_dfd_distances
    clear lcss_distances lcss_ist lcss_soll seg_lcss_info seg_lcss_distances
    clear euclidean_distances euclidean_ist seg_euclidean_info seg_euclidean_distances
    % clear data_ist_trafo

end

%% Plotten
if plots == true
    % Farben
    c1 = [0 0.4470 0.7410];
    c2 = [0.8500 0.3250 0.0980];
    c3 = [0.9290 0.6940 0.1250];
    c4 = [0.4940 0.1840 0.5560];
    c5 = [0.4660 0.6740 0.1880];
    c6 = [0.3010 0.7450 0.9330];
    c7 = [0.6350 0.0780 0.1840];
end

if plots == true && evaluate_velocity == false && evaluate_orientation == false
    
    ist = table2array(data_ist(:,5:7));
    soll = table2array(data_soll(:,5:7));
    
    % Koordinatentrafo für alle Daten 
    data_ist_trafo = coord_transformation(ist,trafo_rot, trafo_trans)
    ist = data_ist_trafo; 
    clear data_ist_trafo
    
    % Plot der Gesamten Bahn
    f0 = figure('Color','white','Name','Soll und Istbahn (gesamte Messung)');
    f0.Position(3:4) = [1520 840];
    hold on 
    plot3(soll(:,1),soll(:,2),soll(:,3),Color=c1,LineWidth=1.5)
    plot3(ist(:,1),ist(:,2),ist(:,3),Color=c2,LineWidth=1.5)
    xlabel('x','FontWeight','bold');
    ylabel('y','FontWeight','bold');
    zlabel('z','FontWeight','bold','Rotation',0);
    legend('Sollbahn (ABB)','Istbahn (VICON)')
    grid on 
    view(3)

    % Plotten der ausgewählten Segmente und deren Abweichungen 
    if evaluate_segmentwise == true 
    
        f1 = figure('Color','white','Name','Soll- und Istbahnen (Bahnsegmente)');
        f1.Position(3:4) = [1520 840];
        hold on
        if segment_last-segment_first == 0
            plot3(segments_trafo.x_ist{segment_first+1,1},segments_trafo.y_ist{segment_first+1,1},segments_trafo.z_ist{segment_first+1,1},Color=c1,LineWidth=1.5)
            plot3(segments_soll.x_soll{segment_first+1,1},segments_soll.y_soll{segment_first+1,1},segments_soll.z_soll{segment_first+1,1},Color=c2,LineWidth=1.5)
        else
            for i = segment_first:1:segment_last-segment_first
                plot3(segments_trafo.x_ist{i+1,1},segments_trafo.y_ist{i+1,1},segments_trafo.z_ist{i+1,1},Color=c1,LineWidth=1.5)
                plot3(segments_soll.x_soll{i+1,1},segments_soll.y_soll{i+1,1},segments_soll.z_soll{i+1,1},Color=c2,LineWidth=1.5)
            end
        end
        title("Bahnabschnitte " + num2str(segment_first) + " bis " + num2str(segment_last))
        xlabel('x','FontWeight','bold'); ylabel('y','FontWeight','bold'); zlabel('z','FontWeight','bold','Rotation',0);
        legend('Sollbahn (ABB)','Istbahn (VICON)')
        grid on 
        view(3)
        
        f2 = figure('Color','white','Name','Mittlere Abweichungen (Bahnsegmente)');
        f2.Position(3:4) = [1520 840];
        subplot(2,2,1)
        title('Mittlere Abweichungen zwischen Soll- und Istbahn')
        hold on 
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_dtw_info.dtw_average_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c1)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_dfd_info.dfd_average_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c2)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_lcss_info.lcss_average_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c3)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_sidtw_info.sidtw_average_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c4)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_euclidean_info.euclidean_average_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c5)
        % Plot der Werte der gesamten Bahn
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.average_distance(3,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c1)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.average_distance(4,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c2)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.average_distance(5,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c3)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.average_distance(2,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c4)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.average_distance(1,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c5)
        xlabel('Bahnsegmente');
        ylabel('Abweichung in mm');
        legend('DTW','DFD','LCSS','SIDTW','Eukl. Dist.')
        grid on
        axis padded
        
        subplot(2,2,2)
        title('Maximale Abweichungen zwischen Soll- und Istbahn')
        hold on 
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_dtw_info.dtw_max_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c1)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_dfd_info.dfd_max_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c2)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_lcss_info.lcss_max_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c3)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_sidtw_info.sidtw_max_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c4)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_euclidean_info.euclidean_max_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c5)
        % Plot der Werte der gesamten Bahn
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.max_distance(3,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c1)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.max_distance(4,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c2)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.max_distance(5,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c3)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.max_distance(2,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c4)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.max_distance(1,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c5)
        xlabel('Bahnsegmente');
        ylabel('Abweichung in mm');
        legend('DTW','DFD','LCSS','SIDTW','Eukl. Dist.')
        grid on
        axis padded
        
        subplot(2,2,3)
        title('Minimale Abweichungen zwischen Soll- und Istbahn')
        hold on 
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_dtw_info.dtw_min_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c1)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_dfd_info.dfd_min_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c2)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_lcss_info.lcss_min_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c3)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_sidtw_info.sidtw_min_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c4)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_euclidean_info.euclidean_min_distance(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c5)
        % Plot der Werte der gesamten Bahn
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.min_distance(3,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c1)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.min_distance(4,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c2)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.min_distance(5,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c3)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.min_distance(2,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c4)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.min_distance(1,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c5)
        xlabel('Bahnsegmente');
        ylabel('Abweichung in mm');
        legend('DTW','DFD','LCSS','SIDTW','Eukl. Dist.')
        grid on
        axis padded
        
        subplot(2,2,4)
        title('Standardabweichungen zwischen Soll- und Istbahn')
        hold on 
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_dtw_info.dtw_standard_deviation(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c1)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_dfd_info.dfd_standard_deviation(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c2)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_lcss_info.lcss_standard_deviation(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c3)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_sidtw_info.sidtw_standard_deviation(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c4)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),table_euclidean_info.euclidean_standard_deviation(segment_first+1:segment_last+1,:),LineWidth=2.5,Color=c5)
        % Plot der Werte der gesamten Bahn
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.standard_deviation(3,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c1)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.standard_deviation(4,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c2)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.standard_deviation(5,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c3)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.standard_deviation(2,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c4)
        plot(linspace(segment_first,segment_last,segment_last-segment_first+1),repelem(table_all_info.standard_deviation(1,:),segment_last-segment_first+1,1),LineWidth=1.2,Color=c5)
        xlabel('Bahnsegmente');
        ylabel('Abweichung in mm');
        legend('DTW','DFD','LCSS','SIDTW','Eukl. Dist.')
        grid on
        axis padded   
    end
end

% Plotten der Euler-Winkel von Soll- und Ist-Bahn
if plots == true && evaluate_orientation == true && evaluate_velocity == false

    % Timestamps in Sekunden
    time_ist = str2double(data_ist.timestamp);
    time_soll = str2double(data_soll.timestamp);
    timestamps_ist = (time_ist(:,1)- time_soll(1,1))/1e9;
    timestamps_soll = (time_soll(:,1)- time_soll(1,1))/1e9;
    

    % Transformation aller Winkel 
    euler_transformation(euler_ist,euler_soll, trafo_euler, trafo_rot)
    % Winkel zwischen 0 - 360°
    % euler_soll = mod(euler_soll,360);
    % euler_trans = mod(euler_trans,360);
    euler_soll = abs(euler_soll);
    euler_trans = abs(euler_trans);

    % Plot 
    figure('Color','white','Name','Eulerwinkel von 0° bis 360°')
    hold on 
    plot(timestamps_soll,euler_soll(:,1),Color=c1,LineWidth=1.5)
    plot(timestamps_soll,euler_soll(:,2),Color=c2,LineWidth=1.5)
    plot(timestamps_soll,euler_soll(:,3),Color=c4,LineWidth=1.5)
    plot(timestamps_ist,euler_trans(:,1),Color=c1)
    plot(timestamps_ist,euler_trans(:,2),Color=c2)
    plot(timestamps_ist,euler_trans(:,3),Color=c4)
    xlabel('Zeit [s]'); ylabel('Winkel [°]');
    legend("roll","pitch","yaw")
    hold off

    % % Plot 
    % figure('Color','white','Name','Mit Originalzeit')
    % hold on 
    % plot(str2double(data_soll.timestamp),euler_soll(:,1),Color=c1,LineWidth=1.5)
    % plot(str2double(data_soll.timestamp),euler_soll(:,2),Color=c2,LineWidth=1.5)
    % plot(str2double(data_soll.timestamp),euler_soll(:,3),Color=c4,LineWidth=1.5)
    % plot(str2double(data_ist.timestamp),euler_trans(:,1),Color=c1)
    % plot(str2double(data_ist.timestamp),euler_trans(:,2),Color=c2)
    % plot(str2double(data_ist.timestamp),euler_trans(:,3),Color=c4)
    % xlabel('Zeit [s]'); ylabel('Winkel [°]');
    % legend("roll","pitch","yaw")
    % hold off

    % Segmentweise plotten
    k1 = 1;
    k2 = 1; 
    figure('Color','white','Name','Eulerwinkel aller Segmente (-180° bis 180°)')
    hold on
    for i = 1:1:num_segments
        plot(timestamps_soll(k1:k1+length(segments_soll.roll_soll{i})-1),segments_soll.roll_soll{i},Color=c1,LineWidth=1.5)
        plot(timestamps_soll(k1:k1+length(segments_soll.roll_soll{i})-1),segments_soll.pitch_soll{i},Color=c2,LineWidth=1.5)
        plot(timestamps_soll(k1:k1+length(segments_soll.roll_soll{i})-1),segments_soll.yaw_soll{i},Color=c4,LineWidth=1.5)
        plot(timestamps_ist(k2:k2+length(segments_trafo.roll_ist{i})-1),segments_trafo.roll_ist{i},Color=c1)
        plot(timestamps_ist(k2:k2+length(segments_trafo.roll_ist{i})-1),segments_trafo.pitch_ist{i},Color=c2)
        plot(timestamps_ist(k2:k2+length(segments_trafo.roll_ist{i})-1),segments_trafo.yaw_ist{i},Color=c4)
        k1 = k1 + length(segments_soll.roll_soll{i});
        k2 = k2 + length(segments_trafo.roll_ist{i});
    end
    xlabel('Zeit [s]'); ylabel('Winkel [°]');
    legend("roll","pitch","yaw")
    hold off

    % 3D - Plot    
    figure('Color','white','Name','Eulerwinkel 3D')
    hold on
    plot3(euler_soll(:,1),euler_soll(:,2),euler_soll(:,3),Color=c1,LineWidth=1.5);
    plot3(euler_trans(:,1),euler_trans(:,2),euler_trans(:,3),Color=c2,LineWidth=1.5);
    legend('Soll','Ist')
    xlabel('Roll'); ylabel('Pitch'); zlabel('Yaw')
    view(3)
    hold off
    axis equal
end

clear c1 c2 c3 c4 c5 c6 c7 segment_first segment_last n i f0 f1 f2 k1 k2 time

% Bestimme den Evaluationstyp basierend auf den Funktionsparametern
if evaluate_velocity == false && evaluate_orientation == false
    evaluation_type = 'position';
elseif evaluate_velocity == false && evaluate_orientation == true
    evaluation_type = 'orientation';
elseif evaluate_velocity == true && evaluate_orientation == false
    evaluation_type = 'speed';
end

% Füge die evaluation-Spalte zu allen Info-Tabellen hinzu
if ~isempty(table_euclidean_info)
    table_euclidean_info = addvars(table_euclidean_info, repelem({evaluation_type}, height(table_euclidean_info), 1), 'NewVariableNames', 'evaluation');
end

if ~isempty(table_sidtw_info)
    table_sidtw_info = addvars(table_sidtw_info, repelem({evaluation_type}, height(table_sidtw_info), 1), 'NewVariableNames', 'evaluation');
end

if ~isempty(table_dtw_info)
    table_dtw_info = addvars(table_dtw_info, repelem({evaluation_type}, height(table_dtw_info), 1), 'NewVariableNames', 'evaluation');
end

if ~isempty(table_dfd_info)
    table_dfd_info = addvars(table_dfd_info, repelem({evaluation_type}, height(table_dfd_info), 1), 'NewVariableNames', 'evaluation');
end

if ~isempty(table_lcss_info)
    table_lcss_info = addvars(table_lcss_info, repelem({evaluation_type}, height(table_lcss_info), 1), 'NewVariableNames', 'evaluation');
end

end

function euler_fixed = fixGimbalLock(euler_angles)
    euler_fixed = euler_angles;
    
    for i = 1:3  % Check each angle component
        angle_data = euler_angles(:,i);
        
        % Check if we have values close to ±180
        near_180 = abs(abs(angle_data) - 180) < 5;
        
        if any(near_180)
            % If we have values near 180, fix sign flips
            mask_neg = angle_data < 0;
            angle_data(mask_neg) = angle_data(mask_neg) + 360;
            euler_fixed(:,i) = angle_data;
        end
    end
end
