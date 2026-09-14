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

Fetching means approaching an object, grasping it, and retrieving it. Existing benchmarks mostly sit
on table tops, where motion planning is close to trivial. FetchBench generates scenes procedurally so
that grasping and planning are both required, and ships a data generation pipeline that collects
successful fetch trajectories for imitation learning.

Baselines span the traditional sense-plan-act pipeline through end-to-end behaviour models. None
exceeds 20 percent success. The paper locates the bottlenecks in the pipeline that account for the
gap, and makes recommendations from that analysis.
