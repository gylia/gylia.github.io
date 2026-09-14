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

## The question

Most manipulation benchmarks live on a table top, where the object is reachable and motion planning
is close to trivial. Daily life is not like that. Things sit on shelves, inside cabinets, at the back
of drawers, under other things. We wanted to know whether methods that look strong on table tops do
anything useful once reaching the object is itself a problem.

Fetching is the whole sequence: approach, grasp, retrieve. It fails if any stage fails, which makes
it a harder and more honest test than scoring grasp poses in isolation.

## What we built

Scenes are generated procedurally rather than hand-built, so the benchmark is not a fixed set of
puzzles that methods can be tuned against. The generator mimics daily environments: shelves, cabinets,
drawers, baskets, boards. Rendering is done in Isaac Sim.

The benchmark also ships a data generation pipeline that collects successful fetch trajectories, so
imitation learning methods have something to train on.

## What we found

**The ceiling is low.** No baseline exceeds roughly 20 percent success. The best is a transformer
variant combining a grasp predictor, motion planning and imitation, at 20 percent. End-to-end behavior
cloning stays under 10 percent. The classical sense-plan-act pipeline, which is reliable on table
tops, drops to 13 percent in novel, complex, partially observed scenes.

**The environment matters more than the object.** Broken down by scene type, shelves, boards and
baskets are dramatically harder than table tops and drawers. A benchmark restricted to table tops
would have reported none of this.

**Perception is not the whole story.** We ran an ablation giving the pipeline ideal information:
ground-truth grasp annotations and the full scene mesh for motion planning. Success only reaches 67
percent. The remaining failures are largely objects slipping, because a grasp annotated in free space
behaves differently when it is actually executed. Better perception alone would not close the gap.

## Limits

The benchmark is simulation-only, so contact physics will not match reality exactly. Evaluation
assumes perfectly segmented point clouds, which real perception does not provide. Everything is run
on a Franka arm and gripper.
