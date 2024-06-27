%% Datenabfrage MongoDB 
clear;
% Verbindung mit MongoDB
connectionString = 'mongodb+srv://felixthomas:felixthomas@cluster0.su3gj7l.mongodb.net/';
conn = mongoc(connectionString, 'robotervermessung');

% Check Verbindung
if isopen(conn)
    disp('Verbindung erfolgreich hergestellt');
else
    disp('Verbindung fehlgeschlagen');
end

% Abfrage für Collection "data"
collection = 'data'; 

searchID = 'robot01719160237_3';  

% Query definieren
query = ['{"trajectory_header_id": "', searchID, '"}'];

% Abfrage ausführen
data = find(conn, collection, 'Query', query);

% Verbindung schließen
close(conn);
%%
% Daten Extrahieren
x = cell2mat(data.x_ist); y = cell2mat(data.y_ist); z = cell2mat(data.z_ist);
trajectory_ist = [x;y;z]';
x = cell2mat(data.x_soll); y = cell2mat(data.y_soll); z = cell2mat(data.z_soll);
trajectory_soll = [x;y;z]';
clear x y z

% Test Plot 
figure;
hold on
plot3(trajectory_ist(:,1),trajectory_ist(:,2),trajectory_ist(:,3),'-o',LineWidth=3);
plot3(trajectory_soll(:,1),trajectory_soll(:,2),trajectory_soll(:,3),'-x',LineWidth=3);
legend("Istbahn","Sollbahn");
hold off


%% Berechnung Metriken

pflag = true;
X = trajectory_soll; Y = trajectory_ist;

fkt_discreteFrechet(trajectory_soll,trajectory_ist)
[dtw_distances, dtw_max, dtw_av, dtw_accdist, dtw_X, dtw_Y, path, ix, iy, localdist] = fkt_dtw3d(X,Y,pflag);


pflag = false;
if pflag 

% Plot Frechet-Distanz
    figure('Name','Discrete Frechet Distance')
    hold on
    plot3(X(:,1),X(:,2),X(:,3),'o-b','linewidth',2,'markerfacecolor','b')
    plot3(Y(:,1),Y(:,2),Y(:,3),'o-r','linewidth',2,'markerfacecolor','r')
    for j=1:length(frechet_path)
      line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
           [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
           [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
           'color','black');
    end
    [~,max_index] = max(frechet_distances);
    line([X(frechet_path(max_index,1),1) Y(frechet_path(max_index,2),1)],...
           [X(frechet_path(max_index,1),2) Y(frechet_path(max_index,2),2)],...
           [X(frechet_path(max_index,1),3) Y(frechet_path(max_index,2),3)],...
           'color','black','linewidth',3);
    last_index = length(frechet_path);
    line([X(frechet_path(last_index,1),1) Y(frechet_path(last_index,2),1)],...
           [X(frechet_path(last_index,1),2) Y(frechet_path(last_index,2),2)],...
           [X(frechet_path(last_index,1),3) Y(frechet_path(last_index,2),3)],...
           'color',[0 0.8 0.5],'linewidth',3);
    % j = length(frechet_path)-1;
    % line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
    %        [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
    %        [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
    %        'color',[0.8 0.5 0],'linewidth',3);


% Plot DTW-Standard

end