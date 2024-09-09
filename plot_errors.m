function plot_errors(num_segments,num_trajectories,struct_dtw_segments,struct_frechet_segments,struct_lcss_segments,struct_sidtw_segments,struct_euclidean_segments,struct_dtw,struct_frechet,struct_lcss,struct_sidtw,struct_euclidean)

% Für Bahnvergleich
blau = [0 0.4470 0.7410]; % Standard Blau
rot = [0.78 0 0]; % gewählter Rotton in Masterarbeit

% Für Plots Verfahren
c1 = [0 0.4470 0.7410];
c2 = [0.8500 0.3250 0.0980];
c3 = [0.9290 0.6940 0.1250];
c4 = [0.4940 0.1840 0.5560];
c5 = [0.4660 0.6740 0.1880];
c6 = [0.3010 0.7450 0.9330];
c7 = [0.6350 0.0780 0.1840];

%% Extrahieren der Abstände
for i = 1:num_segments
    %%%%%%%%%% SEGMETE
    xs_dists_av_dtw(i) = struct_dtw_segments{i}.dtw_average_distance*1000;
    xs_dists_av_frechet(i) = struct_frechet_segments{i}.frechet_average_distance *1000;
    xs_dists_av_lcss(i) = struct_lcss_segments{i}.lcss_average_distance*1000;
    xs_dists_av_sidtw(i) = struct_sidtw_segments{i}.dtw_average_distance*1000;
    xs_dists_av_eucl(i) = struct_euclidean_segments{i}.euclidean_average_distance*1000;

    xs_dists_max_dtw(i) = struct_dtw_segments{i}.dtw_max_distance*1000;
    xs_dists_max_frechet(i) = struct_frechet_segments{i}.frechet_max_distance *1000;
    xs_dists_max_lcss(i) = struct_lcss_segments{i}.lcss_max_distance*1000;
    xs_dists_max_sidtw(i) = struct_sidtw_segments{i}.dtw_max_distance*1000;
    xs_dists_max_eucl(i) = struct_euclidean_segments{i}.euclidean_max_distance*1000;
end

for i = 1:num_trajectories
    xt_dists_av_dtw(i) = struct_dtw{i}.dtw_average_distance*1000;
    xt_dists_av_frechet(i) = struct_frechet{i}.frechet_average_distance *1000;
    xt_dists_av_lcss(i) = struct_lcss{i}.lcss_average_distance*1000;
    xt_dists_av_sidtw(i) = struct_sidtw{i}.dtw_average_distance*1000;
    xt_dists_av_eucl(i) = struct_euclidean{i}.euclidean_average_distance*1000;

    xt_dists_max_dtw(i) = struct_dtw{i}.dtw_max_distance*1000;
    xt_dists_max_frechet(i) = struct_frechet{i}.frechet_max_distance *1000;
    xt_dists_max_lcss(i) = struct_lcss{i}.lcss_max_distance*1000;
    xt_dists_max_sidtw(i) = struct_sidtw{i}.dtw_max_distance*1000;
    xt_dists_max_eucl(i) = struct_euclidean{i}.euclidean_max_distance*1000;
end

%% Mittel und Max Durchschnittswerte 

% yy_mean_dtw = mean(y_dists_av_dtw);
% yy_mean_frechet = mean(y_dists_av_frechet);
% yy_mean_lcss = mean(y_dists_av_lcss);
% yy_mean_sidtw = mean(y_dists_av_sidtw);
% yy_mean_eucl = mean(y_dists_av_eucl);

%% Plotten

% Mittlere Abweichung
figure('Color','white');
title('Mittlere Abweichungen')
hold on


% Trajektorien
plot(xt_dists_av_dtw,LineWidth=2.5,Color=c1)
plot(xt_dists_av_frechet,LineWidth=2.5,Color=c2)
plot(xt_dists_av_lcss,LineWidth=2.5,Color=c3)
plot(xt_dists_av_sidtw,LineWidth=2.5,Color=c4)
plot(xt_dists_av_eucl,LineWidth=2.5,Color=c5)
% Segmente
plot(xs_dists_av_dtw,LineWidth=1,Color=c1)
plot(xs_dists_av_frechet,LineWidth=1,Color=c2)
plot(xs_dists_av_lcss,LineWidth=1,Color=c3)
plot(xs_dists_av_sidtw,LineWidth=1,Color=c4)
plot(xs_dists_av_eucl,LineWidth=1,Color=c5)

xline(num_trajectories)


xlabel('Bahnsegmente/Trajektorien');
ylabel('Abweichung in mm');
legend('DTW','DFD','LCSS','SIDTW','Eukl. Dist.')

grid on
axis padded
hold off

% Maximale Abweichung
figure('Color','white');
title('Maximale Abweichung')
hold on


% Trajektorien
plot(xt_dists_max_dtw,LineWidth=2.5,Color=c1)
plot(xt_dists_max_frechet,LineWidth=2.5,Color=c2)
plot(xt_dists_max_lcss,LineWidth=2.5,Color=c3)
plot(xt_dists_max_sidtw,LineWidth=2.5,Color=c4)
plot(xt_dists_max_eucl,LineWidth=2.5,Color=c5)

% Segmente
plot(xs_dists_max_dtw,LineWidth=1,Color=c1)
plot(xs_dists_max_frechet,LineWidth=1,Color=c2)
plot(xs_dists_max_lcss,LineWidth=1,Color=c3)
plot(xs_dists_max_sidtw,LineWidth=1,Color=c4)
plot(xs_dists_max_eucl,LineWidth=1,Color=c5)

xline(num_trajectories)


xlabel('Bahnsegmente/Trajektorien');
ylabel('Abweichung in mm');
legend('DTW','DFD','LCSS','SIDTW','Eukl. Dist.')

grid on
axis padded
hold off

end