+++
title = "Learning Open-World Visual–Tactile Grasp Stability Prediction with Synthetic Data"
date = 2026-01-01
draft = false
venue = "Manuscript"
authors_before = "Beining Han*, "
authors_self = "Gan Luyang*"
authors_after = ", Derek Geng, Abhishek Joshi, Jia Deng"
venue_note = "* equal contribution"
paper = ""
code = ""
website = ""
image = "images/papers/vitac.png"
image_caption = "Left two columns: grasps that held. Right two columns: grasps that failed. Rows are the real evaluation set, our synthetic training data, synthetic data from Taxim, and real training data."
tldr = "Grasp stability from vision and touch, trained on FEM-simulated data that beats both real data and rigid-body simulation on unseen objects."
+++

Whether a grasp will hold is difficult to judge from vision alone. This work predicts grasp stability
from vision and touch jointly, trained entirely on synthetic data generated with FEM simulation and
ray-traced tactile rendering.

The claim is tested two ways. On physical fidelity, the simulation is compared against rigid-body
simulation and against real contact. On accuracy, predictors trained on this synthetic data are
compared against predictors trained on real-world data and on rigid-body synthetic data, and come
out ahead on both. Evaluation uses a separate open-world set of 333 real grasps, collected with a
hand-held UMI-based gripper on objects and in environments absent from training.
