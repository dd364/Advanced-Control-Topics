# Advanced Electromechanical System Control – Nonlinear Temperature Regulation

**Author:** Denilson Domingos Monteiro Nicolau  
**Module:** Advanced Topics in Control (866H1-AEMSC)  
**Institution:** University of Sussex  
**Date:** April 2026

## Overview

This repository contains the complete MATLAB/Simulink implementation and experimental data for the closed‑loop temperature control of a PT100‑based electrothermal plant. The system is designed to regulate a rubidium vapour cell at 70 °C for an optically pumped magnetometer (OPM).

Three nonlinear controllers are implemented, analysed, and compared against a PID baseline:

- **Feedback Linearisation (FBL)** – exact cancellation of input nonlinearity and thermal drift (assumes known parameters).
- **Sliding Mode Control (SMC)** – robust to bounded uncertainty in the thermal decay rate α.
- **Model Reference Adaptive Control (MRAC)** – online estimation of α with Lyapunov‑based adaptation.

The repository includes Simulink models for simulation, MATLAB setup scripts for parameter tuning, post‑processing scripts for plotting, and hardware log files (CSV) from the STM32H755 implementation.

## Repository Structure
├── FBL_Plant.slx # Simulink model – Feedback Linearisation
├── SMC_Plant.slx # Simulink model – Sliding Mode Control
├── MRAC_Plant.slx # Simulink model – Adaptive MRAC
├── FEEDBACK_SETUP.m # Parameter initialisation for FBL (Simulink)
├── robust_setup.m # Parameter initialisation for SMC
├── ADAPTIVE_BUILD_SETUP.m # Parameter initialisation for MRAC
├── ADAPTIVE_BUILD_SETUP.mat # Saved workspace for adaptive build
├── FEEDBACK_Linear_data.m # Data script for FBL results
├── robust_test_data.m # Data script for SMC results
├── ADAPTIVE_TEST_RESULTS.m # Plotting script for MRAC simulation results
├── hardware_experiment.m # Main script to load & plot hardware CSV logs
├── hardware_experiment_NOISE_CALCULATION.m # Steady‑state noise (RMS) analysis
├── *.csv # Hardware log files (see below)
├── *.pdf # Background literature (LSTM, Neural Adaptive)
└── slprj/ # Simulink code generation artefacts (auto‑generated)


### Hardware Log Files (CSV)

The following CSV files contain experimental data recorded from the STM32H755 during real‑time operation (4 kHz loop, 250 kbaud telemetry):

| File                          | Controller  | Description |
|-------------------------------|-------------|-------------|
| `pid2_log_20260423_050821.csv`  | PID         | Baseline linear controller |
| `FBL_opm_log_20260423_030945.csv` | FBL         | Feedback linearisation |
| `smc2_log_20260423_033414.csv` | SMC         | Sliding mode control |
| `mrac_log_20260423_042756.csv` | MRAC        | Model reference adaptive control |

Each CSV contains columns: time (s), temperature T (°C), DAC command u (V), ambient temperature Tamb (°C), and enable flag (EN).

## Prerequisites

- MATLAB R2021a or later (tested with R2021a – `.slx.r2021a` backup files provided).
- Simulink (for running the `.slx` models).
- Control System Toolbox (for LTI blocks, if used in models).
- No additional toolboxes required for post‑processing or hardware data analysis.

## Usage

### 1. Simulating the Controllers

1. Open MATLAB and navigate to the repository folder.
2. For **FBL**:  
   `>> FEEDBACK_SETUP`  
   Then open `FBL_Plant.slx` and click **Run**.
3. For **SMC**:  
   `>> robust_setup`  
   Then open `SMC_Plant.slx` and click **Run**.
4. For **MRAC**:  
   `>> ADAPTIVE_BUILD_SETUP`  
   Then open `MRAC_Plant.slx` and click **Run**.

### 2. Plotting Simulation Results

After running a Simulink model, use the corresponding script to generate comparison plots:

- `FEEDBACK_Linear_data.m` – plots FBL step response, tracking error, control effort.
- `robust_test_data.m` – plots SMC responses, boundary layer effects, and robustness studies.
- `ADAPTIVE_TEST_RESULTS.m` – plots MRAC responses, parameter convergence α̂(t), and error evolution.

### 3. Processing Hardware Data

Run the following scripts to load the CSV logs and reproduce the figures from Section 7 (Hardware Implementation):

```matlab
>> hardware_experiment                % plots temperature, error, u(t) for all four controllers
>> hardware_experiment_NOISE_CALCULATION   % calculates and plots steady‑state RMS noise (800–1000 s window)


The noise analysis script computes the zero‑mean temperature fluctuations and generates the RMS bar chart shown in the report.

Key Results (Summary)
Controller	Rise time (to ±0.5 K)	Steady‑state error (±20% α uncertainty)	RMS noise (mK)
PID	~45 s	≥ 0.8 K (model dependent)	219.3
FBL	~14 s	up to 0.8 K offset	229.2
SMC	~18 s	≤ 0.21 K (UUB)	201.2
MRAC	~12 s (with overshoot)	0 K (asymptotic)	216.6
For full details, please refer to the accompanying project report (not included in this repo due to institutional policies).

Notes
The slprj/ folder contains Simulink Coder generated files – do not delete if you plan to rebuild the models for code generation (not required for normal simulation).

The .asv files are MATLAB auto‑save backups – safe to ignore or remove.

The PDF files (Lyapunov-Based Physics-Informed Long_short_term_memory.pdf and Neural Network Adaptive Control with Long Short-Term Memory.pdf) are background literature relevant to advanced adaptive control but not used directly in the Simulink models.

License
This project is for academic submission purposes. Please contact the author before any reuse or redistribution.

Contact
Denilson Domingos Monteiro Nicolau – [GitHub profile link if desired]
Module Coordinator: Dr Yanan Li – University of Sussex
