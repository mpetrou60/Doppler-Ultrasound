%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Project: -------- Doppler ultrasound for blood pressure devices
% --- Authors: -------- Maria N. Petrou
% --- Description: ---- Pulse Wave Doppler Receiver for blood pressure
% --------------------- measurement devices. Takes recorded data from
% --------------------- continuous wave doppler transducers and contains
% --------------------- data from various brachial artery measurements. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clf; close;

%% Read Data
% import files from Doppler Receiver/Transmitter recordings
x0 = readmatrix('scope_0.csv');
x1 = readmatrix('scope_1.csv');
x2 = readmatrix('scope_2.csv');
x3 = readmatrix('scope_3.csv');
x4 = readmatrix('scope_4.csv');
x5 = readmatrix('scope_5.csv');
x6 = readmatrix('scope_6.csv');
x7 = readmatrix('scope_7.csv');
x8 = readmatrix('kit_bpm_3.csv');
x9 = readmatrix('kit_bpm_occluded.csv');
x10 = readmatrix('scope_8.csv');
x11 = readmatrix('scope_9.csv');
x12 = readmatrix('scope_10.csv');
x13 = readmatrix('scope_11.csv');
x14 = readmatrix('scope_12.csv');
x15 = readmatrix('scope_13.csv');

t = [x0(3:end,1), x1(3:end,1), x2(3:end,1), x3(3:end,1), x4(3:end,1),...
     x5(3:end,1), x6(3:end,1), x7(3:end,1), x8(3:end,1), x9(3:end,1),...
     x10(3:end,1), x11(3:end,1), x12(3:end,1), x13(3:end,1),...
     x14(3:end,1), x15(3:end,1)];

y = [x0(3:end,2), x1(3:end,2), x2(3:end,2), x3(3:end,2), x4(3:end,2),...
     x5(3:end,2), x6(3:end,2), x7(3:end,2), x8(3:end,2), x9(3:end,2),...
     x10(3:end,2), x11(3:end,2), x12(3:end,2), x13(3:end,2),...
     x14(3:end,2), x15(3:end,2)];

y(any(isnan(y), 2), :) = 1; % remove any NaN data
y = max(0,y); % remove negative data

%% Define parameters
fs = 1/(t(4,1)-t(3,1));  % Sample Rate [Hz]
dt = 1/fs;               % time increment
n = length(y(:,1));      % number of samples
d = length(y(1,:));      % number of datasets
t = (0:n-1)'*dt;         % time 
T = n*dt;

%% Generate 20Hz Pressure Signature and superimpose - Generic (Square Wave)
fp = 20;
ps = square(2*pi*fp*t); 
% y = y + ps;

%% Plot Received data

for i=1:d
    figure(i);
    plot(t,y(:,i));
    hold on
    xlabel('Time (s)')
    ylabel('Amplitude (V)')
    title('Superimposed Signal')
end

%% Quadrature Demodulator - Hilbert Transform
% From the Signal Processing Toolbox, you can use hilbert() to obtain 
% the analytic signal and separate the imaginary/real part

yh = hilbert(y);
yom = real(yh) + imag(yh);

for i=1:d
    figure(i);
    plot(t,yom(:,i));
    xlabel('Time (s)')
    ylabel('Amplitude (V)')
    title('Hilbert Transformed Signal')
end

%% Quadrature Demodulator - Low Pass Filter

ylpf = lowpass(yom,500,fs);    % Lowpass filter (500 = passband frequency)
% ylpf = max(0,ylpf); % remove negative points again

for i=1:d
    figure(i);
    plot(t,ylpf(:,i));
    xlabel('Time (s)')
    ylabel('Amplitude (V)')
    title('Low Pass Filtered Signal')
end

%% Extracting velocity by obtaining signal envelope
[yupper,~] = envelope(ylpf, 300, 'peak');

for i=1:d
    figure(i);
    plot(t,yupper(:,i),'-k');
    hold off
    xlabel('Time (s)')
    ylabel('Amplitude (V)')
    title('Envelope of Signal')
end

%% Cardiac Cycle Identification
% Extracting a single pulse
% https://medicalxpress.com/news/2021-11-blood-velocity-flexible-doppler-ultrasound.html

% 1 cardiac cycle is typically around 0.78s, this could be rounded up to 1
% or even 1.5s to allow for varying cardiac cycles however for this system
% we will assume the patient is healthy and 1s is a reasonable limit.
ncc = round(0.8/dt);
tp = (0:ncc)'*dt;
pulse = zeros(ncc+1,d);
pulse_env = zeros(ncc+1,d);
p1 = zeros(d,1);

% Identifies highest voltage pulse and takes one cardiac cycle from this.
for i=1:d
    p1(i) = find(ylpf(:,i) >= max(findpeaks(ylpf(:,i))),1,'last');
    if (p1(i)+ncc) < n
        pulse(:,i) = ylpf(p1(i):p1(i)+ncc,i);
        pulse_env(:,i) = yupper(p1(i):p1(i)+ncc,i);
    else
        m = (p1(i) + ncc) - n;
        pulse(1:m,i) = ylpf(p1(i):end,i);
        pulse_env(1:m,i) = yupper(p1(i):end,i);
    end
end
    
for i=1:d
    figure(i);
    plot(tp,pulse(:,i));
    hold on
    plot(tp,pulse_env(:,i));
    hold off
    xlabel('Time (s)')
    ylabel('Amplitude (V)')
    title('1 Cardiac Cycle of Signal')
end

%% Spectrum Extraction - Hanning Window
Twin = 10; % 8; consider changing this to 5?

while(mod(n, Twin) ~= 0)
    Twin = Twin + 1;
end

fs  = length(y)/Twin;
h1=repmat(hann(fs),1,Twin)*2*fs/(fs-1);

%% Spectrum Extraction - CFFT (Complex Fast Fourier Transform)
f=((0:fs-1)/1)';
yw=zeros(length(f),d);

for i=1:d
    yw(:,i)=mean(abs(fft(reshape(ylpf(:,i),fs,Twin).*h1))*2/fs,2);
end
% legend('non-occluded data', 'non-occluded data', 'non-occluded data', 'occluded data', 'Location', 'southeast') 

%% Spectrum Extraction - ABS
yca=abs(yw);                % amplitude

for i=1:d
    figure(i);
    plot(f,yca(:,i));
    xlabel('Frequency (Hz)')
    ylabel('Voltage (V)')
    title('Absolute Signal Output')
end

%% Spectrum Extraction - CFFT (Complex Fast Fourier Transform) - SHIFT
fc = zeros(d,1);
ywshift = zeros(fs,d);

for i=1:d
    ywshift(:,i)=mean(abs(fftshift(reshape(ylpf(:,i),fs,Twin).*h1))*2/fs,2);
    % find carrier frequency from fft
    fc(i) = f(find(ywshift(:,i)<=min(findpeaks(ywshift(:,i))),1,'last')); 
end

%% Spectrum Extraction - ABS WITH SHIFT
ycashift=abs(ywshift);                % amplitude

for i=1:d
    figure(i);
    plot(f,ycashift(:,i));
    xlabel('Frequency (Hz)')
    ylabel('Voltage (V)')
    title('Absolute Signal Output')
end

%% Gate Selection - Frequency Shift/Downconversion
yc = zeros(n,d);
ycagate = zeros(n,d);

for i=1:d
    k = fc(i)*T; % carrier frequncy
    z = exp(-j*2*pi*k*(0:n-1)'/n); % frequency shift
    yc(:,i) = ylpf(:,i).*z; % down convert
    yc(:,i) = gfilter(yc(:,i),fs,1000,5000); % filter
    ycagate(:,i)=abs(yc(:,i)); % amplitude

    figure(i);
    plot(t,ycagate(:,i))
    xlabel('Time (s)')
    ylabel('Amplitude')
    title('Frequency Shifted Signal')
end

%% Doppler Extraction
prf = fs;

for i = 1:d
    fasttime = f/(fc(i)*prf);
    rangebins = (1540*fasttime)/2;
    
    sig = reshape(ycagate(:,i),fs,10);
    
    [pks,range_detect] = findpeaks(pulsint(sig,'noncoherent'),...
        'SortStr','descend');
    range_estimate = rangebins(range_detect(1));
    
    ts = sig(range_detect(1),:).';
    [Pxx,F] = periodogram(ts,[],256,prf,'centered');
    plot(F,10*log10(Pxx))
    grid
    xlabel('Frequency (Hz)')
    ylabel('Power (dB)')
    title('Periodogram Spectrum Estimate')
    
    i
    [Y,I] = max(Pxx);
    lambda = 1540/fc(i);
    tgtspeed = dop2speed((F(I)+prf/fc(i))/2,lambda);
    fprintf('Estimated range of the target is %4.4f meters.\n',...
        range_estimate)
    
    fprintf('Estimated target speed is %3.4f m/sec.\n',tgtspeed)
    
    if F(I)>0
        fprintf('The target is approaching the radar.\n')
    else
        fprintf('The target is moving away from the radar.\n')
    end
end

%% SNR Tests
% SNR should be compared against noise for accurate values
for i = 1:d
    i
    snr(ycagate(:,i),y(:,10))
    snr(yupper(:,i),y(:,10)) 
    snr(ylpf(:,i),y(:,10)) 
end

%% Short Term Fourier Transform
win = hamming(100,'periodic');

for i=1:d
    figure(i);
    stft(ylpf(:,i),fs,'Window',win,'OverlapLength',98,'FFTLength',128);
    view(-45,65)
    colormap jet
end