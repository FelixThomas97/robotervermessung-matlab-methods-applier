%% Laden der Trajektorien 

clear all

% load square1.mat
% load iso_path_A_1.mat
load iso_path_B_real_1.mat

% load('robotdata_ist.mat');
% load('robotdata_soll.mat');
% 
% data_odom = table2array(robotdata_ist);
% data_soll = table2array(robotdata_soll);

figureson = 0;

% X = pathX'; 
% Y = pathY';

% X = data_soll;
% Y = data_odom;

X = soll; 
Y = ist;

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
        localdist(i,j) =  euclDist(i,j,X,Y);
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

i = length(X);
j = length(Y);
path2 = [M N];                                 
while i > 1 || j > 1
    if i == 1
        j = j-1;
    elseif j == 1
        i = i-1;
    else
        mini = min([localdist(i-1,j), localdist(i,j-1), localdist(i-1,j-1)]);
        if mini == localdist(i-1,j)              
            i = i-1;
        elseif mini == localdist(i,j-1)
            j = j-1;
        else
            i = i-1;
            j = j-1;
        end
    end
    path2 = [i, j; path2];   
end


ix = path(:,1);
iy = path(:,2);
dtwX = X(ix,:);
dtwY = Y(iy,:);

% Distanzen zwischen den interpolierten Bahnen
distances = zeros(length(dtwX),1);
for i = 1:1:length(dtwX)
    dist = euclDist(i,i,dtwX,dtwY);
    distances(i,1) = dist;
end
% maximale und mittlere Distanz 
maxDistance = max(distances)
averageDistance = mean(distances)

%% Plotten

if figureson

    figure('Name','DTW - Akkumulierte Distanz','NumberTitle','off');
    surf(accdist)
    hold on           
    imagesc(accdist)
    colormap("jet");
    xlabel('Pfad Y [Index]');
    ylabel('Pfad X [Index]');
    zlabel('Akkumulierte Kosten')
    axis padded;
    
    figure('Name','DTW - Kostenkarte und Mapping ','NumberTitle','off');
    hold on
    % main=subplot('Position',[0.19 0.19 0.67 0.79]);           
    imagesc(accdist)
    colormap("jet"); % colormap("turbo");
    colorb = colorbar;
    colorb.Label.String = 'Akkumulierte Kosten';
    % --------To-Do: Colorbar normen auf 1----------
    % set(colorb,'FontSize',10,'YTickLabel','');
    % set(colorb,'FontSize',10;
    % hold on
    plot(iy, ix,"-w","LineWidth",1)
    xlabel('Pfad Y [Index]');
    ylabel('Pfad X [Index]');
    axis([min(iy) max(iy) 1 max(ix)]);
    set(gca,'FontSize',10,'YDir', 'normal');
    
    
    figure('Name','Vergleich zweier Signale', 'NumberTitle','off');     
    subplot(1,2,1);
    hold on;
    plot3(X(:,1),X(:,2),X(:,3),'-bo', 'LineWidth', 1);
    plot3(Y(:,1),Y(:,2),Y(:,3),'-ro','LineWidth', 1);
    plot3(X(1,1), X(1,2), X(1,3), 'k','Marker','o', 'LineWidth', 10);
    hold off;
    axis padded;
    grid on;
    legend('signal 1','signal 2');
    xlabel('x');
    ylabel('y');
    zlabel('z');
    view(3);
    
    subplot(1,2,2);
    hold on;
    plot3(dtwX(:,1),dtwX(:,2),dtwX(:,3),'-bo', 'LineWidth', 1);
    plot3(dtwY(:,1),dtwY(:,2),dtwY(:,3),'-ro','LineWidth', 1);
    hold off;
    grid on;
    legend('signal 1','signal 2');
    title('Original signals');
    xlabel('x');
    ylabel('y');
    zlabel('z');
    view(3);
end

%%
% 3D - Visualierung der Zuordnung der Bahnpunkte
    figure('Name','SelectIntDistance - Zuordnung der Bahnpunkte','NumberTitle','off')
    hold on;
    plot3(dtwX(:,1),dtwX(:,2),dtwX(:,3),'-ko', 'LineWidth', 1);
    plot3(dtwY(:,1),dtwY(:,2),dtwY(:,3),'-ro','LineWidth', 1);
    for i = 1:1:length(dtwX)
        line([dtwY(i,1),dtwX(i,1)],[dtwY(i,2),dtwX(i,2)],[dtwY(i,3),dtwX(i,3)],'Color','red')
    end
    hold off;
    xlim auto
    ylim auto
    legend({'Soll-Bahn','Ist-Bahn'},'Location','northeast')
    fontsize(gca,20,"pixels")
    zlim auto;
    box on
    grid on
    view(3)
    xlabel("x [cm]","FontWeight","bold")
    ylabel("y [cm]","FontWeight","bold")
    zlabel("z [cm]","FontWeight","bold")


%% Funktionen

% Berechnung des eukl. Abstands zwischen zwei Punkten von pathX und Y
function distance = euclDist(i, j, pathX, pathY)

    distance = norm(pathX(i,:) - pathY(j,:));
end

