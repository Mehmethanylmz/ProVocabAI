# Run Phase

Goal:
- Execute Phase {{PHASE_NUMBER}} from ai/RESTORASYON_PLANI.md

Process:
1) List the tasks in that phase (IDs like F9-01, F9-02...)
2) For each task:
   - locate target files
   - implement the change
   - update any broken references
3) Self-check:
   - project compiles
   - minimal smoke test (if no automated tests)
4) Output:
   - short changelog
   - files changed
   - next steps / risks
5) Create a git commit:
   "Phase {{PHASE_NUMBER}} – <short description>"