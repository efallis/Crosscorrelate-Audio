clc;
close all;

% Navigate to location of all files
cd ''

% Defines
PLOT_NUM = 3;

% Configuration
samples = {'Nature', 'Music', 'Mechanical', 'Human'};
%samples = {'Nature', 'Music'};
mics = {'rec_inv', 'rec_pui', 'rec_st_analog', 'rec_st_embedded', 'rec_st_external'};
%mics = {'rec_inv'};
%mics = {'rec_pui', 'rec_st_embedded'};
names = {'InvenSense (Analog)', 'PUI (Analog)', 'ST (Analog)', 'ST (Digital Embedded)', 'ST (Digital External)'};
start = [3.16 2.40 2.68 2.92 2.70];
%start = [3.16];
%start = [1.6485 3.374];
maxCorr = [1.6728e+11 3.4696e+11 2.7497e+11 1.0349e+11];

% Variables
correlation = {[length(mics) 1]};
data = cell([length(mics)+1 length(samples)+1]);

%f = figure;
%uit = uitable(f);
%d = {'Audio','Nature','Music','Mechanical','Human','Total';'InvenSense (Analog)',31,23,73,117,244;'PUI (Analog)',39,20,76,126,261;'ST (Analog)',35,26,117,189,367;'ST (Embedded Digital)',34,19,109,118,280;'ST (External Digital)',39,23,112,135,309};
%uit.Data = d;
%uit.Position = [20 20 258 78];


% Loop through mics
for i = 1:length(mics)
    figure('Name', char(names(i)))
    title(names(i))
    data(i + 1, 1) = names(i);
    
    [y_mic,Fs_mic] = audioread(char(strcat('recording/', mics(i), '.wav')));
    y_mic = y_mic(:,1); % Only take real values
    
    % Loop through sounds
    for j = 1:length(samples)
        startTime = start(i) + 40.3395*(j - 1);  % Time where the audio clips start being recorded  
        rows = 0;
        
        [y_sample,Fs_sample] = audioread(char(strcat('source/', samples(j), '_combo.wav')));
        y_sample = y_sample(:,1);   % Only take real values
        y_sample = y_sample / max(y_sample);
        
        y_mic_normal = y_mic(round(startTime*Fs_mic):round((startTime + 40)*Fs_mic));    % Trim to only compare the matching audio clip
        y_mic_normal = y_mic_normal / max(y_mic_normal);    % Normalize

        % Raw
        subplot(PLOT_NUM, length(samples), rows*length(samples) + j);
        rows = rows + 1;

        plot_raw(y_sample, Fs_sample);
        hold on
        plot_raw(y_mic_normal, Fs_mic);
        legend({'Original','Recording'},'Location','northeast')
        
        title(char(samples(j)));
        
        
        % FFT
        subplot(PLOT_NUM, length(samples), rows*length(samples) + j);
        rows = rows + 1;
        
        [P1,Q1] = rat(Fs_mic/Fs_sample);          % Rational fraction approximation
        
        y_mic_96000 = resample(y_mic_normal,Q1,P1);
        
        %y_sample_96000 = resample(y_sample,P1,Q1);
        y_sample_96000 = y_sample;
        
        fft_sample = plot_fft(y_sample, Fs_sample);
        fft_sample = abs(fft_sample);
        hold on;
        %fft_mic = plot_fft(y_sample, Fs_sample);
        %fft_mic = abs(fft_mic);
        fft_mic = plot_fft(y_mic_96000, 96000);
        fft_mic = abs(fft_mic);
        
        % Correlation
        subplot(PLOT_NUM, length(samples), rows*length(samples) + j);
        rows = rows + 1;
        
        cross_corr = xcorr(fft_sample, fft_mic);
        %correlation(j,1) = max(cross_corr);
        
        data(1, j + 1) = samples(j);
        data(i + 1, j + 1) = num2cell(max(cross_corr)/maxCorr(j), 1);

        plot(cross_corr);
        %plot(y_sample_96000, y_sample_96000)
    end
    
    set(gcf, 'Position', [0, 50, 1275, 1300])
        
    %correlation(end) = sum(correlation(1:end-1));    % Last row is the sum
    %disp(char(strcat(names(i), ': ', mat2str(correlation))));
    
    %data(i + 1, :) = correlation;
end

%f = figure;
%uit = uitable(f);
%data(1, :) = {[''; samples]};
%data(:, 1) =  {[''; names]};

disp(data)
%uit.Data = data;
%uit.Position = [20 20 258 78];




h = figure;
u = uitable('Position',[20 20 500 70],'data',data);
table_extent = get(u,'Extent');
set(u,'Position',[1 1 table_extent(3) table_extent(4)])
figure_size = get(h,'outerposition');
desired_fig_size = [figure_size(1) figure_size(2) table_extent(3)+15 table_extent(4)+65];
set(h,'outerposition', desired_fig_size);





function plot_raw(y, Fs)
    t = (1:size(y))/Fs;
    p = plot(t, y);
    grid on
    set(gca, 'fontsize', 12);
    set(findall(gca, 'Type', 'Line'), 'LineWidth', 1.5);
    xlabel('Time (s)')
    ylabel('Amplitude')
    set(gca, 'XLim',[0 40]);
    set(gca, 'YLim',[-1 1]);
    p.Color(4) = 0.2;
end

function fft_y = plot_fft(y, Fs)
    L = length(y);
    fft_x = Fs*(0:(L/2))/L;
    fft_y = fft(y);

    P2 = abs(fft_y/L);
    P1 = P2(1:round(L/2+1));
    P1(2:end-1) = 2*P1(2:end-1);
    
    if (length(fft_x) ~= length(P1))
        P1 = P1(1:end-1);
    end
    
    p = plot(fft_x, P1);
    
    grid on
    set(gca, 'fontsize', 12);
    set(findall(gca, 'Type', 'Line'), 'LineWidth', 1.5);
    xlabel('Frequency (Hz)')
    ylabel('Amplitude')
    set(gca, 'XLim',[-100 4000]);
    set(gca, 'YLim',[0 0.020]);
    p.Color(4) = 0.2;
end
