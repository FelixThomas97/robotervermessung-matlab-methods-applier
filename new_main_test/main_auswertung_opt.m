clear; tic
%% Eingaben
% Falls spezifische Bahn-ID ausgewertet werden soll
bahn_id = '';
% Falls Daten aus einem bestimmten Zeitraum ausgewertet werden sollen
record_date = '12.02.2025'; % Format: dd.mm.yyyy
% record_date = '02.07.2024';

% Falls mehrere Daten ausgewertet werden sollen
loop_record_date = true; 
loop_all = true;
% Falls Daten gelöscht und überschrieben werden sollen
overwrite = false;

% Berechnung der Metriken für die Geschwindikeitsabweichungen
evaluate_velocity = 0;
% Berechnung der Metriken für die Orientierungsabweichungen
evaluate_orientation = 0;

% ! ! ! Falls keine Eingabe erfolgt, wird die Position ausgewertet

% Daten hochladen
%%%%
upload = true;
%%%%
upload_info = true;        % Info-Tabellen hochladen
upload_deviations = true;  % Abweichungs-Tabellen hochladen

% Plotten 
plots = false; 

% Verbindung mit der Datenbank
conn = connectingToPostgres;

% Überprüfung ob das Datum korrekt eingeben wurde wenn keine Bahn-Id vorliegt
if isempty(bahn_id)
    try
        dt = datetime(record_date, 'InputFormat', 'dd.MM.yyyy');
        isValid = true;
    catch
        isValid = false;
    end
    if  isValid
        record_date = datetime(record_date, 'InputFormat', 'dd.MM.yyyy');
        record_date = datestr(record_date, 'yyyymmdd');
    else
        error('record_date hat nicht das richtige Format.');    
    end
end
clear isValid dt

%% Wenn loop aktiv
if loop_all || loop_record_date

    % Prüft anhand der mit SIDTW ausgewerteten Daten welche Bahnen bereits ausgewertet wurden
    [bahn_ids_all, bahn_ids_evaluated] = getBahnIds(conn,evaluate_orientation,evaluate_velocity);
    
    % Wenn Daten eines bestimmten Datums ausgewertet werden sollen
    if loop_record_date
        % Info Tabellen des relevanten Tages extrahieren
        query = sprintf('SELECT * FROM robotervermessung.bewegungsdaten.bahn_info');
        all_info = fetch(conn,query);
        % Datum aus dem String extrahieren
        all_dates = extractBetween(all_info.record_filename, "record_", "_");
        bahn_info = all_info(all_dates == record_date, :);
        bahn_ids_all = double(bahn_info.bahn_id);
        bahn_ids_all_str = bahn_info.bahn_id;
    end

    % Wenn Daten überschrieben werden sollen, werden die bereits ausgewerteten Daten auf 0 gesetzt
    if overwrite
        bahn_ids_evaluated = zeros(1);
    end
    
    % Collection aus der die Daten extrahiert werden
    schema = 'bewegungsdaten';

    clear all_dates all_info bahn_info 

    % Schleife
    % for j = 1:1:height(bahn_ids)
    for j = 1:1:1

        bahn_id = convertStringsToChars(string(bahn_ids_all(j)));

        % Wird ausgeführt falls die Bahn noch nicht ausgewertet wurde oder überschrieben werden soll
        if ~ismember(bahn_ids_all(j),bahn_ids_evaluated)

            disp('Datei: '+string(j)+' Auswertung der Datei: ' + string(bahn_id))

            % Suche nach passender Kalibrierungsdatei
            [calibration_id, is_calibration_run] = findCalibrationRun(conn, bahn_id, schema);

            % Extraktion der Soll- und Ist-Daten der Kalibrierungsdatei
            tablename_cal = ['robotervermessung.' schema '.bahn_pose_ist'];
            query = sprintf("SELECT * FROM %s WHERE bahn_id = '%s'", tablename_cal, calibration_id);
            data_cal_ist = fetch(conn, query);
            data_cal_ist = sortrows(data_cal_ist,'timestamp');

            tablename_cal = ['robotervermessung.' schema '.bahn_events'];
            query = sprintf("SELECT * FROM %s WHERE bahn_id = '%s'", tablename_cal, calibration_id);
            data_cal_soll = fetch(conn, query);
            data_cal_soll = sortrows(data_cal_soll,'timestamp');

            % Positionsdaten für Koordinatentransformation
            calibration(data_cal_ist,data_cal_soll, plots)

            % Bei Auswertung der Orientierung wird zusätzlich eine andere Collection benötigt
            if evaluate_orientation
                tablename_cal = ['robotervermessung.' schema '.bahn_orientation_soll'];
                query = sprintf("SELECT * FROM %s WHERE bahn_id = '%s'", tablename_cal, calibration_id);
                data_cal_soll = fetch(conn, query);
                data_cal_soll = sortrows(data_cal_soll,'timestamp');
                
                % Transformation der Quaternionen/Eulerwinkel
                calibrateQuaternion(data_cal_ist, data_cal_soll);
            end

            clear tablename_cal data_cal_ist data_cal_soll

            if evaluate_orientation 
                getSegments(conn, bahn_id, schema, evaluate_orientation, evaluate_velocity, trafo_rot, trafo_trans, q_transform)
            else
                q_transform = 0;
                getSegments(conn, bahn_id, schema, evaluate_orientation, evaluate_velocity, trafo_rot, trafo_trans, q_transform)
            end

        else
            disp('Datei: '+string(j)+" mit der Bahn-ID "+ string(bahn_id+ " lag bereits vor!"))
        end
    end
end

%%

toc 