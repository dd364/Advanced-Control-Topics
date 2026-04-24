%% =========================================================
%  build_MRAC_section6.m
%  Builds MRAC_Plant.slx — High-Performance Tuning
%
%  Plant model (report eq 2.11):
%    Tdot = -alpha*(T-Tamb) + beta*phi(u)
%
%  Adaptive control law (report eq 6.2):
%    Pd = (1/beta)*[alpha_hat*(T-Tamb) - k_a*e]
%
%  Adaptation law (report eq 6.4):
%    alpha_hat_dot = -gamma * e * (T - Tamb)
% =========================================================
clear; clc;

%% ── PARAMETERS ──
alpha_true = 0.0333;   % True plant thermal decay rate [s^-1]
alpha_hat0 = 0.0167;   % Initial estimate (-50% mismatch) [s^-1]
beta       = 1.6;      % Thermal capacity gain [K/J] (known)
T_ref      = 70;       % Setpoint temperature [°C]
T_amb      = 25;       % Ambient temperature [°C]
T_init     = 25;       % Initial cell temperature [°C]

% --- OPTIMIZED TUNING PARAMETERS ---
k_a        = 1.2;      % Tighter error-damping gain to prevent overshoot
gamma      = 5e-5;     % 100x faster adaptation learning rate

T_sim      = 300;      % Reduced back to 300s due to fast convergence
u_max      = 1.057;    % Firmware DAC clamp [V]
P_max      = 2.42;     % Hardware power limit [W]

%% ── CREATE / RESET MODEL ────────────────────────────────
mdl = 'MRAC_Plant';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl, 'Location', [50 50 1400 820]);

%% ── LAYOUT CONSTANTS ────────────────────────────────────
xRef = 80;  xMRAC = 320;  xPhi = 490;  xSat = 600;
xAct = 720; xPlt = 880;   xOut = 1040;
yM = 240;   H = 50;

%% ── TOP-LEVEL BLOCKS ────────────────────────────────────
add_block('simulink/Sources/Step', [mdl '/T_ref'], ...
    'Position', posr(xRef, yM, 80, H), ...
    'Time', '0', 'Before', num2str(T_amb), 'After', num2str(T_ref), 'SampleTime', '0');

add_block('simulink/Sources/Constant', [mdl '/T_amb'], ...
    'Position', posr(xRef, yM+120, 80, H), 'Value', num2str(T_amb));

add_block('simulink/Ports & Subsystems/Subsystem', [mdl '/MRAC_Ctrl'], ...
    'Position', posr(xMRAC, yM, 180, H+40));

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [mdl '/phi_inv'], 'Position', posr(xPhi, yM, 100, H));

add_block('simulink/Discontinuities/Saturation', [mdl '/Sat_u'], ...
    'Position', posr(xSat, yM, 50, H), 'UpperLimit', num2str(u_max), 'LowerLimit', '0');

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [mdl '/Actuator'], 'Position', posr(xAct, yM, 100, H));

add_block('simulink/Ports & Subsystems/Subsystem', [mdl '/Plant'], ...
    'Position', posr(xPlt, yM, 120, H+10));

add_block('simulink/Sinks/To Workspace', [mdl '/Log_T'], ...
    'Position', posr(xOut, yM-30, 70, 28), 'VariableName', 'T_MRAC', 'SaveFormat', 'Timeseries');
add_block('simulink/Sinks/To Workspace', [mdl '/Log_u'], ...
    'Position', posr(xOut, yM+20, 70, 28), 'VariableName', 'u_MRAC', 'SaveFormat', 'Timeseries');
add_block('simulink/Sinks/To Workspace', [mdl '/Log_alpha'], ...
    'Position', posr(xOut, yM+70, 70, 28), 'VariableName', 'alpha_hat_MRAC', 'SaveFormat', 'Timeseries');

%% ── MRAC CONTROLLER SUBSYSTEM ───────────────────────────
mrac = [mdl '/MRAC_Ctrl'];
delete_line(mrac, 'In1/1', 'Out1/1');
delete_block([mrac '/In1']); delete_block([mrac '/Out1']);

add_block('simulink/Sources/In1', [mrac '/T'],    'Position', posr(20,  60, 45, 28), 'Port', '1');
add_block('simulink/Sources/In1', [mrac '/Tref'], 'Position', posr(20, 110, 45, 28), 'Port', '2');
add_block('simulink/Sources/In1', [mrac '/Ta'],   'Position', posr(20, 160, 45, 28), 'Port', '3');

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [mrac '/Control_Law'], 'Position', posr(250, 80, 180, 100));

add_block('simulink/User-Defined Functions/MATLAB Function', ...
    [mrac '/Adaptation_Law'], 'Position', posr(250, 220, 180, 80));

add_block('simulink/Continuous/Integrator', [mrac '/Alpha_Integrator'], ...
    'Position', posr(420, 220, 40, 40), 'InitialCondition', num2str(alpha_hat0));

add_block('simulink/Sinks/Out1', [mrac '/Pd'], 'Position', posr(500, 80, 45, 28), 'Port', '1');
add_block('simulink/Sinks/Out1', [mrac '/alpha_hat_out'], 'Position', posr(500, 220, 45, 28), 'Port', '2');

rt = sfroot();
ch_ctrl = rt.find('-isa', 'Stateflow.EMChart', '-and', 'Path', [mrac '/Control_Law']);
if ~isempty(ch_ctrl)
    ch_ctrl.Script = sprintf([ ...
        'function Pd = Control_Law(T, Tref, Ta, alpha_hat)\n' ...
        '%%#codegen\n' ...
        '  beta  = %.10g;\n' ...
        '  k_a   = %.10g;\n' ...
        '  P_max = %.10g;\n' ...
        '  e = double(T) - double(Tref);\n' ...
        '  W = double(T) - double(Ta);\n' ...
        '  Pd = (1/beta) * (alpha_hat * W - k_a * e);\n' ...
        '  Pd = max(0, min(P_max, Pd));\n' ...
        'end\n'], beta, k_a, P_max);
end

ch_adapt = rt.find('-isa', 'Stateflow.EMChart', '-and', 'Path', [mrac '/Adaptation_Law']);
if ~isempty(ch_adapt)
    ch_adapt.Script = sprintf([ ...
        'function alpha_hat_dot = Adaptation_Law(T, Tref, Ta)\n' ...
        '%%#codegen\n' ...
        '  gamma = %.10g;\n' ...
        '  e = double(T) - double(Tref);\n' ...
        '  W = double(T) - double(Ta);\n' ...
        '  alpha_hat_dot = -gamma * e * W;\n' ...
        'end\n'], gamma);
end
pause(0.4);

add_line(mrac, 'T/1',      'Control_Law/1', 'autorouting', 'on');
add_line(mrac, 'Tref/1',   'Control_Law/2', 'autorouting', 'on');
add_line(mrac, 'Ta/1',     'Control_Law/3', 'autorouting', 'on');
add_line(mrac, 'T/1',      'Adaptation_Law/1', 'autorouting', 'on');
add_line(mrac, 'Tref/1',   'Adaptation_Law/2', 'autorouting', 'on');
add_line(mrac, 'Ta/1',     'Adaptation_Law/3', 'autorouting', 'on');
add_line(mrac, 'Adaptation_Law/1', 'Alpha_Integrator/1', 'autorouting', 'on');
add_line(mrac, 'Alpha_Integrator/1', 'Control_Law/4', 'autorouting', 'on');
add_line(mrac, 'Control_Law/1', 'Pd/1', 'autorouting', 'on');
add_line(mrac, 'Alpha_Integrator/1', 'alpha_hat_out/1', 'autorouting', 'on');

%% ── PHI_INV & ACTUATOR ───────────────────────────
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
add_block('simulink/Math Operations/Gain', [plt '/Ga'], 'Position', posr(270, 141, 70, 42), 'Gain', num2str(alpha_true)); % True physical alpha

add_line(plt, 'Pin/1', 'Gb/1',  'autorouting', 'on');
add_line(plt, 'Gb/1',  'S1/1',  'autorouting', 'on');
add_line(plt, 'Ga/1',  'S1/2',  'autorouting', 'on');
add_line(plt, 'S1/1',  'Int/1', 'autorouting', 'on');
add_line(plt, 'Int/1', 'T/1',   'autorouting', 'on');
add_line(plt, 'Int/1', 'S2/1',  'autorouting', 'on');
add_line(plt, 'Ta/1',  'S2/2',  'autorouting', 'on');
add_line(plt, 'S2/1',  'Ga/1',  'autorouting', 'on');

%% ── TOP-LEVEL WIRING ────────────────────────────────────
add_line(mdl, 'Plant/1',    'MRAC_Ctrl/1', 'autorouting', 'on');
add_line(mdl, 'T_ref/1',    'MRAC_Ctrl/2', 'autorouting', 'on');
add_line(mdl, 'T_amb/1',    'MRAC_Ctrl/3', 'autorouting', 'on');
add_line(mdl, 'T_amb/1',    'Plant/2',     'autorouting', 'on');
add_line(mdl, 'MRAC_Ctrl/1','phi_inv/1',   'autorouting', 'on');
add_line(mdl, 'phi_inv/1',  'Sat_u/1',     'autorouting', 'on');
add_line(mdl, 'Sat_u/1',    'Actuator/1',  'autorouting', 'on');
add_line(mdl, 'Actuator/1', 'Plant/1',     'autorouting', 'on');
add_line(mdl, 'Plant/1',    'Log_T/1',     'autorouting', 'on');
add_line(mdl, 'Sat_u/1',    'Log_u/1',     'autorouting', 'on');
add_line(mdl, 'MRAC_Ctrl/2','Log_alpha/1', 'autorouting', 'on');

%% ── SIMULATION SETTINGS ─────────────────────────────────
set_param(mdl, 'StopTime', num2str(T_sim), 'Solver', 'ode45', ...
    'MaxStep', '0.2', 'RelTol', '1e-5', 'SaveTime', 'on', ...
    'TimeSaveName', 'tout', 'ReturnWorkspaceOutputs','on');
save_system(mdl);
fprintf('\nMRAC Model saved: %s.slx\n', mdl);

function p = posr(x, y, w, h)
    p = [x-w/2, y-h/2, x+w/2, y+h/2];
end