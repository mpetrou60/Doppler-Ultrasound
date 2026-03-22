% time series box car filter
% [yi % time series box car filter
% [yi]=gfilter(y,fs,flow,fupp)
% input:  
% y      - time series 
% fs     - sampling frequency 
% flow   - lower corner frequency (high pass) 
% fupp   - upper corner frequency (low pass) 
% output: 
% yi     - filtered time series 
function [yi]=gfilter(y,fs,flow,fupp)
n=length(y);                                  % no of samples in time series
yf=fft(y);                                    % spectrum 
f=[0:n/2,n/2-1:-1:1]*fs/n;                    % frequencies of spectrum
id=f<flow|f>fupp; clear f;                    % box car filter    
yf(id)=0;                                     % filter spectrum 
yi=ifft(yf);                                  % inverse time series