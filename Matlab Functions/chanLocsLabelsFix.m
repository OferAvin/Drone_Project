eeglab
EEG = pop_biosig('C:\Users\ophir\Desktop\Uni\BCI\13Hz_60RfRt_30sec_orange_M_filtered.edf');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off');

chanlocsLables = {EEG.chanlocs.labels};
for i=1:length(chanlocsLables)
    if startsWith(chanlocsLables(i),'EEG') && endsWith(chanlocsLables(i),"-Vref")
        lable_name = char(extractBetween(chanlocsLables(i),"EEG ","-Vref"));
        EEG.chanlocs(i).labels = lable_name;
    end
end
EEG=pop_chanedit(EEG,'lookup','C:\Users\ophir\Desktop\Uni\BCI\Drone_Project\eeg\standard_1005.elc');
eeglab redraw