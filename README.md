# pupillometry

MATLAB pipeline for analyzing pupil diameter dynamics in rodent behavioral experiments, including pupillometry compiled across sessions, logistic curve fitting to behavioral performance, and integration with eye-blink conditioning paradigms.

## Overview

This repository contains tools for processing and analyzing pupil diameter recordings collected during behavioral neuroscience experiments. The pipeline supports extraction of pupil diameter traces, trial-based averaging, session-level compilation, and statistical analysis of pupil responses as a function of behavioral state and experimental condition.

## Contents

- `pupilAnalyses.m` — Core pupil diameter analysis pipeline; extracts and analyzes pupil traces aligned to behavioral events
- `pupilCompile.m` — Batch compilation of pupil data across subjects and sessions; produces population-level summaries
- `plotFitLine.m` — Linear regression fitting and visualization for pupil response analysis
- `plotLogisticWithBins.m` — Logistic curve fitting with binned data visualization for behavioral performance tracking
- `EbPupillometry.m` — Integrated analysis of pupillometry and eye-blink conditioning data; aligns pupil responses to CS/US events in classical conditioning paradigms
- `convert2video.m` — Converts raw pupil recording data to video format for quality control review

## Requirements

- MATLAB R2018a or later
- Statistics and Machine Learning Toolbox
- Image Processing Toolbox
