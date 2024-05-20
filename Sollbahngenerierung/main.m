%% Laden der Daten

%%%%%%%%%%%%%%%%%%%%%% Bereits hinzugefügte Daten %%%%%%%%%%%%%%%%%%%%%%%%%
% 'iso_diagonal_v1000_15x.xlsx' ---> robot01716221276i

filename_excel = 'iso_diagonal_v1000_15x.xlsx';  
filename_json = 'data_ist';   % .jason wird später hinzugefügt 
extract_ist_file(filename_excel);

%% Dateneingabe

    % Dateneingabe für Header
    header_data = struct();
    header_data.data_id = [];                   % leere Zellen werden später gefüllt
    header_data.robot_name = "robot0";
    header_data.robot_model = "abb_irb4400";
    header_data.trajectory_type = "iso_path_A";
    header_data.carthesian = "true";
    header_data.path_solver = "abb_steuerung";
    header_data.recording_date = "2024-05-16T16:32:00.241866";
    header_data.real_robot = "true";
    header_data.number_of_points_ist = [];      % leere Zellen werden später gefüllt
    header_data.number_of_points_soll = [];     % leere Zellen werden später gefüllt
    header_data.sample_frequency_ist = [];      % leere Zellen werden später gefüllt
    header_data.source = "matlab";

    % Dateneingabe für Sollbahn
    home = [133 -645 1990];
    laenge = 630;
    num_points_per_segment = 100;  % Anzahl der Interpolationspunkte pro Teilbahn
    defined_velocity = 1000;
    
    % Besteht Gesamtbahn aus mehreren Bahnen und soll zerlegt werden
    split = false; 

    % Welche Metriken sollen berechnet werden
    dtw_johnen = true;
    euclidean = true; 
    frechet = false; 

    % Automatisch in Datenbank eingtragen
    mongoDB = false;

    % Plotten der Ergebnisse 
    pflag = false;
    
    % Key Points für ISO-Bahn A
    if header_data.trajectory_type == "iso_path_A"
        
        position(1,:) = home;
        position(2,:) = home + [0 -laenge 0];
        position(3,:) = home + [laenge -laenge -laenge];
        position(4,:) = home + [laenge 0 -laenge];
        position(5,:) = home;

    end
    
    % Anzahl der Key Points
    num_key_points = size(position, 1);
    num_sample_soll = num_points_per_segment*(num_key_points-1)+1;

%% Generiere Sollbahn 
% (später muss das nach Istbahn für automatische Generierung) 

% Interpoliere Sollbahn
trajectory_soll = interpolate_trajectory(num_points_per_segment,position);

% Generiere json File für die interpolierte Sollbahn
filename = 'data_soll.json';  
generate_trajectory_json(trajectory_soll, filename, defined_velocity);

% Plotten der Sollbahn
plot3(trajectory_soll(:,1), trajectory_soll(:,2), trajectory_soll(:,3), '-o');
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Interpolated Trajectory');

%% Abfrage ob die Bahn zerlegt werden soll

% Finden und Anzahl der Ereignisse während der Messung
index_events = find(~cellfun('isempty', events_ist));
num_events_ist = length(index_events);


% Zerlegung der gesamten Ist-Bahn in die einzelnen ISO-Bahnen
index_teilbahnen = index_events(1:num_key_points-1:end); 
wdh_teilbahn = length(index_teilbahnen);

teilbahnen = cell(1,wdh_teilbahn);

% Bahn soll zerlegt werden
if split == true

    for i = 1:1:wdh_teilbahn

        if i < wdh_teilbahn
            teilbahnen{i} = data_ist(index_teilbahnen(i):index_teilbahnen(i+1)-1,:);
        else
            teilbahnen{i} = data_ist(index_teilbahnen(i):end,:);
        end

        ist_file_to_json(filename_json,teilbahnen{i},col_names,i,split);
        generate_header(trajectory_header_id, header_data, timestamp_ist,num_sample_soll, i,split);
        file1 = 'data_ist'+string(i)+'.json';
        file2 = 'data_soll.json';
        combined_file = 'data_'+trajectory_header_id+'.json';
        merge_json_files(file1, file2, combined_file);

    end

else % Bahn soll nicht zerlegt werden

    ist_file_to_json(filename_json,data_ist,col_names,i,split)
    generate_header(trajectory_header_id, header_data, timestamp_ist, num_sample_soll, i,split);
    file1 = 'data_ist.json';
    file2 = 'data_soll.json';
    combined_file = 'data_'+trajectory_header_id+'.json';
    merge_json_files(file1, file2, combined_file);

end

%% Vorbereitungen für Anwendung der Verfahren

if split == false

    % Sollbahn vervielfachen
    trajectory_soll = repmat(trajectory_soll(1:end-1,:), wdh_teilbahn, 1);
    trajectory_ist = [x_ist y_ist z_ist];

else
    % String in Char umwandeln
    trajectory_header_id = char(trajectory_header_id);
    % Header ID wieder in Anfangszustand
    if wdh_teilbahn < 10
        trajectory_header_id = trajectory_header_id(1:end-1);
    else
        trajectory_header_id = trajectory_header_id(1:end-2);
    end

end

%% Berechnung Selective Interpolation DTW (Johnen)

if dtw_johnen == true

    if split == false

         % Berechnung DTW Johnen
        [distances_selintdtw, maxDistance_selintdtw, avDistance_selintdtw,...
            accdist_selintdtw, X_selintdtw, Y_selintdtw, path_selintdtw, ix, iy]...
            = fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
        % Generiere Metrics-Datei
        generate_metric_johnen(trajectory_header_id,maxDistance_selintdtw, avDistance_selintdtw, ...
            distances_selintdtw,X_selintdtw,Y_selintdtw,accdist_selintdtw,path_selintdtw,i,split);
    
    else 
        
        for i = 1:1:wdh_teilbahn

            trajectory_ist_table = teilbahnen{i}(:, 2:4);
            trajectory_ist = table2array(trajectory_ist_table);

            % Berechnung DTW Johnen
            [distances_selintdtw, maxDistance_selintdtw, avDistance_selintdtw, ...
                accdist_selintdtw, X_selintdtw, Y_selintdtw, path_selintdtw, ix, iy] = ...
                fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
            % Generiere Metrics Datei
            generate_metric_johnen(trajectory_header_id,maxDistance_selintdtw, avDistance_selintdtw, ...
                distances_selintdtw,X_selintdtw,Y_selintdtw,accdist_selintdtw,path_selintdtw,i,split);

        end
    end
end

%% Berechnung der Euklidschen Distanz 

if euclidean == true

    if split == false
    
        [eucl_intepol_soll,eucl_distances,eucl_t] = distance2curve(trajectory_soll,trajectory_ist,'linear');
        generate_metric_euclidean(eucl_distances,trajectory_header_id,i,split);
    
    else 

        for i= 1:1:wdh_teilbahn
    
            trajectory_ist_table = teilbahnen{i}(:, 2:4);
            trajectory_ist = table2array(trajectory_ist_table);
    
            [eucl_intepol_soll,eucl_distances,eucl_t] = distance2curve(trajectory_soll,trajectory_ist,'linear');
            generate_metric_euclidean(eucl_distances,trajectory_header_id,i,split);
    
        end    
    end
end

%% Eintragen in Datenbank 

if mongoDB == true

    % Verbindung mit MongoDB
    connectionString = 'mongodb+srv://felixthomas:felixthomas@cluster0.su3gj7l.mongodb.net/';
    conn = mongoc(connectionString, 'robotervermessung');
    
    % Check Verbindung
    if isopen(conn)
        disp('Verbindung erfolgreich hergestellt');
    else
        disp('Verbindung fehlgeschlagen');
    end

    if split == true
    
        for i = 1:1:wdh_teilbahn
    
            filename = 'header_'+trajectory_header_id+string(i)+'.json';
            jsonfile_header = fileread(filename);
            insert(conn,'header',jsonfile_header)
    
            filename = 'data_'+trajectory_header_id+string(i)+'.json';
            jsonfile_data = fileread(filename);
            insert(conn,'data',jsonfile_data);
    
            filename = 'metrics_johnen_'+trajectory_header_id+string(i)+'.json';
            jsonfile_metrics_johnen = fileread(filename);
            insert(conn,'metrics',jsonfile_metrics_johnen);
    
            filename = 'metrics_euclidean_'+trajectory_header_id+string(i)+'.json';
            jsonfile_metrics_euclidean = fileread(filename);
            insert(conn,'metrics',jsonfile_metrics_euclidean);
        end
    
    else
            filename = 'header_'+trajectory_header_id+'.json';
            jsonfile_header = fileread(filename);
            insert(conn,'header',jsonfile_header);
    
            filename = 'data_'+trajectory_header_id+'.json';
            jsonfile_data = fileread(filename);
            insert(conn,'data',jsonfile_data);
    
            filename = 'metrics_johnen_'+trajectory_header_id+'.json';
            jsonfile_metrics_johnen = fileread(filename);
            insert(conn,'metrics',jsonfile_metrics_johnen);
    
            filename = 'metrics_euclidean_'+trajectory_header_id+'.json';
            jsonfile_metrics_euclidean = fileread(filename);
            insert(conn,'metrics',jsonfile_metrics_euclidean)
              
    
    end
end



%% Plots

% if pflag == true
%     figure('Name','Euklidischer Abstand - Zuordnung der Bahnpunkte','NumberTitle','off');
%     hold on
%     grid on
%     box on
%     plot3(trajectory_soll(:,1),trajectory_soll(:,2),trajectory_soll(:,3),'-ko','LineWidth',2)
%     plot3(trajectory_ist(:,1),trajectory_ist(:,2),trajectory_ist(:,3), 'LineWidth',2,'Color','blue')
%     line([trajectory_ist(:,1),xy(:,1)]',[trajectory_ist(:,2),xy(:,2)]',[trajectory_ist(:,3),xy(:,3)]','color',"red")
%     legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
%     xlabel("x [mm]","FontWeight","bold")
%     ylabel("y [mm]","FontWeight","bold")
%     zlabel("z [mm]","FontWeight","bold")
%     hold off
% end

% % 2D Visualisierung der akkumulierten Kosten samt Mapping 
%     figure('Name','SelectiveInterpolationDTW - Kostenkarte und optimaler Pfad','NumberTitle','off');
%     hold on
%     % main=subplot('Position',[0.19 0.19 0.67 0.79]);           
%     imagesc(accdist_selintdtw)
%     colormap("turbo"); % colormap("turbo");
%     colorb = colorbar;
%     colorb.Label.String = 'Akkumulierte Kosten';
%     plot(iy, ix,"-w","LineWidth",1)
%     xlabel('Pfad Y [Index]');
%     ylabel('Pfad X [Index]');
%     axis([min(iy) max(iy) 1 max(ix)]);
%     set(gca,'FontSize',10,'YDir', 'normal');
% 
% % Plot der beiden Bahnen und Zuordnung
%     figure('Name','SelectiveInterpolationDTW - Zuordnung der Bahnpunkte','NumberTitle','off')
%     hold on;
%     grid on;
%     box on;
%     plot3(X_selintdtw(:,1),X_selintdtw(:,2),X_selintdtw(:,3),'-ko', 'LineWidth', 2);
%     plot3(Y_selintdtw(:,1),Y_selintdtw(:,2),Y_selintdtw(:,3),'-bo','LineWidth', 2);
%     for i = 1:1:length(X_selintdtw)
%         line([Y_selintdtw(i,1),X_selintdtw(i,1)],[Y_selintdtw(i,2),X_selintdtw(i,2)],[Y_selintdtw(i,3),X_selintdtw(i,3)],'Color','red')
%     end
%     legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
%     xlabel("x [mm]","FontWeight","bold")
%     ylabel("y [mm]","FontWeight","bold")
%     zlabel("z [mm]","FontWeight","bold")
% % Plot der längsten Distanz
%     [~,j] = max(distances_selintdtw);
%     line([Y_selintdtw(j,1),X_selintdtw(j,1)],[Y_selintdtw(j,2),X_selintdtw(j,2)],[Y_selintdtw(j,3),X_selintdtw(j,3)],'color','red','linewidth',3)





