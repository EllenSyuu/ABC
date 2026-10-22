# Bundle checks

- All 9 R/config source files passed tree-sitter R syntax parsing. This is static parsing, not execution by R.
- Exactly 12 old int array declarations were modernised. After removing the added attribution header, the modern model equals the original source under that declaration-only transformation.
- Nine-group user-reported summary checked for 4 chains and zero diagnostic flags.
- No user-specific C:/Users path in R files.
- End-to-end R execution, package resolution, C++ compilation, original-data checks, import, post-processing and figures were not executed here: R and the public data file are absent.
- No actual user RDS files or raw diagnostic tables are included.

An SHA-256 manifest covers the delivered files. It establishes file integrity, not statistical validity.
