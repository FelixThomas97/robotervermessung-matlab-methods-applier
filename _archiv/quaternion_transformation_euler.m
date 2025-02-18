function [quat_trans, q_transform] = quaternion_transformation_euler(varargin)
    % QUATERNION_TRANSFORMATION_OPT Transformiert Orientierungsdaten zwischen Koordinatensystemen
    % mit Berücksichtigung von Gimbal Lock und kontinuierlicher Winkelkonversion
    
    % Eingabeparameter verarbeiten
    data_ist = varargin{1};
    
    % Modus 1: Kalibrierungsmodus (zwei Eingaben)
    if nargin == 2
        data_soll = varargin{2};
        
        % Quaternionen aus den Datentabellen extrahieren
        q_soll = table2array(data_soll(:,5:8));
        q_soll = [q_soll(:,4), q_soll(:,3), q_soll(:,2), q_soll(:,1)]; % [w x y z]
        
        q_ist = table2array(data_ist(:,8:11));
        q_ist = [q_ist(:,4), q_ist(:,3), q_ist(:,2), q_ist(:,1)]; % [w x y z]
        
        % Quaternionen normalisieren
        q_ist_norm = q_ist ./ sqrt(sum(q_ist.^2, 2));
        q_soll_norm = q_soll ./ sqrt(sum(q_soll.^2, 2));
        
        % Mittlere Quaternionen berechnen
        q_ist_mean = calculateMeanQuaternion(q_ist_norm);
        q_soll_mean = calculateMeanQuaternion(q_soll_norm);
        
        % Transformationsquaternion berechnen
        q_transform = quatmultiply(q_soll_mean, quaternionInverse(q_ist_mean));
        
        % Keine Euler-Winkel im Kalibrierungsmodus
        quat_trans = [];
        
        % Transformationsquaternion im Workspace speichern
        assignin('base', 'trafo_quat', q_transform);
    
    % Modus 2: Transformationsmodus (mehr als zwei Eingaben)
    else
        euler_ist = data_ist;
        euler_ist = euler_ist * varargin{4}; % Rotationsmatrix anwenden
        q_transform = varargin{3};
        
        % Euler zu Quaternion
        q_ist = eul2quat(deg2rad(euler_ist), 'ZYX');
        
        % Quaternionen normalisieren
        q_ist_norm = q_ist ./ sqrt(sum(q_ist.^2, 2));
        
        % Transformation anwenden
        q_transformed = zeros(size(q_ist_norm));
        for i = 1:size(q_ist_norm, 1)
            q_transformed(i,:) = quatmultiply(q_transform, q_ist_norm(i,:));
        end
        
        % Kontinuierliche Euler-Winkel mit Unwrapping
        quat_trans = quaternionToContinuousEuler(q_transformed, false);

        % Fix gimbal lock for each angle
        for i = 1:3
            angle_data = quat_trans(:,i);
            near_180 = abs(abs(angle_data) - 180) < 2;
            
            if any(near_180)
                mask_neg = angle_data < 0;
                angle_data(mask_neg) = angle_data(mask_neg) + 360;
                quat_trans(:,i) = angle_data;
            end
        end
        
        % Berechne Quaternionen-Fehler für die Analyse
        q_soll_ref = eul2quat(varargin{2});
        quaternion_errors = calculateQuaternionErrors(q_transformed, q_soll_ref);
        
        % Visualisiere die Analyse
        timestamps = (str2double(varargin{1}) - str2double(varargin{1}(1))) / 1e9;
        plotQuaternionAnalysis(timestamps, quaternion_errors);
        % Ergebnis im Workspace speichern
        assignin('base', 'quat_errors', quaternion_errors);
        assignin('base', 'quat_trans', quat_trans);
        %assignin('base', 'quat_trans_orig', quat_trans_orig);
        assignin('base', 'q_transformed', q_transformed)
    end
end

function angles_out = quaternionToContinuousEuler(q, use_unwrapped)
    if isa(q, 'quaternion')
        q_array = compact(q);
    else
        q_array = q;
    end
    
    q_norm = q_array ./ sqrt(sum(q_array.^2, 2));
    angles = quat2eul(q_norm, 'ZYX');
    angles_deg = rad2deg(angles);
    
    if use_unwrapped
        % Convert negative values to positive (around 180)
        roll = angles_deg(:,1);  % Roll is in third column for ZYX
        mask_neg = roll < 0;
        roll(mask_neg) = roll(mask_neg) + 360;
        
        % Force values near 180 to exactly 180
        threshold = 5;
        mask_180 = abs(roll - 180) < threshold;
        roll(mask_180) = 180;
        
        angles_out = angles_deg;
        angles_out(:,1) = roll;
    else
        angles_out = angles_deg;
    end
end

function q_mean = calculateMeanQuaternion(quaternions)
    % Berechnet den Mittelwert mehrerer Quaternionen
    M = zeros(4,4);
    n = size(quaternions, 1);
    
    for i = 1:n
        q = quaternions(i,:);
        M = M + (q' * q);
    end
    
    M = M / n;
    [V, D] = eig(M);
    [~, idx] = max(diag(D));
    q_mean = V(:,idx)';
end

function q_inv = quaternionInverse(q)
    % Berechnet das inverse Quaternion
    q_inv = [q(1) -q(2:4)];
    q_inv = q_inv / sum(q.^2);
end

function quaternion_errors = calculateQuaternionErrors(q1, q2)
    % Berechnet den Winkelunterschied zwischen zwei Quaternionen-Sets
    n_points = min(size(q1, 1), size(q2, 1));  % Berücksichtigt unterschiedliche Längen
    quaternion_errors = zeros(n_points, 1);
    
    for i = 1:n_points
        % Normalisierung für numerische Stabilität
        q1_norm = q1(i,:) / norm(q1(i,:));
        q2_norm = q2(i,:) / norm(q2(i,:));
        
        % Berechnung des Skalarprodukts und Begrenzung auf [-1,1]
        dot_product = abs(sum(q1_norm .* q2_norm));
        dot_product = min(max(dot_product, -1), 1);
        
        % Umrechnung in Winkel (Grad)
        quaternion_errors(i) = 2 * acosd(dot_product);
    end
end

function plotQuaternionAnalysis(timestamps, quaternion_errors)
    figure('Position', [100, 100, 1200, 800], 'Name', 'Quaternion Analysis');
    
    % Zeitreihenanalyse mit gleitendem Mittelwert
    subplot(2,2,[1,2]);
    plot(timestamps, quaternion_errors, 'b-', 'LineWidth', 1.5);
    hold on;
    plot(timestamps, movmean(quaternion_errors, 50), 'r-', 'LineWidth', 2);
    title('Quaternion Angular Error Over Time');
    xlabel('Time (s)');
    ylabel('Angular Error (degrees)');
    grid on;
    legend('Raw Error', 'Moving Average (50 points)');
    
    % Fehlerverteilung als Histogramm
    subplot(2,2,3);
    histogram(quaternion_errors, 30, 'Normalization', 'probability');
    title('Error Distribution');
    xlabel('Angular Error (degrees)');
    ylabel('Probability');
    grid on;
    
    % Statistische Zusammenfassung
    error_stats = struct(...
        'mean', mean(quaternion_errors), ...
        'median', median(quaternion_errors), ...
        'std', std(quaternion_errors), ...
        'max', max(quaternion_errors), ...
        'min', min(quaternion_errors));
    
    subplot(2,2,4);
    text(0.1, 0.8, sprintf('Statistics (degrees):\nMean: %.2f\nMedian: %.2f\nStd Dev: %.2f\nMin/Max: %.2f / %.2f', ...
        error_stats.mean, error_stats.median, error_stats.std, error_stats.min, error_stats.max), ...
        'Units', 'normalized');
    axis off;
    
    sgtitle('Quaternion Transformation Analysis');
end