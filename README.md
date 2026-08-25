<p align="center">
  <img src="./docs/assets/logo.png" width="150" title="SatelliteToolboxSpaceIndexSets"><br>
  <small><i>This repository is part of the <a href="https://github.com/JuliaSpace/SatelliteToolbox.jl">SatelliteToolbox.jl</a> ecosystem.</i></small>
</p>

# SatelliteToolboxSpaceIndexSets

[![F10.7 Prediction](https://img.shields.io/github/actions/workflow/status/JuliaSpace/SatelliteToolboxSpaceIndexSets/f107_prediction.yml?style=flat-square&logo=githubactions&logoColor=white&labelColor=475569&label=F10.7%20Prediction)](https://github.com/JuliaSpace/SatelliteToolboxSpaceIndexSets/actions/workflows/f107_prediction.yml)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495D1?style=flat-square&logo=julia&logoColor=white&labelColor=475569)](https://github.com/invenia/BlueStyle)
[![License](https://img.shields.io/github/license/JuliaSpace/SatelliteToolboxSpaceIndexSets?style=flat-square&logo=readme&logoColor=white&labelColor=475569&color=0284C7)](https://github.com/JuliaSpace/SatelliteToolboxSpaceIndexSets/blob/main/LICENSE.txt)

This repository contains scripts to generate space index sets for the
**SatelliteToolbox.jl** ecosystem. The generated files are stored in the [`files`](./files)
directory and are updated automatically every day by a GitHub action.

## Generated Files

| File                                        | Description                                                 |
|:--------------------------------------------|:------------------------------------------------------------|
| `f107_observed_prediction_coefficients.csv` | Coefficients to predict the observed F10.7 solar flux index |
| `f107_adjusted_prediction_coefficients.csv` | Coefficients to predict the adjusted F10.7 solar flux index |

## F10.7 Prediction Coefficients

The script [`fit_f107.jl`](./scripts/f107_prediction/fit_f107.jl) generates the
coefficients to predict the F10.7 solar flux index for satellite decay analysis. It fits
either the observed or the adjusted data obtained from
[Celestrak](https://celestrak.org), from 1957-10-02 up to the current day, considering the
following harmonic model:

```math
\bar{F}_{10.7} = F_0 + \sum_{i = 1}^{6} a_i \sin\left(2\pi i \frac{t - t_0}{P}\right) +
b_i \cos\left(2\pi i \frac{t - t_0}{P}\right),
```

where $t_0$ is the reference day (1957-10-02) represented in Julian day. The fitting
coefficients are:

- $F_0$: the mean value of the F10.7 index [sfu];
- $a_i$: the sine coefficients for the i-th harmonic [sfu];
- $b_i$: the cosine coefficients for the i-th harmonic [sfu]; and
- $P$: the period of the solar cycle [days].

This model was based on the information available in **[1]**.

### Output Format

The output is stored in the CSV files
[`files/f107_observed_prediction_coefficients.csv`](./files/f107_observed_prediction_coefficients.csv)
(observed index) and
[`files/f107_adjusted_prediction_coefficients.csv`](./files/f107_adjusted_prediction_coefficients.csv)
(adjusted index) with the following columns:

```
t₀, F₀, P, a₁, a₂, a₃, a₄, a₅, a₆, b₁, b₂, b₃, b₄, b₅, b₆
```

where `t₀` is expressed in Julian day, `F₀` and the harmonic coefficients in sfu, and `P`
in days.

### Running Locally

The script requires Julia and its project environment can be instantiated with:

```bash
julia --project=scripts/f107_prediction -e 'using Pkg; Pkg.instantiate()'
```

Afterward, run the fitting with:

```bash
julia --project=scripts/f107_prediction scripts/f107_prediction/fit_f107.jl
```

The output file path can be passed as the first command-line argument and the F10.7 index
set (`observed` or `adjusted`) as the second one. If omitted, the script fits the observed
index and writes the file next to itself:

```bash
julia --project=scripts/f107_prediction scripts/f107_prediction/fit_f107.jl files/f107_observed_prediction_coefficients.csv observed
julia --project=scripts/f107_prediction scripts/f107_prediction/fit_f107.jl files/f107_adjusted_prediction_coefficients.csv adjusted
```

The script prints a report of each step, including the convergence status, the fitted
parameters, and the root-mean-square error of the residuals.

## Automation

The GitHub action
[`f107_prediction.yml`](./.github/workflows/f107_prediction.yml) runs the fitting script
every day at 21:00 UTC for both the observed and the adjusted indices, writes the outputs
to the [`files`](./files) directory, and commits the result if the coefficients changed. It can also be triggered manually from the Actions
tab using the `workflow_dispatch` event.

## References

- **[1]** D. Whitlock (2006). *Modeling the Effect of High Solar Activity on the Orbital
  Debris Environment*. Orbital Debris Quarterly News, vol. 10, n. 2, April, 2006.
