function rethresholding(sourceDir, chanTotNum, varargin)
% ======================================================================
% rethresholding is a function to extract the neural timestamps and
% waveforms from raw .ns6. It depends on NPMK-5.2.1.0
%
% input:
% - sourceDir: path of .ns6 file.
% - tarDir: complete path and name of saved waveforms
% - chanTotNum: number of output channels

% optional input:
% - threshold: either vector of threshold (negative, uV) or single
% positive value (rms multiplier)
% - chan:channels to be processed, need to be a subset of chanTotNum

% if parameters are not specified by optional args, this code will use
% uiopen for users to load parameter file. Else if parameters were 
% specified, the code will autosave the parameters under the same directory.

% for example:
%  rethresholding('E:\nyx\datafile002.ns6', 16, ...
% 'threshold', [-106 -95 -92 -95 -100 -99 -90  -116 -103 -121 -118],...
% 'chan', [1 3 5 6 7 9 10 11 12 13 16]);


% @ 2022 Yuxiao Ning           ningyuxiao@zju.edu.cn
% ======================================================================

%% parse input

[filepath, filename, ext] = fileparts(sourceDir);
if nargin == 2
    uiopen(filepath);
elseif nargin ~= 6
    error('Not enough input args');
else
    for i = 1:2
        switch varargin{2*i-1}
            case 'threshold'
                threshold = varargin{2*i};
            case 'chan'
                chan = varargin{2*i};
        end
    end
    t = clock;
    t = num2str(t(1:5),'%02d');
    t(isspace(t)) = [];
    save(fullfile(filepath,[t '.mat']),'threshold','chan');
end
    
%% 

openNSx(sourceDir);
wf = cell(chanTotNum,1);
ts = cell(chanTotNum,1);

if NS6.MetaTags.Timestamp > 1
    Timestamp = NS6.MetaTags.Timestamp;
%     splitNSxPauses([filepath '.ns6']);
    listing = dir([filepath '\' filename '-s*.ns6']);
    Spikes_out = [];
    for isplit = 1:length(listing)
        openNSx(fullfile(listing(isplit).folder,listing(isplit).name));
        Spikes = findSpikes(NS6, 'threshold',threshold,'channels',chan,'filter',[250 3000]);

        for i = 1:chanTotNum
            idx = find(Spikes.Electrode == i);
            wf{i,1} = [wf{i,1}; Spikes.Waveform(:,idx)'];
            ts{i,1} = [ts{i,1}; Spikes.TimeStamp(:,idx)' + Timestamp(isplit)];
        end        
    end
else
    Spikes = findSpikes(NS6, 'threshold',threshold,'channels',chan,'filter',[250 3000]);

    for i = 1:chanTotNum
        idx = find(Spikes.Electrode == i);
        wf{i,1} = [wf{i,1}; Spikes.Waveform(:,idx)'];
        ts{i,1} = [ts{i,1}; Spikes.TimeStamp(:,idx)' + TimeStamp];
    end  
end

save([fullfile(filepath,filename) '-spk.mat'],'wf','ts');
