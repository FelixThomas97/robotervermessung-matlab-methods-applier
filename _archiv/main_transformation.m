% Upload der in Position und Orientierung transformierten Daten

%% Einstellungen

clear;

bahn_id_ ='1721047931'; % Orientierungsänderung ohne Kalibrierungsdatei

% Plotten der Daten 
plots = true;

% Upload in die Datenbank
upload_all = false;
upload_single = false;
is_pick_and_place = false;  % NEU: Flag für Pick-and-Place Aufgaben

% Verbindung mit PostgreSQL
datasource = "RobotervermessungMATLAB";
username = "felixthomas";
password = "manager";
conn = postgresql(datasource,username,password);

% Überprüfe Verbindung
if isopen(conn)
    disp('Verbindung erfolgreich hergestellt');
else
    disp('Verbindung fehlgeschlagen');
end

clear datasource username password


%% Alle Bahn-Id's erhalten 

tic;

query = 'SELECT bahn_id FROM robotervermessung.bewegungsdaten.bahn_info';
bahn_ids = fetch(conn, query);
bahn_ids = str2double(table2array(bahn_ids));
query = 'SELECT DISTINCT bahn_id FROM robotervermessung.bewegungsdaten.bahn_pose_trans';
existing_bahn_ids = fetch(conn, query);
existing_bahn_ids = str2double(table2array(existing_bahn_ids));

%% SUCHE NACH KALIBRIERUNGSDATEI

% Prüfe ob die Bahn-ID in der Tabelle bereits enthalten ist
if upload_all
    for i = 1:1:height(bahn_ids)

        bahn_id_ = convertStringsToChars(string(bahn_ids(i)));

        if ~ismember(bahn_ids(i),existing_bahn_ids)
            % SQL-Abfrage für Calibration Runs
            query_cal = 'SELECT * FROM robotervermessung.bewegungsdaten.bahn_info WHERE calibration_run = true';
            
            % Abfrage ausführen und Ergebnisse abrufen
            data_cal_info = fetch(conn, query_cal);
            
            % Aktuelles Aufnahmedatum aus bahn_info holen
            query_current = sprintf('SELECT recording_date FROM robotervermessung.bewegungsdaten.bahn_info WHERE bahn_id = ''%s''', bahn_id_);
            current_date_info = fetch(conn, query_current);
            current_datetime = datetime(current_date_info.recording_date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');    
            % Initialisierung der Variablen für die beste Übereinstimmung
            best_time_diff = Inf;
            calibration_id = bahn_id_;  % Default: aktuelle Bahn-ID
            found_calibration = false;
            
            if any(strcmp(data_cal_info.bahn_id, bahn_id_))
                disp('Die aktuelle Bahn ist bereits eine Kalibrierungsbahn!')
            else
                % Durchsuche alle Calibration Runs
                for i = 1:height(data_cal_info)
                    cal_datetime = datetime(data_cal_info.recording_date(i), 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
                    
                    % Prüfe ob gleicher Tag und Calibration Run zeitlich davor liegt
                    if dateshift(cal_datetime, 'start', 'day') == dateshift(current_datetime, 'start', 'day') && ...
                       cal_datetime < current_datetime
                        
                        time_diff = seconds(current_datetime - cal_datetime);
                        
                        % Update beste Übereinstimmung wenn dieser Run näher liegt
                        if time_diff < best_time_diff
                            best_time_diff = time_diff;
                            calibration_id = char(data_cal_info.bahn_id(i));
                            found_calibration = true;
                        end
                    end
                end
            end
        
            % Ausgabe des Ergebnisses
            if found_calibration
                disp('Kalibrierungs-Datei vorhanden! ID der Messaufnahme: ' + string(calibration_id))
            else
                calibration_id = bahn_id_;
                disp('Zu dem ausgewählten Datensatz liegt keine Kalibrierungsdatei vom gleichen Tag vor!')
            end
                    
            % Extrahieren der Kalibrierungs-Daten für die Position
            tablename_cal = 'robotervermessung.bewegungsdaten.bahn_pose_ist';
            opts_cal = databaseImportOptions(conn,tablename_cal);
            opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
            data_cal_ist= sqlread(conn,tablename_cal,opts_cal);
            data_cal_ist = sortrows(data_cal_ist,'timestamp');
            
            tablename_cal = 'robotervermessung.bewegungsdaten.bahn_events';
            opts_cal = databaseImportOptions(conn,tablename_cal);
            opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
            data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
            data_cal_soll = sortrows(data_cal_soll,'timestamp');
            
            % Positionsdaten für Koordinatentransformation
            calibration(data_cal_ist,data_cal_soll)
            
            % Extrahieren der Kalibrierungs-Daten für die Orientierung
            tablename_cal = 'robotervermessung.bewegungsdaten.bahn_orientation_soll';
            opts_cal = databaseImportOptions(conn,tablename_cal);
            opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
            data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
            data_cal_soll = sortrows(data_cal_soll,'timestamp');
            
            % Berechnung der relativen Rotationsmatrix für die Orientierung 
            euler_transformation(data_cal_ist,data_cal_soll)
            
            
            clear data_cal data_cal_info diff_bahn_id min_diff_bahn_id min_idx opts_cal tablename_cal check_bahn_id
            clear query_cal min_diff_idx
            clear data_cal_ist data_cal_soll
            
            
            %% Auslesen der Soll- und Ist-Daten
            
            % Auslesen der gesamten Ist-Daten
            query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_pose_ist ' ...
                    'WHERE robotervermessung.bewegungsdaten.bahn_pose_ist.bahn_id = ''' bahn_id_ ''''];
            data_ist = fetch(conn, query);
            data_ist = sortrows(data_ist,'timestamp');
            
            % Auslesen der gesamten Soll-Daten der Orientierung
            query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_orientation_soll ' ...
                    'WHERE robotervermessung.bewegungsdaten.bahn_orientation_soll.bahn_id = ''' bahn_id_ ''''];
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
            query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_position_soll ' ...
                    'WHERE robotervermessung.bewegungsdaten.bahn_position_soll.bahn_id = ''' bahn_id_ ''''];
            data_position_soll = fetch(conn, query);
            data_position_soll = sortrows(data_position_soll,'timestamp');
            
            position_ist = table2array(data_ist(:,5:7));
            position_soll = table2array(data_position_soll(:,5:7));
            
            clear q_ist q_soll query
            
            %% Berechnung der Transformationen
            
            euler_transformation(euler_ist,euler_soll, trafo_euler,trafo_rot);
            coord_transformation(position_ist,trafo_rot,trafo_trans);
    
            %% Erstellen der Tabelle mit den transfromierten Daten
            
            bahn_pose_trans = table('Size',[size(data_ist,1),10], ...
                'VariableTypes',{'string','string','string','double','double','double','double','double','double','string'}, ...
                'VariableNames',{'bahn_id','segment_id','timestamp','x_trans','y_trans','z_trans','roll_trans','pitch_trans','yaw_trans','calibration_id'});
            
            % bahn_pose_trans.bahn_id = data_ist.bahn_id;
            calibration_ids = repelem(string(calibration_id),height(bahn_pose_trans))';
            bahn_pose_trans{:,:} = [data_ist{:,2:4}, data_ist_trafo, euler_trans,calibration_ids];
            toc;

            tic;
            sqlwrite(conn,'robotervermessung.bewegungsdaten.bahn_pose_trans',bahn_pose_trans)
            disp('Bahn mit der ID '+string(bahn_id_)+' wurde hochgeladen')
            toc;
            
            %% Plots zur Übrüfung
            
            if plots 
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
                plot(timestamps_ist,euler_trans(:,1),Color=c1)
                plot(timestamps_ist,euler_trans(:,2),Color=c2)
                plot(timestamps_ist,euler_trans(:,3),Color=c4)
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
        else
            disp('Datei: '+string(i)+" mit der Bahn-ID "+ string(bahn_id_+ " lag bereits vor!"))
        end
    end
end



%% Suche nach zugehörigem "Calibration Run"

if upload_single && ~ismember(str2double(bahn_id_), existing_bahn_ids)
    % SQL-Abfrage für Calibration Runs
    query_cal = 'SELECT * FROM robotervermessung.bewegungsdaten.bahn_info WHERE calibration_run = true';
    
    % Abfrage ausführen und Ergebnisse abrufen
    data_cal_info = fetch(conn, query_cal);
    
    % Aktuelles Aufnahmedatum aus bahn_info holen
    query_current = sprintf('SELECT recording_date FROM robotervermessung.bewegungsdaten.bahn_info WHERE bahn_id = ''%s''', bahn_id_);
    current_date_info = fetch(conn, query_current);
    current_datetime = datetime(current_date_info.recording_date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');    
    % Initialisierung der Variablen für die beste Übereinstimmung
    best_time_diff = Inf;
    calibration_id = bahn_id_;  % Default: aktuelle Bahn-ID
    found_calibration = false;
    
    if any(strcmp(data_cal_info.bahn_id, bahn_id_))
        disp('Die aktuelle Bahn ist bereits eine Kalibrierungsbahn!')
    else
        % Durchsuche alle Calibration Runs
        for i = 1:height(data_cal_info)
            cal_datetime = datetime(data_cal_info.recording_date(i), 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSSSSS');
            
            % Prüfe ob gleicher Tag und Calibration Run zeitlich davor liegt
            if dateshift(cal_datetime, 'start', 'day') == dateshift(current_datetime, 'start', 'day') && ...
               cal_datetime < current_datetime
                
                time_diff = seconds(current_datetime - cal_datetime);
                
                % Update beste Übereinstimmung wenn dieser Run näher liegt
                if time_diff < best_time_diff
                    best_time_diff = time_diff;
                    calibration_id = char(data_cal_info.bahn_id(i));
                    found_calibration = true;
                end
            end
        end
    end

    % Ausgabe des Ergebnisses
    if found_calibration
        disp('Kalibrierungs-Datei vorhanden! ID der Messaufnahme: ' + string(calibration_id))
    else
        calibration_id = bahn_id_;
        disp('Zu dem ausgewählten Datensatz liegt keine Kalibrierungsdatei vom gleichen Tag vor!')
    end
    
    % Extrahieren der Kalibrierungs-Daten für die Position
    tablename_cal = 'robotervermessung.bewegungsdaten.bahn_pose_ist';
    opts_cal = databaseImportOptions(conn,tablename_cal);
    opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
    data_cal_ist= sqlread(conn,tablename_cal,opts_cal);
    data_cal_ist = sortrows(data_cal_ist,'timestamp');
    
    tablename_cal = 'robotervermessung.bewegungsdaten.bahn_events';
    opts_cal = databaseImportOptions(conn,tablename_cal);
    opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
    data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
    data_cal_soll = sortrows(data_cal_soll,'timestamp');
    
    % Positionsdaten für Koordinatentransformation
    calibration(data_cal_ist,data_cal_soll)
    
    % Extrahieren der Kalibrierungs-Daten für die Orientierung
    tablename_cal = 'robotervermessung.bewegungsdaten.bahn_orientation_soll';
    opts_cal = databaseImportOptions(conn,tablename_cal);
    opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
    data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
    data_cal_soll = sortrows(data_cal_soll,'timestamp');
    
    % Berechnung der relativen Rotationsmatrix für die Orientierung 
    euler_transformation(data_cal_ist,data_cal_soll)
    
    
    clear data_cal data_cal_info diff_bahn_id min_diff_bahn_id min_idx opts_cal tablename_cal check_bahn_id
    clear query_cal min_diff_idx
    clear data_cal_ist data_cal_soll
    
    
    %% Auslesen der Soll- und Ist-Daten
    
    % Auslesen der gesamten Ist-Daten
    query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_pose_ist ' ...
            'WHERE robotervermessung.bewegungsdaten.bahn_pose_ist.bahn_id = ''' bahn_id_ ''''];
    data_ist = fetch(conn, query);
    data_ist = sortrows(data_ist,'timestamp');
    
    % Auslesen der gesamten Soll-Daten der Orientierung
    query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_orientation_soll ' ...
            'WHERE robotervermessung.bewegungsdaten.bahn_orientation_soll.bahn_id = ''' bahn_id_ ''''];
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
    query = ['SELECT * FROM robotervermessung.bewegungsdaten.bahn_position_soll ' ...
            'WHERE robotervermessung.bewegungsdaten.bahn_position_soll.bahn_id = ''' bahn_id_ ''''];
    data_position_soll = fetch(conn, query);
    data_position_soll = sortrows(data_position_soll,'timestamp');
    
    position_ist = table2array(data_ist(:,5:7));
    position_soll = table2array(data_position_soll(:,5:7));
    
    clear q_ist q_soll query
    
    %% Berechnung der Transformationen
    
    euler_transformation(euler_ist,euler_soll, trafo_euler,trafo_rot);
    coord_transformation(position_ist,trafo_rot,trafo_trans);
    
    %% Plots zur Übrüfung
    
    if plots 
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
        plot(timestamps_ist,euler_trans(:,1),Color=c1)
        plot(timestamps_ist,euler_trans(:,2),Color=c2)
        plot(timestamps_ist,euler_trans(:,3),Color=c4)
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
    
    %% Erstellen der Tabelle mit den transfromierten Daten
    
    bahn_pose_trans = table('Size',[size(data_ist,1),10], ...
        'VariableTypes',{'string','string','string','double','double','double','double','double','double','string'}, ...
        'VariableNames',{'bahn_id','segment_id','timestamp','x_trans','y_trans','z_trans','roll_trans','pitch_trans','yaw_trans','calibration_id'});
    
    % bahn_pose_trans.bahn_id = data_ist.bahn_id;
    calibration_ids = repelem(string(calibration_id),height(bahn_pose_trans))';
    bahn_pose_trans{:,:} = [data_ist{:,2:4}, data_ist_trafo, euler_trans,calibration_ids];
    
    sqlwrite(conn,'robotervermessung.bewegungsdaten.bahn_pose_trans',bahn_pose_trans)
    disp('Einzelne Bahn mit der ID '+string(bahn_id_)+' wurde hochgeladen')
elseif upload_single == true && ismember(str2double(bahn_id_), existing_bahn_ids)
    disp("Datei mit der Bahn-ID "+ string(bahn_id_+ " lag bereits vor!"))
end
toc;
