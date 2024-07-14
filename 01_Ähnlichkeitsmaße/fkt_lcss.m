function [lcss_av, lcss_max, lcss_distances, lcss_accdist, lcss_path, lcss_X, lcss_Y,lcss_score,lcss_epsilon] = fkt_lcss(X,Y,pflag)
    %% Test
    % clear
    % load test_lcss
    % X = trajectories_soll{1};
    % X = trajectories_abb{1}(:,2:4);
    % Y = trajectories_ist{1}(:,2:4);
    % 
    % pflag = 1;
    %%
    M = size(X, 1);
    N = size(Y, 1);
    
    % In tslearn können hier die Beschränkungen von Sakoe & Chiba oder Itakura
    %   als Maske verwendet werden Zeile 1738 ff. --> evtl. noch später implementieren 
    
    mask = zeros(M,N); % keine Maske
    
    % Euklidische Distanz
    [~,eucl_distances,~] = distance2curve(X,Y,'linear');
    
    eucl_max = max(eucl_distances);
    eucl_av = mean(eucl_distances);
    
    % Maximaler Abstand der bei einer Zuordnung möglich ist!
    % MUSS ANGEGEBEN WERDEN --> Möglichkeit: ca. den max. euclidischen Abstand
    lcss_epsilon = eucl_max + 0.5*eucl_max;
    % epsilon = 0.025;
    % epsilon = 0.9;
    
    % Akkumulierte Kostenmatrix aller Bahnpunkte 
    lcss_accdist = lcss_accumulated_matrix(X, Y, lcss_epsilon, mask);
    % Zuordnungssequenz der Bahnpunkte
    lcss_path = return_lcss_path(X, Y, lcss_epsilon, mask, lcss_accdist, M, N);
    % LCSS-Score [0,1] --> 1 = die Bahnen sind nach dem Verfahren identisch!
    lcss_score = double(lcss_accdist(end, end)) / min([M, N]);
    
    % Punkte auf den Bahnen und Distanzen zwischen diesen Punkten
    lcss_X = X(lcss_path(:,1),:);
    lcss_Y = Y(lcss_path(:,2),:);
    lcss_distances = zeros(length(lcss_path),1);
    for i = 1:length(lcss_distances)
        lcss_distances(i) = fkt_euclDist(i,i,lcss_X,lcss_Y); 
    end
    % Maximaler und durschnittlicher Abstand
    lcss_max = max(lcss_distances);
    lcss_av = mean(lcss_distances);

%% Funktionen

% Berechnet die Akkumulierten Kosten
    function acc_cost_mat = lcss_accumulated_matrix(s1, s2, epsilon, mask)    
        l1 = size(s1, 1);
        l2 = size(s2, 1);
        acc_cost_mat = zeros(l1 + 1, l2 + 1);
    
        for i = 2:l1 + 1
            for j = 2:l2 + 1
                if isfinite(mask(i - 1, j - 1)) % isfinite falls Itakura o. Sakoe Chiba noch implementiert wird
                    if fkt_euclDist(i-1, j-1, s1, s2) <= epsilon
                        acc_cost_mat(i, j) = 1 + acc_cost_mat(i - 1, j - 1);
                    else
                        acc_cost_mat(i, j) = max(acc_cost_mat(i, j - 1), acc_cost_mat(i - 1, j));
                    end
                end
            end
        end
    end
    
% Berechnet den Pfad 
    function lcss_path = return_lcss_path(s1, s2, epsilon, mask, acc_cost_mat, sz1, sz2)
     i = sz1;
        j = sz2;
        lcss_path = [];
    
        while i > 0 && j > 0 % && ein entscheidender Unterschied zu DTW
            if isfinite(mask(i, j))
                if fkt_euclDist(i, j, s1, s2) <= epsilon
                    lcss_path = [lcss_path; i, j];
                    i = i - 1;
                    j = j - 1;
                elseif acc_cost_mat(i, j + 1) > acc_cost_mat(i + 1, j)
                    i = i - 1;
                else
                    j = j - 1;
                end
            else % Wird nie durchlaufen ohne Maske
                if i > 1 && acc_cost_mat(i - 1, j) == acc_cost_mat(i, j)
                    i = i - 1;
                else
                    j = j - 1;
                end
            end
        end
    
        lcss_path = flip(lcss_path, 1) ;
        
    end
    %%
if pflag 
%% Kostenmatrix

    % Akkumulierte Kostenmatrix und Pfad plotten

    % Plot der akkumulierten Kostenmatrix
    figure;
    imagesc(lcss_accdist);
    colormap('sky');
    colorbar;
    hold on;
    
    % % Pfad auf der akkumulierten Kostenmatrix plotten
    % for k = 1:length(lcss_path)
    %     i = lcss_path(k, 1); 
    %     j = lcss_path(k, 2); 
    %     plot(j, i, 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g');
    %     plot(j, i, 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
    % end
    
    % Liniensegmenten für den Pfad zeichnen
    for k = 1:length(lcss_path)-1
        i1 = lcss_path(k, 1);
        j1 = lcss_path(k, 2);
        i2 = lcss_path(k+1, 1);
        j2 = lcss_path(k+1, 2);
        plot([j1 j2], [i1 i2],'-k', 'LineWidth', 2.5);
    end
    
    title('Accumulated Cost Matrix with LCSS Path');
    xlabel('s2 Index');
    ylabel('s1 Index');
    
    % Setzt die Achsen so, dass der Ursprung unten links liegt
    set(gca, 'YDir', 'normal');

%% Plot der dem Pfad zugehörigen Punkte
    figure;
    hold on;
    grid on;
    
    % Darstellung der ursprünglichen Zeitreihen
    plot3(X(:,1), X(:,2), X(:,3), '-bx', 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', 'b');
    plot3(Y(:,1), Y(:,2), Y(:,3), '-rx', 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', 'b');
    
    % Darstellung der Punkte und Verbindungslinien
    plot3(lcss_X(:,1), lcss_X(:,2), lcss_X(:,3), '-go', 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', 'b');
    plot3(lcss_Y(:,1), lcss_Y(:,2), lcss_Y(:,3), '-ko', 'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', 'r');
    for k = 1:length(lcss_path)    
        % Verbindungslinien
        plot3([lcss_X(k,1), lcss_Y(k,1)], [lcss_X(k,2), lcss_Y(k,2)], [lcss_X(k,3), lcss_Y(k,3)], 'k-');
    end
    
    j = length(lcss_path);
    plot3(Y(1,1), Y(1,2), Y(1,3), '-bx', 'LineWidth', 1.5, 'MarkerSize', 10, 'MarkerFaceColor', 'b');
    line([X(lcss_path(j,1),1) Y(lcss_path(j,2),1)],...
           [X(lcss_path(j,1),2) Y(lcss_path(j,2),2)],...
           [X(lcss_path(j,1),3) Y(lcss_path(j,2),3)],...
           'color',[0 0.8 0.5],'linewidth',3);
    
    title('Matched Points with LCSS Path');
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    legend({'s1 Points', 's2 Points', 'Matching Lines'}, 'Location', 'best');
    view(2);
end

end