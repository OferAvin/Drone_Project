function spec_output =  SpecPowerdrone(spec_output)
%MATLAB R2019b
%
%This function will take the fourier transform values, transform them into
%power values in dB units, and finally mean over all the results.
%
%specoutput- the matrix of the output from the spectrogram, from all the
%trials to mean over.
%
%mean_power - mean of the power in dB over all the trials.
%
%--------------------------------------------------------------------------------

%Tranform to power
spec_output = abs(spec_output);
spec_output = spec_output.^2;
%Transform to decibels
spec_output = 10*log10(spec_output);

