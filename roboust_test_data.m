%% =========================================================
%  SMC_sim_results.m  —  Section 5.4 simulation figures
%  Run AFTER build_SMC_section5.m
% =========================================================
clear; clc;

mdl        = 'SMC_Plant';
T_sim      = 300;
T_ref      = 70;      % Aligned with FBL section
T_amb      = 25;
alpha_hat  = 0.0333;
beta       = 1.6;
k_s_nom    = 0.7;
phi_nom    = 0.5;
d_max      = 0.633;   
eta        = k_s_nom - d_max;   

if ~bdIsLoaded(mdl)
    error('Run build_SMC_section5.m first to create SMC_Plant.slx.');
end

%% ════════════════════════════════════════════════════════
%  FIG 5.2 — Nominal step response + +5K disturbance
%% ════════════════════════════════════════════════════════
set_smc(mdl, k_s_nom, phi_nom, alpha_hat, beta, alpha_hat);
[t_nom, T_nom, u_nom] = run_sim(mdl, T_sim);
e_nom = T_nom - T_ref;

fig1 = figure('Name', 'Fig 5.2 — SMC Nominal', 'NumberTitle', 'off', ...
    'Position', [50 50 900 850], 'Color', 'white');

% --- 1. TEMPERATURE PLOT (MACRO) ---
ax1a = subplot(3,1,1); hold(ax1a, 'on');
plot(ax1a, t_nom, T_nom, 'b', 'LineWidth', 2);
plot(ax1a, [0 T_sim], [T_ref T_ref], 'r--', 'LineWidth', 1.2);
xline(ax1a, 150, '--', 'Color', [.55 .35 0], 'LineWidth', 1.0);
fill(ax1a, [0 T_sim T_sim 0], ...
    [T_ref-phi_nom T_ref-phi_nom T_ref+phi_nom T_ref+phi_nom], ...
    [.82 .94 .82], 'FaceAlpha', .8, 'EdgeColor', 'none');
legend(ax1a, 'T(t)', sprintf('T_{ref} = %d °C', T_ref), '+5 K at t=150 s', ...
    sprintf('\\pm%.1f K band', phi_nom), 'Location', 'southeast', 'FontSize', 8);
ylabel(ax1a, 'Temperature (°C)', 'FontSize', 9);
title(ax1a, 'Temperature response with Steady-State Zoom', 'FontSize', 10, 'FontWeight', 'bold');
grid(ax1a, 'on'); xlim(ax1a, [0 T_sim]); ylim(ax1a, [20 80]);

% --- 2. ERROR/SLIDING SURFACE PLOT (MACRO) ---
ax1b = subplot(3,1,2); hold(ax1b, 'on');
plot(ax1b, t_nom, e_nom, 'b', 'LineWidth', 1.5);
plot(ax1b, [0 T_sim], [0 0], 'k--', 'LineWidth', 0.8);
plot(ax1b, [0 T_sim], [ phi_nom  phi_nom], '--', 'Color', [.6 .6 .6], 'LineWidth', 0.9);
plot(ax1b, [0 T_sim], [-phi_nom -phi_nom], '--', 'Color', [.6 .6 .6], 'LineWidth', 0.9);
xline(ax1b, 150, '--', 'Color', [.55 .35 0], 'LineWidth', 1.0);
ylabel(ax1b, 's(t) = T − T_{ref}  (K)', 'FontSize', 9);
title(ax1b, sprintf('Sliding surface converges into boundary layer |s| \\leq \\Phi = %.1f K', phi_nom), ...
    'FontSize', 10, 'FontWeight', 'bold');
grid(ax1b, 'on'); xlim(ax1b, [0 T_sim]); ylim(ax1b, [-50 10]);

% --- 3. DAC VOLTAGE PLOT ---
ax1c = subplot(3,1,3); hold(ax1c, 'on');
plot(ax1c, t_nom, u_nom, 'b', 'LineWidth', 1.5);
plot(ax1c, [0 T_sim], [0.921 0.921], 'r--', 'LineWidth', 1.0);
plot(ax1c, [0 T_sim], [1.057 1.057], '--', 'Color', [.65 0 0], 'LineWidth', 0.9);
legend(ax1c, 'u(t)', 'Linear Saturation \approx 0.921 V', 'Firmware limit 1.057 V', ...
    'Location', 'northeast', 'FontSize', 8);
xlabel(ax1c, 'Time (s)', 'FontSize', 9);
ylabel(ax1c, 'u(t)  (V)', 'FontSize', 9);
title(ax1c, 'DAC voltage — smooth due to sat() boundary layer', 'FontSize', 10, 'FontWeight', 'bold');
grid(ax1c, 'on'); xlim(ax1c, [0 T_sim]); ylim(ax1c, [0 1.2]);

% --- CREATE INSETS AT THE END SO THEY STAY ON TOP ---
ax_inset_T1 = axes('Position', [0.35 0.74 0.35 0.12]); hold(ax_inset_T1, 'on'); box(ax_inset_T1, 'on');
fill(ax_inset_T1, [0 T_sim T_sim 0], [T_ref-phi_nom T_ref-phi_nom T_ref+phi_nom T_ref+phi_nom], ...
    [.82 .94 .82], 'FaceAlpha', .6, 'EdgeColor', 'none');
plot(ax_inset_T1, [0 T_sim], [T_ref T_ref], 'r--', 'LineWidth', 1);
plot(ax_inset_T1, t_nom, T_nom, 'b', 'LineWidth', 1.5);
xlim(ax_inset_T1, [200 300]); ylim(ax_inset_T1, [69.2 70.8]);
grid(ax_inset_T1, 'on'); title(ax_inset_T1, 'Steady-State Zoom (t > 200s)', 'FontSize', 8, 'FontWeight', 'normal');

ax_inset_s1 = axes('Position', [0.35 0.43 0.35 0.12]); hold(ax_inset_s1, 'on'); box(ax_inset_s1, 'on');
plot(ax_inset_s1, [0 T_sim], [0 0], 'k--', 'LineWidth', 0.8);
plot(ax_inset_s1, [0 T_sim], [ phi_nom  phi_nom], '--', 'Color', [.6 .6 .6], 'LineWidth', 0.9);
plot(ax_inset_s1, [0 T_sim], [-phi_nom -phi_nom], '--', 'Color', [.6 .6 .6], 'LineWidth', 0.9);
plot(ax_inset_s1, t_nom, e_nom, 'b', 'LineWidth', 1.5);
xlim(ax_inset_s1, [200 300]); ylim(ax_inset_s1, [-0.8 0.8]);
grid(ax_inset_s1, 'on'); title(ax_inset_s1, 'Steady-State Error Zoom', 'FontSize', 8, 'FontWeight', 'normal');

% Layout Adjustments
set(fig1, 'Units', 'normalized');
set(ax1a, 'Position', [0.11 0.70 0.83 0.22]);
set(ax1b, 'Position', [0.11 0.39 0.83 0.22]);
set(ax1c, 'Position', [0.11 0.08 0.83 0.22]);
annotation(fig1, 'textbox', [0.02 0.95 0.96 0.05], 'String', 'Fig. 5.2 — SMC Robust Controller: Nominal Step Response', ...
    'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'EdgeColor', 'none', 'FitBoxToText', 'off');
uistack(ax_inset_T1, 'top'); uistack(ax_inset_s1, 'top');
exportgraphics(fig1, 'fig_5_2_SMC_step_response.pdf', 'ContentType', 'vector');
fprintf('Saved: fig_5_2_SMC_step_response.pdf\n');

%% ════════════════════════════════════════════════════════
%  FIG 5.3 — SMC vs FBL: robustness to ±20% α uncertainty
%% ════════════════════════════════════════════════════════
mismatch = [-20, 0, +20];
cols     = [0.80 0.15 0.15; 0.11 0.62 0.46; 0.09 0.45 0.70];
labels_m = arrayfun(@(p) sprintf('\\Delta\\alpha = %+d%%', p), mismatch, 'UniformOutput', false);
has_fbl = bdIsLoaded('FBL_Plant');

fig2 = figure('Name', 'Fig 5.3 — SMC vs FBL Mismatch', 'NumberTitle', 'off', ...
    'Position', [60 60 900 800], 'Color', 'white');

ax2a = subplot(2,1,1); hold(ax2a, 'on');
ax2b = subplot(2,1,2); hold(ax2b, 'on');

results_SMC = struct(); results_FBL = struct();

for i = 1:length(mismatch)
    alpha_true = alpha_hat * (1 + mismatch(i)/100);

    % SMC Run & Plot
    set_smc(mdl, k_s_nom, phi_nom, alpha_hat, beta, alpha_true);
    [t, T, ~] = run_sim(mdl, T_sim);
    results_SMC(i).t = t; results_SMC(i).T = T;
    
    plot(ax2a, t, T, 'Color', cols(i,:), 'LineWidth', 2, 'DisplayName', [labels_m{i} ' — SMC']);
    plot(ax2b, t, T - T_ref, 'Color', cols(i,:), 'LineWidth', 2, 'DisplayName', [labels_m{i} ' — SMC']);
    
    % FBL Run & Plot
    if has_fbl
        set_k1_fbl('FBL_Plant', 1.5, alpha_true, beta);  
        [tf, Tf, ~] = run_sim_fbl('FBL_Plant', T_sim);
        results_FBL(i).t = tf; results_FBL(i).T = Tf;
        
        plot(ax2a, tf, Tf, 'Color', cols(i,:), 'LineWidth', 1.3, 'LineStyle', '--', 'DisplayName', [labels_m{i} ' — FBL']);
        plot(ax2b, tf, Tf - T_ref, 'Color', cols(i,:), 'LineWidth', 1.3, 'LineStyle', '--');
    end
end

plot(ax2a, [0 T_sim], [T_ref T_ref], 'k--', 'LineWidth', 1.2);
legend(ax2a, 'Location', 'southeast', 'FontSize', 8);
ylabel(ax2a, 'Temperature (°C)', 'FontSize', 9);
title(ax2a, {' ', 'SMC (solid) vs FBL (dashed) — robustness to \pm20% uncertainty in \alpha'}, 'FontSize', 10, 'FontWeight', 'bold');
grid(ax2a, 'on'); xlim(ax2a, [0 T_sim]); ylim(ax2a, [20 80]);

plot(ax2b, [0 T_sim], [0 0], 'k--', 'LineWidth', 0.9);
plot(ax2b, [0 T_sim], [ .5  .5], 'r--', 'LineWidth', 1.0);
plot(ax2b, [0 T_sim], [-.5 -.5], 'r--', 'LineWidth', 1.0);
xlabel(ax2b, 'Time (s)', 'FontSize', 9); ylabel(ax2b, 'Error  e(t)  (K)', 'FontSize', 9);
title(ax2b, {' ', 'SMC stays within \pm0.5 K; FBL develops persistent steady-state offset'}, 'FontSize', 10, 'FontWeight', 'bold');
grid(ax2b, 'on'); xlim(ax2b, [0 T_sim]); ylim(ax2b, [-50 10]);

% --- CREATE INSETS ---
ax_inset_T2 = axes('Position', [0.45 0.62 0.30 0.15]); hold(ax_inset_T2, 'on'); box(ax_inset_T2, 'on');
for i = 1:length(mismatch)
    plot(ax_inset_T2, results_SMC(i).t, results_SMC(i).T, 'Color', cols(i,:), 'LineWidth', 2);
    if has_fbl
        plot(ax_inset_T2, results_FBL(i).t, results_FBL(i).T, 'Color', cols(i,:), 'LineWidth', 1.3, 'LineStyle', '--');
    end
end
plot(ax_inset_T2, [0 T_sim], [T_ref T_ref], 'k--', 'LineWidth', 0.8);
xlim(ax_inset_T2, [200 300]); ylim(ax_inset_T2, [69 71.5]); grid(ax_inset_T2, 'on');
title(ax_inset_T2, 'Temp. Detail (FBL drifts vs SMC tight)', 'FontSize', 8, 'FontWeight', 'normal');

ax_inset_err2 = axes('Position', [0.45 0.18 0.30 0.15]); hold(ax_inset_err2, 'on'); box(ax_inset_err2, 'on');
for i = 1:length(mismatch)
    plot(ax_inset_err2, results_SMC(i).t, results_SMC(i).T - T_ref, 'Color', cols(i,:), 'LineWidth', 2);
    if has_fbl
        plot(ax_inset_err2, results_FBL(i).t, results_FBL(i).T - T_ref, 'Color', cols(i,:), 'LineWidth', 1.3, 'LineStyle', '--');
    end
end
plot(ax_inset_err2, [0 T_sim], [0 0], 'k--', 'LineWidth', 0.8);
plot(ax_inset_err2, [0 T_sim], [ phi_nom  phi_nom], 'r--', 'LineWidth', 1.0);
plot(ax_inset_err2, [0 T_sim], [-phi_nom -phi_nom], 'r--', 'LineWidth', 1.0);
xlim(ax_inset_err2, [200 300]); ylim(ax_inset_err2, [-1.5 1.5]); grid(ax_inset_err2, 'on');
title(ax_inset_err2, 'Error Detail (FBL offset vs SMC bounded)', 'FontSize', 8, 'FontWeight', 'normal');

set(fig2, 'Units', 'normalized');
set(ax2a, 'Position', [0.11 0.52 0.83 0.34]);
set(ax2b, 'Position', [0.11 0.08 0.83 0.34]);
annotation(fig2, 'textbox', [0.02 0.95 0.96 0.05], 'String', 'Fig. 5.3 — SMC Robustness vs FBL under Parameter Uncertainty', ...
    'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'EdgeColor', 'none', 'FitBoxToText', 'off');
uistack(ax_inset_T2, 'top'); uistack(ax_inset_err2, 'top');
exportgraphics(fig2, 'fig_5_3_SMC_vs_FBL.pdf', 'ContentType', 'vector');
fprintf('Saved: fig_5_3_SMC_vs_FBL.pdf\n');

%% ════════════════════════════════════════════════════════
%  FIG 5.4 — Boundary layer φ sweep
%% ════════════════════════════════════════════════════════
phi_vals = [0.1, 0.5, 1.0, 2.0, 5.0];
col_phi  = [0.80 0.10 0.10; 0.09 0.45 0.70; 0.11 0.62 0.46; 0.85 0.55 0.10; 0.40 0.20 0.70];
alpha_mm = alpha_hat * 1.20;   

fig4 = figure('Name', 'Fig 5.4 — Boundary Layer Sweep', 'NumberTitle', 'off', ...
    'Position', [70 70 900 680], 'Color', 'white');

ax4a = subplot(2,1,1); hold(ax4a, 'on');
ax4b = subplot(2,1,2); hold(ax4b, 'on');

results_phi = struct();
for i = 1:length(phi_vals)
    set_smc(mdl, k_s_nom, phi_vals(i), alpha_hat, beta, alpha_mm);
    [t, T, u] = run_sim(mdl, T_sim);
    results_phi(i).t = t; results_phi(i).T = T;
    
    lbl = sprintf('\\Phi = %.1f K', phi_vals(i));
    plot(ax4a, t, T, 'Color', col_phi(i,:), 'LineWidth', 1.8, 'DisplayName', lbl);
    plot(ax4b, t, u, 'Color', col_phi(i,:), 'LineWidth', 1.5, 'DisplayName', lbl);
end

plot(ax4a, [0 T_sim], [T_ref T_ref], 'k--', 'LineWidth', 1.2);
legend(ax4a, 'Location', 'southeast', 'FontSize', 8);
ylabel(ax4a, 'Temperature (°C)', 'FontSize', 9);
title(ax4a, {' ', 'Smaller \Phi: tighter tracking, more switching  (\Delta\alpha = +20%)'}, 'FontSize', 10, 'FontWeight', 'bold');
grid(ax4a, 'on'); xlim(ax4a, [0 T_sim]); ylim(ax4a, [20 80]);

plot(ax4b, [0 T_sim], [0.921 0.921], 'r--', 'LineWidth', 1.0);
legend(ax4b, 'Location', 'northeast', 'FontSize', 8);
xlabel(ax4b, 'Time (s)', 'FontSize', 9); ylabel(ax4b, 'u(t)  (V)', 'FontSize', 9);
title(ax4b, {' ', 'DAC voltage — larger \Phi gives smoother control signal'}, 'FontSize', 10, 'FontWeight', 'bold');
grid(ax4b, 'on'); xlim(ax4b, [0 T_sim]); ylim(ax4b, [0 1.2]);

% --- CREATE INSET ---
ax_inset_T4 = axes('Position', [0.45 0.58 0.28 0.18]); hold(ax_inset_T4, 'on'); box(ax_inset_T4, 'on');
for i = 1:length(phi_vals)
    plot(ax_inset_T4, results_phi(i).t, results_phi(i).T, 'Color', col_phi(i,:), 'LineWidth', 1.8);
end
plot(ax_inset_T4, [0 T_sim], [T_ref T_ref], 'k--', 'LineWidth', 1.0);
xlim(ax_inset_T4, [100 200]); ylim(ax_inset_T4, [65 75]); grid(ax_inset_T4, 'on');
title(ax_inset_T4, 'Steady-State Offset Detail', 'FontSize', 8, 'FontWeight', 'normal');

set(fig4, 'Units', 'normalized');
set(ax4a, 'Position', [0.11 0.52 0.83 0.34]);
set(ax4b, 'Position', [0.11 0.08 0.83 0.34]);
annotation(fig4, 'textbox', [0.02 0.95 0.96 0.05], 'String', 'Fig. 5.4 — Boundary Layer Trade-off: Accuracy vs Smoothness (\Delta\alpha = +20%)', ...
    'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'EdgeColor', 'none', 'FitBoxToText', 'off');
uistack(ax_inset_T4, 'top');
exportgraphics(fig4, 'fig_5_4_SMC_phi_sweep.pdf', 'ContentType', 'vector');
fprintf('Saved: fig_5_4_SMC_phi_sweep.pdf\n');

%% ════════════════════════════════════════════════════════
%  FIG 5.5 — Chattering analysis: sign() vs sat(s/φ)
%% ════════════════════════════════════════════════════════
set_smc(mdl, k_s_nom, 0.001, alpha_hat, beta, alpha_hat);
[t_sgn, T_sgn, u_sgn] = run_sim(mdl, T_sim);
set_smc(mdl, k_s_nom, phi_nom, alpha_hat, beta, alpha_hat);
[t_sat, T_sat, u_sat] = run_sim(mdl, T_sim);

t_zoom = [200 300];
mask_sgn = (t_sgn >= t_zoom(1) & t_sgn <= t_zoom(2));
mask_sat = (t_sat >= t_zoom(1) & t_sat <= t_zoom(2));

fig5 = figure('Name', 'Fig 5.5 — Chattering Analysis', 'NumberTitle', 'off', ...
    'Position', [80 80 900 780], 'Color', 'white');

ax5a = subplot(3,1,1); hold(ax5a, 'on');
plot(ax5a, t_sgn, T_sgn, 'r',  'LineWidth', 1.5, 'DisplayName', 'sign(s) — ideal  (\Phi \to 0)');
plot(ax5a, t_sat, T_sat, 'b',  'LineWidth', 2.0, 'DisplayName', sprintf('sat(s/\\Phi) — \\Phi = %.1f K', phi_nom));
plot(ax5a, [0 T_sim], [T_ref T_ref], 'k--', 'LineWidth', 1.0);
legend(ax5a, 'Location', 'southeast', 'FontSize', 8);
ylabel(ax5a, 'Temperature (°C)', 'FontSize', 9);
title(ax5a, 'Temperature: both sign() and sat() converge to T_{ref}', 'FontSize', 10, 'FontWeight', 'bold');
grid(ax5a, 'on'); xlim(ax5a, [0 T_sim]); ylim(ax5a, [20 80]);

ax5b = subplot(3,1,2); hold(ax5b, 'on');
plot(ax5b, t_sgn, u_sgn, 'r', 'LineWidth', 1.0, 'DisplayName', 'sign(s) — chattering');
plot(ax5b, t_sat, u_sat, 'b', 'LineWidth', 2.0, 'DisplayName', 'sat(s/\Phi) — smooth');
legend(ax5b, 'Location', 'northeast', 'FontSize', 8);
ylabel(ax5b, 'u(t)  (V)', 'FontSize', 9);
title(ax5b, 'DAC voltage — full duration', 'FontSize', 10, 'FontWeight', 'bold');
grid(ax5b, 'on'); xlim(ax5b, [0 T_sim]); ylim(ax5b, [0 1.2]);

ax5c = subplot(3,1,3); hold(ax5c, 'on');
plot(ax5c, t_sgn(mask_sgn), u_sgn(mask_sgn), 'r', 'LineWidth', 1.2, 'DisplayName', 'sign(s) — high-frequency switching');
plot(ax5c, t_sat(mask_sat), u_sat(mask_sat), 'b', 'LineWidth', 2.0, 'DisplayName', sprintf('sat(s/\\Phi),  \\Phi = %.1f K — smooth', phi_nom));
legend(ax5c, 'Location', 'best', 'FontSize', 8);
xlabel(ax5c, 'Time (s)', 'FontSize', 9); ylabel(ax5c, 'u(t)  (V)', 'FontSize', 9);
title(ax5c, sprintf('Zoom t \\in [%d, %d] s — boundary layer eliminates chattering', t_zoom(1), t_zoom(2)), 'FontSize', 10, 'FontWeight', 'bold');
grid(ax5c, 'on'); xlim(ax5c, t_zoom); ylim(ax5c, [0 1.2]);

% --- CREATE INSET ---
ax_inset_T5 = axes('Position', [0.40 0.77 0.25 0.12]); hold(ax_inset_T5, 'on'); box(ax_inset_T5, 'on');
plot(ax_inset_T5, t_sgn, T_sgn, 'r', 'LineWidth', 1.5);
plot(ax_inset_T5, t_sat, T_sat, 'b', 'LineWidth', 2.0);
plot(ax_inset_T5, [0 T_sim], [T_ref T_ref], 'k--', 'LineWidth', 1.0);
xlim(ax_inset_T5, [250 260]); ylim(ax_inset_T5, [69.95 70.05]); 
grid(ax_inset_T5, 'on'); title(ax_inset_T5, 'Temp Ripple Zoom (sign vs sat)', 'FontSize', 8, 'FontWeight', 'normal');

set(fig5, 'Units', 'normalized');
set(ax5a, 'Position', [0.11 0.70 0.83 0.22]);
set(ax5b, 'Position', [0.11 0.41 0.83 0.22]);
set(ax5c, 'Position', [0.11 0.09 0.83 0.24]);
annotation(fig5, 'textbox', [0.02 0.94 0.96 0.055], 'String', 'Fig. 5.5 — Chattering Analysis: sign() vs sat() Boundary Layer', ...
    'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'EdgeColor', 'none', 'FitBoxToText', 'off');
uistack(ax_inset_T5, 'top');
exportgraphics(fig5, 'fig_5_5_SMC_no_chattering.pdf', 'ContentType', 'vector');
fprintf('Saved: fig_5_5_SMC_no_chattering.pdf\n');

% Restore nominal plant
set_smc(mdl, k_s_nom, phi_nom, alpha_hat, beta, alpha_hat);

%% ── LOCAL FUNCTIONS ──────────────────────────────────────
function [t, T, u] = run_sim(mdl, T_sim)
    simOut = sim(mdl, 'StopTime', num2str(T_sim), 'ReturnWorkspaceOutputs', 'on', 'SaveOutput', 'on');
    t = simOut.tout(:);
    raw_T = []; raw_u = [];
    try, v = simOut.get('T_SMC'); raw_T = v.Data(:); catch, end
    try, v = simOut.get('u_SMC'); raw_u = v.Data(:); catch, end
    if isempty(raw_T), raw_T = zeros(size(t)); end
    if isempty(raw_u), raw_u = zeros(size(t)); end
    n = min([length(t), length(raw_T), length(raw_u)]);
    t = t(1:n); T = raw_T(1:n); u = raw_u(1:n);
end

function set_smc(mdl, k_s, phi_BL, alpha_hat, beta, alpha_true)
    smc_path = [mdl '/SMC_Ctrl/SMC_Law'];
    rt = sfroot();
    ch = rt.find('-isa', 'Stateflow.EMChart', '-and', 'Path', smc_path);
    if ~isempty(ch)
        ch.Script = sprintf([ ...
            'function Pd = SMC_Law(T, Tref, Ta)\n'                                  ...
            '%%#codegen\n'                                                          ...
            '  alpha_hat = %.10g;\n'                                                ...
            '  beta      = %.10g;\n'                                                ...
            '  k_s       = %.10g;\n'                                                ...
            '  phi_BL    = %.10g;\n'                                                ...
            '  s = double(T) - double(Tref);\n'                                     ...
            '  if abs(s) > phi_BL\n'                                                ...
            '    sat_val = sign(s);\n'                                              ...
            '  else\n'                                                              ...
            '    sat_val = s / phi_BL;\n'                                           ...
            '  end\n'                                                               ...
            '  Pd = (1/beta)*(alpha_hat*(double(T)-double(Ta))-k_s*sat_val);\n'     ...
            '  Pd = max(0, min(2.42, Pd));\n'                                       ...
            'end\n'], alpha_hat, beta, k_s, phi_BL);
        pause(0.2);
    end
    set_param([mdl '/Plant/Ga'], 'Gain', num2str(alpha_true));
    set_param(mdl, 'SimulationCommand', 'update');
    pause(0.1);
end

function [t, T, u] = run_sim_fbl(mdl, T_sim)
    simOut = sim(mdl, 'StopTime', num2str(T_sim), 'ReturnWorkspaceOutputs', 'on', 'SaveOutput', 'on');
    t = simOut.tout(:);
    raw_T = []; raw_u = [];
    try, v = simOut.get('T_FBL'); raw_T = v.Data(:); catch, end
    try, v = simOut.get('u_FBL'); raw_u = v.Data(:); catch, end
    if isempty(raw_T), raw_T = zeros(size(t)); end
    if isempty(raw_u), raw_u = zeros(size(t)); end
    n = min([length(t), length(raw_T), length(raw_u)]);
    t = t(1:n); T = raw_T(1:n); u = raw_u(1:n);
end

function set_k1_fbl(mdl, k1, alpha, beta)
    fbl_path = [mdl '/FBL_Ctrl/FBL_Law'];
    rt = sfroot();
    ch = rt.find('-isa', 'Stateflow.EMChart', '-and', 'Path', fbl_path);
    if ~isempty(ch)
        ch.Script = sprintf([ ...
            'function Pd = FBL_Law(e, T, Ta)\n'                                     ...
            '  alpha = %.10g; beta = %.10g; k1 = %.10g;\n'                          ...
            '  Pd = (1/beta)*(alpha*(double(T)-double(Ta))-k1*double(e));\n'        ...
            '  Pd = max(0, min(2.42, Pd));\n'                                       ...
            'end\n'], alpha, beta, k1);
        pause(0.15);
    end
end