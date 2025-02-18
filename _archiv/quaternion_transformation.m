% Clear workspace and command window for fresh start
clear;
clc;

bahn_id_ = '1738827002';
%bahn_id_ = '1721048142';% Orientierungsänderung ohne Kalibrierungsdatei
plots = true;              % Plotten der Daten 
upload_all = false;        % Upload aller Bahnen
upload_single = false;     % Nur eine einzelne Bahn
transform_only = true;     % Nur Transformation und Plot, kein Upload
is_pick_and_place = true;  % NEU: Flag für Pick-and-Place Aufgaben
use_unwrapped = true;      % Verwendung von kontinuierlichen (unwrapped) Winkeln 

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

% Extrahieren der Kalibrierungs-Daten für die Position
tablename_cal = ['robotervermessung.' schema '.bahn_pose_ist'];
opts_cal = databaseImportOptions(conn,tablename_cal);
opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == bahn_id_;
data_cal_ist= sqlread(conn,tablename_cal,opts_cal);
data_cal_ist = sortrows(data_cal_ist,'timestamp');

tablename_cal = ['robotervermessung.' schema '.bahn_events'];
opts_cal = databaseImportOptions(conn,tablename_cal);
opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == bahn_id_;
data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
data_cal_soll = sortrows(data_cal_soll,'timestamp');

% Positionsdaten für Koordinatentransformation
calibration(data_cal_ist,data_cal_soll)

% Extrahieren der Kalibrierungs-Daten für die Orientierung
tablename_cal = ['robotervermessung.' schema '.bahn_orientation_soll'];
opts_cal = databaseImportOptions(conn,tablename_cal);
opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == bahn_id_;
data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
data_cal_soll = sortrows(data_cal_soll,'timestamp');

% Print the sizes of both datasets to understand the mismatch
fprintf('Size of ist dataset: %d samples\n', height(data_cal_ist));
fprintf('Size of soll dataset: %d samples\n', height(data_cal_soll));

%%

% Extract quaternions from tables using your data structure
q_soll = table2array(data_cal_soll(:,5:8));
q_soll = [q_soll(:,4), q_soll(:,3), q_soll(:,2),q_soll(:,1)]; % Reorder to [w x y z]
%q_soll = [q_soll(:,4), q_soll(:,3), q_soll(:,2),q_soll(:,1)]; % Reorder to original

q_ist = table2array(data_cal_ist(:,8:11));
q_ist = [q_ist(:,4), q_ist(:,3), q_ist(:,2), q_ist(:,1)];   % Reorder to [w x y z]

% Create timestamps from your data
ist_timestamps = str2double(data_cal_ist.timestamp);
soll_timestamps = str2double(data_cal_soll.timestamp);
ist_times = (ist_timestamps - ist_timestamps(1))/1e9;
soll_times = (soll_timestamps - ist_timestamps(1))/1e9;

% First, find nearest controller points for each mocap measurement
[~, nearest_indices] = min(abs(soll_times - ist_times'), [], 1);
q_soll_matched = q_soll(nearest_indices, :);

% Normalize quaternions to ensure unit length
q_ist_norm = q_ist ./ sqrt(sum(q_ist.^2, 2));
q_soll_matched_norm = q_soll_matched ./ sqrt(sum(q_soll_matched.^2, 2));

% Convert arrays to quaternion objects
q_soll_quat = quaternion(q_soll_matched_norm);
q_ist_quat = quaternion(q_ist);

% Now proceed with the averaging calculation using the matched datasets
n = length(q_ist_quat);
M_ist = zeros(4,4);
M_soll = zeros(4,4);


% Build averaging matrices
for i = 1:n
    q_i_ist = compact(q_ist_quat(i));
    q_i_soll = compact(q_soll_quat(i));
    
    M_ist = M_ist + (q_i_ist' * q_i_ist);
    M_soll = M_soll + (q_i_soll' * q_i_soll);
end

% Find principal eigenvectors - these represent our average orientations
[V_ist, D_ist] = eig(M_ist);
[~, ind_ist] = max(diag(D_ist));
[V_soll, D_soll] = eig(M_soll);
[~, ind_soll] = max(diag(D_soll));

% Create mean quaternions from eigenvectors
q_ist_mean = quaternion(V_ist(:,ind_ist)');
q_soll_mean = quaternion(V_soll(:,ind_soll)');

% Calculate transformation quaternion that takes ist to soll orientation
q_transform = q_soll_mean / q_ist_mean;

% Apply transformation to all ist quaternions
q_transformed = q_transform * q_ist_quat;

% Extract components for visualization using compact
% This gives us arrays of [w x y z] values for each quaternion sequence
q_ist_array = zeros(n, 4);
q_soll_array = zeros(n, 4);
q_transformed_array = zeros(n, 4);

for i = 1:n
    q_ist_array(i,:) = compact(q_ist_quat(i));
    q_soll_array(i,:) = compact(q_soll_quat(i));
    q_transformed_array(i,:) = compact(q_transformed(i));
end

% Farbdefinitionen am Anfang des Scripts
if use_unwrapped
    % Warme Farben für unwrapped
    colors.roll = [255, 107, 107]/255;        % Rot
    colors.pitch = [255, 179, 71]/255;        % Orange
    colors.yaw = [78, 205, 196]/255;          % Türkis
    colors.ist = [150, 150, 150]/255;         % Grau
    colors.transformed = [50, 50, 50]/255;    % Dunkelgrau
else
    % Kühle Farben für nicht-unwrapped
    colors.roll = [69, 183, 209]/255;         % Hellblau
    colors.pitch = [45, 62, 80]/255;          % Dunkelblau
    colors.yaw = [39, 174, 96]/255;           % Grün
    colors.ist = [150, 150, 150]/255;         % Grau
    colors.transformed = [50, 50, 50]/255;    % Dunkelgrau
end


% Kombinierte Visualisierung der Quaternionen-Komponenten
figure('Color', 'white', 'Position', [100, 100, 1200, 400]);
hold on;
% X-Komponente
plot(ist_times, q_ist_array(:,2), 'b--', 'LineWidth', 1);
plot(ist_times, q_soll_array(:,2), 'r-', 'LineWidth', 1);
plot(ist_times, q_transformed_array(:,2), 'g-', 'LineWidth', 2);
% Y-Komponente
plot(ist_times, q_ist_array(:,3), 'b--', 'LineWidth', 1);
plot(ist_times, q_soll_array(:,3), 'r-', 'LineWidth', 1);
plot(ist_times, q_transformed_array(:,3), 'g-', 'LineWidth', 2);
% Z-Komponente
plot(ist_times, q_ist_array(:,4), 'b--', 'LineWidth', 1);
plot(ist_times, q_soll_array(:,4), 'r-', 'LineWidth', 1);
plot(ist_times, q_transformed_array(:,4), 'g-', 'LineWidth', 2);
title('Quaternion Components');
ylabel('Component Value');
xlabel('Time (s)');
legend('Ist X', 'Soll X', 'Trans X', 'Ist Y', 'Soll Y', 'Trans Y', 'Ist Z', 'Soll Z', 'Trans Z', 'Location', 'best');
grid on;
hold off;

% Print transformation quaternion components
transform_array = compact(q_transform);
fprintf('Transformation Quaternion [w x y z]: %.4f %.4f %.4f %.4f\n', transform_array);

% Calculate error metrics using compact arrays
error_before = mean(sqrt(sum((q_soll_array - q_ist_array).^2, 2)));
error_after = mean(sqrt(sum((q_soll_array - q_transformed_array).^2, 2)));

fprintf('Average quaternion error before transformation: %.4f\n', error_before);
fprintf('Average quaternion error after transformation: %.4f\n', error_after);

% Store the transformation quaternion in the workspace
assignin('base', 'trafo_quat', q_transform);

% Find the nearest ist measurement for each soll timestamp
[~, nearest_indices] = min(abs(ist_times - soll_times'), [], 1);

% Berechne Fehler für beide Varianten
% Unwrapped Version
euler_ist_unwrapped = quaternionToContinuousEuler(q_ist_quat, true);
euler_soll_unwrapped = quaternionToContinuousEuler(q_soll, true);
euler_transformed_unwrapped = quaternionToContinuousEuler(q_transformed, true);

% Normal Version (ohne Unwrapping)
euler_ist_base = quaternionToContinuousEuler(q_ist_quat, false);
euler_soll_base = quaternionToContinuousEuler(q_soll, false);
euler_transformed_base = quaternionToContinuousEuler(q_transformed, false);

% Get the transformed values at soll timestamps
euler_transformed_unwrapped_at_soll = euler_transformed_unwrapped(nearest_indices, :);
euler_transformed_base_at_soll = euler_transformed_base(nearest_indices, :);

% Berechne relative Abweichungen für beide Varianten
fprintf('\nRelative Abweichungen:\n');
fprintf('Mit Unwrapping:\n');
rel_error_unwrapped = abs(euler_soll_unwrapped - euler_transformed_unwrapped_at_soll) ./ abs(euler_soll_unwrapped) * 100;
fprintf('  Roll: %.2f%%\n  Pitch: %.2f%%\n  Yaw: %.2f%%\n', ...
    mean(rel_error_unwrapped(:,3)), ...
    mean(rel_error_unwrapped(:,2)), ...
    mean(rel_error_unwrapped(:,1)));

fprintf('\nOhne Unwrapping:\n');
rel_error_normal = abs(euler_soll_base - euler_transformed_base_at_soll) ./ abs(euler_soll_base) * 100;
fprintf('  Roll: %.2f%%\n  Pitch: %.2f%%\n  Yaw: %.2f%%\n', ...
    mean(rel_error_normal(:,3)), ...
    mean(rel_error_normal(:,2)), ...
    mean(rel_error_normal(:,1)));

% Verwendung in den Plots
figure('Color', 'white', 'Position', [100, 100, 1200, 400]);
hold on;
% Roll
plot(ist_times, euler_ist_base(:,3), '--', 'Color', colors.ist, 'LineWidth', 1);
plot(soll_times, euler_soll_base(:,3), '-', 'Color', colors.roll, 'LineWidth', 2);
plot(ist_times, euler_transformed_base(:,3), '-', 'Color', colors.transformed, 'LineWidth', 1);
% Pitch
plot(ist_times, euler_ist_base(:,2), '--', 'Color', colors.ist, 'LineWidth', 1);
plot(soll_times, euler_soll_base(:,2), '-', 'Color', colors.pitch, 'LineWidth', 2);
plot(ist_times, euler_transformed_base(:,2), '-', 'Color', colors.transformed, 'LineWidth', 1);
% Yaw
plot(ist_times, euler_ist_base(:,1), '--', 'Color', colors.ist, 'LineWidth', 1);
plot(soll_times, euler_soll_base(:,1), '-', 'Color', colors.yaw, 'LineWidth', 2);
plot(ist_times, euler_transformed_base(:,1), '-', 'Color', colors.transformed, 'LineWidth', 1);
title('Euler Angles');
ylabel('Degrees');
xlabel('Time (s)');
legend('Ist Roll', 'Soll Roll', 'Trans Roll', 'Ist Pitch', 'Soll Pitch', 'Trans Pitch', 'Ist Yaw', 'Soll Yaw', 'Trans Yaw', 'Location', 'best');
grid on;
hold off;

% Find the nearest ist measurement for each soll timestamp
[~, nearest_indices] = min(abs(ist_times - soll_times'), [], 1);
% Now nearest_indices will be length 1417 (same as soll data)
% Each value in nearest_indices tells us which ist measurement is closest to each soll timestamp

% Get the ist and transformed values at these indices
euler_ist_base_at_soll = euler_ist_base(nearest_indices, :);         % Will be 1417 x 3
euler_transformed_base_at_soll = euler_transformed_base(nearest_indices, :); % Will be 1417 x 3

% Calculate errors - now all arrays have length 1417
euler_error_before = mean(abs(euler_soll_base - euler_ist_base_at_soll), 1);
euler_error_after = mean(abs(euler_soll_base - euler_transformed_base_at_soll), 1);

fprintf('\nEuler Angle Errors (in degrees):\n');
fprintf('Before transformation:\n');
fprintf('  Roll error: %.2f°\n', euler_error_before(3));
fprintf('  Pitch error: %.2f°\n', euler_error_before(2));
fprintf('  Yaw error: %.2f°\n', euler_error_before(1));

fprintf('\nAfter transformation:\n');
fprintf('  Roll error: %.2f°\n', euler_error_after(3));
fprintf('  Pitch error: %.2f°\n', euler_error_after(2));
fprintf('  Yaw error: %.2f°\n', euler_error_after(1));

%% METHODS

% Your existing database connection and data loading code stays the same until the quaternion part

% Print the sizes of both datasets to understand the mismatch
fprintf('\nSize of ist dataset: %d samples\n', height(data_cal_ist));
fprintf('Size of soll dataset: %d samples\n', height(data_cal_soll));

% Extract quaternions from tables as before
q_soll = table2array(data_cal_soll(:,5:8));
q_soll = [q_soll(:,4), q_soll(:,3), q_soll(:,2), q_soll(:,1)]; % [w x y z]

q_ist = table2array(data_cal_ist(:,8:11));
q_ist = [q_ist(:,4), q_ist(:,3), q_ist(:,2), q_ist(:,1)];   % [w x y z]

% Create timestamps from your data
ist_timestamps = str2double(data_cal_ist.timestamp);
soll_timestamps = str2double(data_cal_soll.timestamp);
ist_times = (ist_timestamps - ist_timestamps(1))/1e9;
soll_times = (soll_timestamps - ist_timestamps(1))/1e9;

% Now let's implement all three methods and compare them

%% 1. Interpolation Method (Original approach)
fprintf('\nExecuting Interpolation Method...\n');
q_soll_interp = zeros(size(q_ist));
for i = 1:4
    q_soll_interp(:,i) = interp1(soll_times, q_soll(:,i), ist_times, 'spline');
end
q_soll_interp = q_soll_interp ./ sqrt(sum(q_soll_interp.^2, 2));
q_soll_quat_interp = quaternion(q_soll_interp);
q_ist_quat_interp = quaternion(q_ist);

%% 2. Nearest Neighbor Method
fprintf('\nExecuting Nearest Neighbor Method...\n');
[~, nearest_indices] = min(abs(soll_times - ist_times'), [], 1);
q_soll_nn = q_soll(nearest_indices, :);
q_soll_quat_nn = quaternion(q_soll_nn);
q_ist_quat_nn = quaternion(q_ist);

%% 3. Time Window Method
fprintf('\nExecuting Time Window Method...\n');
window_size = 1.2/mean(diff(soll_times)); % Window slightly larger than controller period
valid_pairs_idx = [];
for i = 1:length(soll_times)
    time_window = abs(ist_times - soll_times(i)) < window_size/2;
    if any(time_window)
        [~, closest_idx] = min(abs(ist_times(time_window) - soll_times(i)));
        window_indices = find(time_window);
        valid_pairs_idx = [valid_pairs_idx; window_indices(closest_idx)];
    end
end
q_ist_window = q_ist(valid_pairs_idx, :);
q_soll_window = q_soll(1:length(valid_pairs_idx), :);
q_soll_quat_window = quaternion(q_soll_window);
q_ist_quat_window = quaternion(q_ist_window);

%% Calculate transformations for each method
% Function to calculate transformation for a method
function [q_transform, M_ist, M_soll] = calculateMethodTransform(q_ist_quat, q_soll_quat)
    n = length(q_ist_quat);
    M_ist = zeros(4,4);
    M_soll = zeros(4,4);
    
    for i = 1:n
        q_i_ist = compact(q_ist_quat(i));
        q_i_soll = compact(q_soll_quat(i));
        M_ist = M_ist + (q_i_ist' * q_i_ist);
        M_soll = M_soll + (q_i_soll' * q_i_soll);
    end
    
    M_ist = M_ist / n;
    M_soll = M_soll / n;
    
    [V_ist, D_ist] = eig(M_ist);
    [V_soll, D_soll] = eig(M_soll);
    [~, ind_ist] = max(diag(D_ist));
    [~, ind_soll] = max(diag(D_soll));
    
    q_ist_mean = quaternion(V_ist(:,ind_ist)');
    q_soll_mean = quaternion(V_soll(:,ind_soll)');
    q_transform = q_soll_mean / q_ist_mean;
end

% Calculate transformations
[q_transform_interp, M_ist_interp, M_soll_interp] = calculateMethodTransform(q_ist_quat_interp, q_soll_quat_interp);
[q_transform_nn, M_ist_nn, M_soll_nn] = calculateMethodTransform(q_ist_quat_nn, q_soll_quat_nn);
[q_transform_window, M_ist_window, M_soll_window] = calculateMethodTransform(q_ist_quat_window, q_soll_quat_window);

%% Apply transformations and calculate errors
q_transformed_interp = q_transform_interp * q_ist_quat_interp;
q_transformed_nn = q_transform_nn * q_ist_quat_nn;
q_transformed_window = q_transform_window * q_ist_quat_window;

%% Convert to Euler angles for comparison
euler_ist = zeros(length(q_ist_quat_interp), 3);
euler_soll = zeros(length(q_soll_quat_interp), 3);
euler_transformed_interp = zeros(length(q_transformed_interp), 3);
euler_transformed_nn = zeros(length(q_transformed_nn), 3);
euler_transformed_window = zeros(length(q_transformed_window), 3);

for i = 1:length(q_ist_quat_interp)
    euler_ist(i,:) = quat2eul(compact(q_ist_quat_interp(i)), 'ZYX');
    euler_soll(i,:) = quat2eul(compact(q_soll_quat_interp(i)), 'ZYX');
    euler_transformed_interp(i,:) = quat2eul(compact(q_transformed_interp(i)), 'ZYX');
    euler_transformed_nn(i,:) = quat2eul(compact(q_transformed_nn(i)), 'ZYX');
end

for i = 1:length(q_transformed_window)
    euler_transformed_window(i,:) = quat2eul(compact(q_transformed_window(i)), 'ZYX');
end

euler_ist = quaternionToContinuousEuler(q_ist_quat_interp, use_unwrapped);
euler_soll = quaternionToContinuousEuler(q_soll_quat_interp, use_unwrapped);
euler_transformed_interp = quaternionToContinuousEuler(q_transformed_interp, use_unwrapped);
euler_transformed_nn = quaternionToContinuousEuler(q_transformed_nn, use_unwrapped);
euler_transformed_window = quaternionToContinuousEuler(q_transformed_window, use_unwrapped);

%% Calculate errors for each method
fprintf('\nComparison of Methods:\n');

% Interpolation Method
error_interp = mean(abs(euler_soll - euler_transformed_interp));
fprintf('\nInterpolation Method Errors:\n');
fprintf('  Roll: %.2f°\n  Pitch: %.2f°\n  Yaw: %.2f°\n', ...
    error_interp(3), error_interp(2), error_interp(1));

% Nearest Neighbor Method
error_nn = mean(abs(euler_soll - euler_transformed_nn));
fprintf('\nNearest Neighbor Method Errors:\n');
fprintf('  Roll: %.2f°\n  Pitch: %.2f°\n  Yaw: %.2f°\n', ...
    error_nn(3), error_nn(2), error_nn(1));

% Time Window Method
error_window = mean(abs(euler_soll(valid_pairs_idx,:) - euler_transformed_window));
fprintf('\nTime Window Method Errors:\n');
fprintf('  Roll: %.2f°\n  Pitch: %.2f°\n  Yaw: %.2f°\n', ...
    error_window(3), error_window(2), error_window(1));

%% Visualization of all methods
figure('Name', 'Comparison of Transformation Methods', 'Position', [100 100 1500 800]);

% Roll comparison
subplot(3,1,1);
hold on;
plot(ist_times, euler_transformed_interp(:,3), 'b-', 'LineWidth', 1, 'DisplayName', 'Interpolation');
plot(ist_times, euler_transformed_nn(:,3), 'r--', 'LineWidth', 1, 'DisplayName', 'Nearest Neighbor');
plot(ist_times(valid_pairs_idx), euler_transformed_window(:,3), 'g:', 'LineWidth', 2, 'DisplayName', 'Time Window');
plot(ist_times, euler_soll(:,3), 'k-', 'LineWidth', 1, 'DisplayName', 'Target');
title('Roll Angle Comparison');
ylabel('Degrees');
legend('Location', 'best');
grid on;
hold off;

% Pitch comparison
subplot(3,1,2);
hold on;
plot(ist_times, euler_transformed_interp(:,2), 'b-', 'LineWidth', 1, 'DisplayName', 'Interpolation');
plot(ist_times, euler_transformed_nn(:,2), 'r--', 'LineWidth', 1, 'DisplayName', 'Nearest Neighbor');
plot(ist_times(valid_pairs_idx), euler_transformed_window(:,2), 'g:', 'LineWidth', 2, 'DisplayName', 'Time Window');
plot(ist_times, euler_soll(:,2), 'k-', 'LineWidth', 1, 'DisplayName', 'Target');
title('Pitch Angle Comparison');
ylabel('Degrees');
legend('Location', 'best');
grid on;
hold off;

% Yaw comparison
subplot(3,1,3);
hold on;
plot(ist_times, euler_transformed_interp(:,1), 'b-', 'LineWidth', 1, 'DisplayName', 'Interpolation');
plot(ist_times, euler_transformed_nn(:,1), 'r--', 'LineWidth', 1, 'DisplayName', 'Nearest Neighbor');
plot(ist_times(valid_pairs_idx), euler_transformed_window(:,1), 'g:', 'LineWidth', 2, 'DisplayName', 'Time Window');
plot(ist_times, euler_soll(:,1), 'k-', 'LineWidth', 1, 'DisplayName', 'Target');
title('Yaw Angle Comparison');
xlabel('Time (s)');
ylabel('Degrees');
legend('Location', 'best');
grid on;
hold off;

% Store the transformation quaternions in the workspace
assignin('base', 'trafo_quat_interp', q_transform_interp);
assignin('base', 'trafo_quat_nn', q_transform_nn);
assignin('base', 'trafo_quat_window', q_transform_window);

function angles_out = quaternionToContinuousEuler(q, use_unwrapped)
    if isa(q, 'quaternion')
        q_array = compact(q);
    else
        q_array = q;
    end
    
    q_norm = q_array ./ sqrt(sum(q_array.^2, 2));
    angles = quat2eul(q_norm, 'ZYX');
    
    if use_unwrapped
        % Wandle in Grad um und wende unwrap an
        angles_unwrapped = unwrap(angles);
        angles_out = rad2deg(angles_unwrapped);
        
        % Korrigiere Yaw durch Überprüfung der Rotation
        yaw = angles_out(:,1);
        if abs(mean(yaw)) > 90
            angles_out(:,1) = 180 * sign(mean(yaw)) - yaw;
        end
    else
        angles_out = rad2deg(angles);
    end
end

%%

% When loading your data
q_soll = table2array(data_cal_soll(:,5:8));
q_ist = table2array(data_cal_ist(:,8:11));

% Call the new transformation function
% Call the new transformation function with timestamps
[q_transformed, error_metrics] = transformQuaternionsWithCoordinates(q_ist, q_soll, ist_times, soll_times, 'XYZ', 'ZYX', true);

% Print error metrics
fprintf('Mean angular error: %.2f degrees\n', error_metrics.mean_angular_error);
fprintf('Mean quaternion distance: %.4f\n', error_metrics.quaternion_distance);