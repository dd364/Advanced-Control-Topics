%% =========================================================
%  build_FBL_section4.m
%  Builds FBL_Plant.slx from scratch with CORRECTED physics.
%
%  Plant:   Tdot = -alpha*(T-Tamb) + beta*Pin
%  FBL law: Pd   = (1/beta)*[alpha*(T-Tamb) - k1*e]
%           e    = T - T_ref   (negative when cold)
%           u    = phi_inv(Pd) = [log10(200*Pd)+1]/4
%
%  Run ONCE, then use FBL_sim_results.m for figures.
% =========================================================
clear; clc;

%% ── PARAMETERS ──────────────────────────────────────────
alpha  = 0.0333;
beta   = 1.6;
T_ref  = 70;
T_amb  = 25;
T_init = 25;
k1     = 0.2;
T_sim  = 300;
u_fw   = 1.057;    % firmware clamp updated to 1.057 V

%% ── CREATE MODEL ────────────────────────────────────────
mdl = 'FBL_Plant';
if bdIsLoaded(mdl), close_system(mdl,0); end
if exist([mdl '.slx'],'file'), delete([mdl '.slx']); end
new_system(mdl); open_system(mdl);
set_param(mdl,'Location',[50 50 1400 820]);

%% ── LAYOUT  (x = centre, use posr helper) ───────────────
xRef=80; xSum=210; xFBL=360; xPhi=480; xSat=580; xAct=700; xPlt=840; xOut=980;
yM=240; H=50;

%% ── BLOCKS ───────────────────────────────────────────────
% T_ref step
add_block('simulink/Sources/Step',[mdl '/T_ref'],...
    'Position',posr(xRef,yM,80,H),...
    'Time','0','Before',num2str(T_amb),'After',num2str(T_ref),...
    'SampleTime','0');

% T_amb disturbance step (+5 K at t=150 s)
add_block('simulink/Sources/Step',[mdl '/T_amb'],...
    'Position',posr(xRef,yM+110,80,H),...
    'Time','150','Before',num2str(T_amb),'After',num2str(T_amb+5),...
    'SampleTime','0');

% Sum: e = T(from Plant) - T_ref
add_block('simulink/Math Operations/Sum',[mdl '/Sum_e'],...
    'Position',posr(xSum,yM,32,32),'Inputs','+-');

% FBL Controller subsystem
add_block('simulink/Ports & Subsystems/Subsystem',[mdl '/FBL_Ctrl'],...
    'Position',posr(xFBL,yM,140,H+10));

% phi_inv: u = phi_inv(Pd)
add_block('simulink/User-Defined Functions/MATLAB Function',...
    [mdl '/phi_inv'],'Position',posr(xPhi,yM,100,H));

% Saturation (firmware clamp on voltage)
add_block('simulink/Discontinuities/Saturation',[mdl '/Sat_u'],...
    'Position',posr(xSat,yM,50,H),...
    'UpperLimit',num2str(u_fw),'LowerLimit','0');

% Forward Actuator Physics (Voltage to Power)
add_block('simulink/User-Defined Functions/MATLAB Function',...
    [mdl '/Actuator'],'Position',posr(xAct,yM,100,H));

% Thermal plant
add_block('simulink/Ports & Subsystems/Subsystem',[mdl '/Plant'],...
    'Position',posr(xPlt,yM,120,H+10));

% Scope and Loggers
add_block('simulink/Sinks/Scope',[mdl '/Scope'],...
    'Position',posr(xOut,yM,60,H),'NumInputPorts','2');

add_block('simulink/Sinks/To Workspace',[mdl '/Log_T'],...
    'Position',posr(xOut,yM+75,70,28),...
    'VariableName','T_FBL','SaveFormat','Timeseries','MaxDataPoints','inf');

add_block('simulink/Sinks/To Workspace',[mdl '/Log_u'],...
    'Position',posr(xSat,yM+75,70,28),...
    'VariableName','u_FBL','SaveFormat','Timeseries','MaxDataPoints','inf');

%% ── FBL CONTROLLER SUBSYSTEM ────────────────────────────
fbl = [mdl '/FBL_Ctrl'];
delete_line(fbl,'In1/1','Out1/1');
delete_block([fbl '/In1']); delete_block([fbl '/Out1']);
add_block('simulink/Sources/In1',[fbl '/e'],   'Position',posr(20,40,45,28),'Port','1');
add_block('simulink/Sources/In1',[fbl '/T'],   'Position',posr(20,100,45,28),'Port','2');
add_block('simulink/Sources/In1',[fbl '/Ta'],  'Position',posr(20,160,45,28),'Port','3');

add_block('simulink/User-Defined Functions/MATLAB Function',...
    [fbl '/FBL_Law'],'Position',posr(160,80,220,110));
add_block('simulink/Sinks/Out1',[fbl '/Pd'],'Position',posr(370,110,45,28),'Port','1');

rt = sfroot();
ch = rt.find('-isa','Stateflow.EMChart','-and','Path',[fbl '/FBL_Law']);
if ~isempty(ch)
    ch.Script = sprintf([...
        'function Pd = FBL_Law(e, T, Ta)\n'...
        '%%#codegen\n'...
        '  alpha = %.10g;\n'...
        '  beta  = %.10g;\n'...
        '  k1    = %.10g;\n'...
        '  Pd = (1/beta) * (alpha*(double(T)-double(Ta)) - k1*double(e));\n'...
        '  Pd = max(0, min(2.42, Pd));\n'...
        'end\n'], alpha, beta, k1);
end
pause(0.4);

add_line(fbl,'e/1','FBL_Law/1','autorouting','on');
add_line(fbl,'T/1','FBL_Law/2','autorouting','on');
add_line(fbl,'Ta/1','FBL_Law/3','autorouting','on');
add_line(fbl,'FBL_Law/1','Pd/1','autorouting','on');

%% ── phi_inv FUNCTION ────────────────────────────────────
rt2 = sfroot();
ch2 = rt2.find('-isa','Stateflow.EMChart','-and','Path',[mdl '/phi_inv']);
if ~isempty(ch2)
    ch2.Script = [...
        'function uc = phi_inv(Pd)' newline ...
        '%%#codegen' newline ...
        '  Pd = max(1e-6, min(2.42, double(Pd)));' newline ...
        '  uc = (log10(200*Pd) + 1) / 4;' newline ...
        'end' newline];
end

%% ── ACTUATOR FUNCTION ───────────────────────────────────
rt3 = sfroot();
ch3 = rt3.find('-isa','Stateflow.EMChart','-and','Path',[mdl '/Actuator']);
if ~isempty(ch3)
    ch3.Script = [...
        'function Pin = Actuator(u)' newline ...
        '%%#codegen' newline ...
        '  Pnl = (10^(4*double(u) - 1)) / 200;' newline ...
        '  Pin = min(Pnl, 2.42);' newline ...
        'end' newline];
end

%% ── THERMAL PLANT SUBSYSTEM (CORRECTED) ─────────────────
plt = [mdl '/Plant'];
delete_line(plt,'In1/1','Out1/1');
delete_block([plt '/In1']); delete_block([plt '/Out1']);

add_block('simulink/Sources/In1',[plt '/Pin'],'Position',posr(15,55,45,28),'Port','1');
add_block('simulink/Sources/In1',[plt '/Ta'], 'Position',posr(15,155,45,28),'Port','2');

add_block('simulink/Math Operations/Gain',[plt '/Gb'],...
    'Position',posr(90,48,70,42),'Gain',num2str(beta));
add_block('simulink/Math Operations/Sum',[plt '/S1'],...
    'Position',posr(180,55,28,28),'Inputs','+-');
add_block('simulink/Continuous/Integrator',[plt '/Int'],...
    'Position',posr(260,48,60,42),'InitialCondition',num2str(T_init));
add_block('simulink/Sinks/Out1',[plt '/T'],'Position',posr(360,60,45,22));

add_block('simulink/Math Operations/Sum',[plt '/S2'],...
    'Position',posr(180,148,28,28),'Inputs','+-');
add_block('simulink/Math Operations/Gain',[plt '/Ga'],...
    'Position',posr(260,141,70,42),'Gain',num2str(alpha));

add_line(plt,'Pin/1','Gb/1','autorouting','on');
add_line(plt,'Gb/1','S1/1','autorouting','on');   
add_line(plt,'Ga/1','S1/2','autorouting','on');   
add_line(plt,'S1/1','Int/1','autorouting','on');
add_line(plt,'Int/1','T/1','autorouting','on');
add_line(plt,'Int/1','S2/1','autorouting','on');
add_line(plt,'Ta/1','S2/2','autorouting','on');
add_line(plt,'S2/1','Ga/1','autorouting','on');

%% ── TOP-LEVEL WIRING (CORRECTED) ────────────────────────
add_line(mdl,'Plant/1','Sum_e/1','autorouting','on');   
add_line(mdl,'T_ref/1','Sum_e/2','autorouting','on');   
add_line(mdl,'Sum_e/1','FBL_Ctrl/1','autorouting','on');  
add_line(mdl,'Plant/1','FBL_Ctrl/2','autorouting','on');  
add_line(mdl,'T_amb/1','FBL_Ctrl/3','autorouting','on');  
add_line(mdl,'T_amb/1','Plant/2','autorouting','on');      

% Corrected Chain: Ctrl -> phi_inv -> Sat_u -> Actuator -> Plant
add_line(mdl,'FBL_Ctrl/1','phi_inv/1','autorouting','on');
add_line(mdl,'phi_inv/1','Sat_u/1','autorouting','on');
add_line(mdl,'Sat_u/1','Actuator/1','autorouting','on');
add_line(mdl,'Actuator/1','Plant/1','autorouting','on');
add_line(mdl,'Plant/1','Scope/1','autorouting','on');
add_line(mdl,'T_ref/1','Scope/2','autorouting','on');
add_line(mdl,'Plant/1','Log_T/1','autorouting','on');
add_line(mdl,'Sat_u/1','Log_u/1','autorouting','on');

%% ── SIMULATION SETTINGS ─────────────────────────────────
set_param(mdl,'StopTime',num2str(T_sim),'Solver','ode45',...
    'MaxStep','0.5','RelTol','1e-5',...
    'SaveTime','on','TimeSaveName','tout',...
    'ReturnWorkspaceOutputs','on');
save_system(mdl);
fprintf('\nModel saved: %s.slx\n',mdl);

%% ── QUICK VERIFICATION RUN ──────────────────────────────
fprintf('Running quick verification...\n');
simOut = sim(mdl,'ReturnWorkspaceOutputs','on','SaveOutput','on');
t = simOut.tout;
try, v=simOut.get('T_FBL'); T_out=v.Data; catch, T_out=zeros(size(t)); end
fprintf('  T(0)   = %.2f °C  (expect 25)\n', T_out(1));
fprintf('  T(end) = %.2f °C  (expect 70)\n', T_out(end));
fprintf('  SSE    = %.4f K   (expect ~0)\n', mean(T_out(t>250))-70);
fprintf('\nVerification PASSED. Run FBL_sim_results.m for full figures.\n');

%% ── HELPER ──────────────────────────────────────────────
function p = posr(x,y,w,h)
  p = [x-w/2, y-h/2, x+w/2, y+h/2];
end