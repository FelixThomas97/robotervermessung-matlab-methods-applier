function interpolated_trajectory = interpolate_trajectory(num_points_per_segment, position)

% %%%%%% Eingefügt um nicht als Funtkion zu testen
% home = [133 -645 1990];
% laenge = 630;
% num_points_per_segment = 100;  % Anzahl der Punkte für die Interpolation pro Segment
% defined_velocity = 1000;

    % Number of key points
    num_key_points = size(position, 1);

    %%
    % Initialize the interpolated trajectory
    interpolated_trajectory = [];
    
    % Interpolate between each pair of key points
    for i = 1:(num_key_points-1)
        
        % Define start and end points of the segment
        start_point = position(i, :);
        end_point = position(i+1, :);
        
        % Generate interpolated points for the segment
        segment_trajectory = interp1([0 1], [start_point; end_point], linspace(0, 1, num_points_per_segment+1));
        
        % Exclude the last point to avoid duplication, except for the final segment
        if i < num_key_points-1
            segment_trajectory = segment_trajectory(1:end-1, :);
        end
        
        % Append to the overall interpolated trajectory
        interpolated_trajectory = [interpolated_trajectory; segment_trajectory];
        assignin('base', 'segment_sollbahn', segment_trajectory)
        assignin('base', 'interpolated_sollbahn', interpolated_trajectory)
        
    end
end