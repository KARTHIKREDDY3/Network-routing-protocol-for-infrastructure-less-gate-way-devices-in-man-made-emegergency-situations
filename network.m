clc;
clear all;
close all;
function [T,E] = go( msg,path )
    global position N
    timeline=zeros(1,N);
    Energy=zeros(1,N);
    passtime=msg(2)/1000;
    pt=passtime;
    for i=1:numel(path)
        timeline(path(i))=pt;
        pt=pt+passtime;
        if i<numel(path)
            Energy(path(i))=100*msg(2)*1e-6+100e-9*msg(2)*dist(position(:,i)',position(:,i+1))^2;
        else
            Energy(path(i))=50e-6*msg(2);
        end
    end
    T=timeline;
    E=Energy;
end
%% Making Network:
global position N
N=50; % Number of Nodes in network
position=randsrc(2,N,1:1000); % set position of each node in network 1000x1000 meters
S=1; % Source Node
D=50; % Destination Node
Net=zeros(N);
range=250; % Radio propagation range of each node (meter)
plot(position(1,:),position(2,:),'ro');
title('Network');
xlabel('x (m)');
ylabel('y (m)');
grid();
hold on

for i=1:N
    for j=1:N
        if i~=j && dist(position(:,i)',position(:,j))<=range
            Net(i,j)=1; %Connection between 2 nodes (i,j)
            line([position(1,i),position(1,j)],[position(2,i),position(2,j)]);
        end
    end
end
plot(position(1,S),position(2,S),'ks');
plot(position(1,D),position(2,D),'g^');
%% Route Discovery:
for i=1:30
    path=S;
    tik=zeros(1,N);
    tik(S)=1;
    while (1)
        a=find(Net(path(end),:)==1);
        b=a(tik(a)==0);
        if isempty(b)==1
            break;
        end
        next=randsrc(1,1,b);
        if tik(next)==0
            path=[path,next];
            tik(next)=1;
        end
        if path(end)==D
            routePool{i}=path;
            break;
        end
    end
end
j=1;
for i=1:numel(routePool)
    if isempty(routePool{i})==0
        Pool{j}=routePool{i};
        j=j+1;
    end
end
for i=1:numel(Pool)-1
    for k=i+1:numel(Pool)
        if numel(Pool{i})== numel(Pool{k})
            if sum(Pool{i}==Pool{k})==numel(Pool{k})
                Pool{k}=[];
            end
        end
    end
end
routePool=Pool;
clear Pool;
j=1;
for i=1:numel(routePool)
    if isempty(routePool{i})==0
        Pool{j}=routePool{i};
        j=j+1;
    end
end

for k=1:numel(Pool)
    figure, plot(position(1,:),position(2,:),'ro');
    hold on;
    for i=1:numel(Pool{k})-1
        line([position(1,Pool{k}(i)),position(1,Pool{k}(i+1))],[position(2,Pool{k}(i)),position(2,Pool{k}(i+1))]);
    end
end
%% Sorting routes
for i=1:numel(Pool)
    count(i)=numel(Pool{i});
end
[~,idx]=sort(count);
for i=1:numel(Pool)
    sPool{i}=Pool{idx(i)};
end
Pool=sPool;
clear sPool
%% Packet Injection
packeti=rand(2500,1); % message importance
packetc=50*ones(2500,1); % Capasity of message (from 1 kb to 100 kb)
packet=[packeti,packetc];
j=1;
disp('----------------------------');
discard=0;
tl=zeros(1,50);
E=tl;
kk=1;
while isempty(packet)==0
    msg=packet(1,:);
    packet(1,:)=[];
    status(kk)=abs(1-sum(sum(tl))/10000);
    decision=status(kk); 
    kk=kk+1;
    if decision<0.1
        discard=discard+1;
        continue;
    end
    if (decision>=0.1) && (decision<0.6)
        path=Pool{randsrc(1,1,1:floor(numel(Pool)/3))};
    elseif decision>=0.6 && decision<0.8 
        path=Pool{randsrc(1,1,floor(numel(Pool)/3):floor(numel(Pool)*2/3))};
    elseif decision>=0.8 
        path=Pool{randsrc(1,1,floor(numel(Pool)*2/3):numel(Pool))};
    end
    [tl(j,:),E(j,:)]=go(msg,path);
    j=j+1;
end
total_Time=(sum(tl));
delivery_time=total_Time(end)
total_Energy=sum(sum(E))
discard
Time=sum(tl);
Energy=sum(E);
