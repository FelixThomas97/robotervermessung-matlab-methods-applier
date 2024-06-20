function generate_header(trajectory_header_id, header_data, trajectory_ist, trajectory_soll)

%% Header - Eintragen

timestamp_ist = trajectory_ist(:,1);
num_points_ist = size(trajectory_ist,1);
num_points_soll = size(trajectory_soll,1);

% Übrige Daten in Header eintragen
header_data.data_id = trajectory_header_id;
header_data.number_of_points_ist = num_points_ist;
header_data.number_of_points_soll = num_points_soll;
header_data.sample_frequency_ist = length(timestamp_ist)/(timestamp_ist(end)-timestamp_ist(1));

%% Header in Workspace laden
assignin('base','header_data',header_data)

end

