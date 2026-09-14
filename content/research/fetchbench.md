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

Assemble the best fetching pipeline you can from published components, point it at a shelf, and it
succeeds one time in five. Every part of that pipeline has a paper showing it works. We built
FetchBench to find out which part stops working when the object is no longer on a table.

## Background, and the questions

Fetching is the unglamorous thing a home robot would do all day: approach an object, grasp it, bring
it out. The standard recipe splits in two, predict a grasp pose and then plan a collision-free path to
it, and on a table top both halves are in good shape.

A table top is a generous setting. The object sits in the open, the arm can approach from almost any
angle, and a failed plan can simply be retried. Move the same object to the back of a cabinet and the
geometry takes over: only a handful of grasps are reachable at all, and they need not be the ones a
grasp predictor ranks highly. Whether that shift is a nuisance or a wall is an empirical question, and
nobody was measuring it.

So we asked:

1. **Do methods that look strong on table tops survive when reaching is itself hard?**
2. **When the system fails, which component failed?** Grasp prediction, motion planning, or the
   handoff between them.
3. **Would better perception fix it?** This is the expensive assumption, and worth testing before
   anyone spends years on it.

## The benchmark

Scenes are generated procedurally rather than hand-authored, mimicking daily environments: shelves,
cabinets, drawers, baskets, boards. That choice matters for an unglamorous reason, which is that a
fixed set of hand-built scenes is eventually tuned against, and a generator is not. Rendering is in
Isaac Sim.

Because imitation learning needs something to imitate, the benchmark also ships a pipeline that
collects successful fetch trajectories, which lets learned methods be evaluated on the same footing as
classical ones. Baselines then span the range: sense-plan-act assembled from a grasp prediction network
and a motion planner, end-to-end behavior cloning, and hybrids that learn on top of the pipeline.

## 1. The ceiling

| Method | Success |
| --- | --- |
| End-to-end behavior cloning | under 10% |
| Sense-plan-act, novel and partially observed scenes | 13% |
| Best hybrid, grasp prediction + planning + imitation | **20%** |

Twenty percent is the top of the range rather than a weak baseline, and the classical pipeline
considered solved on table tops manages 13%. So the shift is a wall. The next question is where it
stands.

## 2. The environment, not the object

{{< figure src="images/papers/fetchbench_category.png" width="620" class="narrow" caption="Success rate by scene category." >}}

Split by scene type, table tops and drawers stay comfortable while shelves, boards and baskets
collapse. Same grasp predictor, same planner, same object categories: what changes is only what
surrounds the object. Difficulty is a property of the environment, which is the argument for
generating environments rather than curating objects.

## 3. Perception is not the wall

The tempting reading of a 20% success rate is that perception is to blame, since the grasp predictor
works from partial, noisy point clouds. We tested that by handing the pipeline what it wishes it had:
ground-truth grasp annotations instead of predicted ones, and the full scene mesh instead of a partial
point cloud.

Success rises to **67%**. Better, and still a third of attempts failing with nothing left to blame on
seeing.

Those remaining failures are mostly the object slipping during execution. A grasp is annotated in free
space, where it is scored in isolation, and then executed by an arm threading through clutter to reach
it. The pose that was valid on paper is not the pose that gets applied. The gap is between a grasp pose
and an executed grasp, which is a control and contact problem rather than a perception one.

## Limits

Simulation only, so contact physics is an approximation, which is a real caveat for a finding about
contact. Evaluation assumes perfectly segmented point clouds, a gift real perception does not give.
Everything runs on a Franka arm and gripper, so the numbers describe this embodiment.
