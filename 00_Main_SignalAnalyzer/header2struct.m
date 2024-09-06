function header2struct(trajectory_header_id, header_data, trajectory_ist, trajectory_soll, interpolate)

%% Header - Restdaten erstellen

timestamp_ist = trajectory_ist(:,1);
if interpolate == false
    timestamp_soll = trajectory_soll(:,1);
    header_data.source_data_soll = "abb_steuerung_websocket";
else
    header_data.source_data_soll = "interpolation";
end
num_points_ist = size(trajectory_ist,1);
num_points_soll = size(trajectory_soll,1);

% Übrige Daten in Header eintragen
header_data.data_id = trajectory_header_id;
header_data.number_of_points_ist = num_points_ist;
header_data.number_of_points_soll = num_points_soll;
header_data.sample_frequency_ist = length(timestamp_ist)/(timestamp_ist(end)-timestamp_ist(1));
if interpolate == false
    header_data.sample_frequency_soll = length(timestamp_soll)/(timestamp_soll(end)-timestamp_soll(1));
end % Sonst bleibt die sample_frequency_soll leer wie eingangs definiert


%% Header in Workspace laden
assignin('base','header_data',header_data)

end

