%% =========================================================
%  FEEDBACK_Linear_data.m (FBL_sim_results)
%  Produces all figures for Section 4.4 of the report.
%
%  Run AFTER build_FBL_section4.m has been executed once.
% =========================================================
clear; clc;

mdl    = 'FBL_Plant';
T_sim  = 300;
T_amb  = 25;
T_ref  = 70;
alpha  = 0.0333;
beta   = 1.6;
k1_nom = 1.5;

if ~bdIsLoaded(mdl)
    error('Run build_FBL_section4.m first.');
end

%% ════════════════════════════════════════════════════════
%  FIGURE 4.2 — Nominal step response + 5K disturbance
%% ════════════════════════════════════════════════════════
set_k1(mdl, k1_nom, alpha, beta);
[t_nom, T_nom, u_nom] = run_sim(mdl, T_sim);
e_nom = T_nom - T_ref;

% Performance metrics
span = T_ref - T_amb;
idx10 = find(T_nom >= T_amb+0.10*span,1,'first');
idx90 = find(T_nom >= T_amb+0.90*span,1,'first');
t_rise = t_nom(idx90) - t_nom(idx10);

oob_idx = find(abs(e_nom) > 0.5);
t_settle = t_nom(oob_idx(end));
sse = rms(e_nom(t_nom > 250));
overshoot = max(0, max(T_nom)-T_ref);

fprintf('=== FBL Nominal Performance (k1=%.2f) ===\n',k1_nom);
fprintf('  Rise time (10%%->90%%): %.1f s\n',t_rise);
fprintf('  Settling time (|e|<0.5K): %.1f s\n',t_settle);
fprintf('  Steady-state error rms: %.4f K\n',sse);
fprintf('  Overshoot: %.3f K\n',overshoot);
fprintf('  Closed-loop tau = 1/k1 = %.1f s\n',1/k1_nom);

fig1 = figure('Name','FBL Step Response','NumberTitle','off',...
    'Position',[50 50 1000 750],'Color','white');

% --- Subplot 1: Temperature with INSET ---
sp1 = subplot(3,1,1);
plot(t_nom, T_nom,'b','LineWidth',2); hold on;
yline(T_ref,'r--','LineWidth',1.2,'DisplayName',sprintf('T_{ref} = %d °C', T_ref));
xline(150,'--','Color',[.6 .4 0],'LineWidth',0.9,...
    'DisplayName','+5K disturbance');
fill([0 T_sim T_sim 0],[T_ref-.5 T_ref-.5 T_ref+.5 T_ref+.5],...
    [.85 .95 .85],'FaceAlpha',.3,'EdgeColor','none',...
    'DisplayName','±0.5 K band');
xlabel('Time (s)'); ylabel('Temperature (°C)');
title(sprintf('FBL — Temperature response  (k_1 = %.2f s^{-1}, \\tau_{cl} = %.0f s)',...
    k1_nom, 1/k1_nom));
legend('T(t)','T_{ref}','Disturbance','±0.5 K band','Location','southeast');
grid on; xlim([0 T_sim]); ylim([20 80]);
annotation_str = sprintf('Rise: %.0fs  Settle: %.0fs  SSE: %.3fK',...
    t_rise, t_settle, sse);
text(T_sim*0.02,77,annotation_str,'FontSize',9,'Color',[.3 .3 .3]);

% Zoomed Inset for Disturbance
ax_inset1 = axes('Position', [0.45, 0.76, 0.25, 0.12]);
plot(ax_inset1, t_nom, T_nom, 'b', 'LineWidth', 1.5); hold on;
yline(ax_inset1, T_ref, 'r--', 'LineWidth', 1.2);
xline(ax_inset1, 150, '--', 'Color', [.6 .4 0], 'LineWidth', 0.9);
fill(ax_inset1, [0 T_sim T_sim 0],[T_ref-.5 T_ref-.5 T_ref+.5 T_ref+.5],...
    [.85 .95 .85],'FaceAlpha',.3,'EdgeColor','none');
xlim(ax_inset1, [145 165]); ylim(ax_inset1, [69.5 72.5]);
grid(ax_inset1, 'on');
title(ax_inset1, 'Disturbance Detail', 'FontSize', 8, 'FontWeight', 'normal');

% --- Subplot 2: Error ---
sp2 = subplot(3,1,2);
plot(t_nom, e_nom,'b','LineWidth',1.5); hold on;
yline(0,'k--','LineWidth',0.8);
yline(0.5,'--','Color',[.6 .6 .6],'LineWidth',0.8);
yline(-0.5,'--','Color',[.6 .6 .6],'LineWidth',0.8);
xline(150,'--','Color',[.6 .4 0],'LineWidth',0.9);
xlabel('Time (s)'); ylabel('e(t) = T − T_{ref}  (K)');
title('Tracking error: converges to 0 exactly (perfect model knowledge)');
grid on; xlim([0 T_sim]);

% --- Subplot 3: Voltage ---
sp3 = subplot(3,1,3);
plot(t_nom, u_nom,'b','LineWidth',1.5); hold on;
yline(0.9212,'r--','LineWidth',1,'DisplayName','u_{sat} \approx 0.921 V');
yline(1.057,'--','Color',[.7 0 0],'LineWidth',0.8,'DisplayName','Firmware limit (1.057 V)');
xline(150,'--','Color',[.6 .4 0],'LineWidth',0.9);
xlabel('Time (s)'); ylabel('u(t)  (V)');
title('DAC command voltage (Limited to 1.2V max operating, clamped at 1.057V)');
legend('u(t)','Linear Saturation limit','Firmware limit','Location','northeast');
grid on; xlim([0 T_sim]); ylim([0 1.2]); % Expanded to 1.2V

sgtitle('Section 4 — Feedback Linearisation Controller: Nominal Response',...
    'FontWeight','bold','FontSize',13);
exportgraphics(fig1,'fig_4_2_FBL_step_response.pdf','ContentType','vector');
fprintf('Saved: fig_4_2_FBL_step_response.pdf\n');

%% ════════════════════════════════════════════════════════
%  FIGURE 4.3 — k1 parameter sweep
%% ════════════════════════════════════════════════════════
k1_vals   = [0.05, 0.10, 0.20, 0.50, 1.00];
colors_k1 = [0.70 0.85 0.70; 0.11 0.62 0.46; 0.09 0.45 0.70;
             0.85 0.55 0.10; 0.80 0.20 0.20];
labels_k1 = arrayfun(@(k) sprintf('k_1=%.2f (\\tau_{cl}=%.0fs)',k,1/k),...
    k1_vals,'UniformOutput',false);

results_k1 = struct('t',{},'T',{},'u',{},'k1',{});
for i = 1:length(k1_vals)
    set_k1(mdl, k1_vals(i), alpha, beta);
    [t,T,u] = run_sim(mdl, T_sim);
    results_k1(i).t=t; results_k1(i).T=T;
    results_k1(i).u=u; results_k1(i).k1=k1_vals(i);
    fprintf('  k1=%.2f: SSE=%.4fK\n',k1_vals(i),rms(T(t>T_sim-30)-T_ref));
end
set_k1(mdl, k1_nom, alpha, beta); % restore

fig2 = figure('Name','FBL k1 sweep','NumberTitle','off',...
    'Position',[80 80 1000 650],'Color','white');

% --- Subplot 1: Temperature Sweep with INSET ---
sp1 = subplot(2,1,1); hold on;
for i=1:length(k1_vals)
    plot(results_k1(i).t, results_k1(i).T,...
        'Color',colors_k1(i,:),'LineWidth',1.8);
end
yline(T_ref,'k--','LineWidth',1.2);
fill([0 T_sim T_sim 0],[T_ref-.5 T_ref-.5 T_ref+.5 T_ref+.5],...
    [.85 .95 .85],'FaceAlpha',.3,'EdgeColor','none');
legend(labels_k1,'Location','southeast','FontSize',9);
xlabel('Time (s)'); ylabel('Temperature (°C)');
title('FBL — k_1 sweep: closed-loop time constant \tau_{cl} = 1/k_1');
grid on; xlim([0 T_sim]); ylim([20 80]);

% Zoomed Inset for Rise Time
ax_inset2 = axes('Position', [0.45, 0.65, 0.25, 0.18]); hold(ax_inset2, 'on');
for i=1:length(k1_vals)
    plot(ax_inset2, results_k1(i).t, results_k1(i).T, 'Color', colors_k1(i,:), 'LineWidth', 1.5);
end
yline(ax_inset2, T_ref, 'k--', 'LineWidth', 1.2);
xlim(ax_inset2, [0 80]); ylim(ax_inset2, [25 75]);
grid(ax_inset2, 'on');
title(ax_inset2, 'Initial Rise Detail', 'FontSize', 8, 'FontWeight', 'normal');

% --- Subplot 2: Voltage Sweep ---
sp2 = subplot(2,1,2); hold on;
for i=1:length(k1_vals)
    plot(results_k1(i).t, results_k1(i).u,...
        'Color',colors_k1(i,:),'LineWidth',1.5);
end
yline(0.9212,'r--','LineWidth',1,'DisplayName','u_{sat} \approx 0.921 V');
yline(1.057,'--','Color',[.7 0 0],'LineWidth',0.8,'DisplayName','Firmware limit (1.057 V)');
legend([labels_k1,{'Linear Saturation (0.921V)','Firmware limit (1.057V)'}],'Location','northeast','FontSize',8);
xlabel('Time (s)'); ylabel('u(t)  (V)');
title('DAC voltage: larger k_1 demands more initial power');
grid on; xlim([0 T_sim]); ylim([0 1.2]); % Expanded to 1.2V

sgtitle('FBL Parameter Study: Effect of Gain k_1',...
    'FontWeight','bold','FontSize',13);
exportgraphics(fig2,'fig_4_3_FBL_k1_sweep.pdf','ContentType','vector');
fprintf('Saved: fig_4_3_FBL_k1_sweep.pdf\n');

%% ════════════════════════════════════════════════════════
%  FIGURE 4.4 — Model mismatch study
%% ════════════════════════════════════════════════════════
mismatch = [-40,-20,0,+20,+40,+80];
colors_mm = [0.80 0.10 0.10; 0.90 0.50 0.20; 0.11 0.62 0.46;
             0.09 0.45 0.70; 0.40 0.20 0.70; 0.20 0.20 0.20];

set_k1(mdl, k1_nom, alpha, beta);
results_mm = struct('t',{},'T',{},'pct',{});

for i = 1:length(mismatch)
    alpha_used = alpha * (1 + mismatch(i)/100);
    set_k1(mdl, k1_nom, alpha_used, beta);
    [t,T,~] = run_sim(mdl, T_sim);
    results_mm(i).t=t; results_mm(i).T=T; results_mm(i).pct=mismatch(i);
    sse_mm = mean(T(t>T_sim-30)) - T_ref;
    fprintf('  alpha mismatch %+d%%: SS error = %.3f K\n',mismatch(i),sse_mm);
end
set_k1(mdl, k1_nom, alpha, beta);

fig3 = figure('Name','FBL Mismatch','NumberTitle','off',...
    'Position',[100 100 1000 600],'Color','white');

% --- Subplot 1: Temperature Mismatch with INSET ---
sp1 = subplot(2,1,1); hold on;
for i=1:length(mismatch)
    plot(results_mm(i).t, results_mm(i).T,...
        'Color',colors_mm(i,:),'LineWidth',1.8);
end
yline(T_ref,'k--','LineWidth',1.2);
fill([0 T_sim T_sim 0],[T_ref-.5 T_ref-.5 T_ref+.5 T_ref+.5],...
    [.85 .95 .85],'FaceAlpha',.3,'EdgeColor','none');
labels_mm = arrayfun(@(p) sprintf('\\alpha error = %+d%%',p),...
    mismatch,'UniformOutput',false);
legend(labels_mm,'Location','southeast','FontSize',9);
xlabel('Time (s)'); ylabel('Temperature (°C)');
title({'FBL limitation: steady-state error grows with model mismatch in \alpha',...
    'Exact cancellation requires exact \alpha — motivates Sections 5 and 6'});
grid on; xlim([0 T_sim]); ylim([18 80]);

% Zoomed Inset for Steady-State Error
ax_inset3 = axes('Position', [0.45, 0.65, 0.25, 0.18]); hold(ax_inset3, 'on');
for i=1:length(mismatch)
    plot(ax_inset3, results_mm(i).t, results_mm(i).T, 'Color', colors_mm(i,:), 'LineWidth', 1.5);
end
yline(ax_inset3, T_ref, 'k--', 'LineWidth', 1.2);
xlim(ax_inset3, [200 300]); ylim(ax_inset3, [60 76]);
grid(ax_inset3, 'on');
title(ax_inset3, 'Steady-State Detail', 'FontSize', 8, 'FontWeight', 'normal');

% --- Subplot 2: Steady State Error Bars ---
sp2 = subplot(2,1,2);
ss_err = arrayfun(@(r) mean(r.T(r.t>T_sim-30))-T_ref, results_mm);
bar(mismatch, ss_err, 'FaceColor',[0.09 0.45 0.70],'EdgeColor','none');
yline(0.5,'r--','LineWidth',1.5); yline(-0.5,'r--','LineWidth',1.5);
xlabel('\alpha model error (%)'); ylabel('Steady-state error (K)');
title('FBL: steady-state offset is proportional to model error — zero only when model is exact');
grid on;

sgtitle('FBL Limitation: Effect of Model Mismatch in \alpha',...
    'FontWeight','bold','FontSize',13);
exportgraphics(fig3,'fig_4_4_FBL_mismatch.pdf','ContentType','vector');
fprintf('Saved: fig_4_4_FBL_mismatch.pdf\n');
fprintf('\n=== All figures saved. Add to report as Fig 4.2, 4.3, 4.4. ===\n');

%% ── HELPER FUNCTIONS (MUST BE AT THE VERY BOTTOM) ─────────
function [t,T,u] = run_sim(mdl,T_sim)
    simOut = sim(mdl,'StopTime',num2str(T_sim),...
        'ReturnWorkspaceOutputs','on','SaveOutput','on');
    t = simOut.tout(:);
    raw_T = []; raw_u = [];
    try, v=simOut.get('T_FBL'); raw_T=v.Data(:); catch, end
    try, v=simOut.get('u_FBL'); raw_u=v.Data(:); catch, end
    if isempty(raw_T), raw_T=zeros(size(t)); end
    if isempty(raw_u), raw_u=zeros(size(t)); end
    n=min([length(t),length(raw_T),length(raw_u)]);
    t=t(1:n); T=raw_T(1:n); u=raw_u(1:n);
end

function set_k1(mdl, k1_new, alpha, beta)
    fbl_path = [mdl '/FBL_Ctrl/FBL_Law'];
    rt = sfroot();
    ch = rt.find('-isa','Stateflow.EMChart','-and','Path',fbl_path);
    if ~isempty(ch)
        ch.Script = sprintf([...
            'function Pd = FBL_Law(e, T, Ta)\n'...
            '  alpha = %.10g;\n'...
            '  beta  = %.10g;\n'...
            '  k1    = %.10g;\n'...
            '  Pd    = (1/beta)*(alpha*(double(T)-double(Ta))-k1*double(e));\n'...
            '  Pd    = max(0, min(2.42, Pd));\n'...
            'end\n'], alpha, beta, k1_new);
        pause(0.2);
    end
end