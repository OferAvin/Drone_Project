function [psdx, freq] = fftPSD(xout,Fs,figFlag)
%psd with FFT using N = length(x) and nextpow2(length(x))
% xout � EEG data from single channel
set(groot,'defaulttextinterpreter','latex');

m = [length(xout), 2^(nextpow2(length(xout)))];
for i=1:1:length(m)
    N = m(i);
    xdft = fft(xout,N);                     % Start FFT 
    xdft = xdft(1:N/2+1);                   % discard higher than Nyquist
    psdx = (1/(Fs*N)) * abs(xdft).^2;       % normalize & take absolute
    psdx(2:end-1) = 2*psdx(2:end-1);        % discard DC
    freq = 0:Fs/N:Fs/2;                     % create frequency vector
    if figFlag
        subplot(2,1,i)
        plot(freq,10*log10(psdx))
        text_t = sprintf('PSD using N-point FFT, with N = %d', m(i));
        title(text_t, 'FontSize', 24)
        xlabel('Frequency [Hz]', 'FontSize', 24)
        ylabel('PSD [V$^2$/Hz]', 'FontSize', 24)
        grid on
    end
end