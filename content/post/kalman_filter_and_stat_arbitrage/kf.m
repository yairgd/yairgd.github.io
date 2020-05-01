mu=0.1;
t=1:1000;
sig=0.3;
T=1;
N=1000;
r=mu-sig^2/2;
Y=randn;
h=T/N;
sh=sqrt(h);
mh=r*h;
x0=100;
X=x0;


% generate beta
Q=sqrt(0.00001);
beta=1+cumsum (Q*randn(size(t)));
figure;plot (t,beta)
xlabel('time');
ylabel('beta');

% generate x and y
clear G
G(:,1)=[0 x0];
for j=2:N
	z=randn;
	X=X*exp(mh+sh*sig*z);
	G(:,j) = [j*h X];
end
x=G(2,:);

R=sqrt(0.1);
y=x.*beta + R*randn(size(t));
figure;plot (x);hold on;plot (y,'r')
xlabel('time');
ylabel('price');
title ('X and Y');
legend ('X','Y')

% kalman filter calculation
Q=0.6; %sqrt(0.00001);
P=1;
K=1;
H=1;
F=[0.1 0.2 .7 ];n=3;
beta_est(1:n)=beta(1:n);
clear PP
for i=n+1:size(t,2)
	%Prediction
	beta_est(i)=F*beta_est(i-n:i-1)';
	beta_pred(i)=F*beta_est(i-n:i-1)';

	P=F*P*F'+Q;

	% update
	r= y(i)/x(i) -beta_est(i);
	K=P^1*H'*(R+H*P^-1*H')^-1;
	beta_est(i)=beta_est(i) + K*r;
	P=(ones(1,1)-K*H)*P;
	PP(end+1,:) = [P K];	
end
figure(1);clf;plot (beta);hold on;plot (beta_est,'r');plot (beta_pred,'g')
xlabel('time');
ylabel('price');
legend ('beta','estimated beta','predicted beta');

% trading algorithm
 ii=find  (y-beta_pred.*x>0.0);
s=y-x;
s=[0 diff(s)];
figure;plot (cumsum(s(ii)))
xlabel('time');
ylabel('equity curve');



