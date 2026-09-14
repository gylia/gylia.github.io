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

## The question

Before a robot moves an object, it helps to know whether the grip will hold. Existing grasp stability
predictors are trained and tested in one lab, on objects they have already seen. We wanted a predictor
that works zero-shot: novel objects, novel environments, no retraining.

Real visual-tactile data is the obvious way to get there, and it does not scale. Collecting it is slow,
and existing datasets are locked to one gripper, one camera position, one type of tactile sensor and a
small set of objects. Scaling that up to open-world coverage is not realistic.

## The approach

Generate the data instead. The simulator uses FEM to model the deformable gel of the tactile sensor
against a rigid object, with ray-traced rendering for the tactile images. Grasping runs in three
stages, finger closure, force adjustment, and lift, which is what produces a stable and consistent
grasping force rather than an instantaneous contact.

The resulting dataset is over 30,000 visual-tactile pairs from 10,000 unique grasps across 453 objects.

## Does the simulation match reality?

Tested directly, on 5 3D-printed objects with 20 grasps each, by asking how often the simulated
outcome agrees with what actually happened:

| Simulator | Agreement with real outcomes |
| --- | --- |
| Taxim, rigid-body on PyBullet | 0.73 |
| Ours, FEM on Taccel | **0.94** |

The gap has a concrete cause. Rigid-body simulators need convex decomposition for collision detection,
and for objects with complex geometry that decomposition introduces artifacts exactly where contact is
being computed. Modelling the soft gel against the rigid object directly avoids both that and the
approximation of gel deformation.

## Does it train better predictors?

Evaluation uses a separate real dataset of 333 open-world grasps, collected with a hand-held UMI-based
gripper on objects and in environments the model never saw.

| Training data | Accuracy |
| --- | --- |
| Large existing real-world dataset | 53% |
| Synthetic, from Taxim | 61% |
| Synthetic, ours | **77.5%** |

Training on real data lands close to chance, which is the scaling problem showing up as a number.

Vision alone and touch alone were also tested, and neither produces a robust predictor on its own.
For this task the two modalities are not redundant.
