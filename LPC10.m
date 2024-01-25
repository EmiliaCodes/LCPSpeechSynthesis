clearvars
clc
close all

% You can put your own audio here
synthesized_speech_padded = main("G&VAdvanced_05.wav");

function synthesized_speech_padded = main(source_file)
    % Read audio file and resample to 8kHz
    [y, original_fs] = audioread(source_file);
    target_fs = 8000;
    y_resampled = resample(y, target_fs, original_fs);

    % Frame processing
    [frames, pitch_periods] = processFrames(y_resampled, target_fs);

    % LPC Analysis
    [lpc_coefficients, residual_signals] = LPCAnalysis(frames, pitch_periods);

    % Voicing decision (vowel or consonant)
    voiced_frames = decideVoicing(frames, pitch_periods, target_fs);

    % LPC Synthesis
    synthesized_speech = LPCSynthesis(lpc_coefficients, voiced_frames, pitch_periods, size(residual_signals, 1), 160);

    % Zero-padding
    synthesized_speech_padded = normalize([zeros(target_fs*0.5, 1); synthesized_speech; zeros(target_fs*0.5, 1)], 'range', [-1, 1]);

    % Play and save synthesized speech
    sound(synthesized_speech_padded, 8000);
    filename = sprintf('synth_%s', source_file);
    audiowrite(filename, synthesized_speech_padded, 8000);
end

function [frames, pitch_periods] = processFrames(y_resampled, target_fs)
    % Frame parameters
    frame_length = 20e-3;
    frame_shift = 20e-3;
    frame_size = round(frame_length * target_fs);
    frame_shift_samples = round(frame_shift * target_fs);

    % Frame extraction
    num_frames = floor((length(y_resampled) - frame_size) / frame_shift_samples) + 1;
    frames = zeros(frame_size, num_frames);

    for i = 1:num_frames
        start_idx = (i - 1) * frame_shift_samples + 1;
        end_idx = start_idx + frame_size - 1;
        frames(:, i) = y_resampled(start_idx:end_idx);
    end

    % Preemphasis
    frames = applyPreemphasis(frames);
    
    % Hamming window
    frames = applyHammingWindow(frames);
    
    % Pitch period estimation
    pitch_periods = estimatePitchPeriod(frames);
end

function frames = applyPreemphasis(frames)
    alpha = 0.99;
    for i = 1:size(frames, 2)
        frames(:, i) = frames(:, i) - alpha * [0; frames(1:end-1, i)];
    end
end

function frames = applyHammingWindow(frames)
    frame_size = size(frames, 1);
    hamming_window = hamming(frame_size);
    
    for i = 1:size(frames, 2)
        frames(:, i) = frames(:, i) .* hamming_window;
    end
end

function pitch_periods = estimatePitchPeriod(frames)
    min_pitch_period = 5;
    max_pitch_period = 155;
    num_frames = size(frames, 2);
    pitch_periods = zeros(1, num_frames);

    for i = 1:num_frames
        frame = frames(:, i);
        mdf_values = calculateMDF(frame, min_pitch_period, max_pitch_period);
        [~, min_index] = min(mdf_values);
        pitch_periods(i) = min_pitch_period + min_index - 1;
    end
end

function mdf_values = calculateMDF(frame, min_pitch_period, max_pitch_period)
    mdf_values = zeros(1, max_pitch_period - min_pitch_period + 1);
    
    for lag = min_pitch_period:max_pitch_period
        delayed_frame = [zeros(1, lag), frame(1:end-lag)'];
        mdf_values(lag - min_pitch_period + 1) = sum(abs(frame - delayed_frame'));
    end
end

function [lpc_coefficients, residual_signals] = LPCAnalysis(frames, ~)
    order = 10;
    num_frames = size(frames, 2);
    lpc_coefficients = zeros(order + 1, num_frames);
    residual_signals = zeros(size(frames));

    for i = 1:num_frames
        frame = frames(:, i);
        autocorrelation = xcorr(frame);
        autocorrelation = autocorrelation(end - size(frame, 1) + 1:end);
        [lpc_coefficients(:, i), ~] = levinson(autocorrelation, order);
        residual_signals(:, i) = filter(lpc_coefficients(:, i), 1, frame);
    end
end

function voiced_frames = decideVoicing(frames, ~, ~)
    num_frames = size(frames, 2);
    voiced_frames = false(1, num_frames);
    voiced_threshold_zc = 0.002;
    voiced_threshold_energy = 0.005;

    for i = 1:num_frames
        frame = frames(:, i);
        zero_crossings = sum(frame(1:end-1) .* frame(2:end) < 0);
        zero_crossing_rate = zero_crossings / (size(frame, 1) - 1);
        energy = sum(frame.^2) / size(frame, 1);
        voiced_frames(i) = zero_crossing_rate < voiced_threshold_zc && energy > voiced_threshold_energy;
    end
end

function synthesized_speech = LPCSynthesis(lpc_coefficients, voiced, pitch_periods, frame_size, frame_shift_samples)
    num_frames = size(lpc_coefficients, 2);
    synthesized_speech = zeros((num_frames - 1) * frame_shift_samples + frame_size, 1);

    for i = 1:num_frames
        a = lpc_coefficients(:, i);
        pitch_period = pitch_periods(i);

        if voiced(i)
            excitation_signal = generateVoicedExcitation(frame_size, pitch_period);
        else
            excitation_signal = generateUnvoicedExcitation(frame_size);
        end

        synthesized_frame = filter(1, a, excitation_signal);
        
        start_idx = (i - 1) * frame_shift_samples + 1;
        end_idx = start_idx + frame_size - 1;
        synthesized_speech(start_idx:end_idx) = synthesized_speech(start_idx:end_idx) + synthesized_frame;
    end
end

function excitation_signal = generateVoicedExcitation(frame_size, pitch_period)
    excitation_signal = zeros(frame_size, 1);
    impulses = [1; zeros(pitch_period - 1, 1)];
    for j = 1:ceil(frame_size / pitch_period)
        excitation_signal((j - 1) * pitch_period + 1:min(j * pitch_period, frame_size)) = impulses(1:min(pitch_period, frame_size - (j - 1) * pitch_period));
    end
end

function excitation_signal = generateUnvoicedExcitation(frame_size)
    excitation_signal = 0.01 * randn(frame_size, 1);
end
