%% =========================================================
%  MRAC_sim_results.m  —  Section 6.4 simulation figures
%  Run AFTER build_MRAC_section6.m
% =========================================================
clear; clc;

mdl        = 'MRAC_Plant';
T_sim      = 300;      % Back to 300s (learning is fast now!)
T_ref      = 70;       
T_amb      = 25;
alpha_true = 0.0333;
alpha_hat0 = 0.0167; 

if ~bdIsLoaded(mdl)
    error('Run build_MRAC_section6.m first to create MRAC_Plant.slx.');
end

%% ── RUN SIMULATION ──
simOut = sim(mdl, 'StopTime', num2str(T_sim), 'ReturnWorkspaceOutputs', 'on');
t = simOut.tout(:);
T_mrac = simOut.get('T_MRAC').Data(:);
u_mrac = simOut.get('u_MRAC').Data(:);
alpha_hat = simOut.get('alpha_hat_MRAC').Data(:);
e_mrac = T_mrac - T_ref;

% Performance metrics
idx10 = find(T_mrac >= T_amb + 0.10*(T_ref - T_amb), 1, 'first');
idx90 = find(T_mrac >= T_amb + 0.90*(T_ref - T_amb), 1, 'first');
t_rise = t(idx90) - t(idx10);
sse_final = rms(e_mrac(t > T_sim - 50)); 
alpha_error_final = abs(alpha_hat(end) - alpha_true) / alpha_true * 100;

fprintf('=== MRAC Performance (High-Performance Tuning) ===\n');
fprintf('  Initial alpha error: -50%%\n');
fprintf('  Final alpha error:   %.2f%%\n', alpha_error_final);
fprintf('  Steady-State Error:  %.4f K (Expect exactly 0)\n', sse_final);

%% ════════════════════════════════════════════════════════
%  FIG 6.1 — Adaptive Temperature Tracking
%% ════════════════════════════════════════════════════════
fig1 = figure('Name', 'Fig 6.1 — MRAC Tracking', 'NumberTitle', 'off', ...
    'Position', [50 50 900 800], 'Color', 'white');

% --- 1. TEMPERATURE PLOT (MACRO) ---
ax1a = subplot(3,1,1); hold(ax1a, 'on');
plot(ax1a, t, T_mrac, 'b', 'LineWidth', 2);
plot(ax1a, [0 T_sim], [T_ref T_ref], 'r--', 'LineWidth', 1.2);
legend(ax1a, 'T(t) (Adaptive)', sprintf('T_{ref} = %d °C', T_ref), 'Location', 'southeast', 'FontSize', 9);
ylabel(ax1a, 'Temperature (°C)', 'FontSize', 9);
title(ax1a, {' ', 'Temperature response: Fast convergence via aggressive learning rate'}, 'FontSize', 10, 'FontWeight', 'bold');
grid(ax1a, 'on'); xlim(ax1a, [0 T_sim]); ylim(ax1a, [20 80]);

% --- 2. ERROR PLOT ---
ax1b = subplot(3,1,2); hold(ax1b, 'on');
plot(ax1b, t, e_mrac, 'b', 'LineWidth', 1.5);
plot(ax1b, [0 T_sim], [0 0], 'k--', 'LineWidth', 1);
ylabel(ax1b, 'e(t) = T − T_{ref} (K)', 'FontSize', 9);
title(ax1b, {' ', 'Tracking error: e(t) \to 0 via Barbalat''s Lemma'}, 'FontSize', 10, 'FontWeight', 'bold');
grid(ax1b, 'on'); xlim(ax1b, [0 T_sim]); ylim(ax1b, [-50 10]);

% --- 3. DAC VOLTAGE PLOT ---
ax1c = subplot(3,1,3); hold(ax1c, 'on');
plot(ax1c, t, u_mrac, 'b', 'LineWidth', 1.5);
plot(ax1c, [0 T_sim], [0.921 0.921], 'r--', 'LineWidth', 1.0);
plot(ax1c, [0 T_sim], [1.057 1.057], '--', 'Color', [.65 0 0], 'LineWidth', 1.0);
legend(ax1c, 'u(t)', 'Linear Saturation \approx 0.921 V', 'Firmware limit 1.057 V', 'Location', 'northeast', 'FontSize', 9);
xlabel(ax1c, 'Time (s)', 'FontSize', 9);
ylabel(ax1c, 'u(t) (V)', 'FontSize', 9);
title(ax1c, {' ', 'DAC Voltage: Aggressive initial output, settling smoothly'}, 'FontSize', 10, 'FontWeight', 'bold');
grid(ax1c, 'on'); xlim(ax1c, [0 T_sim]); ylim(ax1c, [0 1.2]);

% --- CREATE TEMPERATURE INSET LAST (Z-INDEX FIX) ---
ax_inset_T = axes('Position', [0.45 0.73 0.35 0.12]); hold(ax_inset_T, 'on'); box(ax_inset_T, 'on');
plot(ax_inset_T, [0 T_sim], [T_ref T_ref], 'r--', 'LineWidth', 1);
plot(ax_inset_T, t, T_mrac, 'b', 'LineWidth', 1.5);
xlim(ax_inset_T, [100 T_sim]); % Zoomed to the flat steady state
ylim(ax_inset_T, [69.8 70.2]); % Highly zoomed to prove exact zero error
grid(ax_inset_T, 'on');
title(ax_inset_T, 'Steady-State Zoom (t > 100s)', 'FontSize', 8, 'FontWeight', 'normal');

% Apply layout adjustments and bring inset to top
set(fig1, 'Units', 'normalized');
set(ax1a, 'Position', [0.11 0.68 0.83 0.23]);
set(ax1b, 'Position', [0.11 0.38 0.83 0.22]);
set(ax1c, 'Position', [0.11 0.08 0.83 0.22]);
uistack(ax_inset_T, 'top');
annotation(fig1, 'textbox', [0.02 0.94 0.96 0.05], ...
    'String', 'Fig. 6.1 — MRAC Adaptive Temperature Tracking (High-Performance Tuning)', ...
    'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
    'EdgeColor', 'none', 'FitBoxToText', 'off');

exportgraphics(fig1, 'fig_6_1_MRAC_tracking.pdf', 'ContentType', 'vector');
fprintf('Saved: fig_6_1_MRAC_tracking.pdf\n');

%% ════════════════════════════════════════════════════════
%  FIG 6.2 — Parameter Convergence
%% ════════════════════════════════════════════════════════
fig2 = figure('Name', 'Fig 6.2 — MRAC Parameter Convergence', 'NumberTitle', 'off', ...
    'Position', [80 80 900 550], 'Color', 'white');

ax2a = subplot(2,1,1); hold(ax2a, 'on');
plot(ax2a, t, alpha_hat, 'b', 'LineWidth', 2);
plot(ax2a, [0 T_sim], [alpha_true alpha_true], 'r--', 'LineWidth', 1.5);
plot(ax2a, 0, alpha_hat0, 'ko', 'MarkerFaceColor', 'k');
text(ax2a, 5, alpha_hat0, '\leftarrow \alpha_{hat}(0) = 0.0167 (-50% error)', 'FontSize', 9, 'VerticalAlignment', 'bottom');

legend(ax2a, 'Estimated \alpha_{hat}(t)', 'True Plant \alpha = 0.0333', 'Location', 'southeast', 'FontSize', 9);
ylabel(ax2a, 'Thermal Decay Rate (s^{-1})', 'FontSize', 9);
title(ax2a, {' ', 'Online Parameter Identification via Lyapunov Adaptation Law'}, 'FontSize', 10, 'FontWeight', 'bold');
grid(ax2a, 'on'); xlim(ax2a, [0 T_sim]); 
ylim(ax2a, [0.015 0.035]);

ax2b = subplot(2,1,2); hold(ax2b, 'on');
alpha_tilde = alpha_hat - alpha_true;
plot(ax2b, t, alpha_tilde, 'b', 'LineWidth', 1.5);
plot(ax2b, [0 T_sim], [0 0], 'k--', 'LineWidth', 1);
xlabel(ax2b, 'Time (s)', 'FontSize', 9);
ylabel(ax2b, 'Estimation Error \alpha_{tilde} (s^{-1})', 'FontSize', 9);
title(ax2b, {' ', 'Parameter Error: \alpha_{tilde}(t) \to 0 driven by Persistent Excitation'}, 'FontSize', 10, 'FontWeight', 'bold');
grid(ax2b, 'on'); xlim(ax2b, [0 T_sim]);

set(fig2, 'Units', 'normalized');
set(ax2a, 'Position', [0.11 0.55 0.83 0.34]);
set(ax2b, 'Position', [0.11 0.10 0.83 0.35]);
annotation(fig2, 'textbox', [0.02 0.94 0.96 0.05], ...
    'String', 'Fig. 6.2 — MRAC Rapid Parameter Convergence', ...
    'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', ...
    'EdgeColor', 'none', 'FitBoxToText', 'off');

exportgraphics(fig2, 'fig_6_2_MRAC_convergence.pdf', 'ContentType', 'vector');
fprintf('Saved: fig_6_2_MRAC_convergence.pdf\n');
fprintf('\n=== All MRAC figures saved successfully. ===\n');