clear; close; clf;

%% Initialise Parameters for Digital Transmitter
fc = 4e6;      % Carrier Frequency
prf = 2e6;     % Pulse Repetition Frequency
n = 500;      % number of points
pulse_len = 1e-6;
t = linspace(0,pulse_len,n); % time
total = 10000;

%% Transmit Pulse Generator
pulse = square(2*pi*fc*t);

%% Frequency Divider
freq_div = fc/prf;
sig = pulse/freq_div;

for i = 1:length(sig)
    if sig(i) > 0
        sig(i) = 1;
    else
        sig(i) = 0;
    end
end

%% Transmit Gate
gate_len = 5e-6;
end_gate = round((gate_len/pulse_len)*n); % time
end_gate = end_gate + n;

%% Transmit
j = 0;
transmit = zeros(total, 1);
time = zeros(total, 1);

for i = 1:total
    if i < total
        time(i+1) = time(i) + t(2);
    end
    j = j+1;
    if j < n
        transmit(i) = sig(j);
    end
    if j == end_gate
        j = 1;
    end
end

figure(1)
plot(time, transmit)
xlabel('Time (s)')
ylabel('Amplitude (s)')
title('Transmitted Pulse Train')

%% cwd

s = daq.createSession('ni');
addAnalogOutputChannel(s,'Dev3',1,'Voltage');
addAnalogInputChannel(s,'Dev3','ai4','Voltage');
lh = addlistener(s,'DataAvailable',@plotData); 

s.IsContinuous = true;
s.Rate=10000;
data=transmit; %linspace(-1,1,5000)';
lh = addlistener(s,'DataRequired', ...
        @(src,event) src.queueOutputData(data));
queueOutputData(s,data) 
startBackground(s); 
% stop(s)

%% pwd

% s = daq.createSession('ni');
% ch = addDigitalChannel(s,'Dev3', 'Port0/Line0', 'Bidirectional');
% 
% ch.Direction = 'Output';
% 
% s.IsContinuous = true;
% s.Rate=10000;
% data = zeros(length(transmit),1);
% 
% for i=1:length(transmit)
%     ch.Direction = 'Output';
%     outputSingleScan(s,transmit(i));
% 
%     ch.Direction = 'Input';
%     data(i) = inputSingleScan(s);
%     plot(data)
% end
 
function plotData(src,event)
     plot(event.TimeStamps,event.Data)
end
