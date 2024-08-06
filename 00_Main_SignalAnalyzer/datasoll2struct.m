% Generiere Struktur der Solldaten für die Datenbankeintragung 
function datasoll2struct(trajectory_soll, defined_velocity, interpolate)
    
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
        events_soll = [];

    else
    % Für gemessene Sollbahnen
        
        % Extrahiere die Daten aus Array
        timestamp_soll = trajectory_soll(:, 1);
        x_soll = trajectory_soll(:, 2)/1000;
        y_soll = trajectory_soll(:, 3)/1000;
        z_soll = trajectory_soll(:, 4)/1000;
        tcp_velocity_soll = trajectory_soll(:, 5);
        % tcp_acceleration_soll = trajectory_soll(:, 6);  %%%
        % cpu_temperature_soll = trajectory_soll(:, 7);
        joint_state_soll = trajectory_soll(:, 8:13);
        q_soll = trajectory_soll(:, 14:17);
        events_soll = trajectory_soll(:,18);
        
    end

    %% Struktur für Datenbank erstellen - Steuerung (40Hz)
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
    data_soll.events_soll = events_soll;        


    %% Laden in Workspace
    assignin("base","data_soll_part",data_soll)
end