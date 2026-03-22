%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Project: -------- Doppler ultrasound for blood pressure devices
% --- Authors: -------- Maria N. Petrou
% --- Description: ---- Pulse Wave Doppler Transmitter for blood pressure
% --------------------- measurement devices.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clf;

%% Initialise Parameters
fc = 3.769e6;                % Carrier Frequency
prf = 5e3;                   % Pulse Repetition Frequency
n = 500;                     % Number of points
pulse_len = 1e-6;            % Time period of pulse
t = linspace(0,pulse_len,n); % Time
total = 100000;              % Total points to be transmitted - remove for 
                             % continuous transmission.

%% Transmit Pulse Generator
pulse = sin(2*pi*fc*t); 

%% Frequency Divider
% divide the signal by the pulse repetition frequency
freq_div = fc/prf;
sig = pulse/freq_div;

%% Normalise signal
% If a digital signal is being transmitted limit numbers 1 and 0
for i = 1:length(sig)
    if sig(i) > 0
        sig(i) = 1;
    else
        sig(i) = 0;
    end
end

%% Transmit Gate
gate_len = 1e-3;                          % Time period of gate
end_gate = round((gate_len/pulse_len)*n); 
end_gate = end_gate + n;                  % Number of points for gate to end

%% Transmit
% Simulate pulse train transmission

% Initialise parameters
j = 0;
transmit = zeros(total, 1);
time = zeros(total, 1);

% generate arrays
for i = 1:total
    if i < total
        time(i+1) = time(i) + t(2); % time array
    end
    j = j+1;
    if j < n
        transmit(i) = sig(j); % transmission array
    end
    if j == end_gate
        j = 1;
    end
end

% plot outputs
figure(1)
plot(time, transmit)
xlabel('Time (s)')
ylabel('Amplitude (s)')
title('Transmitted Pulse Train')
