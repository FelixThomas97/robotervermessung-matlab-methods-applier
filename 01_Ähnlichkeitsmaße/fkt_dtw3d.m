function [distances, maxDistance, averageDistance, accdist, dtw_X, dtw_Y, path, ix, iy, localdist] = fkt_dtw3d(X,Y,pflag)

M = length(X);
N = length(Y);

%% Sowohl Zeilen als Spaltenvektoren verarbeiten

% [row,M]=size(X);
% if (row > M) 
%     M=row; 
%     r=r'; 
% end
% [row,N]=size(Y); 
% if (row > N) 
%     N=row; 
%     t=t'; 
% end

%% Lokale und akkumulierte Distanzen berechen

% Lokale Kosten
localdist = zeros(length(X),length(Y));
MaxLocalCost = 0;
MinLocalCost = Inf;
for i = 1:length(X)
    for j = 1:length(Y)
        localdist(i,j) =  fkt_euclDist(i,j,X,Y);
        if localdist(i, j) > MaxLocalCost
            MaxLocalCost = localdist(i, j);
        end
        if localdist(i, j) < MinLocalCost
            MinLocalCost = localdist(i, j);
        end
    end
end

% Akkumulierte Kosten
accdist=zeros(size(localdist));                 % bei Johnen so!
% accdist(1,1)=localdist(1,1);                  % bei anderen Varianten so!
for i = 2:length(X)
    accdist(i,1) = accdist(i-1,1) + localdist(i,1);
end
for j = 2:length(Y)
    accdist(1,j) = accdist(1,j-1) + localdist(1,j);
end
for i = 2:length(X)
    for j = 2:length(Y)
        accdist(i,j) = localdist(i,j) + min([accdist(i-1,j), accdist(i,j-1), accdist(i-1,j-1)]);
    end
end

%% DTW-Pfad berechnen

path = [M N];                                 
while i > 1 || j > 1
    if i == 1
        j = j-1;
    elseif j == 1
        i = i-1;
    else
        mini = min([accdist(i-1,j), accdist(i,j-1), accdist(i-1,j-1)]);
        if mini == accdist(i-1,j)              
            i = i-1;
        elseif mini == accdist(i,j-1)
            j = j-1;
        else
            i = i-1;
            j = j-1;
        end
    end
    path = [i, j; path];   
end

ix = path(:,1);
iy = path(:,2);
dtw_X = X(ix,:);
dtw_Y = Y(iy,:);

% Distanzen zwischen den interpolierten Bahnen
distances = zeros(length(dtw_X),1);
for i = 1:1:length(dtw_X)
    dist = fkt_euclDist(i,i,dtw_X,dtw_Y);
    distances(i,1) = dist;
end
% maximale und mittlere Distanz 
maxDistance = max(distances);
averageDistance = mean(distances);

%% Plots

if pflag

%% 3D - Oberfläche der Kostenmatrix
    % figure('Name','DTW - Akkumulierte Distanz','NumberTitle','off');
    % surf(accdist)
    % hold on           
    % imagesc(accdist)
    % colormap("jet");
    % xlabel('Pfad Y [Index]');
    % ylabel('Pfad X [Index]');
    % zlabel('Akkumulierte Kosten')
    % axis padded;
    % hold off
    
%% 2D - Kostendarstellung und Warping Pfad
    figure('Name','DTW - Kostenkarte und Mapping ','NumberTitle','off');
    hold on
    % main=subplot('Position',[0.19 0.19 0.67 0.79]);           
    imagesc(accdist)
    colormap("turbo"); % colormap("jet");
    colorb = colorbar;
    colorb.Label.String = 'Akkumulierte Kosten';
    % --------To-Do: Colorbar normen auf 1----------
    % set(colorb,'FontSize',10,'YTickLabel','');
    % set(colorb,'FontSize',10;
    % hold on
    plot(iy, ix,"-w","LineWidth",1.5)
    xlabel('Pfad Y [Index]');
    ylabel('Pfad X [Index]');
    axis([min(iy) max(iy) 1 max(ix)]);
    set(gca,'FontSize',10,'YDir', 'normal');
    hold off

%% 3D - Visualierung der Zuordnung der Bahnpunkte
    figure('Name','DTW - Zuordnung der Bahnpunkte','NumberTitle','off')
    hold on;
    grid on;
    box on;
    plot3(dtw_X(:,1),dtw_X(:,2),dtw_X(:,3),'-ko', 'LineWidth', 2);
    plot3(dtw_Y(:,1),dtw_Y(:,2),dtw_Y(:,3),'b','LineWidth', 2);
    for i = 1:1:length(dtw_X)
        line([dtw_Y(i,1),dtw_X(i,1)],[dtw_Y(i,2),dtw_X(i,2)],[dtw_Y(i,3),dtw_X(i,3)],'Color','red')
    end
    legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
    xlabel("x [mm]","FontWeight","bold")
    ylabel("y [mm]","FontWeight","bold")
    zlabel("z [mm]","FontWeight","bold")
    hold off
%% Vergleich von Ist und Sollbahn
    % figure('Name','Vergleich zweier Signale', 'NumberTitle','off');     
    % subplot(1,2,1);
    % hold on;
    % plot3(X(:,1),X(:,2),X(:,3),'-bo', 'LineWidth', 1);
    % plot3(Y(:,1),Y(:,2),Y(:,3),'-ro','LineWidth', 1);
    % plot3(X(1,1), X(1,2), X(1,3), 'k','Marker','o', 'LineWidth', 10);
    % hold off;
    % axis padded;
    % grid on;
    % legend('signal 1','signal 2');
    % xlabel('x');
    % ylabel('y');
    % zlabel('z');
    % view(3);
    % 
    % subplot(1,2,2);
    % hold on;
    % plot3(dtw_X(:,1),dtw_X(:,2),dtw_X(:,3),'-bo', 'LineWidth', 1);
    % plot3(dtw_Y(:,1),dtw_Y(:,2),dtw_Y(:,3),'-ro','LineWidth', 1);
    % hold off;
    % grid on;
    % legend('signal 1','signal 2');
    % title('Original signals');
    % xlabel('x');
    % ylabel('y');
    % zlabel('z');
    % view(3);

%% 3D - Visualierung der Zuordnung der Bahnpunkte
    % figure('Name','SelectIntDistance - Zuordnung der Bahnpunkte','NumberTitle','off')
    % hold on;
    % plot3(dtw_X(:,1),dtw_X(:,2),dtw_X(:,3),'-ko', 'LineWidth', 1);
    % plot3(dtw_Y(:,1),dtw_Y(:,2),dtw_Y(:,3),'-ro','LineWidth', 1);
    % for i = 1:1:length(dtw_X)
    %     line([dtw_Y(i,1),dtw_X(i,1)],[dtw_Y(i,2),dtw_X(i,2)],[dtw_Y(i,3),dtw_X(i,3)],'Color','red')
    % end
    % hold off;
    % xlim auto
    % ylim auto
    % legend({'Soll-Bahn','Ist-Bahn','Abweichung'},'Location','northeast')
    % fontsize(gca,20,"pixels")
    % zlim auto;
    % box on
    % grid on
    % view(3)
    % xlabel("x [cm]","FontWeight","bold")
    % ylabel("y [cm]","FontWeight","bold")
    % zlabel("z [cm]","FontWeight","bold")
end

%% Funktionen

% Berechnung des eukl. Abstands zwischen zwei Punkten von pathX und Y
function distance = fkt_euclDist(i, j, pathX, pathY)

    distance = norm(pathX(i,:) - pathY(j,:));