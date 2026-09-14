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

This paper was never published, so this page is the full account of it.

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

## The simulator

Prior synthetic tactile data comes from rigid-body engines. We use FEM instead, on
[Taccel](https://arxiv.org/abs/2504.12908), which is built on the IPC contact framework, because the
quantity we need to get right is the deformation of a soft gel against a rigid object.

The gripper is reduced to what matters: two tetrahedral FEM bodies, 2.5 × 2 × 0.4 cm, standing in for
the gels of two GelSight Mini sensors, with Young's modulus 10⁶ Pa and Poisson ratio 0.3. Vertices on
the back of each gel are **active nodes** driven by a target velocity at kinematic stiffness 5 × 10⁴;
everything else is passive and free to deform. The object is loaded as a rigid ABD body carrying its
own mass and friction coefficient.

### A grasp is a process, not an instant

The part that took the most iteration is that a grasp cannot be simulated as a single closing motion.

{{< figure src="images/papers/vitac_stages.png" width="700" class="narrow" caption="Contact force on both gels through a stable grasp of the ORG object. The dotted line is the stopping threshold. Below, the physical state of gels and object at the end of each stage: red points are passive gel vertices, black points are the active nodes driven by target velocity." >}}

1. **Finger closure.** Gels close at 1 cm/s. At each step we sum the contact force over all passive
   vertices along the closing direction. When both gels exceed a stopping threshold, or the fingers
   fully close, the stage ends.
2. **Force adjustment.** Early gel-object contact produces wildly unstable forces, visible as the
   spike in the plot above. So the gripper spends 1.5 s in closed loop, opening at 0.2 cm/s when the
   mean force runs above threshold and closing at 0.2 cm/s when it runs below, until the force settles.
3. **Lifting.** The gripper rises at 2 cm/s to 5 cm, still regulating force. The grasp counts as a
   success if every point of the object ends more than 2 cm off the ground.

The training sample is rendered from the **last frame of the force adjustment stage**, which is the
moment a real predictor would have to commit: contact has stabilised, the lift has not yet happened.

Accuracy here is bought with time. A 0.01 s step, contact stiffness 3 × 10⁶ kg·s⁻², contact distance
threshold 5 × 10⁻⁴ m, and a CG solver held to 5 × 10⁻⁵ tolerance over up to 10⁴ steps make the
simulation slow, but they are what keep the contact force consistent enough to be worth labelling.

### The tactile renderer

Taccel's built-in renderer casts rays at the **tetrahedron surface** to build a depth map. With gels
meshed as coarsely as ours, that surface is faceted, so the depth map inherits a checkered pattern and
a contact patch larger than the real one.

The fix is small and worth stating plainly: cast the rays at the **object mesh** instead. We know the
object's geometry, its pose, and the pose of the image plane, so the intersection can be computed
directly and clipped by gel thickness, with RGB rendered in OpenGL over LED colours and positions
tuned against real readings.

{{< figure src="images/papers/vitac_renderer.png" width="880" caption="Left to right: the real sensor at rest, the real sensor pressed against the ORG object, our render, and Taccel's built-in render. Top row is the left finger, bottom the right." >}}

### Objects, textures and light

Meshes and grasp poses come from ACRONYM, which supplies neither texture nor physical properties. We
prompt GPT-4o for a plausible texture type from the object category, generate the UV map with Paint3D,
and prompt GPT-4o again for mass and friction given category, dimensions and texture.

Visual frames are ray-traced in IsaacSim Replicator with the full gripper geometry reconstructed from
the gel poses, randomised ground textures, and HDRI dome lighting from PolyHaven at random intensity.
The camera sits eye-in-hand, matching the real rig, with pose and focal length jitter.

### What came out

453 objects, 10k+ collision-free grasps simulated at two stopping thresholds (10 N and 40 N), three
randomised renders each. **30k+ visual-tactile pairs from 10k+ unique grasps**, costing roughly
**2,500 GPU hours** of physics and another 20 for rendering. The raw result skews positive and skews
toward easy categories such as mugs, so the training set is resampled to balance both.

## The real data

No open-world visual-tactile grasping dataset existed, so we built the rig and collected one.

{{< figure src="images/papers/vitac_gripper.jpg" width="620" class="narrow" caption="The hand-held gripper: UMI mechanics, two GelSight Mini sensors on modified fingers, and a RealSense D435 centred for a symmetric view." >}}

Because a person actuates it, data can be collected anywhere, at whatever grip force a hand happens to
apply, which is the point.

**Open-world set.** 60 everyday objects, some from YCB, deliberately including transparent and
reflective ones such as glasses and forks, across 10 real scenes: classrooms, kitchens, offices. The
operator picks a grasp, squeezes, saves the frame before lifting, then lifts and records the outcome.
**333 grasps, 163 failures and 170 successes**, split 67 for validation and 266 for test.

{{< figure src="images/papers/vitac_objects.png" width="760" caption="The open-world object set. Transparent and reflective items are included on purpose: they are where vision is least reliable." >}}

**Grasp-annotated set.** Five 3D-printed objects with deliberately awkward geometry, some from EGAD,
the kind usually called adversarial for grasping. 20 grasps each, with ground-truth grasp poses
recovered from ArUco markers on a board and on the gripper. This set exists to compare simulators,
which needs the grasp pose known exactly.

## 1. Fidelity

Replay all 20 grasps per object in both simulators and count how often the simulated outcome matches
what really happened. Neither friction nor grip force is known, so both simulators get the same
treatment: a grid search over friction coefficient and stopping force, with the best combination
reported.

| Simulator | B1 | B4 | C2 | C4 | ORG | Avg |
| --- | --- | --- | --- | --- | --- | --- |
| Taxim, rigid-body on PyBullet | 0.55 | 0.85 | 0.95 | 0.65 | 0.65 | 0.73 |
| Ours, FEM on Taccel | 0.90 | 1.00 | 0.95 | 0.90 | 0.95 | **0.94** |

The failures cluster on B1, C4 and ORG, the three most awkward shapes, and there are two reasons.

Rigid-body engines need **convex decomposition** for collision detection, so an object with concavities
becomes a union of convex pieces, and the approximation error lands on the contact surface, the one
place the outcome is decided. Second, a real gel **wraps** around what it touches, spreading contact
over a surface; rigid-rigid contact between a flat fingertip and an object gives you a point instead.
FEM avoids the decomposition entirely and models the wrap directly.

{{< figure src="images/papers/vitac_simreal.png" width="880" caption="ORG on the left, B4 on the right. Top row real, middle ours, bottom Taxim. Taxim either loses most of the signal (ORG) or fills the reading with artifacts (B4)." >}}

Fidelity is worth having on its own terms, but it only matters here if it survives into a trained
model.

## 2 and 3. Transfer, and whether touch earns its place

The predictor is deliberately ordinary, so that the data is what is being compared. Tactile input is
the **change** in reading, grasp minus initialisation, rather than the raw image. Two 240 × 320 tactile
images and one 240 × 320 RGB frame each go through a 4-layer CNN with BatchNorm and ReLU into 512-dim
embeddings; the three are concatenated and read out by a 2-layer MLP with a sigmoid. Adam at 3 × 10⁻⁴,
five seeds, checkpoint chosen on validation accuracy, evaluated on the held-out real test set.

Two baselines. **Real** is the Calandra et al. dataset: 9.2k grasps over 106 objects, collected on a
Sawyer mount with a different GelSight model and a third-person camera. **Taxim** is a synthetic set
built to be as close to ours as possible, same objects, physical properties, textures, backgrounds,
grasp poses and balancing, differing only in the simulator and tactile renderer, at 33k+ pairs from
11k+ grasps.

{{< figure src="images/papers/vitac_results.png" width="760" class="narrow" caption="Accuracy on the open-world test set, mean and one standard deviation over 5 runs. V = vision, T = tactile." >}}

| Training data | Accuracy |
| --- | --- |
| Real dataset, vision + tactile | 53% |
| Taxim synthetic, vision + tactile | 62% |
| Ours, vision only | 53.2% |
| Ours, tactile only | 61.1%, and unstable |
| Ours, vision + tactile | **77.5%** |

**Real data lands at chance,** and not because it is small or careless. It is bound to one embodiment,
one sensor, one camera angle, one object set, and open-world test objects fall outside all of them.
The distribution shift, not the sample count, is what costs the accuracy.

**Taxim is synthetic too, and reaches 62%.** Generating data is not what helps. Generating data whose
contact physics is right is. The fidelity result and the transfer result are the same result seen
twice.

**Vision alone scores 53.2%, indistinguishable from guessing.** The cause is mundane and instructive:
the camera is eye-in-hand, so at the moment of grasp roughly half the object is occluded by the
gripper. There is often not enough of the object left in frame to infer its geometry, let alone its
mass or friction.

**Touch alone reaches 61.1% but swings wildly between seeds.** That is a model which sometimes works,
not one that works. Only the pair reaches 77.5%, with the tightest spread of anything we ran. The
reading is that tactile carries the contact and the force while vision carries category and texture,
which are proxies for mass and friction, and the prediction needs both.

## Takeaway

The bottleneck was never volume. It was whether the process producing the data gets contact right, and
that is a property you can lose by choosing a faster simulator. Fidelity at the point of contact is
what a synthetic pipeline is actually buying, here and, I suspect, wherever the label depends on
physics.

The honest limitation is that all of this is one gripper, two GelSight Minis, and a parallel-jaw
geometry. The claim that synthetic data transfers better than real data is established here for that
embodiment, on 333 real grasps. Whether the same holds for other hands and other sensors is exactly
the kind of thing the pipeline was built to make cheap to test, and it has not been tested yet.
