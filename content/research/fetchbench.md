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

Fetching is the whole sequence: approach an object, grasp it, bring it out. FetchBench asks how well
current methods do it when the object is not on a table top, and the answer is that the best baseline
we assembled reaches about **20%**. The paper's contribution is not that number alone but the
decomposition underneath it, which separates how much of the failure belongs to grasp prediction, to
partial observation, and to execution.

Paper: [arXiv:2406.11793](https://arxiv.org/abs/2406.11793) · Code:
[princeton-vl/FetchBench-CORL2024](https://github.com/princeton-vl/FetchBench-CORL2024)

## What the benchmark contains

**The task.** A 7-DOF Franka arm with a Franka gripper is spawned in front of a scene in Isaac Gym.
Two cameras on either side give a partial point cloud, with randomised poses that keep the whole scene
in view. The method receives the segmented point cloud and joint states, and must bring the target
object out to free space. A trajectory counts as successful only if the task completes **with no other
object significantly displaced**, so knocking the shelf over on the way out does not count. Average
computation time and C-space trajectory length are reported as secondary metrics.

{{< figure src="images/papers/fetchbench_task.png" width="880" caption="Task definition: the agent receives joint and gripper states plus a segmented point cloud, and outputs delta joint movements." >}}

Segmentation masks for the robot and target object are assumed given. The paper argues this is
practical with eye-to-hand calibration and off-the-shelf models, citing
[SAM](https://arxiv.org/abs/2304.02643) for segmentation and
[XMem](https://arxiv.org/abs/2207.07115) for tracking, and lists the assumption again as a limitation.

**The scenes.** 13 types of procedural scene built from [Infinigen](https://infinigen.org/) assets,
with **310+ independent parameters** that can be sampled to produce distinct instances. Support
surfaces are annotated automatically into four categories, **on-table, on-shelf, in-drawer and
in-basket**, which is what makes per-category evaluation possible.

{{< figure src="images/papers/fetchbench_scenes.png" width="880" caption="Procedural scenes built from Infinigen assets (top), with IKEA furniture counterparts that can be reproduced in the real world (bottom)." >}}

**The objects.** **5,544 objects**, mostly from [ACRONYM](https://arxiv.org/abs/2011.09584),
plus procedurally generated ones from Infinigen such as plates, food bags, containers and forks. Grasp
poses are labelled in Isaac Gym. The split is roughly **7:1**, with the test split used only for
evaluation.

**The tasks.** Objects are placed on support surfaces in random stable poses, and robot position,
camera poses, friction, restitution and object density are all randomised. Instances are filtered out
when an object is not static at initialisation, when no collision-free IK solution exists for any
annotated grasp pose, or when the target is near absent from the input point cloud. What remains is
**6,000 test tasks**: 1,526 on-table, 2,724 on-shelf, 891 in-basket, 859 in-drawer.

**The training data.** For imitation learning the benchmark ships a generated dataset of fetch
trajectories, produced by iterating over valid grasp poses and motion planning the approach and
retrieval phases with [CuRobo](https://curobo.org/), which the paper found more efficient and
shorter-path than [OMPL](https://ompl.kavrakilab.org/). The released set is **27.5k trajectories, over
3.6M frames, across 5.7k task instances**, and the pipeline can generate more.

## What the baselines are

{{< figure src="images/papers/fetchbench_pipeline.png" width="920" caption="The sense-plan-act pipeline the classical baselines follow: predict grasp poses from the partial point cloud, plan to pre-grasp, grasp, lift to post-grasp, plan out to free space." >}}

Three families are evaluated.

**Sense-plan-act.** [ContactGraspNet](https://arxiv.org/abs/2103.14127) predicts 6-DoF grasp poses,
followed by a motion planner: CuRobo (**CGN-CuRobo**) or
RRT-Connect (**CGN-RRTConnect**). A third variant,
**CGN-Cabinet**, replaces the planner with MPPI iterations driven
by [CabiNet](https://arxiv.org/abs/2304.09302)'s neural collision checker and waypoint proposals.

**End-to-end imitation.** Segmented point clouds are encoded and concatenated with joint and
end-effector embeddings, then passed to a backbone: an MLP after
[Robomimic](https://arxiv.org/abs/2108.03298) (**E2EImit-MLP**) or a history-conditioned transformer
after [Optimus](https://arxiv.org/abs/2305.16309) (**E2EImit-Transformer**).

**Hybrid.** **CGN-CuRobo-Imit** runs the pipeline for approach and grasp, then hands the retrieval
phase to the behaviour-cloned policy, in MLP and transformer variants.

## Results

| Method | Success | Computation time (s) | C-space length (rad) |
| --- | --- | --- | --- |
| CGN-CuRobo | 0.094 | 16.4 | 6.17 |
| CGN-RRTConnect | 0.131 | 139.0 | 12.4 |
| CGN-Cabinet | 0.121 | 42.3 | **5.82** |
| E2EImit-MLP | 0.082 | 58.6 | 38.4 |
| E2EImit-Transformer | 0.099 | 57.5 | 22.3 |
| CGN-CuRobo-Imit-MLP | 0.200 | 17.0 | 20.7 |
| CGN-CuRobo-Imit-Transformer | **0.203** | **16.1** | 6.32 |

The maximum any baseline reaches is about 20%, which the paper reads as the task being far from
solved. End-to-end policies stay under 10%; the paper attributes this to the grasping phase, where the
model has to learn collision-free planning and generalise across object shapes at the same time.

The hybrid variants do best, and the paper's explanation is decomposition: in the approach phase a
grasp prediction model generalises to novel objects better than an end-to-end policy, while in the
retrieval phase the behaviour model sidesteps motion planning in a partial point cloud by using
what the demonstrations taught it implicitly.

{{< figure src="images/papers/fetchbench_category.png" width="620" class="narrow" caption="Success rate by scene category." >}}

Split by category, the paper reports that fetching from shelves, boards and baskets is significantly
harder than from table tops and drawers, which it takes as an argument for benchmarks that span the
range of everyday scenes.

## Where the pipeline breaks

The ablation replaces pipeline components with oracles and reports each phase separately, so failures
can be attributed rather than guessed at.

| Ablation | Approach plan | Approach exec | Retrieval plan | Final success |
| --- | --- | --- | --- | --- |
| GA-Mesh-CuRobo | 0.865 | 0.861 | 0.776 | 0.671 |
| GA-Mesh-RRTConnect | 0.947 | 0.903 | 0.681 | 0.529 |
| GA-Ptd-CuRobo | 0.792 | 0.705 | 0.321 | 0.190 |
| GA-Ptd-RRTConnect | 0.949 | 0.678 | 0.502 | 0.306 |
| CGN-Mesh-CuRobo | 0.611 | 0.602 | 0.546 | 0.336 |
| CGN-Mesh-RRTConnect | 0.607 | – | 0.478 | 0.275 |

**Oracle grasps and an oracle mesh give 67%.** With annotated grasp poses that admit a collision-free
IK solution and the ground-truth scene mesh for planning, CuRobo reaches 67% and RRTConnect 53%. Among
the GA-Mesh-CuRobo failures, motion planning fails in 14% of cases reaching the pre-grasp pose and 9%
reaching the end state, and in a further 10% the object slips from the gripper during fetching. The
paper attributes the slipping to grasp poses being annotated in free space: there the object settles
against the gripper, while in clutter it can collide with neighbours or the support surface.

**Replacing the mesh with a partial point cloud costs more than anything else.** GA-Ptd-CuRobo drops
to 19% and GA-Ptd-RRTConnect to 31%. The paper's reading is that planning against a partially observed
point cloud underestimates collisions at execution time: GA-Ptd-RRTConnect finds a collision-free path
to pre-grasp in 95% of cases but executes successfully only 68% of the time, and in the retrieval
phase plans successfully 50% of the time for a 31% final success. That gap between planning and
execution is markedly wider than under GA-Mesh.

**Grasp prediction costs about half.** CGN-Mesh-CuRobo reaches 34% and CGN-Mesh-RRTConnect 28%, which
the paper describes as roughly a 50% drop relative to the GA-Mesh ablations, leaving room for better
grasp pose prediction.

### Retrying is not the answer

{{< figure src="images/papers/fetchbench_retry.png" width="920" caption="Running the pipeline once versus retrying up to five times, across success rate, computation time and trajectory length." >}}

Retrying up to five times improves success by 8% to 13% depending on the ablation, but average
computation time almost doubles and average trajectory length grows by 75%. The paper's conclusion is
that naive retrial is inefficient and that more flexible re-grasping skills are needed.

## On a real robot

{{< figure src="images/papers/fetchbench_real.png" width="880" caption="Real-world fetching scenes." >}}

The difficulty is not an artifact of simulation. Using CGN-RRTConnect with
[MoveIt](https://moveit.ai/) on 52 on-table, 83 on-shelf and 32 in-basket tasks over 26 objects, total
success is **21%**: 38% on table tops, 13.3% on shelves, 12.5% in baskets. The failures break down as
25.8% from low-quality grasp poses where the object slips, 27.3% from motion planning failure, 23.5%
from unexpected collision with the scene, and the rest from no grasp proposals at all.

## Limitations

The paper lists three. It is simulation-based, so sim-to-real discrepancies remain, particularly in
contact physics. Evaluation assumes perfectly segmented point clouds, where real perception has
segmentation noise and struggles with non-Lambertian objects. And everything is run on a Franka arm
and gripper, so extending to other robots and wider object coverage is left to future work.

Full experimental details, the appendix ablations, and the real-robot videos are in the
[paper](https://arxiv.org/abs/2406.11793); the benchmark and dataset generation code are on
[GitHub](https://github.com/princeton-vl/FetchBench-CORL2024).
