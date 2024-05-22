%% Laden der Daten
clear;
%%%%%%%%%%%%%%%%%%%%%% Bereits hinzugefügte Daten %%%%%%%%%%%%%%%%%%%%%%%%%
% 'iso_diagonal_v1000_15x.xlsx' ---> robot01716299489i
% 'iso_diagonal_v2000_15x.xlsx' ---> robot01716299123i

filename_excel = 'iso_diagonal_v1000_15x.xlsx';  
filename_json = 'data_ist';   % .json wird später hinzugefügt 
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
    header_data.recording_date = "2024-05-16T16:37:00.241866";
    header_data.real_robot = "true";
    header_data.number_of_points_ist = [];      % leere Zellen werden später gefüllt
    header_data.number_of_points_soll = [];     % leere Zellen werden später gefüllt
    header_data.sample_frequency_ist = [];      % leere Zellen werden später gefüllt
    header_data.source = "matlab";

    % Dateneingabe für Sollbahn
    home = [133 -645 1990];
    laenge = 630;
    num_points_per_segment = 50;  % Anzahl der Interpolationspunkte pro Teilbahn
    defined_velocity = 1000;
    
    % Besteht Gesamtbahn aus mehreren Bahnen und soll zerlegt werden
    split = true; 

    % Welche Metriken sollen berechnet werden
    dtw_johnen = true;
    euclidean = true; 
    frechet = false;
    lcss = false;

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

% % Generiere json File für die interpolierte Sollbahn
% filename = 'data_soll.json';  
generate_trajectory_struct(trajectory_soll, defined_velocity);

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

    struct_header = cell(1,wdh_teilbahn);
    struct_data = cell(1,wdh_teilbahn);

    for i = 1:1:wdh_teilbahn

        if i < wdh_teilbahn
            teilbahnen{i} = data_ist(index_teilbahnen(i):index_teilbahnen(i+1)-1,:);
        else
            teilbahnen{i} = data_ist(index_teilbahnen(i):end,:);
        end
        
        % Ist Daten
        ist_file_to_struct(teilbahnen{i},col_names,i,split);
        struct_data{i} = data_ist_part;
        % Header Daten
        generate_header_struct(trajectory_header_id, header_data, timestamp_ist,num_sample_soll, i,split);
        struct_header{i} = header_data;
    
        % Ist Daten und Soll Daten zusammenfügen
        fields_soll = fieldnames(data_soll);
        for j = 1:length(fields_soll)
            struct_data{i}.(fields_soll{j}) = data_soll.(fields_soll{j});
        end

    end

else % Bahn soll nicht zerlegt werden

    % Ist Daten
    ist_file_to_struct(data_ist,col_names,i,split);
    struct_data = data_ist_part;  
    % Header Daten
    generate_header_struct(trajectory_header_id, header_data, timestamp_ist, num_sample_soll, i,split);
    struct_header = header_data;
    
    % Ist Daten und Soll Daten zusammenfügen
    fields_soll = fieldnames(data_soll);
    for j = 1:length(fields_soll)
        struct_data.(fields_soll{j}) = data_soll.(fields_soll{j});
    end

    % ist_file_to_json(filename_json,data_ist,col_names,i,split)
    % generate_header(trajectory_header_id, header_data, timestamp_ist, num_sample_soll, i,split);
    % file1 = 'data_ist.json';
    % file2 = 'data_soll.json';
    % combined_file = 'data_'+trajectory_header_id+'.json';
    % merge_json_files(file1, file2, combined_file);

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
        [selintdtw_distances, selintdtw_max, selintdtw_av,...
            selintdtw_accdist, selintdtw_X, selintdtw_Y, selintdtw_path, ix, iy]...
            = fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
        % Generiere Metrics-Datei
        generate_dtwjohnen_struct(trajectory_header_id,selintdtw_max, selintdtw_av, ...
            selintdtw_distances,selintdtw_X,selintdtw_Y,selintdtw_accdist,selintdtw_path,i,split);
        
        struct_johnen = metrics_johnen;

    else 

        struct_johnen = cell(1,wdh_teilbahn);
        
        for i = 1:1:wdh_teilbahn

            trajectory_ist_table = teilbahnen{i}(:, 2:4);
            trajectory_ist = table2array(trajectory_ist_table);

            % Berechnung DTW Johnen
            [selintdtw_distances, selintdtw_max, selintdtw_av, ...
                selintdtw_accdist, selintdtw_X, selintdtw_Y, selintdtw_path, ix, iy] = ...
                fkt_selintdtw3d(trajectory_soll,trajectory_ist,pflag);
            % Generiere Metrics Datei
            generate_dtwjohnen_struct(trajectory_header_id,selintdtw_max, selintdtw_av, ...
                selintdtw_distances,selintdtw_X,selintdtw_Y,selintdtw_accdist,selintdtw_path,i,split);

            struct_johnen{i} = metrics_johnen;
        end
    end
end

%% Berechnung der Euklidschen Distanz 

if euclidean == true

    if split == false
    
        [eucl_intepolation,eucl_distances,eucl_t] = distance2curve(trajectory_ist,trajectory_soll,'linear');
        generate_euclidean_struct(trajectory_soll, eucl_intepolation, eucl_distances,trajectory_header_id,i,split);

        struct_euclidean = metrics_euclidean;
    
    else 

        struct_euclidean = cell(1,wdh_teilbahn);

        for i= 1:1:wdh_teilbahn
    
            trajectory_ist_table = teilbahnen{i}(:, 2:4);
            trajectory_ist = table2array(trajectory_ist_table);
    
            [eucl_intepolation,eucl_distances,eucl_t] = distance2curve(trajectory_ist,trajectory_soll,'linear');
            generate_euclidean_struct(trajectory_soll, eucl_intepolation, eucl_distances,trajectory_header_id,i,split);

            struct_euclidean{i} = metrics_euclidean;
    
        end    
    end
end

%% Eintragen in Datenbank 

mongoDB = true;

if mongoDB == true

    trajectory_header_id = string(trajectory_header_id);

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
            
             % Upload in Datenbank
            insert(conn, 'header', struct_header{i});
            insert(conn, 'data', struct_data{i});
            insert(conn, 'metrics', struct_johnen{i});
            insert(conn, 'metrics', struct_euclidean{i});
        end

    else
             % Upload in Datenbank
            insert(conn, 'header', struct_header);
            insert(conn, 'data', struct_data);
            insert(conn, 'metrics', struct_johnen);
            insert(conn, 'metrics', struct_euclidean);   
    end
end



%% Plots

if pflag == true
    figure('Name','Euklidischer Abstand - Zuordnung der Bahnpunkte','NumberTitle','off');
    hold on
    grid on
    box on
    plot3(trajectory_soll(:,1),trajectory_soll(:,2),trajectory_soll(:,3),'-ko','LineWidth',2)
    plot3(trajectory_ist(:,1),trajectory_ist(:,2),trajectory_ist(:,3), 'LineWidth',2,'Color','blue')
    line([trajectory_soll(:,1),eucl_intepolation(:,1)]',[trajectory_soll(:,2),eucl_intepolation(:,2)]',[trajectory_soll(:,3),eucl_intepolation(:,3)]','color',"red")
    legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
    xlabel("x [mm]","FontWeight","bold")
    ylabel("y [mm]","FontWeight","bold")
    zlabel("z [mm]","FontWeight","bold")
    hold off


% 2D Visualisierung der akkumulierten Kosten samt Mapping 
    figure('Name','SelectiveInterpolationDTW - Kostenkarte und optimaler Pfad','NumberTitle','off');
    hold on
    % main=subplot('Position',[0.19 0.19 0.67 0.79]);           
    imagesc(selintdtw_accdist)
    colormap("turbo"); % colormap("turbo");
    colorb = colorbar;
    colorb.Label.String = 'Akkumulierte Kosten';
    plot(iy, ix,"-w","LineWidth",1)
    xlabel('Pfad Y [Index]');
    ylabel('Pfad X [Index]');
    axis([min(iy) max(iy) 1 max(ix)]);
    set(gca,'FontSize',10,'YDir', 'normal');

% Plot der beiden Bahnen und Zuordnung
    figure('Name','SelectiveInterpolationDTW - Zuordnung der Bahnpunkte','NumberTitle','off')
    hold on;
    grid on;
    box on;
    plot3(selintdtw_X(:,1),selintdtw_X(:,2),selintdtw_X(:,3),'-ko', 'LineWidth', 2);
    plot3(selintdtw_Y(:,1),selintdtw_Y(:,2),selintdtw_Y(:,3),'-bo','LineWidth', 2);
    for i = 1:1:length(selintdtw_X)
        line([selintdtw_Y(i,1),selintdtw_X(i,1)],[selintdtw_Y(i,2),selintdtw_X(i,2)],[selintdtw_Y(i,3),selintdtw_X(i,3)],'Color','red')
    end
    legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
    xlabel("x [mm]","FontWeight","bold")
    ylabel("y [mm]","FontWeight","bold")
    zlabel("z [mm]","FontWeight","bold")
% Plot der längsten Distanz
    [~,j] = max(selintdtw_distances);
    line([selintdtw_Y(j,1),selintdtw_X(j,1)],[selintdtw_Y(j,2),selintdtw_X(j,2)],[selintdtw_Y(j,3),selintdtw_X(j,3)],'color','red','linewidth',3)

end
%% testtest
% 
% clear
% 
% filename = 'metrics_johnen_robot0171624288811.json';
% 
% jsonfile = fileread(filename);
% 
% struct = jsondecode(jsonfile);
% 
% a = struct.dtw_distances*1000;
% 
% X = struct.dtw_X;
% Y = struct.dtw_Y;
% 
% % Plot der beiden Bahnen und Zuordnung
%     figure('Name','SelectiveInterpolationDTW - Zuordnung der Bahnpunkte','NumberTitle','off')
%     hold on;
%     grid on;
%     box on;
%     plot3(X(:,1),X(:,2),X(:,3),'-ko', 'LineWidth', 2);
%     plot3(Y(:,1),Y(:,2),Y(:,3),'-bo','LineWidth', 2);
%     for i = 1:1:length(X)
%         line([Y(i,1),X(i,1)],[Y(i,2),X(i,2)],[Y(i,3),X(i,3)],'Color','red')
%     end
%     legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
%     xlabel("x [mm]","FontWeight","bold")
%     ylabel("y [mm]","FontWeight","bold")
%     zlabel("z [mm]","FontWeight","bold")
% % Plot der längsten Distanz
%     [~,j] = max(a);
%     line([Y(j,1),X(j,1)],[Y(j,2),X(j,2)],[Y(j,3),X(j,3)],'color','red','linewidth', 5)
% 
% 
% 
% 
