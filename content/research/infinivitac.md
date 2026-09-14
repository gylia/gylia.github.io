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

A model trained on a large real-world visual-tactile dataset predicts grasp success on unfamiliar
objects at **53%**, which is a coin flip. Trained on data we generated in simulation, the same model
reaches **77.5%**. Real data is supposed to be the gold standard, and the reason it loses here is not
that there was too little of it.

## Background, and the questions

Whether a grip holds is settled by friction, contact area, and how force distributes across the
fingers. A camera sees none of these, which is why grasp stability is normally predicted with a
tactile sensor: a GelSight-style soft gel behind a camera, imaging its own deformation as it presses
against the object.

Those sensors are also what makes the data hard to come by. Visual-tactile datasets are collected by
hand, and each one ends up bound to a single gripper, a fixed camera position, one sensor model and a
modest set of objects. A predictor trained on such a dataset inherits every one of those constraints.
For the open-world case, where the object and the room are both unfamiliar, no feasible amount of
further collection undoes that.

Generating the data instead raises three questions.

1. **Can a simulator be faithful enough that its grasp outcomes match reality?** Contact mechanics is
   the hardest thing for a simulator to get right, and it is precisely what the label depends on.
2. **Does training on synthetic data beat training on real data** once the test set is open-world?
3. **Is touch earning its place**, or would vision alone have done as well?

## The generator

Grasping is simulated with FEM rather than rigid bodies. The deformable gel is a tetrahedral FEM body
pressed against the object, so its deformation is computed rather than approximated, and the tactile
image is a ray-traced render of that deformation.

A grasp is treated as a process rather than an instant: fingers close at a set velocity, force is
adjusted until contact reaches a stopping threshold, then the gripper lifts. That is what produces the
steady grasping force a real grasp has, and what makes the simulated outcome meaningful at all.

The dataset it produced is **30,000 visual-tactile pairs from 10,000 grasps across 453 objects**.

## 1. Fidelity

The direct test: 3D-print five objects, run 20 grasps of each in simulation and in reality, and count
how often the simulated outcome agrees with the real one.

| Simulator | Agreement with reality |
| --- | --- |
| Taxim, rigid-body on PyBullet | 0.73 |
| Ours, FEM on Taccel | **0.94** |

The rigid-body failure has a specific cause. Those engines need convex decomposition for collision
detection, so an object with awkward geometry is replaced by a union of convex pieces, and the
artifacts land on the contact surface, the one place the outcome is decided. Taxim fails hardest on
exactly the objects whose geometry decomposes worst. Solving gel against object directly avoids the
approximation rather than refining it.

Fidelity is worth having on its own terms, but it only matters here if it survives into a trained
model.

## 2 and 3. Transfer, and whether touch earns its place

Testing that needs a set no simulator touched: **333 open-world grasps**, collected with a hand-held
UMI-based gripper on objects and in environments absent from training.

{{< figure src="images/papers/vitac_results.png" width="760" class="narrow" caption="Accuracy on the open-world test set, mean and one standard deviation over 5 runs. V = vision, T = tactile." >}}

| Training data | Accuracy |
| --- | --- |
| Real dataset, vision + tactile | 53% |
| Taxim synthetic, vision + tactile | 62% |
| Ours, vision only | 53% |
| Ours, tactile only | 61%, and unstable |
| Ours, vision + tactile | **77.5%** |

Taxim data is synthetic too, and it reaches 62%. Generating data is not the thing that helps;
generating data whose contact physics is right is. The fidelity result and the transfer result are the
same result seen twice.

The modality rows answer the third question more sharply than we expected. Vision alone, trained on
our data, scores the same 53% as the real dataset. Touch alone reaches 61% with an error bar spanning
0.50 to 0.72, which describes a model that sometimes works rather than one that works. Only the pair
reaches 77.5%, and with the tightest spread of anything we ran. Were touch merely confirming what the
camera suspected, vision-only would be close behind. It is not close.

## Takeaway

The bottleneck was never volume. It was whether the process producing the data gets contact right, and
that is a property you can lose by choosing a faster simulator. Fidelity at the point of contact is
what a synthetic pipeline is actually buying, here and, I suspect, wherever the label depends on
physics.
