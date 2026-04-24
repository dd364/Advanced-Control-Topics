%% =========================================================
%  plot_hardware_final.m
%  Hardware Experimental Results (Truncated to 1000s)
%  - Individual Plots with Non-Blocking Zoom Insets
%  - Annotated SMC Chattering Analysis
%  - Anti-Overlap Master Comparison (Fixed 3x3 Subplot Grid)
% =========================================================
clear; clc; close all;

%% 1. DEFINE FILE NAMES
file_fbl  = 'FBL_opm_log_20260423_030945.csv';
file_smc  = 'smc2_log_20260423_033414.csv';
file_mrac = 'mrac_log_20260423_042756.csv';
file_pid  = 'pid2_log_20260423_050821.csv';

% Ensure files exist
files = {file_fbl, file_smc, file_mrac, file_pid};
for i = 1:length(files)
    if ~isfile(files{i})
        error('File %s not found. Please ensure it is in the current directory.', files{i});
    end
end

%% 2. EXTRACT AND CROP DATA (0 to 1000s)
T_set = 70.0; % Target Setpoint
max_t = 1000; % Crop simulation at 1000 seconds

[t_fbl, T_fbl, u_fbl, e_fbl]    = process_log(file_fbl, T_set, max_t);
[t_smc, T_smc, u_smc, e_smc]    = process_log(file_smc, T_set, max_t);
[t_mrac, T_mrac, u_mrac, e_mrac] = process_log(file_mrac, T_set, max_t);
[t_pid, T_pid, u_pid, e_pid]    = process_log(file_pid, T_set, max_t);

%% 3. PLOTTING CONFIGURATION
zoom_start = 800;  % Start time for the zoomed-in steady-state view
zoom_end   = 1000; % End time for the zoomed-in steady-state view

% Standardized Colors
c_pid  = [0.40 0.40 0.40]; % Gray
c_fbl  = [0.85 0.33 0.10]; % Orange
c_smc  = [0.00 0.60 0.30]; % Green
c_mrac = [0.00 0.45 0.70]; % Blue

%% =========================================================
%  PART A: INDIVIDUAL ALGORITHM PLOTS (1 to 4)
% =========================================================
plot_individual(1, 'PID Baseline', t_pid, T_pid, e_pid, u_pid, c_pid, T_set, max_t, zoom_start, zoom_end);
plot_individual(2, 'FBL (Linearised)', t_fbl, T_fbl, e_fbl, u_fbl, c_fbl, T_set, max_t, zoom_start, zoom_end);
plot_individual(3, 'SMC (Robust)', t_smc, T_smc, e_smc, u_smc, c_smc, T_set, max_t, zoom_start, zoom_end);
plot_individual(4, 'MRAC (Adaptive)', t_mrac, T_mrac, e_mrac, u_mrac, c_mrac, T_set, max_t, zoom_start, zoom_end);

%% =========================================================
%  PART B: MASTER COMPARISON PLOT (ANTI-OVERLAP)
% =========================================================
fig5 = figure('Name', 'Master Comparison', 'Position', [50, 50, 1300, 900], 'Color', 'w');

% --- Subplot 1: Temperature ---
ax1 = subplot(3, 3, [1 2]); hold on; grid on; box on;
% Visual Hierarchy to prevent overlapping hiding traces
plot(t_pid, T_pid, '-', 'Color', c_pid, 'LineWidth', 3.5, 'DisplayName', 'PID');
plot(t_fbl, T_fbl, '--', 'Color', c_fbl, 'LineWidth', 2.5, 'DisplayName', 'FBL');
plot(t_smc, T_smc, '-.', 'Color', c_smc, 'LineWidth', 2.0, 'DisplayName', 'SMC');
plot(t_mrac, T_mrac, '-', 'Color', c_mrac, 'LineWidth', 1.5, 'DisplayName', 'MRAC');
yline(T_set, 'k-', 'LineWidth', 1.0, 'DisplayName', 'Setpoint (70 °C)');
ylabel('Temperature (°C)', 'FontWeight', 'bold');
title('Macro View: Full Hardware Response (0 to 1000s)', 'FontWeight', 'bold', 'FontSize', 12);
legend('Location', 'southeast', 'FontSize', 9);
xlim([0 max_t]); ylim([20 80]);

% Zoom Temp Plot (Right Column)
ax1_z = subplot(3, 3, 3); hold on; grid on; box on;
plot(t_pid, T_pid, '-', 'Color', c_pid, 'LineWidth', 3.5);
plot(t_fbl, T_fbl, '--', 'Color', c_fbl, 'LineWidth', 2.5);
plot(t_smc, T_smc, '-.', 'Color', c_smc, 'LineWidth', 2.0);
plot(t_mrac, T_mrac, '-', 'Color', c_mrac, 'LineWidth', 1.5);
yline(T_set, 'k-', 'LineWidth', 1.0);
title('Zoom: Steady State (800-1000s)', 'FontWeight', 'bold', 'FontSize', 10);
xlim([zoom_start zoom_end]); ylim([69.2 70.8]);

% --- Subplot 2: Tracking Error ---
ax2 = subplot(3, 3, [4 5]); hold on; grid on; box on;
plot(t_pid, e_pid, '-', 'Color', c_pid, 'LineWidth', 3.5);
plot(t_fbl, e_fbl, '--', 'Color', c_fbl, 'LineWidth', 2.5);
plot(t_smc, e_smc, '-.', 'Color', c_smc, 'LineWidth', 2.0);
plot(t_mrac, e_mrac, '-', 'Color', c_mrac, 'LineWidth', 1.5);
yline(0, 'k-', 'LineWidth', 1.0);
ylabel('Tracking Error e(t) [K]', 'FontWeight', 'bold');
xlim([0 max_t]); ylim([-50 10]);

% Zoom Error Plot (Right Column)
ax2_z = subplot(3, 3, 6); hold on; grid on; box on;
fill([zoom_start zoom_end zoom_end zoom_start], [-0.5 -0.5 0.5 0.5], [0.85 0.95 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
plot(t_pid, e_pid, '-', 'Color', c_pid, 'LineWidth', 3.5);
plot(t_fbl, e_fbl, '--', 'Color', c_fbl, 'LineWidth', 2.5);
plot(t_smc, e_smc, '-.', 'Color', c_smc, 'LineWidth', 2.0);
plot(t_mrac, e_mrac, '-', 'Color', c_mrac, 'LineWidth', 1.5);
yline(0, 'k-', 'LineWidth', 1.0);
yline(0.5, 'r:', 'LineWidth', 1.0);
yline(-0.5, 'r:', 'LineWidth', 1.0);
title('Zoom: ±0.5K Bound', 'FontWeight', 'bold', 'FontSize', 10);
xlim([zoom_start zoom_end]); ylim([-1.0 1.0]);

% --- Subplot 3: DAC Voltage ---
ax3 = subplot(3, 3, [7 8]); hold on; grid on; box on;
plot(t_pid, u_pid, '-', 'Color', c_pid, 'LineWidth', 2.5);
plot(t_fbl, u_fbl, '--', 'Color', c_fbl, 'LineWidth', 2.0);
plot(t_smc, u_smc, '-.', 'Color', c_smc, 'LineWidth', 1.5);
plot(t_mrac, u_mrac, '-', 'Color', c_mrac, 'LineWidth', 1.0);
yline(1.057, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Firmware Limit');
xlabel('Time (s)', 'FontWeight', 'bold');
ylabel('DAC Voltage u(t) [V]', 'FontWeight', 'bold');
xlim([0 max_t]); ylim([0 1.2]);

% Zoom Voltage Plot (Right Column)
ax3_z = subplot(3, 3, 9); hold on; grid on; box on;
plot(t_pid, u_pid, '-', 'Color', c_pid, 'LineWidth', 2.5);
plot(t_fbl, u_fbl, '--', 'Color', c_fbl, 'LineWidth', 2.0);
plot(t_smc, u_smc, '-.', 'Color', c_smc, 'LineWidth', 1.5);
plot(t_mrac, u_mrac, '-', 'Color', c_mrac, 'LineWidth', 1.0);
xlabel('Time (s)', 'FontWeight', 'bold');
title('Zoom: Control Effort', 'FontWeight', 'bold', 'FontSize', 10);
xlim([zoom_start zoom_end]); ylim([0.35 0.70]);

% Layout Polish
sgtitle('Master Hardware Comparison: PID vs FBL vs SMC vs MRAC (Anti-Overlap Layout)', 'FontSize', 16, 'FontWeight', 'bold');
disp('All 5 plots generated successfully!');


%% =========================================================
%  HELPER FUNCTIONS
% =========================================================

function [t_out, T_out, u_out, e_out] = process_log(filename, T_set, max_t)
    % Reads CSV, aligns t=0 to EN=1, and crops at max_t
    data = readtable(filename);
    idx = find(data.EN == 1, 1, 'first');
    if isempty(idx), idx = 1; end
    
    t_raw = data.pc_time_s(idx:end) - data.pc_time_s(idx);
    T_raw = data.T_degC(idx:end);
    u_raw = data.u_V(idx:end);
    
    % Crop arrays to max_t
    valid = (t_raw <= max_t);
    t_out = t_raw(valid);
    T_out = T_raw(valid);
    u_out = u_raw(valid);
    e_out = T_out - T_set;
end

function plot_individual(fig_num, name, t, T, e, u, col, T_set, max_t, zoom_st, zoom_en)
    % Generates a 3-panel plot for a single dataset with NON-BLOCKING Zoom Insets
    figure(fig_num); 
    set(gcf, 'Position', [100+(fig_num*30), 100+(fig_num*30), 900, 850], 'Color', 'w', 'Name', name);
    
    % ---------------- 1. TEMPERATURE ----------------
    ax1 = subplot(3,1,1); hold on; grid on; box on;
    fill([0 max_t max_t 0], [T_set-0.5 T_set-0.5 T_set+0.5 T_set+0.5], [0.85 0.95 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5, 'DisplayName', '\pm0.5 K Band');
    plot(t, T, 'Color', col, 'LineWidth', 2, 'DisplayName', 'T(t)');
    yline(T_set, 'k--', 'LineWidth', 1.5, 'DisplayName', 'T_{ref}');
    title([name ' - Hardware Response (0 to 1000s)'], 'FontSize', 13, 'FontWeight', 'bold');
    ylabel('Temperature (°C)', 'FontWeight', 'bold');
    legend('Location', 'southeast'); % Legend Bottom-Right
    xlim([0 max_t]); ylim([20 80]);
    
    % Inset Zoom: Temperature (Moved to Top-Left empty space)
    ax_in1 = axes('Position', [0.18 0.73 0.22 0.11]); hold on; box on; grid on;
    fill([zoom_st zoom_en zoom_en zoom_st], [T_set-0.5 T_set-0.5 T_set+0.5 T_set+0.5], [0.85 0.95 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(ax_in1, t, T, 'Color', col, 'LineWidth', 1.5);
    yline(ax_in1, T_set, 'k--', 'LineWidth', 1.2);
    title(ax_in1, 'Steady-State Zoom', 'FontSize', 8, 'FontWeight', 'normal');
    xlim(ax_in1, [zoom_st zoom_en]); ylim(ax_in1, [69 71]);
    
    % ---------------- 2. ERROR ----------------
    ax2 = subplot(3,1,2); hold on; grid on; box on;
    fill([0 max_t max_t 0], [-0.5 -0.5 0.5 0.5], [0.85 0.95 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(t, e, 'Color', col, 'LineWidth', 1.5);
    yline(0, 'k--', 'LineWidth', 1.0);
    yline(0.5, 'r:', 'LineWidth', 1.0);
    yline(-0.5, 'r:', 'LineWidth', 1.0);
    ylabel('Error e(t) [K]', 'FontWeight', 'bold');
    legend('Location', 'southeast'); % Legend Bottom-Right
    xlim([0 max_t]); ylim([-50 10]);
    
    % Inset Zoom: Error (Moved to Top-Right empty space)
    ax_in2 = axes('Position', [0.68 0.46 0.22 0.11]); hold on; box on; grid on;
    fill([zoom_st zoom_en zoom_en zoom_st], [-0.5 -0.5 0.5 0.5], [0.85 0.95 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
    plot(ax_in2, t, e, 'Color', col, 'LineWidth', 1.5);
    yline(ax_in2, 0, 'k--', 'LineWidth', 1.0);
    yline(ax_in2, 0.5, 'r:', 'LineWidth', 1.0);
    yline(ax_in2, -0.5, 'r:', 'LineWidth', 1.0);
    title(ax_in2, 'Error Detail', 'FontSize', 8, 'FontWeight', 'normal');
    xlim(ax_in2, [zoom_st zoom_en]); ylim(ax_in2, [-1.5 1.5]);
    
    % ---------------- 3. VOLTAGE ----------------
    ax3 = subplot(3,1,3); hold on; grid on; box on;
    plot(t, u, 'Color', col, 'LineWidth', 1.5, 'DisplayName', 'u(t)');
    yline(1.057, 'r--', 'LineWidth', 1.2, 'DisplayName', 'Firmware Limit');
    yline(0.921, 'Color', [1 0.5 0], 'LineStyle', '--', 'LineWidth', 1.2, 'DisplayName', 'Linear Saturation');
    xlabel('Time (s)', 'FontWeight', 'bold');
    ylabel('DAC Voltage u(t) [V]', 'FontWeight', 'bold');
    legend('Location', 'northeast'); % Legend Top-Right
    xlim([0 max_t]); ylim([0 1.2]);
    
    % Inset Zoom: Voltage (Moved to Bottom-Right empty space)
    ax_in3 = axes('Position', [0.68 0.13 0.22 0.11]); hold on; box on; grid on;
    plot(ax_in3, t, u, 'Color', col, 'LineWidth', 1.5);
    title(ax_in3, 'Effort Detail', 'FontSize', 8, 'FontWeight', 'normal');
    xlim(ax_in3, [zoom_st zoom_en]); ylim(ax_in3, [0.4 0.6]);
    
    % --- SPECIAL: SMC CHATTERING ANNOTATION ---
    if contains(name, 'SMC')
        % Red Box indicating Severe Chattering at startup
        rectangle('Position', [0, 0.85, 45, 0.25], 'EdgeColor', 'r', 'LineWidth', 1.5, 'LineStyle', '--');
        text(22, 1.15, 'Severe Chattering', 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'FontSize', 10);
        
        % Arrow indicating smooth line later (Placed safely in empty space)
        text(450, 0.7, '\leftarrow Chattering Eliminated', 'Color', [0 0.5 0], 'FontWeight', 'bold', 'FontSize', 11);
    end
end