function transform_tool_orientation(data_ist, data_soll)
    % Funktion zur Analyse und Visualisierung der Tool-Orientierungen
    % Input:
    % data_ist - Ist-Daten des ersten Tools
    % data_soll - Soll-Daten des zweiten Tools
    
    % Quaternionen extrahieren (xyzw Format)
    q_ist = table2array(data_ist(:,8:11));  % Annahme: Spalten 8-11 enthalten Quaternionen
    q_soll = table2array(data_soll(:,5:8)); % Annahme: Spalten 5-8 enthalten Quaternionen
    
    % Konvertiere zu Euler (ZYX Konvention)
    % Quaternion Format ist xyzw, also brauchen wir [w x y z]
    q_ist_wxyz = [q_ist(:,4), q_ist(:,1), q_ist(:,2), q_ist(:,3)];
    q_soll_wxyz = [q_soll(:,4), q_soll(:,1), q_soll(:,2), q_soll(:,3)];
    
    % Umwandlung in Euler-Winkel
    euler_ist = rad2deg(quat2eul(q_ist_wxyz, "ZYX"));
    euler_soll = rad2deg(quat2eul(q_soll_wxyz, "ZYX"));

    % Original Plot
    plotOrientations(euler_ist, euler_soll, data_ist, data_soll, 'Original Orientierung');
    
    % Teste verschiedene Rotationen der Ist-Werte
    % Y-Rotation (90°)
    euler_ist_90y = euler_ist;
    euler_ist_90y(:,2) = euler_ist(:,1) + 90;  % Y um 90° drehen
    plotOrientations(euler_ist_90y, euler_soll, data_ist, data_soll, 'Y-Rotation 90°');
    
    % Y-Rotation (180°)
    euler_ist_180y = euler_ist;
    euler_ist_180y(:,2) = euler_ist(:,1) + 180;  % Y um 180° drehen
    plotOrientations(euler_ist_180y, euler_soll, data_ist, data_soll, 'Y-Rotation 180°');
    
    % Y-Rotation (-90°)
    euler_ist_minus90y = euler_ist;
    euler_ist_minus90y(:,2) = euler_ist(:,1) - 90;  % Y um -90° drehen
    plotOrientations(euler_ist_minus90y, euler_soll, data_ist, data_soll, 'Y-Rotation -90°');
end

function plotOrientations(euler_ist, euler_soll, data_ist, data_soll, plot_title)
    % Mittelwerte der Euler-Winkel berechnen
    euler_ist_mean = mean(euler_ist, 1);
    euler_soll_mean = mean(euler_soll, 1);
    
    % Differenzen der Euler-Winkel
    euler_diff = euler_soll_mean - euler_ist_mean;
    
    % Ausgabe der Winkel und Differenzen
    fprintf('\n%s:\n', plot_title);
    fprintf('Ist-Winkel (ZYX): [%.2f, %.2f, %.2f]\n', euler_ist_mean);
    fprintf('Soll-Winkel (ZYX): [%.2f, %.2f, %.2f]\n', euler_soll_mean);
    fprintf('Differenz (ZYX): [%.2f, %.2f, %.2f]\n', euler_diff);
    
    % Timestamps für x-Achse
    time_ist = str2double(data_ist.timestamp);
    time_soll = str2double(data_soll.timestamp);
    timestamps_ist = (time_ist(:,1)- time_soll(1,1))/1e9;
    timestamps_soll = (time_soll(:,1)- time_soll(1,1))/1e9;
    
    % Plot der Winkel
    figure('Name', plot_title, 'Color', 'white');
    
    % Farben definieren
    colors = {[0 0.4470 0.7410],    % Blau
              [0.8500 0.3250 0.0980],% Orange
              [0.9290 0.6940 0.1250]};% Gelb
              
    % Subplots für jeden Winkel
    winkel_namen = {'Roll (Z)', 'Pitch (Y)', 'Yaw (X)'};
    
    for i = 1:3
        subplot(3,1,i)
        hold on
        % Plot Soll
        plot(timestamps_soll, euler_soll(:,i), 'Color', colors{i}, 'LineWidth', 1.5)
        % Plot Ist
        plot(timestamps_ist, euler_ist(:,i), '--', 'Color', colors{i}, 'LineWidth', 1.5)
        
        grid on
        title(winkel_namen{i})
        ylabel('Winkel [°]')
        if i == 3  % Nur beim untersten Plot
            xlabel('Zeit [s]')
        end
        legend('Soll', 'Ist', 'Location', 'best')
        hold off
    end
end