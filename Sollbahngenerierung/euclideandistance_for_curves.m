function [euclidean_distances, points_interpolation, max_distance, average_distance] = euclideandistance_for_curves(dbquery, resolution, trim_start, trim_end)
    if nargin < 4
        trim_start = 0;
    end
    if nargin < 5
        trim_end = -1;
    end
    
    % data = dbquery.query_trajectory(data_id);
    data = dbquery;
    
    x_soll = data.x_soll;
    y_soll = data.y_soll;
    z_soll = data.z_soll;
    x_ist = data.x_ist(trim_start:trim_end);
    y_ist = data.y_ist(trim_start:trim_end);
    z_ist = data.z_ist(trim_start:trim_end);
    
    n_points_ist = length(x_ist);
    n_points_soll = length(x_soll);
    interpolation_resolution = resolution;
    n_points_ist_augmented = n_points_soll * interpolation_resolution;
    distances_matrix = zeros(n_points_soll, n_points_ist_augmented);
    
    % ax = dbquery.make_query_plot();

    [euclidean_distances, points_interpolation, max_distance, average_distance] = compute_distance_method();

    function point = get_point_soll(i)
        point = [x_soll(i), y_soll(i), z_soll(i)];
    end

    function point = get_point_ist(j)
        point = [x_ist(j), y_ist(j), z_ist(j)];
    end

    function [euclidean_distances, points_interpolation, max_distance, average_distance] = compute_distance_method()
        euclidean_distances = [];
        points_interpolation = [];
        indexes_original = [];
        
        for i = 1:n_points_soll-1
            p_soll_i = get_point_soll(i);
            distances = [];
            for j = 1:n_points_ist-1
                p_ist = get_point_ist(j);
                distance = norm(p_ist - p_soll_i);
                distances = [distances, distance];
            end
            
            [~, index] = min(distances);
            indexes_original = [indexes_original, index];
            [d_min_1, p_min_1] = interpolate(p_soll_i, index-1, index, i);
            [d_min_2, p_min_2] = interpolate(p_soll_i, index, index+1, i);
            
            if d_min_1 < d_min_2
                d_min = d_min_1;
                p_min = p_min_1;
            else
                d_min = d_min_2;
                p_min = p_min_2;
            end
            
            points_interpolation = [points_interpolation; p_min];
            euclidean_distances = [euclidean_distances, d_min];
        end
        
        max_distance = max(euclidean_distances);
        max_distance_point_ist = points_interpolation(euclidean_distances == max_distance, :);
        max_distance_point_soll = get_point_soll(find(euclidean_distances == max_distance, 1));
        average_distance = mean(euclidean_distances);
        
        plot_intersects(points_interpolation, average_distance, max_distance_point_ist, max_distance_point_soll);
    end

    function [d_min, p_min] = interpolate(p_soll_i, index_before, index_after, current_i)
        if index_before < 1
            index_before = 1;
        end
        if index_after > n_points_ist
            index_after = n_points_ist;
        end

        p_ist_interpolation_final = get_point_ist(index_after);
        p_ist_interpolation_initial = get_point_ist(index_before);
        curve_direction = p_ist_interpolation_final - p_ist_interpolation_initial;
        t = linspace(0, 1, interpolation_resolution);
        distances_interpolated = [];
        parameter_t = [];
        
        for t_i = t
            p_ist_interpolation_i = p_ist_interpolation_initial + t_i * curve_direction;
            distance = norm(p_ist_interpolation_i - p_soll_i);
            matrix_column = floor(interpolation_resolution * (current_i + t_i) - 1) + 1;
            distances_matrix(current_i, matrix_column) = distance;
            distances_interpolated = [distances_interpolated, distance];
            parameter_t = [parameter_t, t_i];
        end
        
        [d_min, min_index] = min(distances_interpolated);
        t_min = parameter_t(min_index);
        p_min = p_ist_interpolation_initial + t_min * curve_direction;
    end

    function plot_intersects(points_interpolation, average_distance, max_distance_point_ist, max_distance_point_soll)
        for i = 1:length(points_interpolation)
            p_intersect = points_interpolation(i, :);
            p_soll_i = get_point_soll(i);
            plot3(ax, [p_soll_i(1), p_intersect(1)], [p_soll_i(2), p_intersect(2)], [p_soll_i(3), p_intersect(3)], 'Color', '#004D40');
        end
        title(ax, sprintf('Euclidean: Average Distance Interpolated: %.5f', average_distance));
    end
end
