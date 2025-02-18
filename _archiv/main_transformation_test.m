%% Einstellungen
clear;

%bahn_id_ = '1738682877';
bahn_id_ = '1738828867';% Orientierungsänderung ohne Kalibrierungsdatei
%bahn_id_ = '1720784405';
transform_only = true;    % Nur Transformation und Plot, kein Upload
plots = true;

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

%% Vorbereitung der zu verarbeitenden Bahn-IDs

% Initialisiere leere Arrays
bahn_ids_to_process = bahn_id_;
existing_bahn_ids = [];

query = ['SELECT DISTINCT bahn_id FROM robotervermessung.' schema '.bahn_pose_trans'];
existing_bahn_ids = str2double(table2array(fetch(conn, query)));

%% Hauptverarbeitungsschleife
tic;


current_bahn_id = bahn_id_;


% Suche nach Kalibrierungslauf
disp(['Verarbeite Bahn-ID: ' current_bahn_id]);
[calibration_id, is_calibration_run] = findCalibrationRun(conn, current_bahn_id, schema);

% Extrahieren der Kalibrierungs-Daten für die Position
tablename_cal = ['robotervermessung.' schema '.bahn_pose_ist'];
opts_cal = databaseImportOptions(conn,tablename_cal);
opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
data_cal_ist = sqlread(conn,tablename_cal,opts_cal);
data_cal_ist = sortrows(data_cal_ist,'timestamp');

tablename_cal = ['robotervermessung.' schema '.bahn_events'];
opts_cal = databaseImportOptions(conn,tablename_cal);
opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
data_cal_soll = sortrows(data_cal_soll,'timestamp');

% Positionsdaten für Koordinatentransformation
calibration(data_cal_ist,data_cal_soll, false)

% Extrahieren der Kalibrierungs-Daten für die Orientierung
tablename_cal = ['robotervermessung.' schema '.bahn_orientation_soll'];
opts_cal = databaseImportOptions(conn,tablename_cal);
opts_cal.RowFilter = opts_cal.RowFilter.bahn_id == calibration_id;
data_cal_soll = sqlread(conn,tablename_cal,opts_cal);
data_cal_soll = sortrows(data_cal_soll,'timestamp');

% Extrai os quaternions ist e soll
q_ist = [data_cal_ist.qw_ist, data_cal_ist.qx_ist, data_cal_ist.qy_ist, data_cal_ist.qz_ist];
q_soll = [data_cal_soll.qw_soll, data_cal_soll.qx_soll, data_cal_soll.qy_soll, data_cal_soll.qz_soll];

% q_ist = [data_cal_ist.qx_ist, data_cal_ist.qy_ist, data_cal_ist.qz_ist, data_cal_ist.qw_ist];
% q_soll = [data_cal_soll.qx_soll, data_cal_soll.qy_soll, data_cal_soll.qz_soll, data_cal_soll.qw_soll];

% Align quaternions to same hemisphere using first as reference
% for i = 2:size(q_ist,1)
%     if dot(q_ist(i,:), q_ist(1,:)) < 0
%         q_ist(i,:) = -q_ist(i,:);
%     end
% end
% 
% for i = 2:size(q_soll,1)
%     if dot(q_soll(i,:), q_soll(1,:)) < 0
%         q_soll(i,:) = -q_soll(i,:);
%     end
% end


% Calcula a média
q_mean_ist = mean(q_ist, 1);
q_mean_ist = q_mean_ist / norm(q_mean_ist);

q_mean_soll = mean(q_soll, 1);
q_mean_soll = q_mean_soll / norm(q_mean_soll);

% Calcula o quaternion de transformação usando quatmultiply
%q_transform = q_mean_ist.^(-1).*q_mean_soll;
q_transform = quatmultiply(quatconj(q_mean_ist), q_mean_soll);

%Auslesen der gesamten Ist-Daten
query = ['SELECT * FROM robotervermessung.' schema '.bahn_pose_ist ' ...
        'WHERE robotervermessung.' schema '.bahn_pose_ist.bahn_id = ''' current_bahn_id ''''];
data_ist = fetch(conn, query);
data_ist = sortrows(data_ist,'timestamp');

% Leitura dos dados soll
query = ['SELECT * FROM robotervermessung.' schema '.bahn_orientation_soll ' ...
'WHERE robotervermessung.' schema '.bahn_orientation_soll.bahn_id = ''' current_bahn_id ''''];
data_soll = fetch(conn, query);
data_soll = sortrows(data_soll,'timestamp');

% Extrair quaternions da trajetória atual
q_traj = [data_ist.qw_ist, data_ist.qx_ist, data_ist.qy_ist, data_ist.qz_ist];
q_soll = [data_soll.qw_soll, data_soll.qx_soll, data_soll.qy_soll, data_soll.qz_soll];

% q_traj = [data_ist.qx_ist, data_ist.qy_ist, data_ist.qz_ist, data_ist.qw_ist];
% q_soll = [data_soll.qx_soll, data_soll.qy_soll, data_soll.qz_soll, data_soll.qw_soll];

% Extrair tempos e quaternions
ist_times = str2double(data_ist.timestamp);
soll_times = str2double(data_soll.timestamp);

% Aplica a transformação para cada ponto
q_traj_transformed = zeros(size(q_traj));
for i = 1:size(q_traj,1)
    q_traj_transformed(i,:) = quatmultiply(q_traj(i,:), q_transform);
end

% Normalizar timestamps
t0_ist = min(ist_times);  % tempo inicial
t0_soll = min(soll_times);  % tempo inicial
t0 = min(t0_ist, t0_soll);  % referência global

ist_times_norm = (ist_times - t0) * 1e-9;  % converter para segundos
soll_times_norm = (soll_times - t0) * 1e-9;  % converter para segundos

% Converter quaternions para ângulos de Euler (em radianos)
euler_ist = quat2eul(q_traj_transformed,'ZYX');
euler_soll = quat2eul(q_soll, 'ZYX');

% Converter para graus
euler_ist_deg = rad2deg(euler_ist);
euler_soll_deg = rad2deg(euler_soll);

% Fix gimbal lock issues
euler_ist_deg_fixed = fixGimbalLock(euler_ist_deg);
euler_soll_deg_fixed = fixGimbalLock(euler_soll_deg);

% Visualização
if plots
    figure;
    
    % Plot do ângulo Z (Yaw)
    subplot(3,1,1);
    plot(ist_times_norm, euler_ist_deg_fixed(:,1), '--'); hold on;
    plot(soll_times_norm, euler_soll_deg_fixed(:,1), '-');
    title('Yaw');
    legend('Transformado', 'Soll');
    ylabel('Ângulo (graus)');
    grid on;
    
    % Plot do ângulo Y (Pitch)
    subplot(3,1,2);
    plot(ist_times_norm, euler_ist_deg_fixed(:,2), '--'); hold on;
    plot(soll_times_norm, euler_soll_deg_fixed(:,2), '-');
    title('Pitch');
    legend('Transformado', 'Soll');
    ylabel('Ângulo (graus)');
    grid on;
    
    % Plot do ângulo X (Roll)
    subplot(3,1,3);
    plot(ist_times_norm, euler_ist_deg_fixed(:,3), '--'); hold on;
    plot(soll_times_norm, euler_soll_deg_fixed(:,3), '-');
    title('Roll');
    legend('Transformado', 'Soll');
    xlabel('Tempo (s)');
    ylabel('Ângulo (graus)');
    grid on;
end

% Encontrar pares de pontos próximos no tempo
max_time_diff = 0.1;  % diferença máxima aceitável em segundos
matched_pairs = [];    % [índice_ist, índice_soll]
errors = [];          % [erro_yaw, erro_pitch, erro_roll]

for i = 1:length(ist_times_norm)
    % Encontrar o ponto mais próximo no tempo
    [min_diff, idx] = min(abs(soll_times_norm - ist_times_norm(i)));
    
    % Só considera se a diferença de tempo for menor que o limiar
    if min_diff <= max_time_diff
        matched_pairs = [matched_pairs; i, idx];
        errors = [errors; euler_ist_deg_fixed(i,:) - euler_soll_deg_fixed(idx,:)];
    end
end

% Calcular estatísticas do erro
error_mean = mean(abs(errors));
error_std = std(errors);
error_max = max(abs(errors));

% Plot dos erros
figure;
subplot(3,1,1);
plot(ist_times_norm(matched_pairs(:,1)), errors(:,1));
title(sprintf('Erro Yaw (média: %.2f°, max: %.2f°)', error_mean(1), error_max(1)));
ylabel('Erro (graus)');
grid on;

subplot(3,1,2);
plot(ist_times_norm(matched_pairs(:,1)), errors(:,2));
title(sprintf('Erro Pitch (média: %.2f°, max: %.2f°)', error_mean(2), error_max(2)));
ylabel('Erro (graus)');
grid on;

subplot(3,1,3);
plot(ist_times_norm(matched_pairs(:,1)), errors(:,3));
title(sprintf('Erro Roll (média: %.2f°, max: %.2f°)', error_mean(3), error_max(3)));
xlabel('Tempo (s)');
ylabel('Erro (graus)');
grid on;

% Exibir estatísticas
fprintf('\nEstatísticas do erro (em graus):\n');
fprintf('          Yaw     Pitch    Roll\n');
fprintf('Média:  %6.2f  %6.2f  %6.2f\n', error_mean);
fprintf('Std:    %6.2f  %6.2f  %6.2f\n', error_std);
fprintf('Max:    %6.2f  %6.2f  %6.2f\n', error_max);
fprintf('Número de pontos correspondentes: %d\n', size(matched_pairs,1));

% Calculate improved quaternion errors
quaternion_errors = zeros(size(matched_pairs, 1), 1);
timestamps = ist_times_norm(matched_pairs(:,1));

for i = 1:size(matched_pairs, 1)
    q1 = q_traj_transformed(matched_pairs(i,1),:);
    q2 = q_soll(matched_pairs(i,2),:);
    
    % Ensure unit quaternions
    q1 = q1 / norm(q1);
    q2 = q2 / norm(q2);
    
    % Calculate inner product
    inner_product = abs(sum(q1.*q2));
    
    % Clamp to [-1,1] to handle numerical errors
    inner_product = min(max(inner_product, -1), 1);
    
    % Calculate angular error in degrees
    quaternion_errors(i) = 2 * acosd(inner_product);
end

% Create figure with subplots
figure('Position', [100, 100, 1200, 800]);

% 1. Time series of quaternion errors
subplot(2,2,[1,2]);
plot(timestamps, quaternion_errors, 'b-', 'LineWidth', 1.5);
hold on;
plot(timestamps, movmean(quaternion_errors, 50), 'r-', 'LineWidth', 2);
title('Quaternion Angular Error Over Time');
xlabel('Time (s)');
ylabel('Angular Error (degrees)');
grid on;
legend('Raw Error', 'Moving Average (50 points)');

% 2. Histogram of errors
subplot(2,2,3);
histogram(quaternion_errors, 30, 'Normalization', 'probability', 'FaceColor', [0.3 0.6 0.9]);
title('Distribution of Angular Errors');
xlabel('Angular Error (degrees)');
ylabel('Probability');
grid on;

% 3. Box plot
subplot(2,2,4);
boxplot(quaternion_errors);
title('Error Statistics');
ylabel('Angular Error (degrees)');
grid on;

% Calculate and display statistics
error_mean = mean(quaternion_errors);
error_std = std(quaternion_errors);
error_median = median(quaternion_errors);
error_max = max(quaternion_errors);
error_min = min(quaternion_errors);

% Add text box with statistics
annotation('textbox', [0.6 0.15 0.35 0.15], ...
    'String', {sprintf('Statistics (degrees):', error_mean), ...
               sprintf('Mean: %.2f', error_mean), ...
               sprintf('Median: %.2f', error_median), ...
               sprintf('Std Dev: %.2f', error_std), ...
               sprintf('Min/Max: %.2f / %.2f', error_min, error_max)}, ...
    'EdgeColor', 'none', ...
    'BackgroundColor', [0.9 0.9 0.9]);

% Adjust layout
sgtitle('Quaternion Error Analysis');
set(gcf, 'Color', 'white');

function euler_fixed = fixGimbalLock(euler_angles)
    euler_fixed = euler_angles;
    
    for i = 1:3  % Check each angle component
        angle_data = euler_angles(:,i);
        
        % Check if we have values close to ±180
        near_180 = abs(abs(angle_data) - 180) < 5;
        
        if any(near_180)
            % If we have values near 180, fix sign flips
            mask_neg = angle_data < 0;
            angle_data(mask_neg) = angle_data(mask_neg) + 360;
            euler_fixed(:,i) = angle_data;
        end
    end
end