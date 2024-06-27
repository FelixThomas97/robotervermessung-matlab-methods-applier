function generate_trajectory_struct_simulation(interpolated_trajectory, defined_velocity)
    % Number of interpolated points
    num_interpolated_points = size(interpolated_trajectory, 1);
    num_sample_soll = num_interpolated_points;
    
    % Generate zero arrays for the quaternion and timestamps
    q1_soll = zeros(num_interpolated_points, 1);
    q2_soll = zeros(num_interpolated_points, 1);
    q3_soll = zeros(num_interpolated_points, 1);
    q4_soll = zeros(num_interpolated_points, 1);
    timestamp_soll = linspace(0, num_interpolated_points-1, num_interpolated_points)';
    
    % Create the structure for JSON export
    data = struct();
    data.timestamp_soll = timestamp_soll;
    data.x_soll = interpolated_trajectory(:, 1)/1000;
    data.y_soll = interpolated_trajectory(:, 2)/1000;
    data.z_soll = interpolated_trajectory(:, 3)/1000;
    data.q1_soll = q1_soll;
    data.q2_soll = q2_soll;
    data.q3_soll = q3_soll;
    data.q4_soll = q4_soll;
    data.tcp_velocity_soll = defined_velocity;
    data.joint_state_soll = [];
    
    assignin("base","data_soll",data)
    
end