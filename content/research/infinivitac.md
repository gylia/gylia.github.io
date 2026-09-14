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

A model trained on a large real-world visual-tactile dataset scores **53%** at predicting whether a
grasp will hold on objects it has not seen before. Coin-flip territory. Train the same model on data
we generated in simulation and it scores **77.5%**.

That gap is the whole project. Real data is supposed to be the gold standard, and here it loses badly
to synthetic data. This page is about why, and what had to be true of the simulator for it to happen.

## Background, and the questions

A robot about to lift something would like to know whether its grip will hold. Vision alone is a poor
judge of this: whether an object slips depends on friction, contact area and how force is distributed
across the fingers, none of which a camera sees. Tactile sensors do see it. The common setup uses a
GelSight-style sensor, a soft gel behind a camera that images its own deformation when pressed
against an object.

The catch is data. Visual-tactile datasets are collected by hand, and each one is locked to a single
gripper, a fixed camera position, one sensor type and a small set of objects. That is fine for
predicting grasps on the objects in the lab. It is hopeless for the open-world case, where the
predictor has to work zero-shot on an unfamiliar object in an unfamiliar place. You cannot collect
your way out of it.

So: generate the data instead. Which raises three questions.

1. **Can a simulator be made physically faithful enough that its grasp outcomes match reality?**
   Grasp stability is decided by contact mechanics, the hardest thing for a simulator to get right.
2. **Does training on synthetic data actually beat training on real data** when the test set is
   open-world?
3. **Is touch pulling its weight**, or would vision alone have done just as well?

## What we built

A synthetic data generator that simulates grasping with FEM rather than rigid bodies. The deformable
gel of the tactile sensor is a tetrahedral FEM body pressed against the object, so gel deformation is
computed rather than approximated, and tactile images come from ray-traced rendering of that
deformation.

Grasping runs in three stages, because a grasp is a process rather than an instant: finger closure at
a set velocity, force adjustment until contact force reaches a stopping threshold, then lift. This is
what produces the steady grasping force that real grasps have.

The resulting dataset is over **30,000 visual-tactile pairs from 10,000 unique grasps across 453
objects**.

## Q1. Does the simulation match reality?

Tested the direct way: 3D-print five objects, run 20 grasps of each in both simulators and in the real
world, and count how often the simulated outcome agrees with the real one.

| Simulator | Agreement with reality |
| --- | --- |
| Taxim, rigid-body on PyBullet | 0.73 |
| Ours, FEM on Taccel | **0.94** |

The failure mode of rigid-body simulation is specific and worth knowing. Rigid-body engines need
convex decomposition to do collision detection, so an object with complex geometry gets approximated
by a union of convex pieces. That approximation introduces artifacts precisely at the contact surface,
which is the one place the answer is decided. Taxim fails hardest on exactly the objects with awkward
geometry. Modelling gel and object directly sidesteps the decomposition entirely.

## Q2 and Q3. Does it train better predictors, and does touch matter?

Evaluation is on a separate real dataset of **333 open-world grasps**, collected with a hand-held
UMI-based gripper on objects and in environments absent from training.

{{< figure src="images/papers/vitac_results.png" width="760" class="narrow" caption="Accuracy on the open-world test set, mean and one standard deviation over 5 runs. V = vision, T = tactile." >}}

| Training data | Accuracy |
| --- | --- |
| Real dataset, vision + tactile | 53% |
| Taxim synthetic, vision + tactile | 62% |
| Ours, vision only | 53% |
| Ours, tactile only | 61%, and unstable |
| Ours, vision + tactile | **77.5%** |

Three things fall out of this chart.

**Real data lands near chance.** Not because the dataset is small or careless, but because open-world
means the test objects are nothing like the training objects. This is the scaling problem showing up
as a number.

**Fidelity is what matters, not synthetic-ness.** Taxim data is synthetic too and only reaches 61%.
Generating data is not automatically a win. Generating data whose contact physics is right is.

**Neither modality gets there alone, and vision is the weaker half.** Trained on our data with vision
only, the model scores 53%, no better than training on the real dataset. Touch alone reaches 61% but
with an error bar spanning 0.50 to 0.72 across runs, which is a model that sometimes works rather than
a model that works. Only the pair reaches 77.5%, and with the tightest spread of anything we ran.

That ordering is the interesting part. If touch were merely confirming what the camera already
suspected, vision-only would be close behind. It is not close. The information that decides a grasp is
mostly not in the image.

## What I would keep from this

The intuition worth carrying forward is that the bottleneck was never data volume. It was whether the
generating process gets contact right. A simulator that is merely fast produces data that trains a
mediocre predictor; a simulator that models deformation correctly produces data that beats
hand-collected reality. That is a statement about where to spend effort in synthetic data pipelines
generally, not only for grasping.
