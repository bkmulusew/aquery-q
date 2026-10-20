# tests/reference_q — what the Scala compiler generates

Made by `tools/gen_reference_q.sh`. For each `tests/inputs/<path>.a`:

- `<path>.q`: compiled with `-a 0` (no optimisation)
- `<path>.opt.q`: compiled with `-a 1`
- `<path>.error.txt`: the jar's message if it cannot parse the input

Only the translated part is stored (from `// Translation begins here`).
The jar's full output is `src/runtime/base.q` followed by this file; the
script checks that. Not used by version 1; these are the expected results
for the code-generation stage.
