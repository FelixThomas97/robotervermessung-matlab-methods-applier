%% Initialisieren

load iso_path_A_1.mat

figureson = 1;

X = soll; 
Y = ist;
M = length(X);
N = length(Y);

localdist = zeros(length(X),length(Y));
MaxLocalCost = 0;
MinLocalCost = Inf;
clear soll ist
b=0;
c=0;
b1 = 0;
c1 = 0;

for i = 1:2:2*M-1
    m = floor(i/2)+1;
    for j = 1:2:2*N-1
        n = floor(j/2)+1;
        localdist(i,j) = euclDist(m,n,X,Y);
        if (m<M & n<N)
            if ((Y(n,:)<=X(m,:) & X(m,:)<=Y(n+1,:)) | (Y(n+1,:)<=X(m,:) & X(m,:)<=Y(n,:))) 
            % if ((norm(Y(n,:))<=norm(X(m,:)) && norm(X(m,:))<=norm(Y(n+1,:))) || (norm(Y(n+1,:))<=norm(X(m,:)) & norm(X(m,:))<=norm(Y(n,:))))
                localdist(i,j+1)=0;
                b = b+1;
            else 
                localdist(i,j+1)=min([X(m,:)-Y(n,:) X(m,:)-Y(n+1,:)].^2);
                b1 = b1+1;
            end
            if ((X(m,:)<=Y(n,:) & Y(n,:)<=X(m+1,:)) | (X(m+1,:)<=Y(n,:) & Y(n,:)<=X(m,:)))
            % if ((norm(X(m,:))<=norm(Y(n,:)) && norm(Y(n,:))<=norm(X(m+1,:))) || (norm(X(m+1,:))<=norm(Y(n,:)) & norm(Y(n,:))<=norm(X(m,:))))
                localdist(i+1,j)=0;
                c = c+1;
            else 
                localdist(i+1,j)=min([Y(n,:)-X(m,:) Y(n,:)-X(m+1,:)].^2);
                c1 = c1+1;
            end
        end
    end
end
%%

% Accumulated distance matrix
accdist=zeros(size(localdist));
accdist(1,1)=localdist(1,1);
for i=3:2:2*M-1
    accdist(i-1,1)=localdist(i-1,1)+accdist(i-2,1);
    accdist(i,1)=localdist(i,1)+accdist(i-1,1);
end
for j=3:2:2*N-1
    accdist(1,j-1)=localdist(1,j-1)+accdist(1,j-2);
    accdist(1,j)=localdist(1,j)+accdist(1,j-1);
end
%% 

for i=3:2:2*M-1
    for j=3:2:2*N-1
        accdist(i-1,j)=localdist(i-1,j)+accdist(i-2,j);
        accdist(i,j-1)=localdist(i,j-1)+accdist(i,j-2);
        accdist(i,j)=localdist(i,j)+min([accdist(i,j-1) accdist(i-1,j) accdist(i-2,j-2)]);
    end
end
%%
% Looking for the optimal path
i=2*M-1;
j=2*N-1;
path=[M N];
dtwX=X(end);
dtwY=Y(end);
%%
while ((i+j)~=2)
    m=floor(i/2)+1;
    n=floor(j/2)+1;
    if (i-2)<0 
        path=[m n-1; path];
        dtwX=[X(m) dtwX];
        dtwY=[Y(n-1) dtwY];
        j=j-2;
    elseif (j-2)<0 
        path=[m-1 n; path];
        dtwX=[X(m-1) dtwX];
        dtwY=[Y(n) dtwY];
        i=i-2;
    else
        [values,number]=min([accdist(i,j-1) accdist(i-1,j) accdist(i-2,j-2)]);
        switch (number)
            case 1,
                if ((Y(n-1)<=X(m) & X(m)<=Y(n)) | (Y(n)<=X(m) & X(m)<=Y(n-1))) x=(X(m)-Y(n-1))/(Y(n)-Y(n-1));
                elseif ((X(m)-Y(n-1))^2 <= (X(m)-Y(n))^2) x=0;
                else x=1;
                end
                path=[m n-1+x; path];
                dtwX=[X(m) dtwX];
                dtwY=[x*(Y(n)-Y(n-1))+Y(n-1) dtwY];
                j=j-2;
            case 2,
                if ((X(m-1)<=Y(n) & Y(n)<=X(m)) | (X(m)<=Y(n) & Y(n)<=X(m-1))) x=(Y(n)-X(m-1))/(X(m)-X(m-1));
                elseif ((Y(n)-X(m-1))^2 <= (Y(n)-X(m))^2) x=0;
                else x=1;
                end
                path=[m-1+x n; path];
                dtwX=[x*(X(m)-X(m-1))+X(m-1) dtwX];
                dtwY=[Y(n) dtwY];
                i=i-2;
            case 3,
                path=[m-1 n-1; path];
                dtwX=[X(m-1) dtwX];
                dtwY=[Y(n-1) dtwY];
                i=i-2;
                j=j-2;
        end
    end
end

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
%hold on
plot(path(:,2), path(:,1),"-w","LineWidth",1)
xlabel('Pfad Y [Index]');
ylabel('Pfad X [Index]');
axis([min(path(:,2)) max(path(:,2)) 1 max(path(:,1))]);
set(gca,'FontSize',10,'YDir', 'normal');

%(X(m)-Y(n))^2;
function distance = euclDist(i, j, pathX, pathY)

    % Berechnung des eukl. Abstands zwischen zwei Punkten von pathX und Y
    distance = norm(pathX(i,:) - pathY(j,:));
end