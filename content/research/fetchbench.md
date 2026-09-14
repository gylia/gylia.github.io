+++
title = "FetchBench: A Simulation Benchmark for Robot Fetching"
date = 2024-10-01
draft = false
venue = "CoRL 2024"
authors_before = "Beining Han, Meenal Parakh, Derek Geng, Jack A. Defay, "
authors_self = "Gan Luyang"
authors_after = ", Jia Deng"
paper = "https://arxiv.org/abs/2406.11793"
code = "https://github.com/princeton-vl/FetchBench-CORL2024"
website = ""
image = "images/papers/fetchbench.png"
image_caption = "Fetching tasks in the benchmark. The red object must be retrieved from clutter. Scenes are generated procedurally and rendered in Isaac Sim."
tldr = "A benchmark for robot fetching in procedural scenes where grasping and motion planning are both required. Baselines from sense-plan-act pipelines to end-to-end policies top out at 20 percent success."
+++

Hand a robot a perfect grasp pose and a complete 3D model of the scene, then ask it to fetch an object
off a shelf. It succeeds **67%** of the time. Take those gifts away and give it the best pipeline we
could assemble from published components, and success falls to **20%**.

We built FetchBench to find that number, and to find out which part of the system was responsible.

## Background, and the questions

Fetching is the unglamorous thing a home robot would do all day: approach an object, grasp it, bring
it out. The standard recipe splits into predict a grasp pose, then plan a collision-free path to it.
Both halves have strong published methods, and on a table top both work well.

A table top is a generous setting, though. The object is in the open, the arm can approach from
almost any angle, and a failed plan can be retried. Put the same object at the back of a cabinet and
the geometry starts doing the work: only a few grasps are reachable at all, and the ones that are
reachable may not be the ones a grasp predictor likes.

So we asked:

1. **Do methods that look strong on table tops survive when reaching is itself hard?**
2. **When the system fails, which component failed?** Grasp prediction, motion planning, or the
   handoff between them.
3. **Would better perception fix it?** This is the expensive assumption everyone makes.

## What we built

A benchmark where scenes are generated procedurally rather than hand-authored, mimicking daily
environments: shelves, cabinets, drawers, baskets, boards. Procedural generation matters here for a
boring but important reason, which is that a fixed set of hand-built scenes eventually gets tuned
against. Rendering is in Isaac Sim.

FetchBench also ships a data generation pipeline that collects successful fetch trajectories, so
imitation learning methods have training data rather than only an evaluation.

Baselines span the range: classical sense-plan-act built from a grasp prediction network and a motion
planner, through end-to-end behavior cloning, through hybrids that learn on top of the pipeline.

## Q1. The ceiling is low

| Method | Success |
| --- | --- |
| End-to-end behavior cloning | under 10% |
| Sense-plan-act, novel and partially observed scenes | 13% |
| Best hybrid, grasp prediction + planning + imitation | **20%** |

Twenty percent is the top of the range, not a weak baseline. The classical pipeline that is considered
solved on table tops delivers 13% here.

## Q2. The environment decides, not the object

{{< figure src="images/papers/fetchbench_category.png" width="620" class="narrow" caption="Success rate by scene category. Table tops and drawers are a different problem from shelves, boards and baskets." >}}

Broken down by scene type, table tops and drawers are comfortably the easiest, while shelves, boards
and baskets collapse. The same grasp predictor and the same planner, on the same object categories,
differ enormously depending on what surrounds the object.

This is the argument for the benchmark existing. A method evaluated only on table tops would report a
respectable number and tell you nothing about the setting you actually care about.

## Q3. Better perception would not save you

The tempting read of a 20% success rate is that perception is the problem: the grasp predictor is
working from partial, noisy point clouds, so of course it struggles. We tested that directly by
handing the pipeline what it wishes it had. Ground-truth grasp annotations instead of predicted ones.
The full scene mesh instead of a partial point cloud.

Success rises to 67%. Better, and still not close to solved.

The residual failures are mostly the object slipping during execution. A grasp annotated in free space,
where it is evaluated in isolation, behaves differently once the arm is actually moving through a
cluttered scene to reach it. The gap is not in seeing the world, it is in the fact that a grasp pose
and an executed grasp are different objects.

## Limits

Simulation only, so contact physics is an approximation of the real thing. Evaluation assumes
perfectly segmented point clouds, which is a gift real perception does not give. Everything runs on a
Franka arm and gripper, so the numbers are about this embodiment.
