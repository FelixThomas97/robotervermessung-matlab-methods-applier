% Clear workspace and command window for fresh start
clear;
clc;

bahn_id_ = '1738682877';
%bahn_id_ = '1721048142';% Orientierungsänderung ohne Kalibrierungsdatei
plots = true;              % Plotten der Daten 
upload_all = false;        % Upload aller Bahnen
upload_single = false;     % Nur eine einzelne Bahn
transform_only = true;    % Nur Transformation und Plot, kein Upload
is_pick_and_place = true;  % NEU: Flag für Pick-and-Place Aufgaben

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

% Extract quaternions from tables using your data structure
q_soll = table2array(data_cal_soll(:,5:8));
q_soll = [q_soll(:,4), q_soll(:,3), q_soll(:,2), q_soll(:,1)]; % Reorder to [w x y z]

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

% Create visualization - we'll plot x, y, z components (ignoring w)
figure('Color', 'white', 'Position', [100, 100, 1200, 600]);

% Plot X component
subplot(3,1,1)
hold on
plot(ist_times, q_ist_array(:,2), 'b--', 'LineWidth', 1, 'DisplayName', 'Original')
plot(ist_times, q_soll_array(:,2), 'r-', 'LineWidth', 1, 'DisplayName', 'Target')
plot(ist_times, q_transformed_array(:,2), 'g-', 'LineWidth', 2, 'DisplayName', 'Transformed')
title('X Component of Quaternion')
ylabel('X')
legend('Location', 'best')
grid on
hold off

% Plot Y component
subplot(3,1,2)
hold on
plot(ist_times, q_ist_array(:,3), 'b--', 'LineWidth', 1, 'DisplayName', 'Original')
plot(ist_times, q_soll_array(:,3), 'r-', 'LineWidth', 1, 'DisplayName', 'Target')
plot(ist_times, q_transformed_array(:,3), 'g-', 'LineWidth', 2, 'DisplayName', 'Transformed')
title('Y Component of Quaternion')
ylabel('Y')
grid on
hold off

% Plot Z component
subplot(3,1,3)
hold on
plot(ist_timestamps, q_ist_array(:,4), 'b--', 'LineWidth', 1, 'DisplayName', 'Original')
plot(ist_timestamps, q_soll_array(:,4), 'r-', 'LineWidth', 1, 'DisplayName', 'Target')
plot(ist_timestamps, q_transformed_array(:,4), 'g-', 'LineWidth', 2, 'DisplayName', 'Transformed')
title('Z Component of Quaternion')
xlabel('Time (s)')
ylabel('Z')
grid on
hold off

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

% For ist data (mocap measurements)
euler_ist = zeros(length(q_ist_quat), 3);
for i = 1:length(q_ist_quat)
    euler_ist(i,:) = quat2eul(compact(q_ist_quat(i)), 'ZYX');
end

% For soll data (robot controller commands) - using original soll data
euler_soll_original = zeros(length(q_soll), 3);
for i = 1:length(q_soll)
    euler_soll_original(i,:) = quat2eul(q_soll(i,:), 'ZYX');
end

% For transformed data
euler_transformed = zeros(length(q_transformed), 3);
for i = 1:length(q_transformed)
    euler_transformed(i,:) = quat2eul(compact(q_transformed(i)), 'ZYX');
end

% Convert all angles to degrees
euler_ist = rad2deg(euler_ist);
euler_soll = rad2deg(euler_soll_original);
euler_transformed = rad2deg(euler_transformed);

% Create new figure for Euler angle comparison
figure('Color', 'white', 'Position', [100, 100, 1200, 600], 'Name', 'Euler Angles Comparison');

% Plot roll (rotation around X)
subplot(3,1,1)
hold on
plot(ist_times, euler_ist(:,3), 'b--', 'LineWidth', 1, 'DisplayName', 'Original')
plot(soll_times, euler_soll(:,3), 'r-', 'LineWidth', 1, 'DisplayName', 'Target')
plot(ist_times, euler_transformed(:,3), 'g-', 'LineWidth', 2, 'DisplayName', 'Transformed')
title('Roll Angle')
ylabel('Degrees')
legend('Location', 'best')
grid on
hold off

% Plot pitch (rotation around Y)
subplot(3,1,2)
hold on
plot(ist_times, euler_ist(:,2), 'b--', 'LineWidth', 1, 'DisplayName', 'Original')
plot(soll_times, euler_soll(:,2), 'r-', 'LineWidth', 1, 'DisplayName', 'Target')
plot(ist_times, euler_transformed(:,2), 'g-', 'LineWidth', 2, 'DisplayName', 'Transformed')
title('Pitch Angle')
ylabel('Degrees')
grid on
hold off

% Plot yaw (rotation around Z)
subplot(3,1,3)
hold on
plot(ist_times, euler_ist(:,1), 'b--', 'LineWidth', 1, 'DisplayName', 'Original')
plot(soll_times, euler_soll(:,1), 'r-', 'LineWidth', 1, 'DisplayName', 'Target')
plot(ist_times, euler_transformed(:,1), 'g-', 'LineWidth', 2, 'DisplayName', 'Transformed')
title('Yaw Angle')
xlabel('Time (s)')
ylabel('Degrees')
grid on
hold off

% First, let's print the sizes to understand what we're working with
fprintf('Size of soll_times: %d\n', length(soll_times));
fprintf('Size of ist_times: %d\n', length(ist_times));
fprintf('Size of euler_transformed: %d\n', size(euler_transformed, 1));
fprintf('Size of euler_soll_original: %d\n', size(euler_soll_original, 1));
fprintf('Size of euler_ist: %d\n', size(euler_ist, 1));

% Find the nearest ist measurement for each soll timestamp
[~, nearest_indices] = min(abs(ist_times - soll_times'), [], 1);
% Now nearest_indices will be length 1417 (same as soll data)
% Each value in nearest_indices tells us which ist measurement is closest to each soll timestamp

% Get the ist and transformed values at these indices
euler_ist_at_soll = euler_ist(nearest_indices, :);         % Will be 1417 x 3
euler_transformed_at_soll = euler_transformed(nearest_indices, :); % Will be 1417 x 3

% Calculate errors - now all arrays have length 1417
euler_error_before = mean(abs(euler_soll_original - euler_ist_at_soll), 1);
euler_error_after = mean(abs(euler_soll_original - euler_transformed_at_soll), 1);

fprintf('\nEuler Angle Errors (in degrees):\n');
fprintf('Before transformation:\n');
fprintf('  Roll error: %.2f°\n', euler_error_before(3));
fprintf('  Pitch error: %.2f°\n', euler_error_before(2));
fprintf('  Yaw error: %.2f°\n', euler_error_before(1));

fprintf('\nAfter transformation:\n');
fprintf('  Roll error: %.2f°\n', euler_error_after(3));
fprintf('  Pitch error: %.2f°\n', euler_error_after(2));
fprintf('  Yaw error: %.2f°\n', euler_error_after(1));

% Function to unwrap angles while maintaining relative differences
function unwrapped = customUnwrap(angles)
    % Start with MATLAB's built-in unwrap for initial correction
    unwrapped = unwrap(angles, pi);  % pi radians = 180 degrees tolerance
    
    % Convert back to degrees
    unwrapped = rad2deg(unwrapped);
    
    % Optional: Normalize to start near zero or another reference
    % This helps make the visualization more intuitive
    unwrapped = unwrapped - unwrapped(1) + angles(1);
end

% Apply unwrapping to each Euler angle component
euler_ist_unwrapped = zeros(size(euler_ist));
euler_soll_unwrapped = zeros(size(euler_soll));
euler_transformed_unwrapped = zeros(size(euler_transformed));

% Unwrap each angle sequence
for i = 1:3
    euler_ist_unwrapped(:,i) = customUnwrap(deg2rad(euler_ist(:,i)));
    euler_soll_unwrapped(:,i) = customUnwrap(deg2rad(euler_soll(:,i)));
    euler_transformed_unwrapped(:,i) = customUnwrap(deg2rad(euler_transformed(:,i)));
end

% Create new figure for unwrapped Euler angle comparison
figure('Color', 'white', 'Position', [100, 100, 1200, 600], 'Name', 'Unwrapped Euler Angles Comparison');

% Plot unwrapped roll (rotation around X)
subplot(3,1,1)
hold on
plot(ist_times, euler_ist_unwrapped(:,3), 'b--', 'LineWidth', 1, 'DisplayName', 'Original')
plot(soll_times, euler_soll_unwrapped(:,3), 'r-', 'LineWidth', 1, 'DisplayName', 'Target')
plot(ist_times, euler_transformed_unwrapped(:,3), 'g-', 'LineWidth', 2, 'DisplayName', 'Transformed')
title('Unwrapped Roll Angle')
ylabel('Degrees')
legend('Location', 'best')
grid on
hold off

% Plot unwrapped pitch (rotation around Y)
subplot(3,1,2)
hold on
plot(ist_times, euler_ist_unwrapped(:,2), 'b--', 'LineWidth', 1, 'DisplayName', 'Original')
plot(soll_times, euler_soll_unwrapped(:,2), 'r-', 'LineWidth', 1, 'DisplayName', 'Target')
plot(ist_times, euler_transformed_unwrapped(:,2), 'g-', 'LineWidth', 2, 'DisplayName', 'Transformed')
title('Unwrapped Pitch Angle')
ylabel('Degrees')
grid on
hold off

% Plot unwrapped yaw (rotation around Z)
subplot(3,1,3)
hold on
plot(ist_times, euler_ist_unwrapped(:,1), 'b--', 'LineWidth', 1, 'DisplayName', 'Original')
plot(soll_times, euler_soll_unwrapped(:,1), 'r-', 'LineWidth', 1, 'DisplayName', 'Target')
plot(ist_times, euler_transformed_unwrapped(:,1), 'g-', 'LineWidth', 2, 'DisplayName', 'Transformed')
title('Unwrapped Yaw Angle')
xlabel('Time (s)')
ylabel('Degrees')
grid on
hold off

% Add overall title to clarify these are unwrapped angles
sgtitle('Unwrapped Euler Angles (Continuous Representation)', 'FontSize', 12)

%% VALIDATION

% 1. Validation at Controller Timestamps
% This checks transformation accuracy at the actual commanded positions
[~, controller_indices] = min(abs(ist_times - soll_times'), [], 1);
controller_errors = zeros(length(soll_times), 3);  % Store errors for each axis

for i = 1:length(soll_times)
    % Get the closest mocap measurement to this controller timestamp
    ist_idx = controller_indices(i);
    
    % Convert quaternions to Euler angles for intuitive comparison
    euler_transformed = quat2eul(compact(q_transformed(ist_idx)), 'ZYX');
    euler_soll = quat2eul(q_soll(i,:), 'ZYX');
    
    % Store errors in degrees for each rotation axis
    controller_errors(i,:) = rad2deg(abs(euler_transformed - euler_soll));
end

fprintf('Accuracy at controller timestamps:\n');
fprintf('  Roll error (mean/max): %.2f° / %.2f°\n', mean(controller_errors(:,3)), max(controller_errors(:,3)));
fprintf('  Pitch error (mean/max): %.2f° / %.2f°\n', mean(controller_errors(:,2)), max(controller_errors(:,2)));
fprintf('  Yaw error (mean/max): %.2f° / %.2f°\n', mean(controller_errors(:,1)), max(controller_errors(:,1)));

% 2. Check Quaternion Properties
% Verify that transformed quaternions maintain unit length
q_lengths = zeros(length(q_transformed), 1);
for i = 1:length(q_transformed)
    q = compact(q_transformed(i));
    q_lengths(i) = norm(q);
end

fprintf('\nQuaternion properties check:\n');
fprintf('  Mean quaternion length: %.6f (should be 1.0)\n', mean(q_lengths));
fprintf('  Max deviation from unit length: %.6f\n', max(abs(1 - q_lengths)));

% 3. Transformation Consistency Check
% The transformation should be consistent across the trajectory
consistency_errors = zeros(length(q_transformed)-1, 1);
for i = 1:length(q_transformed)-1
    % Calculate relative rotation between consecutive points
    rel_rot_transformed = q_transformed(i+1) / q_transformed(i);
    rel_rot_soll = q_soll_quat(i+1) / q_soll_quat(i);
    
    % Compare relative rotations
    consistency_errors(i) = norm(compact(rel_rot_transformed) - compact(rel_rot_soll));
end

fprintf('\nTransformation consistency:\n');
fprintf('  Mean consistency error: %.6f\n', mean(consistency_errors));
fprintf('  Max consistency error: %.6f\n', max(consistency_errors));

% 4. Axis-Specific Validation
% Check if the transformation maintains important axis relationships
% This is particularly useful for robotics applications
reference_vector = [0 0 1];  % Example: checking Z-axis alignment
z_axis_angles = zeros(length(q_transformed), 1);

for i = 1:length(q_transformed)
    transformed_vector = rotatepoint(q_transformed(i), reference_vector);
    target_vector = rotatepoint(q_soll_quat(i), reference_vector);
    z_axis_angles(i) = rad2deg(acos(dot(transformed_vector, target_vector)));
end

fprintf('\nZ-axis alignment check:\n');
fprintf('  Mean Z-axis error: %.2f°\n', mean(z_axis_angles));
fprintf('  Max Z-axis error: %.2f°\n', max(z_axis_angles));

% 5. Visual Validation
figure('Name', 'Transformation Validation', 'Position', [100 100 1200 800]);

% Plot axis-specific errors over time
subplot(2,2,1);
plot(soll_times, controller_errors);
title('Errors at Controller Timestamps');
xlabel('Time (s)');
ylabel('Error (degrees)');
legend('Roll', 'Pitch', 'Yaw');
grid on;

% Plot quaternion lengths
subplot(2,2,2);
plot(ist_times, q_lengths);
title('Quaternion Unit Length Check');
xlabel('Time (s)');
ylabel('Quaternion Length');
yline(1, 'r--', 'Unity');
grid on;

% Plot consistency errors
subplot(2,2,3);
plot(ist_times(1:end-1), consistency_errors);
title('Transformation Consistency');
xlabel('Time (s)');
ylabel('Consistency Error');
grid on;

% Plot Z-axis alignment
subplot(2,2,4);
plot(ist_times, z_axis_angles);
title('Z-Axis Alignment Error');
xlabel('Time (s)');
ylabel('Error (degrees)');
grid on;

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

% Convert to degrees
euler_ist = rad2deg(euler_ist);
euler_soll = rad2deg(euler_soll);
euler_transformed_interp = rad2deg(euler_transformed_interp);
euler_transformed_nn = rad2deg(euler_transformed_nn);
euler_transformed_window = rad2deg(euler_transformed_window);

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