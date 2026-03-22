%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Project: -------- Doppler ultrasound for blood pressure devices
% --- Authors: -------- Maria N. Petrou
% --- Description: ---- Pulse Wave Doppler Receiver for blood pressure
% --------------------- measurement devices. Takes recorded data by Gavin
% --------------------- Dingley of a coffee stirrer in a water tank and
% --------------------- outputs range and velocity.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clf; close;

%% Parameters
prf = 5e3;    % Pulse Repetition Frequency
fc = 3.769e6; % Carrier Frequency

%% Oscilloscope data
% Import .wav file -> outputs I and Q data and sampling frequency
[yo,fs] = audioread('SDRuno_20220512_122432Z_3769kHz.wav');

% Add zeros to the end of the file if it isn't divisible by sampling
% frequency. This will be useful for reshaping.
if mod(length(yo), fs) ~= 0
    To = ceil(length(yo)/fs);
    x = (To*fs) - length(yo);
    yo = [yo; zeros(x, 2)];
end

% Separate I and Q data
I = yo(:,1);
Q = yo(:,2);

dt=1/fs; n=length(I);   % time increment
t=(0:n-1)'*dt; T=n*dt;  % time 
NumPulses = T;          % Number of pulses in given time
caI=mean(abs(fft(reshape(I,fs,T))),2)*2/fs;  % spectrum
caQ=mean(abs(fft(reshape(Q,fs,T))),2)*2/fs;  % spectrum
f=(0:fs-1)'/1;                               % frequencies
y = complex(I, Q);
y=mean(abs(fft(reshape(y,fs,T))),2)*2/fs;    % spectrum

%% Plot Received Data

figure(1); 
semilogy(f,caI,'-k');
hold on
semilogy(f,caQ,'-r');
semilogy(f,y,'-g');
set(gca,'xlim',[0,fs/2]);
hold off
xlabel('Frequency (Hz)')
ylabel('Spectrum')
title('Logarithmic Plot of recorded PWD Data')
legend('I Data', 'Q Data', 'Complex Data')
% o = audioplayer(y(1,n/10),fs/10); play(o); pause;

%% Quadrature Demodulator - Hilbert Transform
% From the Signal Processing Toolbox, you can use hilbert() to obtain 
% the analytic signal and separate the imaginary/real part

yh = hilbert(y);

%% Quadrature Demodulator - Low Pass Filter
ylpf = lowpass(yh,5000,fc);    % Lowpass filter 

%% Plot Processed Data
dt=1/fs; n=length(ylpf);   % time increment
t=(0:n-1)'*dt; T=n*dt;  % time 
 
figure(1);
plot(t,y);
hold on
plot(t,yh);
plot(t,ylpf);
hold off
xlabel('Time (s)')
ylabel('Amplitude (V)')
title('Filtered Signal')

%% Calculate distance of target

fasttime = f/(fc*prf);
rangebins = (1540*fasttime)/2;

[pks,range_detect] = findpeaks(pulsint(ylpf,'noncoherent'),...
    'SortStr','descend');
range_estimate = rangebins(range_detect(1));

%% Plot spectral density of signal
figure(2)
[Pxx,F] = periodogram(ylpf,[],256,prf,'centered');
plot(F,10*log10(Pxx))
grid
xlabel('Frequency (Hz)')
ylabel('Power (dB)')
title('Periodogram Spectrum Estimate')

%% Calculate target speed
[Y,I] = max(ylpf);
lambda = 1540/fc; 
tgtspeed = dop2speed(f(I)/2,lambda);

%% Calculate Doppler Shift
fprintf('Estimated range of the target is %4.4f meters.\n',...
    range_estimate)

fprintf('Estimated target speed is %3.1f m/sec.\n',tgtspeed)

if f(I)>0
    fprintf('The target is approaching the radar.\n')
else
    fprintf('The target is moving away from the radar.\n')
end