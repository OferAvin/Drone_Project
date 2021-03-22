origChans= ["P3","C3", "F3", "Fz", "F4", "C4", "P4",...
    "Cz", "CM", "A1", "Fp1", "Fp2", "T3", "T5", "O1", "O2",...
    "X3", "X2", "F7", "F8", "X1", "A2", "T6", "T4"];
% delVec = zeros(1,length({EEG.chanlocs.labels}));
% for i = 1:length({EEG.chanlocs.labels})
%     currentChan = {EEG.chanlocs(i).labels};
%     if isempty(find(origChans == currentChan, 1))
%         delVec(i) = 1;
%     end    
% end
% delVec =logical(delVec);
% EEG.chanlocs(delVec) = [];

    