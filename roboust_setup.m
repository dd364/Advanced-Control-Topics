%% =========================================================
%  build_SMC_section5.m
%  Builds SMC_Plant.slx — aligned with report Section 5.
%
%  Plant model (report eq 2.11):
%    Tdot = -alpha*(T-Tamb) + beta*phi(u)
%
%  Actuation map phi(u)  (report eq 2.9):
%    phi(u) = (1/200) * 10^(4u-1)   [W]
%
%  Inverse map phi^-1    (report eq 2.10):
%    phi_inv(Pd) = (log10(200*Pd)+1)/4   [V]
%
%  Sliding surface       (report eq 5.1):
%    s = T - T_ref
%
%  Full virtual power    (report eq 5.3):
%    Pd = (1/beta)*[alpha_hat*(T-Tamb) - k_s*sat(s/Phi_BL)]
%
%  DAC voltage           (report eq 5.4):
%    u = phi_inv(Pd)  clipped to [0, 1.057] V
%
%  Uncertainty (Assumption B1):  |Δα/α_hat| ≤ 0.20  (±20%)
%  β treated as known (Assumption B2)
%
%  Run ONCE, then use SMC_sim_results.m for figures 5.2–5.5.
% =========================================================
clear; clc;

%% ── PARAMETERS ──
alpha_hat = 0.0333;   % nominal thermal decay rate [s^-1]
beta      = 1.6;      % thermal capacity gain [K/J]  (known)
T_ref     = 70;       % setpoint temperature [°C]
T_amb     = 25;       % nominal ambient temperature [°C]
T_init    = 25;       % initial cell temperature [°C]
k_s       = 0.7;      % switching gain  (k_s > d_max = 0.633)
phi_BL    = 0.5;      % boundary layer [K]  
T_sim     = 300;      % simulation duration [s]
u_max     = 1.057;    % firmware DAC clamp [V]  
P_max     = 2.42;     % hardware power limit [W] 

%% ── CREATE / RESET MODEL ────────────────────────────────
mdl = 'SMC_Plant';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'Location', [50 50 1400 820]);

%% ── LAYOUT CONSTANTS ────────────────────────────────────
xRef = 80;  xSMC = 300;  xPhi = 460;  xSat = 580;
xAct = 700; xPlt = 840;  xOut = 1010;
yM = 240;   H = 50;

%% ── TOP-LEVEL BLOCKS ────────────────────────────────────
add_block('simulink/Sources/Step', [mdl '/T_ref'], ...
    'Position',   posr(xRef, yM, 80, H), ...
    'Time',       '0', 'Before', num2str(T_amb), 'After', num2str(T_ref), ...
    'SampleTime', '0');

add_block('simulink/Sources/Step', [mdl '/T_amb'], ...
    'Position',   posr(xRef, yM+120, 80, H), ...
    'Time',       '150', 'Before', num2str(T_amb), 'After', num2str(T_amb + 5), ...
    'SampleTime', '0');

add_block('simulink/Ports & Subsystems/Subsystem', [mdl '/SMC_Ctrl'], ...
    'Position', posr(xSMC, yM, 160, H+10));

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [mdl '/phi_inv'], 'Position', posr(xPhi, yM, 110, H));

add_block('simulink/Discontinuities/Saturation', [mdl '/Sat_u'], ...
    'Position',   posr(xSat, yM, 50, H), ...
    'UpperLimit', num2str(u_max), 'LowerLimit', '0');

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [mdl '/Actuator'], 'Position', posr(xAct, yM, 110, H));

add_block('simulink/Ports & Subsystems/Subsystem', [mdl '/Plant'], ...
    'Position', posr(xPlt, yM, 120, H+10));

add_block('simulink/Sinks/Scope', [mdl '/Scope'], ...
    'Position', posr(xOut, yM, 60, H), 'NumInputPorts', '2');
add_block('simulink/Sinks/To Workspace', [mdl '/Log_T'], ...
    'Position', posr(xOut, yM+80, 70, 28), ...
    'VariableName', 'T_SMC', 'SaveFormat', 'Timeseries', 'MaxDataPoints', 'inf');
add_block('simulink/Sinks/To Workspace', [mdl '/Log_u'], ...
    'Position', posr(xSat, yM+80, 70, 28), ...
    'VariableName', 'u_SMC', 'SaveFormat', 'Timeseries', 'MaxDataPoints', 'inf');

%% ── SMC CONTROLLER SUBSYSTEM ────────────────────────────
smc = [mdl '/SMC_Ctrl'];
delete_line(smc, 'In1/1', 'Out1/1');
delete_block([smc '/In1']); delete_block([smc '/Out1']);

add_block('simulink/Sources/In1', [smc '/T'],    'Position', posr(20,  40, 45, 28), 'Port', '1');
add_block('simulink/Sources/In1', [smc '/Tref'], 'Position', posr(20, 100, 45, 28), 'Port', '2');
add_block('simulink/Sources/In1', [smc '/Ta'],   'Position', posr(20, 160, 45, 28), 'Port', '3');
add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [smc '/SMC_Law'], 'Position', posr(190, 90, 235, 110));
add_block('simulink/Sinks/Out1', [smc '/Pd'], 'Position', posr(425, 110, 45, 28), 'Port', '1');

rt = sfroot();
ch = rt.find('-isa', 'Stateflow.EMChart', '-and', 'Path', [smc '/SMC_Law']);
if ~isempty(ch)
    ch.Script = sprintf([ ...
        'function Pd = SMC_Law(T, Tref, Ta)\n'                                        ...
        '%%#codegen\n'                                                                ...
        '  alpha_hat = %.10g;  %% nominal alpha [s^-1]\n'                               ...
        '  beta      = %.10g;  %% known beta  [K/J]\n'                                  ...
        '  k_s       = %.10g;  %% switching gain\n'                                     ...
        '  phi_BL    = %.10g;  %% boundary layer [K]\n'                                 ...
        '  P_max     = %.10g;  %% hardware power limit [W]\n'                           ...
        '  s = double(T) - double(Tref);\n'                                             ...
        '  if abs(s) > phi_BL\n'                                                        ...
        '    sat_val = sign(s);\n'                                                      ...
        '  else\n'                                                                      ...
        '    sat_val = s / phi_BL;\n'                                                   ...
        '  end\n'                                                                       ...
        '  Pd = (1/beta) * (alpha_hat*(double(T)-double(Ta)) - k_s*sat_val);\n'         ...
        '  Pd = max(0, min(P_max, Pd));\n'                                              ...
        'end\n'], alpha_hat, beta, k_s, phi_BL, P_max);
end
pause(0.4);
add_line(smc, 'T/1',      'SMC_Law/1', 'autorouting', 'on');
add_line(smc, 'Tref/1',   'SMC_Law/2', 'autorouting', 'on');
add_line(smc, 'Ta/1',     'SMC_Law/3', 'autorouting', 'on');
add_line(smc, 'SMC_Law/1','Pd/1',      'autorouting', 'on');

%% ── PHI_INV ───────────────────────────
rt2 = sfroot();
ch2 = rt2.find('-isa', 'Stateflow.EMChart', '-and', 'Path', [mdl '/phi_inv']);
if ~isempty(ch2)
    ch2.Script = [ ...
        'function u = phi_inv(Pd)'                               newline ...
        '%%#codegen'                                             newline ...
        '  Pd = max(1e-6, min(2.42, double(Pd)));'               newline ...
        '  u  = (log10(200*Pd) + 1) / 4;'                        newline ...
        'end'                                                    newline];
end

%% ── ACTUATOR ──────────────────────────
rt3 = sfroot();
ch3 = rt3.find('-isa', 'Stateflow.EMChart', '-and', 'Path', [mdl '/Actuator']);
if ~isempty(ch3)
    ch3.Script = [ ...
        'function Pin = Actuator(u)'                              newline ...
        '%%#codegen'                                              newline ...
        '  Pin = (10^(4*double(u) - 1)) / 200;'                   newline ...
        'end'                                                     newline];
end

%% ── THERMAL PLANT ────────────────────
plt = [mdl '/Plant'];
delete_line(plt, 'In1/1', 'Out1/1');
delete_block([plt '/In1']); delete_block([plt '/Out1']);

add_block('simulink/Sources/In1', [plt '/Pin'], 'Position', posr(15,  55, 45, 28), 'Port', '1');
add_block('simulink/Sources/In1', [plt '/Ta'],  'Position', posr(15, 155, 45, 28), 'Port', '2');
add_block('simulink/Math Operations/Gain', [plt '/Gb'], 'Position', posr(90, 48, 70, 42), 'Gain', num2str(beta));          
add_block('simulink/Math Operations/Sum', [plt '/S1'], 'Position', posr(180, 55, 28, 28), 'Inputs', '+-');
add_block('simulink/Continuous/Integrator', [plt '/Int'], 'Position', posr(270, 48, 60, 42), 'InitialCondition', num2str(T_init));
add_block('simulink/Sinks/Out1', [plt '/T'], 'Position', posr(380, 60, 45, 22));
add_block('simulink/Math Operations/Sum', [plt '/S2'], 'Position', posr(180, 148, 28, 28), 'Inputs', '+-');
add_block('simulink/Math Operations/Gain', [plt '/Ga'], 'Position', posr(270, 141, 70, 42), 'Gain', num2str(alpha_hat));  

add_line(plt, 'Pin/1', 'Gb/1',  'autorouting', 'on');
add_line(plt, 'Gb/1',  'S1/1',  'autorouting', 'on');
add_line(plt, 'Ga/1',  'S1/2',  'autorouting', 'on');
add_line(plt, 'S1/1',  'Int/1', 'autorouting', 'on');
add_line(plt, 'Int/1', 'T/1',   'autorouting', 'on');
add_line(plt, 'Int/1', 'S2/1',  'autorouting', 'on');
add_line(plt, 'Ta/1',  'S2/2',  'autorouting', 'on');
add_line(plt, 'S2/1',  'Ga/1',  'autorouting', 'on');

%% ── TOP-LEVEL WIRING ────────────────────────────────────
add_line(mdl, 'Plant/1',    'SMC_Ctrl/1', 'autorouting', 'on');
add_line(mdl, 'T_ref/1',    'SMC_Ctrl/2', 'autorouting', 'on');
add_line(mdl, 'T_amb/1',    'SMC_Ctrl/3', 'autorouting', 'on');
add_line(mdl, 'T_amb/1',    'Plant/2',    'autorouting', 'on');
add_line(mdl, 'SMC_Ctrl/1', 'phi_inv/1',  'autorouting', 'on');
add_line(mdl, 'phi_inv/1',  'Sat_u/1',    'autorouting', 'on');
add_line(mdl, 'Sat_u/1',    'Actuator/1', 'autorouting', 'on');
add_line(mdl, 'Actuator/1', 'Plant/1',    'autorouting', 'on');
add_line(mdl, 'Plant/1',    'Scope/1',    'autorouting', 'on');
add_line(mdl, 'T_ref/1',    'Scope/2',    'autorouting', 'on');
add_line(mdl, 'Plant/1',    'Log_T/1',    'autorouting', 'on');
add_line(mdl, 'Sat_u/1',    'Log_u/1',    'autorouting', 'on');

%% ── SIMULATION SETTINGS ─────────────────────────────────
set_param(mdl, 'StopTime', num2str(T_sim), 'Solver', 'ode45', ...
    'MaxStep', '0.2', 'RelTol', '1e-5', 'SaveTime', 'on', ...
    'TimeSaveName', 'tout', 'ReturnWorkspaceOutputs','on');
save_system(mdl);
fprintf('\nModel saved: %s.slx\n', mdl);

function p = posr(x, y, w, h)
    p = [x-w/2, y-h/2, x+w/2, y+h/2];
end