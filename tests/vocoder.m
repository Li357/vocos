fs = 48000;
order = 4;
shift = 20; % 2^20 multiplication for fixed-point arithmetic

% voice frequency range in Hz split into n_filters + 1 log-spaced
lo = 50;
hi = 7000;
n_filters = 16;

save_coeffs = true;
show_filter_response = false;
hear_output = false;
show_envelopes = false;
show_fft = false;

bands = logspace(log10(lo), log10(hi), n_filters + 1);

% assumes that fvox = fsam = fs
[vox, fvox] = audioread('voice.wav');      % modulator
[sample, fsam] = audioread('trumpet.wav'); % carrier
sample = sample(1:size(vox));              % trim carrier to modulator length

if show_envelopes
    % plot the original
    subplot(4, 1, 1);
    plot(vox);
    title('Original');
    xlabel('Time (s)');
    ylabel('Amplitude');
end

sz = num2cell(size(vox));
vocoded = zeros(sz{:});

% filters plus the LPF for envelope detection and HPF for unvoiced detection
coeffs = zeros(n_filters + 2, 10);

% LPF for envelope detection, 100Hz is a guestimate
lpf = designfilt("lowpassiir", ...
                  FilterOrder=order, ...
                  HalfPowerFrequency=100, ...
                  SampleRate=fs, ...
                  DesignMethod="butter");
filts = [];

for i = 1:n_filters
    df = designfilt("bandpassiir", ...
                    FilterOrder=order, ...
                    HalfPowerFrequency1=bands(i), ...
                    HalfPowerFrequency2=bands(i+1), ...
                    SampleRate=fs, ...
                    DesignMethod="butter");

    % get just b0, b1, b2, a1, a2 since a0 = 1 when normalized
    coeffs(i,:) = [df.Coefficients(1:1,1:3), df.Coefficients(1:1,5:6), df.Coefficients(2:2,1:3), df.Coefficients(2:2,5:6)];
    filts = [filts, df];

    filtered_vox = filter(df, vox);
    env_lpf = filter(lpf, abs(filtered_vox));       % rectify the signal and run thru LPF for envelope
    filtered_samp = filter(df, sample);

    vocoded = vocoded + (env_lpf .* filtered_samp); % use envelope to modulate carrier in corresponding bands
                                                    % and mix signals back together

    % show some of the envelopes for sanity checking
    if show_envelopes && i < 4
        subplot(4, 1, i+1);
        plot(filtered_vox);
        title(strcat('Band ', i));
        xlabel('Time (s)');
        ylabel('Amplitude');
        % 
        hold on
        % 
        plot(env_lpf);
        title(strcat('Envelope ', i));
        xlabel('Time (s)');
        ylabel('Amplitude');
    end
end

% to better capture high-frequency unvoiced sounds, we mix in some noise
hpf = designfilt("highpassiir", ...
                 FilterOrder=order, ...
                 HalfPowerFrequency=10000, ...
                 SampleRate=fs, ...
                 DesignMethod="butter");
filts = [filts, hpf];
coeffs(n_filters + 1,:) = [hpf.Coefficients(1:1,1:3), hpf.Coefficients(1:1,5:6), hpf.Coefficients(2:2,1:3), hpf.Coefficients(2:2,5:6)];
vox_hpf = filter(hpf, vox);
env_vox_hpf = filter(lpf, abs(vox_hpf));
noise = max(abs(vox)) * (2 * rand(size(vox)) - 1); % scale noise to [-absmax(vox), absmax(vox)]

scaled_noise = env_vox_hpf .* noise;
vocoded_with_noise = vocoded + scaled_noise;

if hear_output
    sound(100 * vocoded_with_noise, fs); % get some gain
end

if show_fft
    vocoded_with_noise_fft = fft(vocoded_with_noise);
    plot(fs / length(vox) * (0:length(vox)-1), abs(vocoded_with_noise_fft), 'LineWidth', 1);
    xlabel("f (Hz)");
    ylabel("|fft(X)|");

    hold on

    vocoded_fft = fft(vocoded);
    plot(fs / length(vox) * (0:length(vox)-1), abs(vocoded_fft), 'LineWidth', 1);
    xlabel("f (Hz)");
    ylabel("|fft(X)|");
end

if save_coeffs
    % add in coeffs for LPF at end
    coeffs(n_filters + 2,:) = [lpf.Coefficients(1:1,1:3), lpf.Coefficients(1:1,5:6), lpf.Coefficients(2:2,1:3), lpf.Coefficients(2:2,5:6)];
    % now write the coefficients to a file for Verilog $readmemh
    scaled_coeffs = round(vpa(coeffs) .* 2^(shift)); % more precision and apply FPA shift
    fd = fopen('../data/coeffs.mem', 'w');
    % annoying ugly for loop because matlab indexing is atrocious
    for j = 1:n_filters+1
        for k = 1:10
            fprintf(fd, '%s', dec2hex(scaled_coeffs(j,k), 8));
            if k < 10
                fprintf(fd, ' ');
            end
        end
        fprintf(fd, '\n');
    end
    fclose(fd);
end


if show_filter_response
    h = fvtool(filts(1));
    h.FrequencyScale = 'Log';
    for i = 2:n_filters+1
        addfilter(h, filts(i));
    end
end


