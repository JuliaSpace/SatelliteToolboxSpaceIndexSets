# Repository Guide

This repository is not a Julia package. It contains standalone Julia scripts that generate space index sets (data files) for the SatelliteToolbox.jl ecosystem. The generated files live in `files/` and are refreshed automatically by GitHub actions.

## Repository Structure

- `scripts/f107_prediction/fit_f107.jl` fits a 6-harmonic model to the Celestrak F10.7 observed or adjusted data and writes the prediction coefficients to a CSV file. It has its own project environment (`Project.toml`) in the same directory.
- `files/` holds the generated data files. `files/f107_observed_prediction_coefficients.csv` and `files/f107_adjusted_prediction_coefficients.csv` are the canonical outputs; the copy the script writes next to itself when run without arguments is a local convenience only.
- `.github/workflows/f107_prediction.yml` runs the fitting script every day at 21:00 UTC (and on `workflow_dispatch`), writing to `files/` and committing only when the output changed.
- `docs/assets/logo.png` is the ecosystem logo used by `README.md`. There is no Documenter build.
- `Manifest.toml` is not committed and must never be: the environment is resolved from `Project.toml` by `Pkg.instantiate()`. Do not add dependencies casually; if you add one, use `Pkg.add` inside the script's project so `Project.toml` stays consistent.

## Commands

- Instantiate: `julia --project=scripts/f107_prediction -e 'using Pkg; Pkg.instantiate()'` (first run precompiles for a while; use generous timeouts).
- Run the F10.7 fit: `julia --project=scripts/f107_prediction scripts/f107_prediction/fit_f107.jl files/f107_observed_prediction_coefficients.csv observed` — the first command-line argument is the output path and the second is the index set (`observed` or `adjusted`); omitting them fits the observed index and writes next to the script.
- The script downloads the Celestrak space index files through SpaceIndices.jl at runtime, so it requires network access.
- There is no test suite; verifying a change means running the script and checking that it converges and the output matches the documented column layout.

## Code Style

- Wrap code and comments at 92 characters. End comments with a period.
- Every function has a docstring with the `signature -> return` first line, `# Arguments`/`# Returns` sections, and units in brackets (e.g. `[sfu]`, `[Julian day]`). Match the format used in `fit_f107.jl`.
- Section separators use the boxed `## Description ###...` header and `# == Title ==...` comment style used in `fit_f107.jl`; match them when adding code.
- Scripts print progress with the `print_header`/`run_step`/`print_info` helpers in `fit_f107.jl`; reuse that pattern for new scripts.

## Behavioral Constraints

- The CSV column layout (`t₀, F₀, P, a₁, ..., a₆, b₁, ..., b₆`) is a contract with downstream SatelliteToolbox.jl consumers. Any change to a generated file's format, model, or data source is breaking: update the script header comment, `README.md`, and add a dated `CHANGELOG.md` entry.
- `CHANGELOG.md` uses dated sections (no versions) and records changes to the scripts, output formats, or automation only. The daily automated data commits must never touch it.
- The fitted parameter vector has exactly 14 elements (`F₀`, `P`, `a₁`-`a₆`, `b₁`-`b₆`); keep the model, the CSV header, and the docstrings consistent if the harmonic count ever changes.

## Not Configured

- No formatter, linter, pre-commit hooks, test suite, or docs build is configured; do not invent one from README badges or Julia conventions.
