function fkt_discreteFrechet(trajectory_soll,trajectory_ist,pflag)

if nargin < 3 
    pflag = false; 
end

    X = trajectory_soll;
    Y = trajectory_ist;

    % Anzahl der Punkte und Dimension der Zeitreihen
    M = size(X,1);
    N = size(Y,1);
    
    
    %% Berechnung Frechet-Distanz in 3D
    
    % Berechnung der Frechet-Matrix
    frechet_matrix = zeros(M, N);
    for i = 1:M
        for j = 1:N
            if i == 1 && j == 1
                frechet_matrix(i,j) = fkt_euclDist(1,1,X,Y);                      
            elseif i > 1 && j == 1
                frechet_matrix(i,j) = max( frechet_matrix(i-1, 1), fkt_euclDist(i,1,X,Y)); 
            elseif i == 1 && j > 1
                frechet_matrix(i,j) = max( frechet_matrix(1, j-1), fkt_euclDist(1,j,X,Y));
            elseif i > 1 && j > 1
                frechet_matrix(i,j) = max( min([frechet_matrix(i-1, j), frechet_matrix(i-1, j-1), frechet_matrix(i, j-1)]), fkt_euclDist(i,j,X,Y));
            else
                frechet_matrix(i,j) = inf;
            end
        end
    end
    
    % Maximale Distanz zwischen zwei zugeordneten Punkten
    frechet_dist = frechet_matrix(end,end);
    
    % Finden der Zuordnungssequenz durch Backtracking 
    frechet_path = zeros(N + M + 1, 2);  
    frechet_matrix2 = [ones(1, N + 1) * inf; [ones(M, 1) * inf frechet_matrix]];  
    xi = M + 1;
    yj = N + 1;
    count = 1;
    % Ermittlung der minimalen Kosten pro Schritt durch die Kostenmatrix
    while xi > 2 || yj > 2
        [~, index] = min([frechet_matrix2(xi - 1, yj) frechet_matrix2(xi - 1, yj - 1) frechet_matrix2(xi, yj - 1)]);
        if index == 1
            frechet_path(count, :) = [xi - 1 yj];
            xi = xi - 1;
        elseif index == 2
            frechet_path(count, :) = [xi - 1 yj - 1];
            xi = xi - 1; yj = yj - 1;
        elseif index == 3
            frechet_path(count, :) = [xi yj - 1];
            yj = yj - 1;
        end
        count = count + 1;
    end
    
    frechet_path = flip(frechet_path);                          % Umdrehen 
    lastZero = find(frechet_path(:, 1) == 0, 1, 'last');        % Index der letzten Nullzeile
    frechet_path = frechet_path(lastZero+1:end, :);             % Nullzeilen löschen
    frechet_path = frechet_path -1;                             % Subtrahiere 1 von allen Indizes
    frechet_path = [frechet_path; M N];                         % Füge das letzte Wertepaar hinzu
    
    % Euklidische Distanz zwischen allen Punktpaaren der Zuordnungssequenz
    frechet_distances = sqrt(sum((X(frechet_path(:,1),:) - Y(frechet_path(:,2),:)).^2,2));
    
    frechet_av = mean(frechet_distances);

    frechet_X = X(frechet_path(:,1),:);
    frechet_Y = Y(frechet_path(:,2),:);
    
    %% Plot
    
    if pflag 

     
    % Farben Für Bahnvergleich
    blau = [0 0.4470 0.7410]; % Standard Blau
    rot = [0.78 0 0];
    
    % Für Plots Verfahren
    c1 = [0 0.4470 0.7410];
    c2 = [0.8500 0.3250 0.0980];
    c3 = [0.9290 0.6940 0.1250];
    c4 = [0.4940 0.1840 0.5560];
    c5 = [0.4660 0.6740 0.1880];
    c6 = [0.3010 0.7450 0.9330];
    c7 = [0.6350 0.0780 0.1840];
    
    figure('Color','white','Name','Discrete Frechet Distance')
    hold on
    plot3(X(:,1),X(:,2),X(:,3),Color= c1,LineWidth=1.5,Marker = "o",MarkerFaceColor= c1,MarkerSize=4);
    plot3(Y(:,1),Y(:,2),Y(:,3),Color= rot,LineWidth=1.5,Marker = "square",MarkerFaceColor=rot,MarkerSize=4);
    for j=1:length(frechet_path)
      line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
           [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
           [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
           'color','black');
    end
    view(220, 30)
    legend({'Istbahn','Sollbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
    xlabel("x","FontWeight","bold")
    ylabel("y","FontWeight","bold")
    zlabel("z","FontWeight","bold")
    grid on
    hold off

    % [~,j] = max(frechet_distances);
    % line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
    %        [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
    %        [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
    %        'color','black','linewidth',3);
    % j = length(frechet_path);
    % line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
    %        [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
    %        [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
    %        'color',[0 0.8 0.5],'linewidth',3);
    % j = length(frechet_path)-1;
    % line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
    %        [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
    %        [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
    %        'color',[0.8 0.5 0],'linewidth',3);
    end
    
    %% Variablen in Workspace laden

    assignin('base',"frechet_av",frechet_av)
    assignin('base',"frechet_dist",frechet_dist)
    assignin('base',"frechet_distances",frechet_distances)
    assignin('base',"frechet_path",frechet_path)
    assignin('base',"frechet_matrix",frechet_matrix)
    assignin('base',"frechet_soll",frechet_X)
    assignin('base',"frechet_ist",frechet_Y)
end