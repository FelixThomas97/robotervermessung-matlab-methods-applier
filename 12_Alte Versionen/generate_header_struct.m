function generate_header_struct(trajectory_header_id, header_data, timestamp_ist,num_sample_soll, i,split)

    %% Header - Eintragen

    header_data.data_id = trajectory_header_id;
    header_data.number_of_points_ist = size(timestamp_ist,1);
    header_data.number_of_points_soll = num_sample_soll;
    header_data.sample_frequency_ist = length(timestamp_ist)/(timestamp_ist(end)-timestamp_ist(1));

    %% Header in Workspace laden
    
    assignin('base','header_data',header_data)

end