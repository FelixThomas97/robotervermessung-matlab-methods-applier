

for i = 1:1:num_trajectories
        
        trajectory_header_id = trajectory_header_id_base;
        
        % Aktuelle Ist-Bahn
        trajectory_ist = trajectories_ist{i}(:, 2:4);

        % Aktuelle Soll-Bahn
        if interpolate == false
            trajectory_soll = trajectories_soll{i}(:,2:4);
        else
            trajectory_soll = trajectories_soll{i}(:,1:3);
        end
        
        % Euklidsche Distanzen für die einzelnen Messfahrten
        if euclidean == true
            [eucl_interpolation,eucl_distances,~] = distance2curve(trajectory_ist,trajectory_soll,'linear');
            metric2struct_eucl(trajectory_soll, eucl_interpolation, eucl_distances,trajectory_header_id,i);           
            struct_euclidean{i} = metrics_euclidean;
        else
            clear struct_euclidean
        end
        % DTW für die einzelnen Messfahrten
        if dtw == true
            [dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, dtw_path, ~, ~, ~] = ...
            fkt_dtw3d(trajectory_soll, trajectory_ist, pflag);
            metric2struct_dtw(trajectory_header_id, dtw_av, dtw_max, dtw_distances, dtw_accdist, dtw_path, dtw_X, dtw_Y,i);
            struct_dtw{i} = metrics_dtw;
        else
            clear struct_dtw
        end
        % SIDTW für die einzelnen Messfahrten
        if sidtw == true
            [sidtw_distances, sidtw_max, sidtw_av,...
                sidtw_accdist, sidtw_X, sidtw_Y, sidtw_path, ~, ~]...
                = fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
            metric2struct_sidtw(trajectory_header_id,sidtw_max, sidtw_av, ...
                sidtw_distances,sidtw_X,sidtw_Y,sidtw_accdist,sidtw_path,i);
            struct_sidtw{i} = metrics_johnen;
        else
            clear struct_sidtw
        end
        % Frechet-Distanz für die einzelnen Messfahrten
        if frechet == true
            fkt_discreteFrechet(trajectory_soll,trajectory_ist,pflag);
            metric2struct_frechet(trajectory_header_id, frechet_av, frechet_dist, frechet_distances, frechet_matrix, frechet_path,i);
            
            struct_frechet{i} = metrics_frechet;
        else
            clear struct_frechet
        end
    end
end