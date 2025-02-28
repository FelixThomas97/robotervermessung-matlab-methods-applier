function segment_header2struct(trajectory_header_id,segment_id, timestamp, segment_ist, segment_soll, interpolate)

% %%%%%%%% Dateneingabe Header Segmente %%%%%%%%%%
segment_header = struct();
segment_header.trajectory_header_id = []; 
segment_header.segment_id = [];
segment_header.start_time  = [];
segment_header.end_time = [];
segment_header.number_of_points_ist = [];                  % automatisch
segment_header.number_of_points_soll = [];                 % automatisch
segment_header.sample_frequency_ist = [];                  % automatisch
segment_header.sample_frequency_soll = [];                 % automatisch

%% Header - Restdaten erstellen

timestamp_ist = segment_ist(:,1);
if interpolate == false
    timestamp_soll = segment_soll(:,1);
    segment_header.source_data_soll = "abb_steuerung_websocket";
else
    segment_header.source_data_soll = "interpolation";
end
num_points_ist = size(segment_ist,1);
num_points_soll = size(segment_soll,1);

% Übrige Daten in Header eintragen
segment_header.trajectory_header_id = trajectory_header_id;
segment_header.segment_id = segment_id;
segment_header.number_of_points_ist = num_points_ist;
segment_header.number_of_points_soll = num_points_soll;
segment_header.sample_frequency_ist = length(timestamp_ist)/(timestamp_ist(end)-timestamp_ist(1));
if interpolate == false
    segment_header.sample_frequency_soll = length(timestamp_soll)/(timestamp_soll(end)-timestamp_soll(1));
end % Sonst bleibt die sample_frequency_soll leer wie eingangs definiert

segment_header.start_time = string(datetime(timestamp(1),'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss'));
segment_header.end_time = string(datetime(timestamp(2),'ConvertFrom','epochtime','TicksPerSecond',1e9,'Format','dd-MMM-yyyy HH:mm:ss'));

%% Header in Workspace laden
assignin('base','header_data_segment',segment_header)

end

