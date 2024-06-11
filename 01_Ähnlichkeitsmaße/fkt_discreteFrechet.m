function fkt_discreteFrechet(trajectory_soll,trajectory_ist,pflag)

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
    
    %% Plot
    
    if pflag 
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
    [~,j] = max(frechet_distances);
    line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
           [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
           [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
           'color','black','linewidth',3);
    j = length(frechet_path);
    line([X(frechet_path(j,1),1) Y(frechet_path(j,2),1)],...
           [X(frechet_path(j,1),2) Y(frechet_path(j,2),2)],...
           [X(frechet_path(j,1),3) Y(frechet_path(j,2),3)],...
           'color',[0 0.8 0.5],'linewidth',3);
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

end