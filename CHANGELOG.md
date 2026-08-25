Changelog
=========

2026-08-25
----------

- ![Breaking][badge-breaking] The observed F10.7 prediction coefficients are now stored in
  `files/f107_observed_prediction_coefficients.csv` instead of
  `files/f107_prediction_coefficients.csv`. The column layout is unchanged.
- ![Feature][badge-feature] The F10.7 fitting script now accepts a second command-line
  argument selecting whether the observed or the adjusted index is fitted, defaulting to
  the observed one.
- ![Feature][badge-feature] The GitHub action now generates two coefficient files:
  `files/f107_observed_prediction_coefficients.csv` (observed index) and
  `files/f107_adjusted_prediction_coefficients.csv` (adjusted index).

2026-08-09
----------

- ![Info][badge-info] Initial version.
- ![Feature][badge-feature] Add the script to generate the coefficients to predict the
  F10.7 solar flux index by fitting a 6-harmonic model to the Celestrak observed data.
- ![Feature][badge-feature] Add the GitHub action that runs the fitting script every day at
  21:00 UTC and commits the updated coefficients to the `files` directory.

[badge-breaking]: https://img.shields.io/badge/Breaking-DC2626?style=flat-square
[badge-deprecation]: https://img.shields.io/badge/Deprecation-D97706?style=flat-square
[badge-feature]: https://img.shields.io/badge/Feature-16A34A?style=flat-square
[badge-enhancement]: https://img.shields.io/badge/Enhancement-0284C7?style=flat-square
[badge-bugfix]: https://img.shields.io/badge/Bugfix-DB2777?style=flat-square
[badge-info]: https://img.shields.io/badge/Info-475569?style=flat-square
