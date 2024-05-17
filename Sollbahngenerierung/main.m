%% Ist-Bahn Generierung

filename_excel = 'iso_diagonal_v1000_15x.xlsx';  
filename_json = 'data_ist';   % geändert 
% process_ist_file(filename_excel, filename_json);
extract_ist_file(filename_excel);

%% Soll-Bahn Generierung

% Manuell einzugebende Daten
home = [133 -645 1990];
laenge = 630;
num_points_per_segment = 100;  % Anzahl der Interpolationspunkte pro Teilbahn
defined_velocity = 1000;

% Besteht Gesamtbahn aus mehreren Bahnen und soll zerlegt werden
split = true; 


% Key Points für ISO-Bahn A
position(1,:) = home;
position(2,:) = home + [0 -laenge 0];
position(3,:) = home + [laenge -laenge -laenge];
position(4,:) = home + [laenge 0 -laenge];
position(5,:) = home;

% Anzahl der Key Points
num_key_points = size(position, 1);
num_sample_soll = num_points_per_segment*(num_key_points-1)+1;

%% Muss später noch geändert werden...
% Hier jetzt noch vor der Berechnung der Istbahn ....

% Generate interpolated trajectory
trajectory = interpolate_trajectory(num_points_per_segment,position);

% Generiere json File für die interpolierte Sollbahn
filename = 'data_soll.json';  
generate_trajectory_json(trajectory, filename, defined_velocity);

% Plotten der Sollbahn
plot3(trajectory(:,1), trajectory(:,2), trajectory(:,3), '-o');
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Interpolated Trajectory');

%% Abfrage ob die Bahn zerlegt werden soll

if split == true
    index_events = find(~cellfun('isempty', events_ist));
    num_events_ist = length(index_events);
    

    % Zerlegung der gesamten Ist-Bahn in die einzelnen ISO-Bahnen
    index_teilbahnen = index_events(1:num_key_points-1:end); 
    wdh_teilbahn = length(index_teilbahnen);

    teilbahnen = cell(1,wdh_teilbahn);

    for i = 1:1:wdh_teilbahn
        if i < wdh_teilbahn
            teilbahnen{i} = data_ist(index_teilbahnen(i):index_teilbahnen(i+1)-1,:);
        else
            teilbahnen{i} = data_ist(index_teilbahnen(i):end,:);
        end
        ist_file_to_json(filename_json,teilbahnen{i},col_names,i,split);
        generate_header(trajectory_header_id, timestamp_ist,num_sample_soll, i,split);

        file1 = 'data_ist'+string(i)+'.json';
        file2 = 'data_soll.json';
        combined_file = 'data_'+trajectory_header_id+'.json';
        merge_json_files(file1, file2, combined_file);
    end

else
    % % ist_file_to_json(filename_json,timestamp_ist, x_ist, y_ist, z_ist,tcp_velocity_ist,tcp_acceleration_ist,cpu_temperature_ist,q_ist,joint_states_ist);
    ist_file_to_json(filename_json,data_ist,col_names,i,split)
    generate_header(trajectory_header_id, timestamp_ist,num_sample_soll, i,split);
    file1 = 'data_ist.json';
    file2 = 'data_soll.json';
    combined_file = 'data_'+trajectory_header_id+'.json';
    merge_json_files(file1, file2, combined_file);
end
   
%%
% % Generate interpolated trajectory
% trajectory = interpolate_trajectory(home, laenge, num_points_per_segment,position);
% 
% % Generate JSON file with the interpolated trajectory
% filename = 'data_soll.json';  % Output JSON file name
% generate_trajectory_json(trajectory, filename, defined_velocity);
% 
% % Plotting the trajectory for visualization
% plot3(trajectory(:,1), trajectory(:,2), trajectory(:,3), '-o');
% grid on;
% xlabel('X');
% ylabel('Y');
% zlabel('Z');
% title('Interpolated Trajectory');

%% Header - Eintragen
% data_id = trajectory_header_id;
% robot_name = "robot0";
% robot_model = "abb_irb4400";
% trajectory_type = "iso_path_A";
% carthesian = "true";
% path_solver = "abb_steuerung";
% recording_date = "2024-05-16T16:01:00.241866";
% real_robot = "true";
% number_of_points_ist = size(timestamp_ist,1);
% number_of_points_soll = num_sample_soll;
% sample_frequency_ist = length(timestamp_ist)/(timestamp_ist(end)-timestamp_ist(1)); % geändert 
% source = "matlab";

%% Header Generierung

% header_data = struct(...
%     'data_id', data_id, ...
%     'robot_name', robot_name, ...
%     'robot_model', robot_model, ...
%     'trajectory_type', trajectory_type, ...
%     'carthesian', carthesian, ...
%     'path_solver', path_solver, ...
%     'recording_date', recording_date, ...
%     'real_robot', real_robot, ...
%     'number_of_points_ist', number_of_points_ist, ...
%     'number_of_points_soll', number_of_points_soll, ...
%     'sample_frequency_ist', sample_frequency_ist, ...
%     'source', source);
% 
% % Converter estrutura para JSON
% jsonStr = jsonencode(header_data);
% 
% % Escrever JSON em arquivo
% fid = fopen('header_'+trajectory_header_id+'.json', 'w');
% if fid == -1
%     error('Cannot create JSON file');
% end
% fwrite(fid, jsonStr, 'char');
% fclose(fid);

%% Kombination JSON-Dateien
% 
% file1 = 'data_ist.json';
% file2 = 'data_soll.json';
% combined_file = 'data_'+trajectory_header_id+'.json';
% % combined_file = 'data.json';
% merge_json_files(file1, file2, combined_file);
