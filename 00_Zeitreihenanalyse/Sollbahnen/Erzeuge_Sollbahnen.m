%% Berechnung von Soll-Bahnen für den Bahnvergleich

clear; 

% load Loop11isodiagonal.mat
load Loop5500hzkreis.mat
% load Loop4500hzrandom.mat

data_ist = table2array(Loop5500hzkreis);

x_ist = data_ist(:,1);
y_ist = data_ist(:,2);
z_ist = data_ist(:,3);

% Timestamp entweder Spalte 7 oder 8
t_ist = data_ist(:,8);

% Auswahl der gemessenen Bahn
isodiagonal = 0;
kreis = 1; 
random = 0;

% plot3(x_ist,y_ist,z_ist,'LineWidth',3,'Color','red');
% axis equal


%% FÜR ISO-DIAGONALE BAHN
if isodiagonal
    
% Manuelle Eingabe der Positionen und Bahnlänge aus Rapid-Code.
    home = [133 -645 1990];
    laenge = 630;
    % anzahl_punkte = length(data_ist);
    anzahl_punkte = 300;

    position(1,:) = home;
    position(2,:) = home + [0 -laenge 0];
    position(3,:) = home + [laenge -laenge -laenge];
    position(4,:) = home + [laenge 0 -laenge];
    position(5,:) = home;

    % figure;
    % plot3(position(:,1),position(:,2),position(:,3));

% Für die gleichmäßige Verteilung der Punkte
    laenge_ab = norm(position(1,:)-position(2,:));
    laenge_bc = norm(position(3,:)-position(2,:));
    laenge_gesamt = 2*laenge_ab+2*laenge_bc;
    anteil_ab = laenge_ab/laenge_gesamt;
    anteil_bc = laenge_bc/laenge_gesamt;
    anzahl_punkte_ab = round(anzahl_punkte*anteil_ab);
    anzahl_punkte_bc = round(anzahl_punkte*anteil_bc);

% Berechnung der zusätzlichen Punkte entlang der Geraden zwischen den Eckpunkten.
    interpolierte_punkte = [];
    for i = 2:1:size(position, 1)
% Lineare Interpolation zwischen den Eckpunkten, sodass gleiche Abstände zwischen den Punkten vorliegen.
        if mod(i,2)==1 
            x_interp = linspace(position(i-1, 1), position(i, 1), anzahl_punkte_bc+1)';
            y_interp = linspace(position(i-1, 2), position(i, 2), anzahl_punkte_bc+1)';
            z_interp = linspace(position(i-1, 3), position(i, 3), anzahl_punkte_bc+1)';
        else
            x_interp = linspace(position(i-1, 1), position(i, 1), anzahl_punkte_ab+1)';
            y_interp = linspace(position(i-1, 2), position(i, 2), anzahl_punkte_ab+1)';
            z_interp = linspace(position(i-1, 3), position(i, 3), anzahl_punkte_ab+1)'; 
        end      
% Die interpolierten Punkte werden hinzugefügt (der letzte Punkt entspricht bereits dem nächsten Eckpunkt).
        interpolierte_punkte = [interpolierte_punkte; [x_interp(1:end-1), y_interp(1:end-1), z_interp(1:end-1)]];
    end
    
% Alle Punkte einschließlich des letzten vorgegebenen Bahnpunktes, da dieser durch obige Rechnung nicht mehr inkludiert wird --> da: end-1
    alle_punkte = [interpolierte_punkte; position(end,:)];
    bahn_ist = [data_ist(:,1) data_ist(:,2) data_ist(:,3)];
    bahn_soll = alle_punkte;
    % bahn_soll(end,:)=[];
    clear alle_punkte

% Berechnung und Plot des euklidischen Abstands zwischen Ist- und Sollbahn
    [xy,distance,t] = distance2curve(bahn_soll,bahn_ist,'linear');
    figure('Name','Euklidischer Abstand - Zuordnung der Bahnpunkte','NumberTitle','off');
    hold on
    grid on
    box on
    plot3(bahn_soll(:,1),bahn_soll(:,2),bahn_soll(:,3),'-ko','LineWidth',2)
    plot3(x_ist,y_ist,z_ist, 'LineWidth',2,'Color','blue')
    line([x_ist,xy(:,1)]',[y_ist,xy(:,2)]',[z_ist,xy(:,3)]','color',"red")
    legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
    xlabel("x [mm]","FontWeight","bold")
    ylabel("y [mm]","FontWeight","bold")
    zlabel("z [mm]","FontWeight","bold")
    hold off

    eucldist_av = mean(distance)
    eucldist_max = max(distance)


% Daten für DTW bereinigen --> nicht die ganze Bahn!
    for j=1:1:length(bahn_ist)
    distance = norm(bahn_soll(1,:)-bahn_ist(j,:));
        if  distance > 0.5
            bahn_ist(j,:)=NaN;
        else
            break;
        end
    end

    bahn_ist = bahn_ist(~any(isnan(bahn_ist),2),:);

    for i = 1:1:length(bahn_soll)-1
        if bahn_soll(end-i,1) < bahn_ist(end,1)
            bahn_soll(end-i,:) = NaN;
        else
            break;
        end
    end
    
    bahn_soll = bahn_soll(~any(isnan(bahn_soll),2),:);
    % Entfernen der Home Position am Ende!
    bahn_soll(end,:)=[];
    
% Berechnung und Plot DTW (Zeit fehlt noch)
    pflag = 1;
    [dtw_distances, dtw_max, dtw_av, dtwaccdist, dtw_X, dtw_Y, path, ix, iy] = fkt_dtw3d(bahn_soll,bahn_ist,pflag);

    dtw_av
    dtw_max
% Berechnung und Plot Selective Interpolation DTW (Zeit fehlt noch)
    [selintdtw_distances, selintdtw_max, selintdtw_av, selintdtw_accdist, selintdtw_X, selintdtw_Y, selintdtw_path, ix, iy] = fkt_selintdtw3d(bahn_soll, bahn_ist,pflag);

    selintdtw_av
    selintdtw_max

% Plot der interpolierten Soll-Bahn
    figure('Name','Plot der interpolierten Soll-Bahn','NumberTitle','off');
    plot3(bahn_soll(:, 1), bahn_soll(:, 2), bahn_soll(:, 3), 'b.-', 'MarkerSize', 10);
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('Interpolierte Bahn');
    hold off;

end
 
% DTW Problem visualiesiert ... bereinigen! 
 
% figure;
% plot3(bahn_ist(:,1), bahn_ist(:,2), bahn_ist(:,3))
% hold on
% plot3(bahn_ist(1,1), bahn_ist(1,2), bahn_ist(1,3), '*b')
% plot3(bahn_ist(1651,1), bahn_ist(1651,2), bahn_ist(1651,3), '*r')
% plot3(bahn_ist(1500,1), bahn_ist(1500,2), bahn_ist(1500,3), '*g')
% plot3(bahn_ist(3000,1), bahn_ist(3000,2), bahn_ist(3000,3), '*y')
% plot3(bahn_ist(end,1), bahn_ist(end,2), bahn_ist(end,3), '*k')


%% FÜR KREIS BAHN

if kreis

% Manuelle Eingabe der Positionen und Bahnlänge aus Rapid-Code.
    home = [133 -645 1990];
    laenge = 630;
% Die Anzahl der Punkte wird nach der Berechnung etwa auf 3/4 der angebenen Anzahl reduziert !
    % anzahl_punkte = length(data_ist);
    anzahl_punkte = 5000;
    bahn_ist = [data_ist(:,1) data_ist(:,2) data_ist(:,3)];

    position(1,:) = home;
    position(2,:) = home + [0 -laenge/2 0];
    position(3,:) = home + [laenge/2 -laenge -laenge/2];
    position(4,:) = home + [laenge -laenge/2 -laenge];
    position(5,:) = home + [laenge/2 0 -laenge/2];
    position(6,:) = home + [0 -laenge/2 0]; 

% Löschen der Punkte die nicht zur Kreisberechnung gehören
    for j=1:1:length(bahn_ist)
    distance = norm(position(2,:)-bahn_ist(j,:));
        if  distance > 0.2
            bahn_ist(j,:)=NaN;
        else
            break;
        end
    end
% Lösche alle Reihen die NaN sind
    bahn_ist = bahn_ist(~any(isnan(bahn_ist),2),:);    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Kreisberechnung des ersten Kreisabschnittsüber drei Punkte
    p1 = position(2,:);
    p2 = position(3,:);
    p3 = position(4,:);

    [center,rad,n1,n2] = circlefit3d(p1,p2,p3);

    winkel = linspace(0,2*pi,anzahl_punkte)';
    x_soll = center(:,1) + sin(winkel)*rad.*n1(:,1)+cos(winkel)*rad.*n2(:,1);
    y_soll = center(:,2) + sin(winkel)*rad.*n1(:,2)+cos(winkel)*rad.*n2(:,2);
    z_soll = center(:,3) + sin(winkel)*rad.*n1(:,3)+cos(winkel)*rad.*n2(:,3);
    bahn_soll_kreis_1 = [x_soll y_soll z_soll];
    clear x_soll y_soll z_soll

% Bahn am richtigen Punkt anfangen lassen und korrekte Laufrichtung der Bahn (für DTW wichtig)
    abstaende = sqrt(sum((bahn_soll_kreis_1 - p1).^2, 2));
    [min_abstand, index] = min(abstaende);
    flip1 = flip(bahn_soll_kreis_1(1:index-1,:));
    flip2 = flip(bahn_soll_kreis_1(index+1:end,:));
    bahn_soll_kreis_1 = [bahn_soll_kreis_1(index,:); flip1; flip2];

% Datenbereinigung der zuviel berechneten Punkte
    for i = 1:1:length(bahn_soll_kreis_1)
        y_lim = abs(p1(:,2));
        if abs(bahn_soll_kreis_1(i,2)) < y_lim
            bahn_soll_kreis_1(i,:) = NaN;
        end
    end
% Lösche alle Reihen die NaN sind
    bahn_soll_kreis_1 = bahn_soll_kreis_1(~any(isnan(bahn_soll_kreis_1),2),:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Kreisberechnung des zweiten Kreisabschnittsüber drei Punkte
    p1 = position(4,:);
    p2 = position(5,:);
    p3 = position(6,:);

    [center,rad,n1,n2] = circlefit3d(p1,p2,p3);

    winkel = linspace(0,2*pi,anzahl_punkte)';
    x_soll = center(:,1) + sin(winkel)*rad.*n1(:,1)+cos(winkel)*rad.*n2(:,1);
    y_soll = center(:,2) + sin(winkel)*rad.*n1(:,2)+cos(winkel)*rad.*n2(:,2);
    z_soll = center(:,3) + sin(winkel)*rad.*n1(:,3)+cos(winkel)*rad.*n2(:,3);
    bahn_soll_kreis_2 = [x_soll y_soll z_soll];
    clear x_soll y_soll z_soll

% Bahn am richtigen Punkt anfangen lassen und korrekte Laufrichtung der Bahn (für DTW wichtig)
    abstaende = sqrt(sum((bahn_soll_kreis_2 - p1).^2, 2));
    [min_abstand, index] = min(abstaende);
    flip1 = flip(bahn_soll_kreis_2(1:index-1,:));
    flip2 = flip(bahn_soll_kreis_2(index+1:end,:));
    bahn_soll_kreis_2 = [bahn_soll_kreis_2(index,:); flip1; flip2];   

% Datenbereinigung der zuviel berechneten Punkte
    for i = 1:1:length(bahn_soll_kreis_2)
        y_lim = abs(p1(:,2));
        if abs(bahn_soll_kreis_2(i,2)) > y_lim
            bahn_soll_kreis_2(i,:) = NaN;
        end
    end
% Lösche alle Reihen die NaN sind
    bahn_soll_kreis_2 = bahn_soll_kreis_2(~any(isnan(bahn_soll_kreis_2),2),:);

% Zusammenfügen der Einzelbahnen
    bahn_soll = [bahn_soll_kreis_1; bahn_soll_kreis_2];

% Berechnung und Plot des euklidischen Abstands zwischen Ist- und Sollbahn
    [xy,distance,t] = distance2curve(bahn_soll,bahn_ist,'linear');
    figure('Name','Euklidischer Abstand - Zuordnung der Bahnpunkte','NumberTitle','off');
    hold on
    grid on
    box on
    plot3(bahn_soll(:,1),bahn_soll(:,2),bahn_soll(:,3),'-ko','LineWidth',2)
    plot3(bahn_ist(:,1),bahn_ist(:,2),bahn_ist(:,3), 'LineWidth',2,'Color','blue')
    line([bahn_ist(:,1),xy(:,1)]',[bahn_ist(:,2),xy(:,2)]',[bahn_ist(:,3),xy(:,3)]','color',"red")
    legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
    xlabel("x [mm]","FontWeight","bold")
    ylabel("y [mm]","FontWeight","bold")
    zlabel("z [mm]","FontWeight","bold")
    hold off

    eucldist_av = mean(distance)
    eucldist_max = max(distance)


% Daten für DTW bereinigen --> Bahn wurde drei mal abgefahren!

    for j = 100:1:length(bahn_ist)
        distance = norm(position(2,:)-bahn_ist(j,:));
        if  distance < 0.5
            grenze = j;
            for l = j:1:length(bahn_ist)
                bahn_ist(l,:)=NaN;
            end
            break;
        end
    end

    bahn_ist = bahn_ist(~any(isnan(bahn_ist),2),:);

% Berechnung und Plot DTW (Zeit fehlt noch)
    pflag = 1;
    [dtw_distances, dtw_max, dtw_av, dtwaccdist, dtw_X, dtw_Y, path, ix, iy] = fkt_dtw3d(bahn_soll,bahn_ist,pflag);

    dtw_av
    dtw_max

% Berechnung und Plot Selective Interpolation DTW (Zeit fehlt noch)
    [selintdtw_distances, selintdtw_max, selintdtw_av, selintdtw_accdist, selintdtw_X, selintdtw_Y, selintdtw_path, ix, iy] = fkt_selintdtw3d(bahn_soll, bahn_ist,pflag);

    selintdtw_av
    selintdtw_max

% Plot der berechneten Sollbahn
    figure('Name','Plot der interpolierten Soll-Bahn','NumberTitle','off');
    hold on;
    plot3(bahn_soll(:,1),bahn_soll(:,2),bahn_soll(:,3),'b.-','MarkerSize', 10);
    box on;
    grid on;
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('Interpolierte Bahn');
    hold off;
    
end


%% FÜR RANDOM BAHN
if random

% Manuelle Eingabe der Positionen und Bahnlänge aus Rapid-Code.
    home = [133 -645 1990];
    laenge = 630;
    % anzahl_punkte = length(data_ist);
    anzahl_punkte = 300;
    bahn_ist = [data_ist(:,1) data_ist(:,2) data_ist(:,3)];

    p1 = bahn_ist(1,:);
    p2 = home;
    p3 = bahn_ist(1401,:);
    p4 = bahn_ist(1851,:);
    p5 = bahn_ist(2255,:);
    p6 = bahn_ist(2418,:);
    p7 = home;
    p8 = bahn_ist(3938,:);
    p9 = bahn_ist(4322,:);
    p10 = home;
    p11 = bahn_ist(6353,:);
    p12 = bahn_ist(6706,:);
    p13 = bahn_ist(7136,:);
    p14 = bahn_ist(end,:);

    position = [p1; p2; p3; p4; p5; p6; p7; p8; p9; p10; p11; p12; p13; p14];

    %plot3(position(:,1),position(:,2),position(:,3),'-bo');
    %hold off

% % Suche nach den Punkten im Plot ...
%     suche = [762.818 -803.008 1570.1];
%     abstaende = sqrt(sum((bahn_ist - suche).^2, 2));
%     [min_abstand, index] = min(abstaende);

% Längen der Bahnen bestimmen für die gleichmäßige Verteilung der Punkte
    laengen = zeros(1,length(position)-1);
    anteile = laengen;
    anzahl_punkte_anteilig = laengen;
    for i = 2:1:length(position)
        laengen(i-1) = norm(position(i,:)-position(i-1,:));
    end

    laenge_gesamt = sum(laengen);

    for i = 1:1:length(laengen)
        anteile(i) = laengen(i)./laenge_gesamt;
    end
    for i = 1:1:length(laengen)
        anzahl_punkte_anteilig(i) = round(anteile(i)*anzahl_punkte); 
    end

    anzahl_punkte = sum(anzahl_punkte_anteilig);
    bahn_soll = [];
    for i = 2:1:length(position)
        x_interp = linspace(position(i-1, 1), position(i, 1), anzahl_punkte_anteilig(i-1))';
        y_interp = linspace(position(i-1, 2), position(i, 2), anzahl_punkte_anteilig(i-1))';
        z_interp = linspace(position(i-1, 3), position(i, 3), anzahl_punkte_anteilig(i-1))';
        bahn_soll = [bahn_soll; [x_interp(1:end), y_interp(1:end), z_interp(1:end)]];
    end

% Berechnung und Plot des euklidischen Abstands zwischen Ist- und Sollbahn
    [xy,distance,t] = distance2curve(bahn_soll,bahn_ist,'linear');
    figure('Name','Euklidischer Abstand - Zuordnung der Bahnpunkte','NumberTitle','off');
    hold on
    grid on
    box on
    plot3(bahn_soll(:,1),bahn_soll(:,2),bahn_soll(:,3),'-ko','LineWidth',2)
    plot3(bahn_ist(:,1),bahn_ist(:,2),bahn_ist(:,3), 'LineWidth',2,'Color','blue')
    line([bahn_ist(:,1),xy(:,1)]',[bahn_ist(:,2),xy(:,2)]',[bahn_ist(:,3),xy(:,3)]','color',"red")
    legend({'Sollbahn','Istbahn','Abweichung'},'Location','northeast',"FontWeight", "bold")
    xlabel("x [mm]","FontWeight","bold")
    ylabel("y [mm]","FontWeight","bold")
    zlabel("z [mm]","FontWeight","bold")
    hold off

    eucldist_av = mean(distance)
    eucldist_max = max(distance)

% Berechnung und Plot DTW (Zeit fehlt noch)
    pflag = 1;
    [dtw_distances, dtw_max, dtw_av, dtwaccdist, dtw_X, dtw_Y, dtw_path, ix, iy] = fkt_dtw3d(bahn_soll,bahn_ist,pflag);

    dtw_av
    dtw_max

% Berechnung und Plot Selective Interpolation DTW (Zeit fehlt noch) 
    [selintdtw_distances, selintdtw_max, selintdtw_av, selintdtw_accdist, selintdtw_X, selintdtw_Y, selintdtw_path, ix, iy] = fkt_selintdtw3d(bahn_soll, bahn_ist,pflag);

    selintdtw_av
    selintdtw_max

% Plot der berechneten Soll-Bahn
    figure('Name','Plot der interpolierten Soll-Bahn','NumberTitle','off');
    hold on;
    plot3(bahn_soll(:,1),bahn_soll(:,2),bahn_soll(:,3),'b.-','MarkerSize', 10);
    box on;
    grid on;
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('Interpolierte Bahn');
    hold off;

end