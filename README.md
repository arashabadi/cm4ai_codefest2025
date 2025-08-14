# cm4ai_codefest2025
This repo is related to my participation in 2025 CM4AI Hackathon at UAB



My notes:
- [CM4AI Data - Functional Analysis with CRISPR/PerturbSeq](https://www.youtube.com/watch?v=7RaOyiLi2cQ)
Perturbation Correlation Network
1.
For each perturbation, compute the mean of all cells (perturbation mean)
2.
Compute the pairwise Pearson correlation matrix of perturbation means
3.
Use UMAP on the correlation matrix to visualize which perturbations correlate similarly

>> cells that are cluster each other will have similar perturbation means -> results in similar cell phenotype after those perturbations

- [CM4AI Data - Immunofluorescence (IF)](https://www.youtube.com/watch?v=Ys5rFvMMtE4)

---
To install CellMaps Pipeline:

```bash
conda create -n cm4ai python=3.8
conda activate cm4ai
pip install cellmaps_pipeline
```

Docs:
- [CellMaps Pipeline](https://cellmaps-pipeline.readthedocs.io/en/latest/)

---
# Day 1 (9AM-7PM)

DenseMap > IF embading maker

also [SubCell](https://www.biorxiv.org/content/10.1101/2024.12.06.627299v1): Vision foundation models for microscopy
capture single-cell biology

some projects:
1. Embedding
2. Building communty network and hierarchy > classic lovien algorithm 
3. Visible Neural Networks (VNN)


Compute:
https://accounts.tacc.utexas.edu/




## let's run IF tutorial and then subcell

1. first try [cm4ai-tutorial-immunofluorescence/](https://github.com/CM4AI/cm4ai-tutorial-immunofluorescence/tree/main])

2. Try HPA Cell Segmenation
need cuda toolkit >> Run on TACC:

`$ ssh username@frontera.tacc.utexas.edu`

# Day 2 (9AM-5PM)