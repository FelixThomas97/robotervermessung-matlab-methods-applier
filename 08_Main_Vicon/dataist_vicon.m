% Generiere Struktur der Istdaten für die Datenbankeintragung 
function dataist_vicon(trajectory_ist,trajectory_header_id_base,i)

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
        trajectory_header_id = trajectory_header_id_base;
    else
        trajectory_header_id = trajectory_header_id_base + num2str(i);
    end

    %% Struktur für Datenbank erstellen - Steuerung
    % data_ist = struct();
    % data_ist.trajectory_header_id = trajectory_header_id;
    % data_ist.timestamp_ist = timestamp_ist;
    % data_ist.x_ist = x_ist/1000;  
    % data_ist.y_ist = y_ist/1000;
    % data_ist.z_ist = z_ist/1000;
    % data_ist.tcp_velocity_ist = tcp_velocity_ist;
    % data_ist.tcp_acceleration = tcp_acceleration_ist;
    % data_ist.cpu_temperature = cpu_temperature_ist;
    % data_ist.q1_ist = q_ist(:, 1);
    % data_ist.q2_ist = q_ist(:, 2);
    % data_ist.q3_ist = q_ist(:, 3);
    % data_ist.q4_ist = q_ist(:, 4);
    % data_ist.joint_states_ist = joint_states_ist; 
    % data_ist.events_ist = events_ist;
 
%% Struktur für Datenbank erstellen - Vicon / Websocket
    data_ist = struct();
    data_ist.trajectory_header_id = trajectory_header_id;
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
    assignin('base', 'trajectory_header_id', trajectory_header_id)
    assignin('base', 'data_ist_part', data_ist);
end