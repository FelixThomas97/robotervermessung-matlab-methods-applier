% Generiere Struktur der Istdaten für die Datenbankeintragung 
function new_dataist_vicon(trajectory_ist,trajectory_header_id,segment_id)

    % Extrahiere die Daten aus Array
    timestamp_ist = trajectory_ist(:, 1);
    x_ist = trajectory_ist(:, 2);
    y_ist = trajectory_ist(:, 3);
    z_ist = trajectory_ist(:, 4);
    q_ist = trajectory_ist(:, 5:8);
    tcp_velocity_ist = trajectory_ist(:, 12);
    tcp_acceleration_ist = trajectory_ist(:, 20); 

    % Header ID nur hochzählen wenn mehrere Bahnen existieren !
    if nargin < 3
    % Header ID generieren
        trajectory_header_id = trajectory_header_id;
        segment_id = trajectory_header_id;
    else
        trajectory_header_id = trajectory_header_id;
        % Eigene ID der Bahnabschnitte
        segment_id = segment_id;
    end

 
%% Struktur für Datenbank erstellen - Vicon / Websocket
    data_ist = struct();
    data_ist.trajectory_header_id = trajectory_header_id;
    data_ist.segment_id = segment_id;
    data_ist.timestamp_ist = timestamp_ist;
    data_ist.x_ist = x_ist/1000;  
    data_ist.y_ist = y_ist/1000;
    data_ist.z_ist = z_ist/1000;
    data_ist.tcp_velocity_ist = tcp_velocity_ist;
    data_ist.tcp_acceleration = tcp_acceleration_ist;
    data_ist.qx_ist = q_ist(:, 1);
    data_ist.qy_ist = q_ist(:, 2);
    data_ist.qz_ist = q_ist(:, 3);
    data_ist.qw_ist = q_ist(:, 4);

    %% Laden in Workspace
    % assignin('base', 'trajectory_header_id', trajectory_header_id)
    assignin('base', 'data_ist_part', data_ist);
end