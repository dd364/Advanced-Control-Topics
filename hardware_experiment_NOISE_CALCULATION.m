%% =========================================================
%  calculate_system_metrics.m
%  1. Calculates Thermal Capacity (Cth) via Energy Balance
%  2. Calculates and plots TRUE Steady-State RMS Temperature Noise
% =========================================================
clear; clc; close all;

%% 1. DEFINE FILE NAMES
file_fbl  = 'FBL_opm_log_20260423_030945.csv';
file_smc  = 'smc2_log_20260423_033414.csv';
file_mrac = 'mrac_log_20260423_042756.csv';
file_pid  = 'pid2_log_20260423_050821.csv';

% Ensure files exist
files = {file_pid, file_fbl, file_smc, file_mrac};
names = {'PID', 'FBL', 'SMC', 'MRAC'};
colors = {[0.40 0.40 0.40], [0.85 0.33 0.10], [0.00 0.60 0.30], [0.00 0.45 0.70]};

%% 2. LOAD AND ALIGN DATA
data = struct();
for i = 1:4
    tbl = readtable(files{i});
    idx = find(tbl.EN == 1, 1, 'first');
    if isempty(idx), idx = 1; end
    
    data(i).t = tbl.pc_time_s(idx:end) - tbl.pc_time_s(idx);
    data(i).T = tbl.T_degC(idx:end);
    data(i).u = tbl.u_V(idx:end);
    data(i).Tamb = tbl.TempIn_degC(idx:end); 
    data(i).EN = tbl.EN(idx:end); % Save EN state to filter out the cool-down phase
    
    % Calculate ACTUAL physical power delivered by the heater
    % Formula: P = (10^(4u - 1)) / 200
    P_act = zeros(size(data(i).u));
    valid_u = data(i).u > 0;
    P_act(valid_u) = (10.^(4 .* data(i).u(valid_u) - 1)) ./ 200.0;
    data(i).P_act = P_act;
end

%% =========================================================
%  PART 1: THERMAL CAPACITY (C_th) ESTIMATION
% =========================================================
R_th = 48.0; % Thermal resistance (K/W)

% Define the integration window (e.g., from 31.3 C to 50 C)
idx_start = find(data(2).T >= 31.3, 1, 'first');
idx_end   = find(data(2).T >= 50, 1, 'first');

t_window = data(2).t(idx_start:idx_end);
T_window = data(2).T(idx_start:idx_end);
P_window = data(2).P_act(idx_start:idx_end);
Tamb_window = data(2).Tamb(idx_start:idx_end);

% Numerical Integration (Trapezoidal Rule)
delta_T = T_window(end) - T_window(1);
E_in = trapz(t_window, P_window);
E_loss = trapz(t_window, (T_window - Tamb_window) ./ R_th);

C_th_estimated = (E_in - E_loss) / delta_T;

fprintf('\n=== THERMAL CAPACITY ESTIMATION ===\n');
fprintf('Integration Window: %.1f °C to %.1f °C\n', T_window(1), T_window(end));
fprintf('Energy Input (Heater):  %.2f J\n', E_in);
fprintf('Energy Lost to Ambient: %.2f J\n', E_loss);
fprintf('Estimated C_th: %.4f J/K\n', C_th_estimated);

% --- FIGURE 1: C_th Estimation Proof (with corrected legend) ---
fig1 = figure('Name', 'Thermal Capacity Estimation', 'Position', [100, 100, 900, 500], 'Color', 'w');

yyaxis left;
h_temp = plot(data(2).t, data(2).T, 'k', 'LineWidth', 2); hold on;
% Filled area (just visual, no legend entry needed)
fill([t_window; flipud(t_window)], [T_window; ones(size(T_window))*20], ...
     [0.85 0.33 0.10], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
h_window = plot(t_window, T_window, 'r', 'LineWidth', 3);
ylabel('Temperature (°C)', 'FontWeight', 'bold');
ylim([20 80]);

yyaxis right;
h_power = plot(data(2).t, data(2).P_act, 'b--', 'LineWidth', 1.5);
ylabel('Actual Power Delivered (W)', 'FontWeight', 'bold');
ylim([0 3]);

xlim([0 40]);
xlabel('Time (s)', 'FontWeight', 'bold');
title(sprintf('Thermal Capacity Extraction via Energy Balance\nEstimated C_{th} = %.4f J/K', C_th_estimated), ...
      'FontSize', 14);

% Add legend combining both y-axes
legend([h_temp, h_window, h_power], ...
       {'Temperature', 'Temp. (integration window)', 'Power Delivered'}, ...
       'Location', 'northeast');

grid on;

%% =========================================================
%  PART 2: STEADY-STATE RMS NOISE ANALYSIS
% =========================================================
% We isolate the specific 800s to 1000s window where we KNOW it is stable, 
% AND we guarantee the controller is still turned on (EN == 1).
t_ss_start = 800;
t_ss_end   = 1000;

rms_values = zeros(1, 4);
noise_data = cell(1, 4);
time_data  = cell(1, 4);

for i = 1:4
    % Isolate true steady state
    ss_idx = (data(i).t >= t_ss_start) & (data(i).t <= t_ss_end) & (data(i).EN == 1);
    
    t_ss = data(i).t(ss_idx);
    T_ss = data(i).T(ss_idx);
    
    % Zero-mean the temperature to extract pure noise
    T_mean = mean(T_ss);
    T_noise = T_ss - T_mean;
    
    % Calculate RMS (Root Mean Square)
    rms_values(i) = sqrt(mean(T_noise.^2));
    
    % Store for plotting
    noise_data{i} = T_noise;
    time_data{i} = t_ss;
end

fprintf('\n=== TRUE STEADY-STATE RMS NOISE (800s - 1000s) ===\n');
for i = 1:4
    fprintf('%-5s Noise: %.2f mK (± %.3f °C)\n', names{i}, rms_values(i)*1000, rms_values(i));
end

% --- FIGURE 2: RMS Noise Comparison ---
fig2 = figure('Name', 'RMS Noise Analysis', 'Position', [150, 150, 1100, 600], 'Color', 'w');

% Left Plot: Noise Traces overlaid
subplot(1, 3, [1 2]); hold on; box on; grid on;
for i = 1:4
    plot(time_data{i}, noise_data{i}, 'Color', colors{i}, 'LineWidth', 1.0, 'DisplayName', names{i});
end
yline(0, 'k-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
yline(0.05, 'r:', 'LineWidth', 1.0, 'HandleVisibility', 'off');
yline(-0.05, 'r:', 'LineWidth', 1.0, 'HandleVisibility', 'off');
xlabel('Time (s)', 'FontWeight', 'bold');
ylabel('Zero-Mean Temperature Noise (°C)', 'FontWeight', 'bold');
title('True Steady-State Measurement Noise Traces (800s - 1000s)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'northeast');

% Dynamically scale the Y-axis based on the actual noise
max_noise_plot = max(rms_values) * 3; 
if max_noise_plot < 0.05, max_noise_plot = 0.05; end
ylim([-max_noise_plot max_noise_plot]);
xlim([t_ss_start t_ss_end]);

% Right Plot: Bar Chart of RMS in milli-Kelvins (mK)
ax_bar = subplot(1, 3, 3); hold on; box on; grid on;
bar_obj = bar(1:4, rms_values * 1000); 
bar_obj.FaceColor = 'flat';
for i = 1:4
    bar_obj.CData(i,:) = colors{i};
    % Add text on top of bars
    text(i, (rms_values(i)*1000) + (max(rms_values)*50), sprintf('%.1f mK', rms_values(i)*1000), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
set(gca, 'XTick', 1:4, 'XTickLabel', names);
ylabel('RMS Noise (mK)', 'FontWeight', 'bold');
title('Noise Magnitude', 'FontSize', 12, 'FontWeight', 'bold');
ylim([0 max(rms_values*1000) * 1.3]);

sgtitle('High-Resolution Temperature Noise Analysis', 'FontSize', 16, 'FontWeight', 'bold');