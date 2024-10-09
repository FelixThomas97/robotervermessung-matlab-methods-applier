% Generiere Struktur der Solldaten für die Datenbankeintragung 
function datasoll_vicon(trajectory_soll, defined_velocity, interpolate)
    
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
        % tcp_velocity_soll = defined_velocity;
        % joint_state_soll = 0;        
        % events_soll = 0;

    else
    % Für gemessene Sollbahnen (ABB) 
        
        % Extrahiere die Daten aus Array
        timestamp_soll = trajectory_soll(:, 1);
        x_soll = trajectory_soll(:, 2)/1000;
        y_soll = trajectory_soll(:, 3)/1000;
        z_soll = trajectory_soll(:, 4)/1000;
        q_soll = trajectory_soll(:, 5:8);
        tcp_velocity_soll = trajectory_soll(:, 9);
        joint_state_soll = trajectory_soll(:, 10:15);
        events_soll = trajectory_soll(:,16:18);
        
    end       

    %% Struktur für Datenbank erstellen - Websocket
    data_soll = struct();
    data_soll.timestamp_soll = timestamp_soll;
    data_soll.x_soll = x_soll;
    data_soll.y_soll = y_soll;
    data_soll.z_soll = z_soll;
    data_soll.qx_soll = q_soll(:,1);
    data_soll.qy_soll = q_soll(:,2);
    data_soll.qz_soll = q_soll(:,3);
    data_soll.qw_soll = q_soll(:,4);
    if interpolate == false
        data_soll.tcp_velocity_soll = tcp_velocity_soll;
        data_soll.joint_state_soll = joint_state_soll;
        data_soll.events_soll = events_soll;   
    end


    %% Laden in Workspace
    assignin("base","data_soll_part",data_soll)
end