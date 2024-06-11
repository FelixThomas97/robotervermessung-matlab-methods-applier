% Dies ist ein Test
load dynamic_tool_wks_1_test_1.mat

data_ist = dynamic_tool_wks_1';
data_ist = data_ist(3:end-1,:);

x = data_ist(:,1)';
y = data_ist(:,2)';
z = data_ist(:,3)';

%%
% Eingabedaten 
% x = [-5 -4 -3 -2 -1 0 1 2 3 4 5]; % x-Koordinaten, können negative Werte enthalten
% y = [-2 -1.5 -1 -0.5 0 0.5 1 1.5 2 2.5 3]; % y-Koordinaten, können negative Werte enthalten
% z = [0 0.5 -0.5 1 -1 1.5 -1.5 2 -2 2.5 -2.5]; % z-Koordinaten, können negative Werte enthalten

% Anzahl der interpolierten Punkte
numPoints = 10;

% Interpolationsmethode ('linear', 'spline', 'pchip', 'makima')
method = 'linear';

% Neue x-Werte für die Interpolation
xq = linspace(min(x), max(x), numPoints);

% Interpolation der y- und z-Werte
yq = interp1(x, y, xq, method);
zq = interp1(x, z, xq, method);

% Plot der ursprünglichen Daten und der interpolierten Bahn
figure;
plot3(x, y, z, 'o', 'DisplayName', 'Original Data'); % Originaldaten
hold on;
plot3(xq, yq, zq, '-', 'DisplayName', ['Interpolated Path (', method, ')']); % Interpolierte Daten
legend('show');
xlabel('x');
ylabel('y');
zlabel('z');
title('3D Interpolation of Data Sequence');
grid on;

% Achsenbereich anpassen, um negative Werte darzustellen
xlim([min(x) max(x)]);
ylim([min(y) max(y)]);
zlim([min(z) max(z)]);

%%
% Eingabedaten für ein Quadrat
x = [1 1 -1 -1 1]; % x-Koordinaten des Quadrats
y = [1 -1 -1 1 1]; % y-Koordinaten des Quadrats
z = [0 0 0 0 0]; % z-Koordinaten des Quadrats (alle auf derselben Ebene)

% Anzahl der interpolierten Punkte
numPoints = 100;

% Interpolationsmethode ('linear', 'spline', 'pchip', 'makima')
method = 'spline';

% Neue Parameterwerte für die Interpolation
t = linspace(0, 1, length(x)); % Parameter für die Eckpunkte
tq = linspace(0, 1, numPoints); % Parameter für die Interpolation

% Interpolation der x-, y- und z-Werte
xq = interp1(t, x, tq, method);
yq = interp1(t, y, tq, method);
zq = interp1(t, z, tq, method);

% Plot der ursprünglichen Daten und der interpolierten Bahn
figure;
plot3(x, y, z, 'o', 'DisplayName', 'Original Data'); % Originaldaten
hold on;
plot3(xq, yq, zq, '-', 'DisplayName', ['Interpolated Path (', method, ')']); % Interpolierte Daten
legend('show');
xlabel('x');
ylabel('y');
zlabel('z');
title('3D Interpolation of Square');
grid on;

% Achsenbereich anpassen
axis equal;
xlim([-2 2]);
ylim([-2 2]);
zlim([-1 1]);

%%
% Eingabedaten für eine Ellipse
theta = linspace(0, 2*pi, 100); % Parameter für die Ellipse
x = cos(theta); % x-Koordinaten der Ellipse
y = 0.5 * sin(theta); % y-Koordinaten der Ellipse (Halb so lang wie x)
z = zeros(size(theta)); % z-Koordinaten der Ellipse (alle auf derselben Ebene)

% Anzahl der interpolierten Punkte
numPoints = 100;

% Interpolationsmethode ('linear', 'spline', 'pchip', 'makima')
method = 'spline';

% Neue Parameterwerte für die Interpolation
t = linspace(0, 1, length(x)); % Parameter für die Punkte
tq = linspace(0, 1, numPoints); % Parameter für die Interpolation

% Interpolation der x-, y- und z-Werte
xq = interp1(t, x, tq, method);
yq = interp1(t, y, tq, method);
zq = interp1(t, z, tq, method);

% Plot der ursprünglichen Daten und der interpolierten Bahn
figure;
plot3(x, y, z, 'o', 'DisplayName', 'Original Data'); % Originaldaten
hold on;
plot3(xq, yq, zq, '-', 'DisplayName', ['Interpolated Path (', method, ')']); % Interpolierte Daten
legend('show');
xlabel('x');
ylabel('y');
zlabel('z');
title('3D Interpolation of Ellipse');
grid on;

% Achsenbereich anpassen
axis equal;
xlim([-1.5 1.5]);
ylim([-1 1]);
zlim([-1 1]);
