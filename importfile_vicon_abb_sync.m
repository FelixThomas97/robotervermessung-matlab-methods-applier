function data = importfile_vicon_abb_sync(filename, dataLines)

    %% Input handling

    % If dataLines is not specified, define defaults
    if nargin < 2
        dataLines = [2, Inf];
    end

    %% Ermittlung der Anzahl der Spalten der Datei
    fid = fopen(filename, 'r');
    firstLine = fgetl(fid);
    fclose(fid);
    numCols = numel(strsplit(firstLine, ','));

    %% Set up the Import Options and import the data

    if numCols == 40
        opts = delimitedTextImportOptions("NumVariables", 40);
        
        % Specify range and delimiter
        opts.DataLines = dataLines;
        opts.Delimiter = ",";
        
        % Specify column names and types
        opts.VariableNames = ["timestamp", "sec", "nanosec", "pv_x", "pv_y", "pv_z", "ov_x", "ov_y", "ov_z", "ov_w", "tcp_speedv_x", "tcp_speedv_y", "tcp_speedv_z", "tcp_speedv", "tcp_angularv_x", "tcp_angularv_y", "tcp_angularv_z", "tcp_angularv", "tcp_accelv__x", "tcp_accelv__y", "tcp_accelv__z", "tcp_accelv", "tcp_accelv_angular_x", "tcp_accelv_angular_y", "tcp_accelv_angular_z", "tcp_accelv_angular", "ps_x", "ps_y", "ps_z", "os_x", "os_y", "os_z", "os_w", "tcp_speeds", "joint_1", "joint_2", "joint_3", "joint_4", "joint_5", "joint_6"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
        
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";

        events = false;
        assignin('base',"events",events);

   elseif numCols == 43
        opts = delimitedTextImportOptions("NumVariables", 43);
        
        % Specify range and delimiter
        opts.DataLines = dataLines;
        opts.Delimiter = ",";
        
        % Specify column names and types
        opts.VariableNames = ["timestamp", "sec", "nanosec", "pv_x", "pv_y", "pv_z", "ov_x", "ov_y", "ov_z", "ov_w", "tcp_speedv_x", "tcp_speedv_y", "tcp_speedv_z", "tcp_speedv", "tcp_angularv_x", "tcp_angularv_y", "tcp_angularv_z", "tcp_angularv", "tcp_accelv__x", "tcp_accelv__y", "tcp_accelv__z", "tcp_accelv", "tcp_accelv_angular_x", "tcp_accelv_angular_y", "tcp_accelv_angular_z", "tcp_accelv_angular", "ps_x", "ps_y", "ps_z", "os_x", "os_y", "os_z", "os_w", "tcp_speeds", "joint_1", "joint_2", "joint_3", "joint_4", "joint_5", "joint_6", "ap_x", "ap_y", "ap_z"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];
        
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";

        events = true;
        assignin('base',"events",events);
        
    elseif numCols == 47
        opts = delimitedTextImportOptions("NumVariables", 47);
        
        % Specify range and delimiter
        opts.DataLines = dataLines;
        opts.Delimiter = ",";
        
        % Specify column names and types
        opts.VariableNames = ["timestamp", "sec", "nanosec", "pv_x", "pv_y", "pv_z", "ov_x", "ov_y", "ov_z", "ov_w", "tcp_speedv_x", "tcp_speedv_y", "tcp_speedv_z", "tcp_speedv", "tcp_angularv_x", "tcp_angularv_y", "tcp_angularv_z", "tcp_angularv", "tcp_accelv__x", "tcp_accelv__y", "tcp_accelv__z", "tcp_accelv", "tcp_accelv_angular_x", "tcp_accelv_angular_y", "tcp_accelv_angular_z", "tcp_accelv_angular", "ps_x", "ps_y", "ps_z", "os_x", "os_y", "os_z", "os_w", "tcp_speeds", "joint_1", "joint_2", "joint_3", "joint_4", "joint_5", "joint_6", "ap_x", "ap_y", "ap_z", "aq_w", "aq_x","aq_y","aq_z"];
        opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double","double", "double", "double", "double"];
        
        % Specify file level properties
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule = "read";

        events = true;
        assignin('base',"events",events);

    else
        error('Unerwartete Anzahl an Spalten in der Datei!');
    end
    
    % Import the data
    data = readtable(filename, opts);
end
