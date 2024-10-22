% Transformation der Quarternionen zu Euler-Winkeln
q_soll = table2array(data_soll(:,5:8));
q_soll = [q_soll(:,4), q_soll(:,3), q_soll(:,2), q_soll(:,1)];
euler_soll = quat2eul(q_soll,"ZYX");
euler_soll = rad2deg(euler_soll);

q_ist = table2array(data_ist(:,8:11));
q_ist = [q_ist(:,4), q_ist(:,3), q_ist(:,2), q_ist(:,1)];
euler_ist = quat2eul(q_ist,"ZYX");
euler_ist = rad2deg(euler_ist);

% Berechnung der Rotationsmatrizen aller Orientierungen auf Soll & Istbahn
R_ist = eul2rotm(deg2rad(euler_ist),"ZYX");
R_ist_mean = [mean(R_ist(1,1,:)),mean(R_ist(1,2,:)),mean(R_ist(1,3,:)); ...
               mean(R_ist(2,1,:)),mean(R_ist(2,2,:)),mean(R_ist(2,3,:)); ...
               mean(R_ist(3,1,:)),mean(R_ist(3,2,:)),mean(R_ist(3,3,:));];
R_soll = eul2rotm(deg2rad(euler_soll),"ZYX");
R_soll_mean = [mean(R_soll(1,1,:)),mean(R_soll(1,2,:)),mean(R_soll(1,3,:)); ...
               mean(R_soll(2,1,:)),mean(R_soll(2,2,:)),mean(R_soll(2,3,:)); ...
               mean(R_soll(3,1,:)),mean(R_soll(3,2,:)),mean(R_soll(3,3,:));];

% Gemittelte relative Rotationsmatrix
R_rel = R_soll_mean * R_ist_mean;

% Berechnung der Rotationsmatrizen aller Orientierungs-Koordinaten
R_ist_new = eul2rotm(deg2rad(euler_ist),"ZYX");

% Erstellen eines mehrdimensionalen 3x3-Arrays
R_rel = repmat(R_rel,1,1,length(R_ist_new));

% Mehrdimensionale Matrixmulitiplikation
R_trans = pagemtimes(R_rel,R_ist_new);

% Transformierte Eulerwinkel der Istbahn
euler_trans = rad2deg(rotm2eul(R_trans,"ZYX"));